use std::{io::Write, ptr};

use eframe::egui::{self, Color32, ColorImage, FontData, FontDefinitions, FontFamily, vec2};
use egui::epaint::text::{
    FontPriority, GlyphBitmap, GlyphRasterizer, GlyphRasterizerRequest, RasterizedGlyph,
};
use fontconfig_sys as fc;
use freetype_sys as ffi;
use pango::{FontDescription, Layout, glib::translate::*, prelude::*};
use tempfile::NamedTempFile;

// gtk-rs exposes Pango but not PangoFT2. These functions are linked by build.rs.
unsafe extern "C" {
    fn pango_ft2_font_map_new() -> *mut pango::ffi::PangoFontMap;
    fn pango_fc_font_map_set_config(map: *mut pango::ffi::PangoFontMap, config: *mut fc::FcConfig);
    fn FcConfigParseAndLoadFromMemory(
        config: *mut fc::FcConfig,
        xml: *const u8,
        complain: fc::FcBool,
    ) -> fc::FcBool;
    fn pango_fc_font_lock_face(font: *mut pango::ffi::PangoFont) -> ffi::FT_Face;
    fn pango_fc_font_unlock_face(font: *mut pango::ffi::PangoFont);
    #[cfg(test)]
    fn pango_fc_font_get_pattern(font: *mut pango::ffi::PangoFont) -> *mut fc::FcPattern;
    fn pango_ft2_render_layout(
        bitmap: *mut ffi::FT_Bitmap,
        layout: *mut pango::ffi::PangoLayout,
        x: i32,
        y: i32,
    );
}

thread_local! {
    // Pango objects stay on their creating thread; egui's callback is Send + Sync.
    static FONTS: MonochromeFonts = MonochromeFonts::new();
}

pub fn install(ctx: &egui::Context) {
    ctx.set_fonts(definitions());
    ctx.add_glyph_rasterizer(
        GlyphRasterizer::new("zine::monochrome", |request| {
            Some(FONTS.with(|fonts| fonts.rasterize(request)))
        })
        .with_priority(FontPriority::Highest),
    );
    ctx.add_plugin(NearestFontSampling);
}

fn definitions() -> FontDefinitions {
    let mut fonts = FontDefinitions::default();
    for (name, bytes) in [
        (
            "Droid Sans",
            include_bytes!("../assets/fonts/DroidSans.ttf").as_slice(),
        ),
        (
            "Droid Sans Bold",
            include_bytes!("../assets/fonts/DroidSans-Bold.ttf").as_slice(),
        ),
        (
            "Michroma",
            include_bytes!("../assets/fonts/Michroma-Regular.ttf").as_slice(),
        ),
    ] {
        fonts
            .font_data
            .insert(name.into(), FontData::from_static(bytes).into());
        let family = if name == "Droid Sans" {
            FontFamily::Proportional
        } else {
            FontFamily::Name(name.into())
        };
        // egui uses the primary font for line metrics; Pango selects fallbacks.
        fonts.families.insert(family, vec![name.into()]);
    }
    fonts
}

struct MonochromeFonts {
    context: pango::Context,
    // Pango loads fonts from files. Keep the embedded font files alive with the map.
    _files: Vec<NamedTempFile>,
}

impl MonochromeFonts {
    fn new() -> Self {
        // Keep font discovery, but override rendering rules in a private config.
        // A target="font" rule must run after matching; request options can be
        // overridden by user rules (including a global hintnone setting).
        // SAFETY: The config/map are newly owned. Pango retains the config, and
        // from_glib_full takes ownership of the map. Nothing crosses threads.
        let map: pango::FontMap = unsafe {
            let config = fc::FcInitLoadConfigAndFonts();
            assert!(!config.is_null(), "load Fontconfig configuration");
            let configured = FcConfigParseAndLoadFromMemory(
                config,
                cr#"
                <fontconfig><match target="font">
                  <edit name="antialias" mode="assign"><bool>false</bool></edit>
                  <edit name="hinting" mode="assign"><bool>true</bool></edit>
                  <edit name="hintstyle" mode="assign"><const>hintfull</const></edit>
                  <edit name="autohint" mode="assign"><bool>false</bool></edit>
                </match></fontconfig>
            "#
                .as_ptr()
                .cast(),
                1,
            );
            assert_ne!(configured, 0, "configure mono hinting and rendering");
            let map = pango_ft2_font_map_new();
            pango_fc_font_map_set_config(map, config);
            fc::FcConfigDestroy(config);
            from_glib_full(map)
        };
        let files = definitions()
            .font_data
            .values()
            .map(|data| {
                let mut file = NamedTempFile::new().expect("create embedded font file");
                file.write_all(data.bytes()).expect("write embedded font");
                map.add_font_file(file.path())
                    .expect("register embedded font with Pango");
                file
            })
            .collect();
        let context = map.create_context();
        context.set_round_glyph_positions(true);
        // Each FT2 map owns a FreeType library shared by its primary/fallback fonts.
        let font = context
            .load_font(&FontDescription::from_string("Droid Sans 12"))
            .expect("load FreeType font");
        let version: ffi::FT_UInt = 35;
        // SAFETY: Access the map's library through its locked face, then unlock
        // before checking the result. Configure it before shaping any layout.
        let error = unsafe {
            let face = pango_fc_font_lock_face(font.to_glib_none().0);
            assert!(!face.is_null(), "lock Pango FreeType face");
            let error = ffi::FT_Property_Set(
                (*(*face).glyph).library,
                c"truetype".as_ptr(),
                c"interpreter-version".as_ptr(),
                (&version as *const ffi::FT_UInt).cast(),
            );
            pango_fc_font_unlock_face(font.to_glib_none().0);
            error
        };
        assert_eq!(error, 0, "set FreeType interpreter version to 35");
        Self {
            context,
            _files: files,
        }
    }

    fn layout(&self, request: &GlyphRasterizerRequest<'_>, text: &str) -> Layout {
        let family = match request.family {
            FontFamily::Proportional => "Droid Sans",
            FontFamily::Monospace => "Hack",
            FontFamily::Name(name) => name.as_ref(),
        };
        let mut description = FontDescription::from_string(family);
        description.set_absolute_size(request.font_size_px as f64 * pango::SCALE as f64);
        let layout = Layout::new(&self.context);
        layout.set_font_description(Some(&description));
        layout.set_single_paragraph_mode(true);
        layout.set_text(text);
        layout
    }

    fn rasterize(&self, request: &GlyphRasterizerRequest<'_>) -> RasterizedGlyph {
        let (text, multiplier) = match request.cluster {
            "\t" => (" ", 4.0),
            "\u{2009}" | "\u{202f}" => (" ", 0.5),
            text => (text, 1.0),
        };
        let layout = self.layout(request, text);
        let (ink, _) = layout.pixel_extents();
        let (width, height) = (ink.width().max(1), ink.height().max(1));
        let mut coverage = vec![0u8; width as usize * height as usize];
        // PangoFT2 composites mono glyphs into an 8-bit destination, expanding
        // each bit to 0/255. It also positions and combines all glyphs in the layout.
        let mut bitmap = ffi::FT_Bitmap {
            rows: height,
            width,
            pitch: width,
            buffer: coverage.as_mut_ptr(),
            num_grays: 256,
            pixel_mode: ffi::FT_PIXEL_MODE_GRAY as _,
            palette_mode: 0,
            palette: ptr::null_mut(),
        };
        // SAFETY: The bitmap describes the live, writable coverage buffer, and
        // Pango only borrows it and the layout during this call.
        unsafe {
            pango_ft2_render_layout(&mut bitmap, layout.to_glib_none().0, -ink.x(), -ink.y());
        }
        let pixels = coverage
            .into_iter()
            .map(Color32::from_white_alpha)
            .collect();
        RasterizedGlyph {
            bitmap: GlyphBitmap {
                image: ColorImage::new([width as usize, height as usize], pixels),
                offset_px: vec2(
                    ink.x() as f32 + request.subpixel_offset_px.round(),
                    ink.y() as f32 - layout.baseline() as f32 / pango::SCALE as f32,
                ),
                is_color: false,
            },
            advance_px: layout.size().0 as f32 / pango::SCALE as f32 * multiplier,
        }
    }
}

struct NearestFontSampling;

impl egui::Plugin for NearestFontSampling {
    fn debug_name(&self) -> &'static str {
        "nearest font sampling"
    }

    fn output_hook(&mut self, _ctx: &egui::Context, output: &mut egui::FullOutput) {
        // Only change sampling. Glyph pixels already have binary coverage when
        // they leave the rasterizer; no atlas pixels are inspected or rewritten here.
        for (id, delta) in &mut output.textures_delta.set {
            if *id == egui::TextureId::default() {
                for patch in delta {
                    patch.options = egui::TextureOptions::NEAREST;
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use fc::constants::*;

    fn request<'a>(
        cluster: &'a str,
        family: &'a FontFamily,
        size: f32,
    ) -> GlyphRasterizerRequest<'a> {
        GlyphRasterizerRequest {
            cluster,
            family,
            font_size_px: size,
            subpixel_offset_px: 0.0,
        }
    }

    fn assert_binary(glyph: &RasterizedGlyph) {
        assert!(
            glyph
                .bitmap
                .image
                .pixels
                .iter()
                .all(|&pixel| pixel == Color32::TRANSPARENT || pixel == Color32::WHITE)
        );
    }

    #[test]
    fn all_families_render_binary_at_multiple_pixel_sizes() {
        let fonts = MonochromeFonts::new();
        for family in definitions().families.keys() {
            for size in [10.0, 12.0, 15.0, 17.5, 20.0, 24.0] {
                for cluster in ["A", "g", "@", "→", "é", "x\u{301}", "\u{10ffff}"] {
                    let glyph = fonts.rasterize(&request(cluster, family, size));
                    assert_binary(&glyph);
                    assert!(
                        glyph.bitmap.image.pixels.contains(&Color32::WHITE),
                        "{family:?} {cluster} {size}"
                    );
                    assert!(glyph.advance_px > 0.0);
                }
            }
        }
    }

    #[test]
    fn spaces_are_invisible_and_keep_their_advances() {
        let fonts = MonochromeFonts::new();
        let family = FontFamily::Proportional;
        let space = fonts.rasterize(&request(" ", &family, 24.0));
        assert!(space.advance_px > 0.0);
        for (cluster, multiplier) in [
            (" ", 1.0),
            ("\t", 4.0),
            ("\u{2009}", 0.5),
            ("\u{202f}", 0.5),
        ] {
            let glyph = fonts.rasterize(&request(cluster, &family, 24.0));
            assert_eq!(glyph.advance_px, space.advance_px * multiplier);
            assert!(!glyph.bitmap.image.pixels.is_empty());
            assert!(
                glyph
                    .bitmap
                    .image
                    .pixels
                    .iter()
                    .all(|&pixel| pixel == Color32::TRANSPARENT)
            );
        }
    }

    #[test]
    fn combining_marks_are_shaped_with_the_base_glyph() {
        let fonts = MonochromeFonts::new();
        let family = FontFamily::Proportional;
        let composed = fonts.rasterize(&request("é", &family, 24.0));
        let decomposed = fonts.rasterize(&request("e\u{301}", &family, 24.0));
        assert_eq!(composed.bitmap.image, decomposed.bitmap.image);
        assert_eq!(composed.advance_px, decomposed.advance_px);
        let base = fonts.rasterize(&request("x", &family, 24.0));
        let marked = fonts.rasterize(&request("x\u{301}", &family, 24.0));
        assert_eq!(base.advance_px, marked.advance_px);
        assert!(marked.bitmap.offset_px.y < base.bitmap.offset_px.y);
    }

    #[test]
    fn listener_arrow_uses_a_real_fallback_glyph() {
        let fonts = MonochromeFonts::new();
        let family = FontFamily::Proportional;
        let arrow_request = request("→", &family, 24.0);
        assert_eq!(fonts.layout(&arrow_request, "→").unknown_glyphs_count(), 0);
        let arrow = fonts.rasterize(&arrow_request);
        let replacement = fonts.rasterize(&request("\u{fffd}", &family, 24.0));
        assert_ne!(arrow.bitmap.image, replacement.bitmap.image);
        assert_binary(&arrow);
    }

    #[test]
    fn primary_and_fallback_fonts_use_freetype_v35_and_mono_options() {
        let fonts = MonochromeFonts::new();
        for (family, text, expected) in [
            (
                FontFamily::Proportional,
                "A",
                Some(("Droid Sans", pango::Weight::Normal)),
            ),
            (
                FontFamily::Name("Droid Sans Bold".into()),
                "A",
                Some(("Droid Sans", pango::Weight::Bold)),
            ),
            (
                FontFamily::Name("Michroma".into()),
                "A",
                Some(("Michroma", pango::Weight::Normal)),
            ),
            (FontFamily::Proportional, "→", None),
        ] {
            let layout = fonts.layout(&request(text, &family, 24.0), text);
            let font = layout.line_readonly(0).unwrap().runs()[0]
                .item()
                .analysis()
                .font();
            if let Some((family, weight)) = expected {
                assert_eq!(font.describe().family().as_deref(), Some(family));
                assert_eq!(font.describe().weight(), weight);
            } else {
                assert_ne!(font.describe().family().as_deref(), Some("Droid Sans"));
            }
            // SAFETY: This font comes from our FT2 map and owns the pattern.
            unsafe {
                let pattern = pango_fc_font_get_pattern(font.to_glib_none().0);
                for (key, expected) in [(FC_ANTIALIAS, 0), (FC_HINTING, 1), (FC_AUTOHINT, 0)] {
                    let mut actual = -1;
                    assert_eq!(
                        fc::FcPatternGetBool(pattern, key.as_ptr(), 0, &mut actual),
                        fc::FcResultMatch
                    );
                    assert_eq!(actual, expected);
                }
                let mut hint_style = -1;
                assert_eq!(
                    fc::FcPatternGetInteger(pattern, FC_HINT_STYLE.as_ptr(), 0, &mut hint_style),
                    fc::FcResultMatch
                );
                assert_eq!(hint_style, FC_HINT_FULL);
            }
            let mut version: ffi::FT_UInt = 0;
            // SAFETY: Query the actual rendering library while its face is locked.
            let error = unsafe {
                let face = pango_fc_font_lock_face(font.to_glib_none().0);
                assert!(!face.is_null());
                let error = ffi::FT_Property_Get(
                    (*(*face).glyph).library,
                    c"truetype".as_ptr(),
                    c"interpreter-version".as_ptr(),
                    (&mut version as *mut ffi::FT_UInt).cast(),
                );
                pango_fc_font_unlock_face(font.to_glib_none().0);
                error
            };
            assert_eq!(error, 0);
            assert_eq!(version, 35);
        }
    }
}
