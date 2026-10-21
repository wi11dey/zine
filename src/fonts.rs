use std::{
    collections::BTreeMap,
    sync::{Arc, Mutex},
};

use eframe::egui::{self, Color32, ColorImage, FontData, FontDefinitions, FontFamily, vec2};
use egui::epaint::text::{
    FontPriority, GlyphBitmap, GlyphRasterizer, GlyphRasterizerRequest, RasterizedGlyph,
};
use freetype::{Library, RenderMode, bitmap::PixelMode, face::LoadFlag};
use harfrust::{FontRef, ShapeOptions, ShaperData, UnicodeBuffer};

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
    // egui's callback is Send + Sync. Keep all FreeType operations for this font,
    // including face creation/destruction, under the same lock.
    library: Mutex<Library>,
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
                        library: Mutex::new(Library::init().expect("initialize FreeType")),
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

        let library = self.library.lock().expect("FreeType lock poisoned");
        let face = library
            .new_memory_face2(self.data.bytes(), self.data.index as isize)
            .ok()?;
        // At 72 DPI, FreeType's 26.6 point size equals the requested physical pixels.
        face.set_char_size(0, (size_px * 64.0).round() as isize, 72, 72)
            .ok()?;
        let unit_scale = size_px / face.em_size() as f32;
        let mut bitmaps = Vec::new();
        let mut advance = 0.0_f32;
        for (info, position) in shaped.glyph_infos().iter().zip(shaped.glyph_positions()) {
            // TARGET_MONO is FreeType's strongest B/W grid fitting. Native font
            // hints take precedence; the auto-hinter is available for unhinted
            // fonts. NO_BITMAP ensures embedded strikes cannot bypass hinting.
            face.load_glyph(
                info.glyph_id,
                LoadFlag::TARGET_MONO | LoadFlag::MONOCHROME | LoadFlag::NO_BITMAP,
            )
            .ok()?;
            let slot = face.glyph();
            slot.render_glyph(RenderMode::Mono).ok()?;
            let bitmap = slot.bitmap();
            if bitmap.width() > 0 && bitmap.rows() > 0 {
                if bitmap.pixel_mode().ok()? != PixelMode::Mono {
                    return None;
                }
                // FreeType's outline renderer returns top-down rows. The pitch
                // includes byte padding; each pixel is a single MSB-first bit.
                let pitch = usize::try_from(bitmap.pitch()).ok()?;
                bitmaps.push(GlyphBitmap {
                    image: unpack_mono(
                        bitmap.buffer(),
                        bitmap.width() as usize,
                        bitmap.rows() as usize,
                        pitch,
                    ),
                    offset_px: vec2(
                        (advance
                            + position.x_offset as f32 * unit_scale
                            + request.subpixel_offset_px)
                            .round()
                            + slot.bitmap_left() as f32,
                        (-position.y_offset as f32 * unit_scale
                            + size_px * self.data.tweak.y_offset_factor)
                            .round()
                            - slot.bitmap_top() as f32,
                    ),
                    is_color: false,
                });
            }
            // Preserve shaping adjustments (especially zero-advance marks), but
            // replace each advancing glyph's linear width with its hinted width.
            let mut glyph_advance = position.x_advance as f32 * unit_scale;
            if position.x_advance != 0 {
                glyph_advance +=
                    slot.advance().x as f32 / 64.0 - slot.linear_hori_advance() as f32 / 65536.0;
                glyph_advance = glyph_advance.round();
            }
            advance += glyph_advance;
        }
        Some(combine_bitmaps(bitmaps, advance * advance_multiplier))
    }
}

fn unpack_mono(buffer: &[u8], width: usize, height: usize, pitch: usize) -> ColorImage {
    let mut image = ColorImage::filled([width, height], Color32::TRANSPARENT);
    for y in 0..height {
        for x in 0..width {
            if buffer[y * pitch + x / 8] & (0x80 >> (x % 8)) != 0 {
                image[(x, y)] = Color32::WHITE;
            }
        }
    }
    image
}

fn combine_bitmaps(bitmaps: Vec<GlyphBitmap>, advance_px: f32) -> RasterizedGlyph {
    // egui rejects zero-sized bitmaps, including otherwise valid spaces.
    let Some(first) = bitmaps.first() else {
        return blank_glyph(advance_px);
    };
    let mut min = first.offset_px;
    let mut max = min + vec2(first.image.width() as f32, first.image.height() as f32);
    for bitmap in &bitmaps[1..] {
        min = min.min(bitmap.offset_px);
        max = max.max(
            bitmap.offset_px + vec2(bitmap.image.width() as f32, bitmap.image.height() as f32),
        );
    }
    let size = max - min;
    let mut image = ColorImage::filled([size.x as usize, size.y as usize], Color32::TRANSPARENT);
    for bitmap in bitmaps {
        let offset = bitmap.offset_px - min;
        for y in 0..bitmap.image.height() {
            for x in 0..bitmap.image.width() {
                // Union the masks so a combining mark's transparent pixels do
                // not erase the base glyph beneath it.
                if bitmap.image[(x, y)] == Color32::WHITE {
                    image[(offset.x as usize + x, offset.y as usize + y)] = Color32::WHITE;
                }
            }
        }
    }
    RasterizedGlyph {
        bitmap: GlyphBitmap {
            image,
            offset_px: min,
            is_color: false,
        },
        advance_px,
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

struct NearestFontSampling;

impl egui::Plugin for NearestFontSampling {
    fn debug_name(&self) -> &'static str {
        "nearest font sampling"
    }

    fn output_hook(&mut self, _ctx: &egui::Context, output: &mut egui::FullOutput) {
        // Only change sampling. Glyph pixels already have binary coverage when
        // they leave FreeType; no atlas pixels are inspected or rewritten here.
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
    fn monochrome_bits_respect_bit_order_width_and_row_padding() {
        // Nine pixels in four-byte rows. Padding bits and bytes must be ignored.
        let image = unpack_mono(&[0x81, 0xff, 0xff, 0xff, 0x40, 0x7f, 0xff, 0xff], 9, 2, 4);
        let white: Vec<_> = image
            .pixels
            .iter()
            .enumerate()
            .filter_map(|(i, &pixel)| (pixel == Color32::WHITE).then_some((i % 9, i / 9)))
            .collect();
        assert_eq!(white, [(0, 0), (7, 0), (8, 0), (1, 1)]);
    }

    #[test]
    fn overlapping_glyph_masks_preserve_ink_and_negative_bearings() {
        let glyph = combine_bitmaps(
            vec![
                GlyphBitmap {
                    image: ColorImage::new([2, 1], vec![Color32::WHITE, Color32::TRANSPARENT]),
                    offset_px: vec2(-1.0, -2.0),
                    is_color: false,
                },
                GlyphBitmap {
                    image: ColorImage::new([2, 1], vec![Color32::TRANSPARENT, Color32::WHITE]),
                    offset_px: vec2(-1.0, -2.0),
                    is_color: false,
                },
            ],
            3.0,
        );
        assert_eq!(glyph.bitmap.offset_px, vec2(-1.0, -2.0));
        assert_eq!(glyph.bitmap.image.pixels, [Color32::WHITE, Color32::WHITE]);
        assert_eq!(glyph.advance_px, 3.0);
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
