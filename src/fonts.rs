use std::{collections::BTreeMap, sync::Arc};

use eframe::egui::{self, Color32, ColorImage, FontData, FontDefinitions, FontFamily, vec2};
use egui::epaint::text::{
    FontPriority, GlyphBitmap, GlyphRasterizer, GlyphRasterizerRequest, RasterizedGlyph,
};
use harfrust::{ShapeOptions, ShaperData, UnicodeBuffer};
use skrifa::{
    FontRef, GlyphId, MetadataProvider,
    instance::{LocationRef, Size},
    outline::{DrawSettings, HintingInstance, OutlinePen, Target},
};
use vello_cpu::{
    Pixmap, RenderContext, Resources, color,
    kurbo::{Affine, BezPath},
};

pub fn install(ctx: &egui::Context) {
    let definitions = definitions();
    let rasterizer = MonochromeFonts::new(&definitions);
    ctx.set_fonts(definitions);
    ctx.add_glyph_rasterizer(
        GlyphRasterizer::new("zine::monochrome", move |request| {
            Some(rasterizer.rasterize(request))
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
    }
    fonts
        .families
        .get_mut(&FontFamily::Proportional)
        .unwrap()
        .insert(0, "Droid Sans".into());
    fonts
        .families
        .get_mut(&FontFamily::Proportional)
        .unwrap()
        .push("Hack".into());
    for name in ["Droid Sans Bold", "Michroma"] {
        let mut family = vec![name.into()];
        family.extend(fonts.families[&FontFamily::Proportional].clone());
        fonts.families.insert(FontFamily::Name(name.into()), family);
    }
    fonts
}

struct Face {
    data: Arc<FontData>,
    shaper: ShaperData,
}

struct MonochromeFonts {
    faces: BTreeMap<String, Face>,
    families: BTreeMap<FontFamily, Vec<String>>,
}

impl MonochromeFonts {
    fn new(definitions: &FontDefinitions) -> Self {
        let faces = definitions
            .font_data
            .iter()
            .map(|(name, data)| {
                let font =
                    FontRef::from_index(data.bytes(), data.index).expect("valid embedded font");
                (
                    name.clone(),
                    Face {
                        data: data.clone(),
                        shaper: ShaperData::new(&font),
                    },
                )
            })
            .collect();
        Self {
            faces,
            families: definitions.families.clone(),
        }
    }

    fn rasterize(&self, request: &GlyphRasterizerRequest<'_>) -> RasterizedGlyph {
        let family = self
            .families
            .get(request.family)
            .unwrap_or(&self.families[&FontFamily::Proportional]);
        for name in family {
            if let Some(glyph) = self.faces[name].rasterize(request) {
                return glyph;
            }
        }
        // Missing characters must also stay monochrome instead of falling through
        // to egui's antialiased rasterizer. Use the family's replacement glyph.
        if request.cluster != "\u{fffd}" {
            return self.rasterize(&GlyphRasterizerRequest {
                cluster: "\u{fffd}",
                ..*request
            });
        }
        // Some fallback families have no U+FFFD. Draw a small missing-glyph box.
        let width = (request.font_size_px * 0.5).round().max(3.0) as usize;
        let height = (request.font_size_px * 0.7).round().max(3.0) as usize;
        let mut image = ColorImage::filled([width, height], Color32::TRANSPARENT);
        for y in 0..height {
            for x in 0..width {
                if x == 0 || y == 0 || x == width - 1 || y == height - 1 {
                    image[(x, y)] = Color32::WHITE;
                }
            }
        }
        RasterizedGlyph {
            bitmap: GlyphBitmap {
                image,
                offset_px: vec2(1.0, -(height as f32)),
                is_color: false,
            },
            advance_px: width as f32 + 2.0,
        }
    }
}

impl Face {
    fn rasterize(&self, request: &GlyphRasterizerRequest<'_>) -> Option<RasterizedGlyph> {
        let font = FontRef::from_index(self.data.bytes(), self.data.index).ok()?;
        let size_px = request.font_size_px * self.data.tweak.scale;
        let size = Size::new(size_px);
        let location = LocationRef::default();
        let unit_scale = size_px / font.metrics(size, location).units_per_em as f32;

        let (text, advance_multiplier) = match request.cluster {
            "\t" => (" ", self.data.tweak.tab_size),
            "\u{2009}" | "\u{202f}" => (" ", self.data.tweak.thin_space_width),
            text => (text, 1.0),
        };
        let mut buffer = UnicodeBuffer::new();
        buffer.push_str(text);
        buffer.guess_segment_properties();
        let shaped = self
            .shaper
            .shaper(&font)
            .build()
            .shape(buffer, ShapeOptions::default());
        if shaped.glyph_infos().iter().any(|glyph| glyph.glyph_id == 0) {
            return None;
        }

        let outlines = font.outline_glyphs();
        // Mono hinting grid-fits both axes before Vello rasterizes the outline.
        let hinting = HintingInstance::new(&outlines, size, location, Target::Mono).ok()?;
        let metrics = font.glyph_metrics(size, location);
        let mut path = BezPath::new();
        let mut advance = 0.0_f32;
        for (info, position) in shaped.glyph_infos().iter().zip(shaped.glyph_positions()) {
            let glyph_id = GlyphId::new(info.glyph_id);
            let outline = outlines.get(glyph_id)?;
            let mut pen = GlyphPen {
                path: &mut path,
                x: (advance + position.x_offset as f32 * unit_scale + request.subpixel_offset_px)
                    .round() as f64,
                y: (-position.y_offset as f32 * unit_scale
                    + size_px * self.data.tweak.y_offset_factor)
                    .round() as f64,
            };
            let adjusted = outline
                .draw(DrawSettings::hinted(&hinting, false), &mut pen)
                .ok()?;
            // Keep shaping adjustments (e.g. a combining mark's zero advance),
            // while using the hinter's advance for spacing ordinary glyphs.
            let mut glyph_advance = position.x_advance as f32 * unit_scale;
            if position.x_advance != 0 {
                if let Some(hinted) = adjusted.advance_width {
                    glyph_advance += hinted - metrics.advance_width(glyph_id).unwrap_or(0.0);
                }
                glyph_advance = glyph_advance.round();
            }
            advance += glyph_advance;
        }
        let advance_px = advance * advance_multiplier;
        let bounds = path.control_box().expand();
        if bounds.width() <= 0.0 || bounds.height() <= 0.0 {
            // egui rejects zero-sized bitmaps, including otherwise valid spaces.
            return Some(blank_glyph(advance_px));
        }
        let width = u16::try_from(bounds.width() as u32).ok()?;
        let height = u16::try_from(bounds.height() as u32).ok()?;
        let mut renderer = RenderContext::new(width, height);
        renderer.set_transform(Affine::translate((-bounds.x0, -bounds.y0)));
        renderer.set_paint(color::OpaqueColor::<color::Srgb>::WHITE);
        renderer.set_aliasing_threshold(Some(128));
        renderer.fill_path(&path);
        let mut pixmap = Pixmap::new(width, height);
        renderer.render(&mut pixmap, &mut Resources::new());
        Some(RasterizedGlyph {
            bitmap: GlyphBitmap {
                image: ColorImage::from_rgba_premultiplied(
                    [width as usize, height as usize],
                    pixmap.data_as_u8_slice(),
                ),
                offset_px: vec2(bounds.x0 as f32, bounds.y0 as f32),
                is_color: false,
            },
            advance_px,
        })
    }
}

fn blank_glyph(advance_px: f32) -> RasterizedGlyph {
    RasterizedGlyph {
        bitmap: GlyphBitmap {
            image: ColorImage::filled([1, 1], Color32::TRANSPARENT),
            offset_px: egui::Vec2::ZERO,
            is_color: false,
        },
        advance_px,
    }
}

/// Convert the font's upward Y axis to egui's downward Y axis.
struct GlyphPen<'a> {
    path: &'a mut BezPath,
    x: f64,
    y: f64,
}

impl OutlinePen for GlyphPen<'_> {
    fn move_to(&mut self, x: f32, y: f32) {
        self.path.move_to((self.x + x as f64, self.y - y as f64));
    }

    fn line_to(&mut self, x: f32, y: f32) {
        self.path.line_to((self.x + x as f64, self.y - y as f64));
    }

    fn quad_to(&mut self, cx: f32, cy: f32, x: f32, y: f32) {
        self.path.quad_to(
            (self.x + cx as f64, self.y - cy as f64),
            (self.x + x as f64, self.y - y as f64),
        );
    }

    fn curve_to(&mut self, cx0: f32, cy0: f32, cx1: f32, cy1: f32, x: f32, y: f32) {
        self.path.curve_to(
            (self.x + cx0 as f64, self.y - cy0 as f64),
            (self.x + cx1 as f64, self.y - cy1 as f64),
            (self.x + x as f64, self.y - y as f64),
        );
    }

    fn close(&mut self) {
        self.path.close_path();
    }
}

struct NearestFontSampling;

impl egui::Plugin for NearestFontSampling {
    fn debug_name(&self) -> &'static str {
        "nearest font sampling"
    }

    fn output_hook(&mut self, _ctx: &egui::Context, output: &mut egui::FullOutput) {
        // Only change sampling. Glyph pixels already have binary coverage when
        // they leave Vello; no atlas pixels are inspected or rewritten here.
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
        let fonts = MonochromeFonts::new(&definitions());
        for family in fonts.families.keys() {
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
        let fonts = MonochromeFonts::new(&definitions());
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
        let fonts = MonochromeFonts::new(&definitions());
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
        let fonts = MonochromeFonts::new(&definitions());
        let family = FontFamily::Proportional;
        let arrow_request = request("→", &family, 24.0);
        assert!(
            fonts.faces["Droid Sans"]
                .rasterize(&arrow_request)
                .is_none()
        );
        let arrow = fonts.rasterize(&arrow_request);
        let replacement = fonts.rasterize(&request("\u{fffd}", &family, 24.0));
        assert_ne!(arrow.bitmap.image, replacement.bitmap.image);
        assert_binary(&arrow);
    }
}
