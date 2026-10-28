mod resources;
pub use resources::Resources;
use resources::{font_key, needs_raster, push_raster};
use typst::layout::{Frame, GroupItem};
use typst_layout::{Page, PagedDocument};

pub const PAGE_GAP: f32 = 16.0;

use typst::layout::{Abs, FrameItem, Point, Ratio, Rect, Size, Transform};
use typst::text::TextItem;
use typst::visualize::{
    Color, Curve, CurveItem, Geometry, Gradient, LineCap, LineJoin, Paint, RelativeTo,
};
use webrender::api::units::{
    LayoutPoint, LayoutRect, LayoutSideOffsets, LayoutSize, LayoutTransform,
};
use webrender::api::{
    AlphaType, BorderDetails, BorderRadius, BorderSide, BorderStyle, ClipChainId, ClipMode, ColorF,
    CommonItemProperties, ComplexClipRegion, DisplayListBuilder, ExtendMode, FontInstanceKey,
    GlyphInstance, GradientStop, ImageKey, ImageRendering, NormalBorder, ReferenceFrameKind,
    SpaceAndClipInfo, TransformStyle,
};

/// Append all pages in CSS pixels (96 px = 72 pt), stacked vertically.
/// The caller owns begin/end, resource uploads, and the enclosing viewport.
pub fn to_display_list(builder: &mut DisplayListBuilder, document: PagedDocument) {
    let mut y = 0.0;
    for page in document.pages() {
        push_item(
            builder,
            Point::new(Abs::zero(), Abs::pt(y * 0.75)),
            &FrameItem::Group(GroupItem::new(page.frame.clone())),
            State {
                space: SpaceAndClipInfo::root_scroll(builder.pipeline_id),
                parent: None,
            },
        );
        y += f64::from(px(page.frame.height()) + PAGE_GAP);
    }
}

fn group_parent(
    parent: Option<(Size, Transform)>,
    group: &GroupItem,
    transform: Transform,
) -> Option<(Size, Transform)> {
    match parent {
        Some((size, to_parent)) if group.frame.kind().is_soft() => {
            Some((size, to_parent.pre_concat(transform)))
        }
        _ => Some((group.frame.size(), Transform::identity())),
    }
}

#[derive(Clone, Copy)]
struct State {
    space: SpaceAndClipInfo,
    // Size of the enclosing hard frame and the transform into its coordinates.
    parent: Option<(Size, Transform)>,
}

fn push_item(builder: &mut DisplayListBuilder, location: Point, item: &FrameItem, state: State) {
    if needs_raster(item) {
        push_raster(builder, location, item, state);
        return;
    }
    match item {
        FrameItem::Group(group) => {
            let transform =
                Transform::translate(location.x, location.y).pre_concat(group.transform);
            let mut child = state;
            child.space.spatial_id = reference_frame(builder, state.space, matrix(transform));
            child.parent = group_parent(state.parent, group, transform);
            if let Some(curve) = &group.clip {
                let Some(rect) = curve_rect(curve) else {
                    unreachable!("non-rectangular group clips require a registered image mask");
                };
                let clip =
                    builder.define_clip_rect(child.space.spatial_id, bounds(Point::zero(), rect));
                child.space.clip_chain_id = clip_chain(builder, child.space, clip);
            }
            for (position, item) in group.frame.items() {
                push_item(builder, *position, item, child);
            }
            builder.pop_reference_frame();
        }
        FrameItem::Text(text) => {
            if text.glyphs.is_empty() {
                return;
            }
            if text.stroke.is_some() {
                unreachable!(
                    "stroked text requires glyph outlines rendered to a registered resource"
                );
            }
            let Paint::Solid(fill) = &text.fill else {
                unreachable!("gradient or tiled text requires a registered glyph mask");
            };
            let rect = text.bbox();
            if ![rect.min.x, rect.min.y, rect.max.x, rect.max.y]
                .iter()
                .all(|v| v.to_pt().is_finite())
            {
                // Runs containing only spaces have no ink bounds.
                return;
            }
            let bounds = bounds(location, rect);
            let glyphs = text_glyphs(location, text);
            builder.push_text(
                &CommonItemProperties::new(bounds, state.space),
                bounds,
                &glyphs,
                font_key(text),
                color(fill),
                Some(webrender::api::GlyphOptions {
                    render_mode: webrender::api::FontRenderMode::Mono,
                    flags: webrender::api::FontInstanceFlags::empty(),
                }),
            );
        }
        FrameItem::Shape(shape, _) => match &shape.geometry {
            Geometry::Rect(size) => {
                let rect = bounds(location, shape.bbox(false));
                if let Some(fill) = &shape.fill {
                    // Preserve the direction of gradients on negative-size rectangles.
                    let own = box_transform(location, *size);
                    paint_rect(builder, state, rect, fill, own, shape.bbox(true).size());
                }
                if let Some(stroke) = &shape.stroke {
                    if stroke.thickness <= Abs::zero() {
                        return;
                    }
                    if stroke.dash.is_some() {
                        unreachable!(
                            "dashed rectangle outlines require a rasterized path resource"
                        );
                    }
                    let radius = match stroke.join {
                        LineJoin::Round => px(stroke.thickness) / 2.0,
                        LineJoin::Miter if stroke.miter_limit.get() >= std::f64::consts::SQRT_2 => {
                            0.0
                        }
                        _ => unreachable!(
                            "beveled rectangle outlines require a rasterized path resource"
                        ),
                    };
                    let outer = bounds(location, shape.bbox(true));
                    let width = px(stroke.thickness);
                    if let Paint::Solid(paint) = &stroke.paint {
                        let side = BorderSide {
                            color: color(paint),
                            style: BorderStyle::Solid,
                        };
                        builder.push_border(
                            &CommonItemProperties::new(outer, state.space),
                            outer,
                            LayoutSideOffsets::new_all_same(width),
                            BorderDetails::Normal(NormalBorder {
                                left: side,
                                right: side,
                                top: side,
                                bottom: side,
                                radius: BorderRadius::uniform(radius),
                                do_aa: false,
                            }),
                        );
                    } else {
                        let mut clipped = rounded_clip(builder, state, outer, radius);
                        let inner = outer.inflate(-width, -width);
                        if !inner.is_empty() {
                            let clip = builder.define_clip_rounded_rect(
                                state.space.spatial_id,
                                ComplexClipRegion::new(
                                    inner,
                                    BorderRadius::zero(),
                                    ClipMode::ClipOut,
                                ),
                            );
                            clipped.space.clip_chain_id = clip_chain(builder, clipped.space, clip);
                        }
                        let bbox = shape.bbox(true);
                        let mut origin = location + bbox.min;
                        let mut paint_size = bbox.size();
                        if size.x < Abs::zero() {
                            origin.x += paint_size.x;
                            paint_size.x = -paint_size.x;
                        }
                        if size.y < Abs::zero() {
                            origin.y += paint_size.y;
                            paint_size.y = -paint_size.y;
                        }
                        let own = box_transform(origin, paint_size);
                        paint_rect(builder, clipped, outer, &stroke.paint, own, bbox.size());
                    }
                }
            }
            Geometry::Line(end) => {
                let Some(stroke) = &shape.stroke else { return };
                if stroke.thickness <= Abs::zero() {
                    return;
                }
                let dx = end.x.to_pt();
                let dy = end.y.to_pt();
                let length = dx.hypot(dy);
                if length == 0.0 && stroke.cap == LineCap::Butt {
                    return;
                }
                let (cos, sin) = if length == 0.0 {
                    (1.0, 0.0)
                } else {
                    (dx / length, dy / length)
                };
                let transform = Transform {
                    sx: Ratio::new(cos),
                    ky: Ratio::new(sin),
                    kx: Ratio::new(-sin),
                    sy: Ratio::new(cos),
                    tx: location.x,
                    ty: location.y,
                };
                let mut line_state = state;
                line_state.space.spatial_id =
                    reference_frame(builder, state.space, matrix(transform));
                line_state.parent = state
                    .parent
                    .map(|(size, parent)| (size, parent.pre_concat(transform)));
                let half = px(stroke.thickness) / 2.0;
                let length = px(Abs::pt(length));
                let bbox = if length == 0.0 {
                    Rect::new(
                        Point::splat(-stroke.thickness / 2.0),
                        Point::splat(stroke.thickness / 2.0),
                    )
                } else {
                    shape.bbox(true)
                };
                let own = box_transform(location + bbox.min, bbox.size())
                    .then(&matrix(transform).inverse().unwrap());
                let mut segments = match &stroke.dash {
                    Some(dash) => dash_segments(
                        length,
                        &dash.array.iter().map(|v| px(*v)).collect::<Vec<_>>(),
                        px(dash.phase),
                    ),
                    None => vec![(0.0, length)],
                };
                // Separate draw calls would composite overlapping caps twice.
                // Square caps can be merged; round-cap unions need a path mask.
                if stroke.cap == LineCap::Square {
                    let mut merged: Vec<(f32, f32)> = Vec::new();
                    for (start, end) in segments {
                        if let Some(last) = merged.last_mut()
                            && start - last.1 <= 2.0 * half
                        {
                            last.1 = end;
                        } else {
                            merged.push((start, end));
                        }
                    }
                    segments = merged;
                } else if stroke.cap == LineCap::Round
                    && segments
                        .windows(2)
                        .any(|pair| pair[1].0 - pair[0].1 < 2.0 * half)
                {
                    unreachable!("overlapping round dash caps require a registered path mask");
                }
                for (start, end) in segments {
                    let extension = if stroke.cap == LineCap::Butt {
                        0.0
                    } else {
                        half
                    };
                    let area = LayoutRect::new(
                        LayoutPoint::new(start - extension, -half),
                        LayoutPoint::new(end + extension, half),
                    );
                    let segment_state = if stroke.cap == LineCap::Round {
                        rounded_clip(builder, line_state, area, half)
                    } else {
                        line_state
                    };
                    paint_rect(
                        builder,
                        segment_state,
                        area,
                        &stroke.paint,
                        own,
                        bbox.size(),
                    );
                }
                builder.pop_reference_frame();
            }
            Geometry::Curve(curve) => {
                if let Some(rect) = curve_rect(curve) {
                    let mut rectangle = shape.clone();
                    rectangle.geometry = Geometry::Rect(rect.size());
                    push_item(
                        builder,
                        location + rect.min,
                        &FrameItem::Shape(rectangle, typst::syntax::Span::detached()),
                        state,
                    );
                } else {
                    unreachable!(
                        "arbitrary paths require rasterization to a registered image or mask"
                    );
                }
            }
        },
        FrameItem::Image(..) => unreachable!("images use registered raster resources"),
        FrameItem::Link(_, _) | FrameItem::Tag(_) => {}
    }
}

fn text_glyphs(location: Point, text: &TextItem) -> Vec<GlyphInstance> {
    let mut cursor = Point::zero();
    text.glyphs
        .iter()
        .map(|glyph| {
            let point = LayoutPoint::new(
                px(location.x + cursor.x + glyph.x_offset.at(text.size)),
                px(location.y - cursor.y - glyph.y_offset.at(text.size)),
            );
            cursor.x += glyph.x_advance.at(text.size);
            cursor.y += glyph.y_advance.at(text.size);
            GlyphInstance {
                index: u32::from(glyph.id),
                point,
            }
        })
        .collect()
}

fn paint_rect(
    builder: &mut DisplayListBuilder,
    state: State,
    rect: LayoutRect,
    paint: &Paint,
    own: LayoutTransform,
    own_size: Size,
) {
    if rect.is_empty() {
        return;
    }
    let gradient = match paint {
        Paint::Solid(fill) => {
            builder.push_rect(
                &CommonItemProperties::new(rect, state.space),
                rect,
                color(fill),
            );
            return;
        }
        Paint::Gradient(gradient) => gradient,
        Paint::Tiling(_) => {
            unreachable!("tilings require rendering and registering a tile resource")
        }
    };
    let (mut transform, size) = match gradient.unwrap_relative(false) {
        RelativeTo::Self_ => (own, own_size),
        RelativeTo::Parent => {
            let (size, to_parent) = state
                .parent
                .expect("parent-relative gradients need the containing FrameItem::Group");
            let Some(inverse) = matrix(to_parent).inverse() else {
                return;
            };
            (box_transform(Point::zero(), size).then(&inverse), size)
        }
    };
    let width = px(size.x).abs();
    let height = px(size.y).abs();
    if width == 0.0 || height == 0.0 {
        return;
    }
    // Conic angles are measured in physical coordinates; linear and radial
    // gradients use the normalized unit square, as in Typst's renderer.
    if matches!(gradient, Gradient::Conic(_)) {
        transform = LayoutTransform::scale(1.0 / width, 1.0 / height, 1.0).then(&transform);
    }
    let Some(local_rect) = transform
        .inverse()
        .and_then(|t| t.outer_transformed_box2d(&rect))
    else {
        return;
    };
    let clip = builder.define_clip_rect(state.space.spatial_id, rect);
    let space = SpaceAndClipInfo {
        spatial_id: reference_frame(builder, state.space, transform),
        clip_chain_id: clip_chain(builder, state.space, clip),
    };
    let common = CommonItemProperties::new(local_rect, space);
    let offset = local_rect.min.to_vector();
    let stops = gradient_stops(gradient);
    match gradient {
        Gradient::Linear(linear) => {
            let angle =
                Gradient::correct_aspect_ratio(linear.angle, Ratio::new(f64::from(width / height)));
            let (sin, cos) = (angle.sin() as f32, angle.cos() as f32);
            let factor = sin.abs() + cos.abs();
            let start = LayoutPoint::new(
                if cos < 0.0 { 1.0 } else { 0.0 },
                if sin < 0.0 { 1.0 } else { 0.0 },
            );
            let end = LayoutPoint::new(start.x + cos * factor, start.y + sin * factor);
            let value =
                builder.create_gradient(start - offset, end - offset, stops, ExtendMode::Clamp);
            builder.push_gradient(
                &common,
                local_rect,
                value,
                local_rect.size(),
                LayoutSize::zero(),
            );
        }
        Gradient::Radial(radial) => {
            if radial.focal_center != radial.center {
                unreachable!(
                    "off-center radial gradients require a registered rasterized paint resource"
                );
            }
            let radius = radial.radius.get() as f32;
            let inner = radial.focal_radius.get() as f32;
            let stops = stops
                .into_iter()
                .map(|stop| GradientStop {
                    offset: (inner + stop.offset * (radius - inner)) / radius,
                    ..stop
                })
                .collect();
            let center =
                LayoutPoint::new(radial.center.x.get() as f32, radial.center.y.get() as f32);
            let value = builder.create_radial_gradient(
                center - offset,
                LayoutSize::new(radius, radius),
                stops,
                ExtendMode::Clamp,
            );
            builder.push_radial_gradient(
                &common,
                local_rect,
                value,
                local_rect.size(),
                LayoutSize::zero(),
            );
        }
        Gradient::Conic(conic) => {
            let center = LayoutPoint::new(
                conic.center.x.get() as f32 * width,
                conic.center.y.get() as f32 * height,
            );
            let angle = conic.angle.to_rad() as f32 - std::f32::consts::FRAC_PI_2;
            let value =
                builder.create_conic_gradient(center - offset, angle, stops, ExtendMode::Clamp);
            builder.push_conic_gradient(
                &common,
                local_rect,
                value,
                local_rect.size(),
                LayoutSize::zero(),
            );
        }
    }
    builder.pop_reference_frame();
}

fn gradient_stops(gradient: &Gradient) -> Vec<GradientStop> {
    let stops = gradient.stops();
    let mut result = Vec::new();
    for (index, stop) in stops.iter().enumerate() {
        if index > 0 && stops[index - 1].offset != stop.offset {
            result.extend(
                gradient
                    .generate_intermediate_stops_for_rgb_interpolation(&stops[index - 1], stop)
                    .map(|(c, offset)| GradientStop {
                        color: color(&c),
                        offset: offset.get() as f32,
                    }),
            );
        }
        result.push(GradientStop {
            color: color(&stop.color),
            offset: stop.offset.unwrap().get() as f32,
        });
    }
    result
}

fn dash_segments(length: f32, pattern: &[f32], phase: f32) -> Vec<(f32, f32)> {
    if pattern.is_empty() {
        return vec![(0.0, length)];
    }
    assert!(
        pattern.iter().all(|v| v.is_finite() && *v >= 0.0),
        "invalid dash lengths"
    );
    let count = if pattern.len().is_multiple_of(2) {
        pattern.len()
    } else {
        2 * pattern.len()
    };
    let period: f32 = (0..count).map(|i| pattern[i % pattern.len()]).sum();
    if period == 0.0 {
        return vec![(0.0, length)];
    }
    let mut position = -phase.rem_euclid(period);
    let mut segments = Vec::new();
    let mut index = 0;
    while position < length {
        let end = position + pattern[index % pattern.len()];
        if index % 2 == 0 && end >= 0.0 {
            segments.push((position.max(0.0), end.min(length)));
        }
        position = end;
        index = (index + 1) % count;
    }
    segments
}

fn curve_rect(curve: &Curve) -> Option<Rect> {
    let [
        CurveItem::Move(a),
        CurveItem::Line(b),
        CurveItem::Line(c),
        CurveItem::Line(d),
        CurveItem::Close,
    ] = curve.0.as_slice()
    else {
        return None;
    };
    if (a.y == b.y && b.x == c.x && c.y == d.y && d.x == a.x)
        || (a.x == b.x && b.y == c.y && c.x == d.x && d.y == a.y)
    {
        Some(Rect::new(a.min(*c), a.max(*c)))
    } else {
        None
    }
}

fn rounded_clip(
    builder: &mut DisplayListBuilder,
    mut state: State,
    rect: LayoutRect,
    radius: f32,
) -> State {
    let clip = builder.define_clip_rounded_rect(
        state.space.spatial_id,
        ComplexClipRegion::new(rect, BorderRadius::uniform(radius), ClipMode::Clip),
    );
    state.space.clip_chain_id = clip_chain(builder, state.space, clip);
    state
}

fn clip_chain(
    builder: &mut DisplayListBuilder,
    space: SpaceAndClipInfo,
    clip: webrender::api::ClipId,
) -> ClipChainId {
    let parent = (space.clip_chain_id != ClipChainId::INVALID).then_some(space.clip_chain_id);
    builder.define_clip_chain(parent, [clip])
}

fn reference_frame(
    builder: &mut DisplayListBuilder,
    space: SpaceAndClipInfo,
    transform: LayoutTransform,
) -> webrender::api::SpatialId {
    builder.push_reference_frame(
        LayoutPoint::zero(),
        space.spatial_id,
        TransformStyle::Flat,
        transform.into(),
        ReferenceFrameKind::Transform {
            is_2d_scale_translation: transform.m12 == 0.0 && transform.m21 == 0.0,
            should_snap: false,
            paired_with_perspective: false,
        },
    )
}

fn matrix(t: Transform) -> LayoutTransform {
    LayoutTransform::new(
        t.sx.get() as f32,
        t.ky.get() as f32,
        0.0,
        0.0,
        t.kx.get() as f32,
        t.sy.get() as f32,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        px(t.tx),
        px(t.ty),
        0.0,
        1.0,
    )
}

fn box_transform(origin: Point, size: Size) -> LayoutTransform {
    LayoutTransform::scale(px(size.x), px(size.y), 1.0).then(&LayoutTransform::translation(
        px(origin.x),
        px(origin.y),
        0.0,
    ))
}

pub fn px(length: Abs) -> f32 {
    (length.to_pt() * 96.0 / 72.0) as f32
}

fn bounds(location: Point, rect: Rect) -> LayoutRect {
    let min = location + rect.min.min(rect.max);
    let max = location + rect.min.max(rect.max);
    LayoutRect::new(
        LayoutPoint::new(px(min.x), px(min.y)),
        LayoutPoint::new(px(max.x), px(max.y)),
    )
}

fn color(color: &Color) -> ColorF {
    let (r, g, b, a) = color.to_rgb().into_components();
    ColorF::new(r.clamp(0.0, 1.0), g.clamp(0.0, 1.0), b.clamp(0.0, 1.0), a)
}

#[cfg(test)]
mod tests;
