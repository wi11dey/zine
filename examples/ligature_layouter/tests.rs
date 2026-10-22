use super::*;
use eframe::egui::{
    self, ColorImage, Context, Event, Id, Key, Modifiers, OutputCommand, RawInput, TextBuffer,
    TextEdit,
    epaint::text::{FontPriority, GlyphBitmap, GlyphRasterizer, RasterizedGlyph},
    text::{CCursor, CCursorRange},
    text_edit::TextEditState,
};

const RULES: &[(&str, char)] = &[("->", '\u{e000}'), ("-->", '\u{e001}')];

fn context() -> Context {
    let ctx = Context::default();
    // Test the real rasterizer hook without requiring a patched font file.
    ctx.add_glyph_rasterizer(
        GlyphRasterizer::new("ligature-layout-test", |request| {
            let cells = match request.cluster {
                "\u{e000}" => 2,
                "\u{e001}" => 3,
                _ => return None,
            };
            let width = cells * 12;
            Some(RasterizedGlyph {
                advance_px: width as f32,
                bitmap: GlyphBitmap {
                    image: ColorImage::filled([width + 4, 12], Color32::WHITE),
                    offset_px: egui::vec2(-2.0, -10.0),
                    is_color: false,
                },
            })
        })
        .with_priority(FontPriority::Highest),
    );
    ctx
}

fn in_ui<T>(ctx: &Context, mut f: impl FnMut(&Ui) -> T) -> T {
    let mut result = None;
    ctx.run_ui(RawInput::default(), |ui| result = Some(f(ui)))
        .drop_without_applying_deltas();
    result.unwrap()
}

fn test_layout(ui: &Ui, source: &str, width: f32) -> Arc<Galley> {
    layout(
        ui,
        source,
        FontId::proportional(20.0),
        Color32::WHITE,
        width,
        RULES,
    )
}

#[test]
fn substitution_is_longest_first_and_tracks_utf8_source_spans() {
    let (display, spans) = encode("é-->->\n", RULES);
    assert_eq!(display, "é\u{e001}\u{e000}\n");
    assert_eq!(spans, ["é", "-->", "->", "\n"]);
}

#[test]
fn logical_text_survives_wrapping_newlines_and_empty_input() {
    let ctx = context();
    for source in ["", "\n", "é -> α\n\n--> tail\n", "x->-->->y"] {
        for width in [f32::INFINITY, 40.0] {
            let galley = in_ui(&ctx, |ui| test_layout(ui, source, width));
            let mut reconstructed = String::new();
            for row in &galley.rows {
                reconstructed.push_str(&row.text());
                if row.ends_with_newline {
                    reconstructed.push('\n');
                }
                assert!(row.visuals.mesh.is_valid());
            }
            assert_eq!(reconstructed, source);
            assert_eq!(galley.job.text, source);
            assert_eq!(galley.end().index.0, source.chars().count());
        }
    }
}

#[test]
fn caret_positions_and_hit_testing_include_the_middle_of_a_ligature() {
    for scale in [1.0, 1.5, 2.0] {
        let ctx = context();
        ctx.set_pixels_per_point(scale);
        let galley = in_ui(&ctx, |ui| test_layout(ui, "a->b", f32::INFINITY));
        let x = |index| galley.pos_from_cursor(CCursor::new(index)).center().x;
        assert!((x(2) - (x(1) + x(3)) * 0.5).abs() < 0.001);
        for index in 0..=4 {
            let pos = galley.pos_from_cursor(CCursor::new(index)).center();
            assert_eq!(galley.cursor_from_pos(pos.to_vec2()).index.0, index);
        }
    }
}

#[test]
fn partial_selection_recolors_only_its_slice_and_preserves_ink_overhang() {
    let ctx = context();
    let mut galley = in_ui(&ctx, |ui| test_layout(ui, "->", f32::INFINITY));
    let original = galley.clone();
    let row = &galley.rows[0];
    let cut_x = row.glyphs[1].pos.x;
    let split = row.glyphs[1].first_vertex as usize;
    assert_eq!(split, 4);
    assert_eq!(row.visuals.mesh.vertices.len(), 8);
    assert_eq!(row.visuals.mesh.vertices[1].pos.x, cut_x);
    assert_eq!(row.visuals.mesh.vertices[split].pos.x, cut_x);
    assert_eq!(
        row.visuals.mesh.vertices[1].uv.x,
        row.visuals.mesh.vertices[split].uv.x
    );
    assert!(row.visuals.mesh_bounds.left() < row.glyphs[0].pos.x);
    assert!(row.visuals.mesh_bounds.right() > row.glyphs[1].max_x());

    let mut visuals = egui::Visuals::dark();
    visuals.selection.stroke.color = Color32::RED;
    egui::text_selection::visuals::paint_text_selection(
        &mut galley,
        &visuals,
        &CCursorRange::two(CCursor::new(1), CCursor::new(2)),
        None,
    );
    let vertices = &galley.rows[0].visuals.mesh.vertices;
    assert!(vertices[..split].iter().all(|v| v.color == Color32::WHITE));
    assert!(vertices[split..8].iter().all(|v| v.color == Color32::RED));
    // The shared layout was not changed by either adapter or selection painting.
    assert!(
        original.rows[0]
            .visuals
            .mesh
            .vertices
            .iter()
            .all(|v| v.color == Color32::WHITE)
    );
}

#[test]
fn cached_display_layout_is_not_overwritten_by_source_metadata() {
    let ctx = context();
    in_ui(&ctx, |ui| {
        let adapted = test_layout(ui, "->", f32::INFINITY);
        let literal = test_layout(ui, "\u{e000}", f32::INFINITY);
        assert_eq!(adapted.rows[0].glyphs.len(), 2);
        assert_eq!(literal.rows[0].glyphs.len(), 1);
        assert_eq!(literal.job.text, "\u{e000}");
    });
}

#[test]
fn text_edit_copies_cuts_and_inserts_original_characters() {
    let ctx = context();
    let id = Id::unique("ligature-editor-test");
    let mut source = "a->b".to_owned();
    let frame = |source: &mut String, events| {
        let output = ctx.run_ui(
            RawInput {
                events,
                ..Default::default()
            },
            |ui| {
                let mut layouter =
                    |ui: &Ui, text: &dyn TextBuffer, width| test_layout(ui, text.as_str(), width);
                TextEdit::multiline(source)
                    .id(id)
                    .layouter(&mut layouter)
                    .show(ui)
                    .response
                    .request_focus();
            },
        );
        let commands = output.platform_output.commands.clone();
        output.drop_without_applying_deltas();
        commands
    };
    frame(&mut source, vec![]);
    let mut state = TextEditState::load(&ctx, id).unwrap();
    state
        .cursor
        .set_char_range(Some(CCursorRange::two(CCursor::new(2), CCursor::new(3))));
    state.store(&ctx, id);
    let copied = frame(&mut source, vec![Event::Copy]);
    assert!(
        copied
            .iter()
            .any(|c| matches!(c, OutputCommand::CopyText(s) if s == ">"))
    );
    let cut = frame(&mut source, vec![Event::Cut]);
    assert!(
        cut.iter()
            .any(|c| matches!(c, OutputCommand::CopyText(s) if s == ">"))
    );
    assert_eq!(source, "a-b");
    frame(&mut source, vec![Event::Text(">".into())]);
    assert_eq!(source, "a->b");
    frame(
        &mut source,
        vec![Event::Key {
            key: Key::Backspace,
            physical_key: None,
            pressed: true,
            repeat: false,
            modifiers: Modifiers::NONE,
        }],
    );
    assert_eq!(source, "a-b");
}
