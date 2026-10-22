//! An egui 0.37 example for plain, left-to-right text in a single upright style.
//! Ligature patterns are ASCII operators. Matches are greedy, longest first.
//! Each replacement must be a standalone, visible glyph with a positive advance.
//! Source characters share that advance equally, as in a programming font.
//! This deliberately does not implement syntax styling or contextual font rules.

use std::sync::Arc;

use eframe::egui::{
    Color32, FontId, Galley, Mesh, Rect, Ui,
    epaint::{
        Vertex,
        text::{ByteRange, ByteRangeExt as _, LayoutJob, RowVisuals},
    },
    pos2,
};

pub fn layout(
    ui: &Ui,
    source: &str,
    font: FontId,
    color: Color32,
    wrap_width: f32,
    rules: &[(&str, char)],
) -> Arc<Galley> {
    let (display, spans) = encode(source, rules);
    let mut job = LayoutJob::simple(display, font, color, wrap_width);
    job.keep_trailing_whitespace = true;
    let galley = ui.fonts_mut(|fonts| fonts.layout_job(job));
    adapt(galley, source, &spans)
}

/// One original substring per displayed Unicode scalar, including newlines.
fn encode<'a>(source: &'a str, rules: &[(&str, char)]) -> (String, Vec<&'a str>) {
    for &(pattern, replacement) in rules {
        assert!(pattern.len() >= 2 && pattern.is_ascii());
        assert!(pattern.chars().all(|c| c.is_ascii_punctuation()));
        assert!(!replacement.is_control() && !replacement.is_whitespace());
    }
    let mut display = String::new();
    let mut spans = Vec::new();
    let mut rest = source;
    while !rest.is_empty() {
        let (byte_len, replacement) = rules
            .iter()
            .filter(|(pattern, _)| rest.starts_with(pattern))
            .max_by_key(|(pattern, _)| pattern.len())
            .map(|&(pattern, replacement)| (pattern.len(), replacement))
            .unwrap_or_else(|| {
                let c = rest.chars().next().unwrap();
                (c.len_utf8(), c)
            });
        display.push(replacement);
        spans.push(&rest[..byte_len]);
        rest = &rest[byte_len..];
    }
    (display, spans)
}

/// Retain the laid-out pixels, but restore source characters and caret geometry.
fn adapt(mut galley: Arc<Galley>, source: &str, spans: &[&str]) -> Arc<Galley> {
    // The layout cache owns the original Arc. Never mutate its shared result.
    let galley_mut = Arc::make_mut(&mut galley);
    assert!(!galley_mut.elided);
    let mut spans = spans.iter();

    for placed in &mut galley_mut.rows {
        let row = Arc::make_mut(&mut placed.row);
        let old_glyphs = std::mem::take(&mut row.glyphs);
        let old_visuals = std::mem::take(&mut row.visuals);
        let old_mesh = &old_visuals.mesh;
        // layout() creates a plain job: only glyph quads, no decorations.
        assert_eq!(old_visuals.glyph_vertex_range, 0..old_mesh.vertices.len());
        let mut mesh = Mesh::with_texture(old_mesh.texture_id);

        for (i, old) in old_glyphs.iter().enumerate() {
            let original = spans.next().expect("one span per display character");
            let count = original.chars().count();
            let end_vertex = old_glyphs
                .get(i + 1)
                .map_or(old_visuals.glyph_vertex_range.end, |g| {
                    g.first_vertex as usize
                });
            let quad = &old_mesh.vertices[old.first_vertex as usize..end_vertex];

            for (part, chr) in original.chars().enumerate() {
                let mut logical = *old;
                logical.chr = chr;
                logical.pos.x = old.pos.x + old.advance_width * part as f32 / count as f32;
                logical.advance_width = old.advance_width / count as f32;
                logical.first_vertex = mesh.vertices.len() as u32;

                // Include the ink overhang on the outermost slices. Internal
                // cuts coincide with the logical caret positions.
                let left = if part == 0 {
                    f32::NEG_INFINITY
                } else {
                    logical.pos.x
                };
                let right = if part + 1 == count {
                    f32::INFINITY
                } else {
                    logical.max_x()
                };
                append_slice(&mut mesh, quad, left, right);
                row.glyphs.push(logical);
            }
        }

        row.visuals = RowVisuals {
            mesh_bounds: mesh.calc_bounds(),
            glyph_vertex_range: 0..mesh.vertices.len(),
            glyph_index_start: 0,
            mesh,
        };
        if placed.ends_with_newline {
            assert_eq!(spans.next(), Some(&"\n"));
        }
    }
    assert!(
        spans.next().is_none(),
        "layout must cover the complete input"
    );

    // Editing, word navigation, accessibility, etc. must see the source text.
    let job = Arc::make_mut(&mut galley_mut.job);
    job.text = source.to_owned();
    job.sections[0].byte_range = ByteRange::full(source);
    galley_mut.num_vertices = galley_mut
        .rows
        .iter()
        .map(|r| r.visuals.mesh.vertices.len())
        .sum();
    galley_mut.num_indices = galley_mut
        .rows
        .iter()
        .map(|r| r.visuals.mesh.indices.len())
        .sum();
    // Splitting quads leaves row sizes and the overall ink bounds unchanged.
    galley
}

/// Slice the existing glyph quad and its texture coordinates together.
/// Giving each character its own vertices lets egui recolor partial selections.
fn append_slice(mesh: &mut Mesh, quad: &[Vertex], left: f32, right: f32) {
    if quad.is_empty() {
        return; // Spaces and continuation characters have no drawing geometry.
    }
    assert_eq!(quad.len(), 4, "requires egui 0.37's upright glyph quads");
    let rect = Rect::from_min_max(quad[0].pos, quad[3].pos);
    let uv = Rect::from_min_max(quad[0].uv, quad[3].uv);
    let left = left.max(rect.left());
    let right = right.min(rect.right());
    if right <= left {
        return;
    }
    let u = |x| uv.left() + (x - rect.left()) / rect.width() * uv.width();
    mesh.add_rect_with_uv(
        Rect::from_min_max(pos2(left, rect.top()), pos2(right, rect.bottom())),
        Rect::from_min_max(pos2(u(left), uv.top()), pos2(u(right), uv.bottom())),
        quad[0].color,
    );
}

#[cfg(test)]
#[path = "tests.rs"]
mod tests;
