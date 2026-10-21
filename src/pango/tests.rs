use super::*;
use fc::constants::*;

unsafe extern "C" {
    fn pango_fc_font_get_pattern(font: *mut pango::ffi::PangoFont) -> *mut fc::FcPattern;
}

fn request<'a>(cluster: &'a str, family: &'a FontFamily, size: f32) -> GlyphRasterizerRequest<'a> {
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
    for cluster in [" ", "\t", "\u{2009}", "\u{202f}"] {
        let glyph = fonts.rasterize(&request(cluster, &family, 24.0));
        match cluster {
            " " => assert_eq!(glyph.advance_px, space.advance_px),
            "\t" => assert_eq!(glyph.advance_px, space.advance_px * 8.0),
            _ => assert!(glyph.advance_px > 0.0 && glyph.advance_px < space.advance_px),
        }
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
    // ChicagoFLF has precomposed accents but no combining acute; fallback
    // shaping can produce different pixels while preserving the advance.
    assert_eq!(fonts.layout.unknown_glyphs_count(), 0);
    assert_binary(&composed);
    assert_binary(&decomposed);
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
    let arrow = fonts.rasterize(&arrow_request);
    assert_eq!(fonts.layout.unknown_glyphs_count(), 0);
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
            Some(("ChicagoFLF", pango::Weight::Medium)),
        ),
        (
            FontFamily::Name("Orbitron Light".into()),
            "A",
            Some(("Orbitron", pango::Weight::Light)),
        ),
        (FontFamily::Proportional, "→", None),
    ] {
        fonts.rasterize(&request(text, &family, 24.0));
        let font = fonts.layout.line_readonly(0).unwrap().runs()[0]
            .item()
            .analysis()
            .font();
        if let Some((family, weight)) = expected {
            assert_eq!(font.describe().family().as_deref(), Some(family));
            assert_eq!(font.describe().weight(), weight);
        } else {
            assert_ne!(font.describe().family().as_deref(), Some("ChicagoFLF"));
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
