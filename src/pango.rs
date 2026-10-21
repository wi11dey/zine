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
            "Orbitron Light",
            include_bytes!("../assets/fonts/Orbitron-Light.ttf").as_slice(),
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
    layout: Layout,
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
        let layout = Layout::new(&context);
        layout.set_single_paragraph_mode(true);
        Self {
            layout,
            _files: files,
        }
    }

    fn rasterize(&self, request: &GlyphRasterizerRequest<'_>) -> RasterizedGlyph {
        let family = match request.family {
            FontFamily::Proportional | FontFamily::Monospace => "Droid Sans",
            FontFamily::Name(name) => name.as_ref(),
        };
        let mut description = FontDescription::from_string(family);
        description.set_absolute_size(request.font_size_px as f64 * pango::SCALE as f64);
        let layout = &self.layout;
        layout.set_font_description(Some(&description));
        layout.set_text(request.cluster);
        let (ink, _) = layout.pixel_extents();
        let (width, height) = (ink.width().max(1), ink.height().max(1));
        let mut coverage = vec![0u8; width as usize * height as usize];
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
        RasterizedGlyph {
            bitmap: GlyphBitmap {
                image: ColorImage::new(
                    [width as usize, height as usize],
                    coverage
                        .into_iter()
                        .map(Color32::from_white_alpha)
                        .collect(),
                ),
                offset_px: vec2(
                    ink.x() as f32 + request.subpixel_offset_px.round(),
                    ink.y() as f32 - layout.baseline() as f32 / pango::SCALE as f32,
                ),
                is_color: false,
            },
            advance_px: layout.size().0 as f32 / pango::SCALE as f32,
        }
    }
}

struct NearestFontSampling;

impl egui::Plugin for NearestFontSampling {
    fn debug_name(&self) -> &'static str {
        "nearest font sampling"
    }

    fn output_hook(&mut self, _ctx: &egui::Context, output: &mut egui::FullOutput) {
        let atlas = egui::TextureId::default();
        if let Some(patches) = output.textures_delta.set.get_mut(&atlas) {
            for patch in patches {
                patch.options = egui::TextureOptions::NEAREST;
            }
        }
    }
}

#[cfg(test)]
mod tests;
