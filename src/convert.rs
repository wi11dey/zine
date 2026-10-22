use typst::layout::{Abs, FrameItem, Point, Rect};
use typst::visualize::{Geometry, LineCap, LineJoin, Paint};
use webrender::api::units::{LayoutPoint, LayoutRect, LayoutSideOffsets};
use webrender::api::{
    BorderDetails, BorderDisplayItem, BorderSide, BorderStyle, ColorF, CommonItemProperties,
    DisplayItem, LineDisplayItem, LineOrientation, LineStyle, NormalBorder, PipelineId,
    RectangleDisplayItem, SpaceAndClipInfo,
};

/// Convert a standalone item, using CSS pixels (96 px = 72 pt).
///
/// Items use the root scroll node of pipeline (0, 0), with no clip chain. A caller
/// using another pipeline or coordinate space must replace those common fields.
pub fn to_displayitem((location, frame_item): (Point, FrameItem)) -> DisplayItem {
    match frame_item {
        FrameItem::Group(_) => todo!("groups require a display list with child items and scopes"),
        FrameItem::Text(_) => todo!("text requires a registered font and a separate glyph array"),
        FrameItem::Shape(shape, _) => match &shape.geometry {
            Geometry::Rect(_) => match (&shape.fill, &shape.stroke) {
                (Some(_), Some(_)) => todo!("a rectangle's fill and stroke require separate items"),
                (fill, None) => {
                    let bounds = bounds(location, shape.bbox(false));
                    DisplayItem::Rectangle(RectangleDisplayItem {
                        common: common(bounds),
                        bounds,
                        color: fill.as_ref().map_or(ColorF::TRANSPARENT, color).into(),
                    })
                }
                (None, Some(stroke)) => {
                    if stroke.dash.is_some() {
                        todo!("WebRender borders cannot preserve arbitrary dash arrays and phases");
                    }
                    if stroke.join != LineJoin::Miter
                        || stroke.miter_limit.get() < std::f64::consts::SQRT_2
                    {
                        todo!("this rectangle join requires a stroked path");
                    }
                    // Typst centers strokes on the path; WebRender draws borders
                    // inward from their bounds, so include the outer half-stroke.
                    let bounds = bounds(location, shape.bbox(true));
                    let side = BorderSide {
                        color: color(&stroke.paint),
                        style: BorderStyle::Solid,
                    };
                    DisplayItem::Border(BorderDisplayItem {
                        common: common(bounds),
                        bounds,
                        widths: LayoutSideOffsets::new_all_same(px(stroke.thickness)),
                        details: BorderDetails::Normal(NormalBorder {
                            left: side,
                            right: side,
                            top: side,
                            bottom: side,
                            radius: Default::default(),
                            do_aa: true,
                        }),
                    })
                }
            },
            Geometry::Line(end) => {
                let Some(stroke) = &shape.stroke else {
                    // Filling an open straight line paints no area.
                    let bounds = bounds(location, shape.bbox(false));
                    return DisplayItem::Rectangle(RectangleDisplayItem {
                        common: common(bounds),
                        bounds,
                        color: ColorF::TRANSPARENT.into(),
                    });
                };
                if stroke.dash.is_some() {
                    todo!("WebRender lines cannot preserve arbitrary dash arrays and phases");
                }
                if stroke.cap == LineCap::Round {
                    todo!("round line caps require a path or additional primitives");
                }
                let orientation = if end.y == Abs::zero() {
                    LineOrientation::Horizontal
                } else if end.x == Abs::zero() {
                    LineOrientation::Vertical
                } else {
                    todo!("diagonal lines require a transformed coordinate space or a path");
                };
                let half = stroke.thickness / 2.0;
                let extension = if stroke.cap == LineCap::Square {
                    half
                } else {
                    Abs::zero()
                };
                let padding = match orientation {
                    LineOrientation::Horizontal => Point::new(extension, half),
                    LineOrientation::Vertical => Point::new(half, extension),
                };
                let area = bounds(
                    location,
                    Rect::new(
                        end.min(Point::zero()) - padding,
                        end.max(Point::zero()) + padding,
                    ),
                );
                DisplayItem::Line(LineDisplayItem {
                    common: common(area),
                    area,
                    orientation,
                    wavy_line_thickness: 0.0,
                    color: color(&stroke.paint),
                    style: LineStyle::Solid,
                })
            }
            Geometry::Curve(_) => todo!("WebRender has no standalone arbitrary path display item"),
        },
        FrameItem::Image(_, _, _) => todo!("images require a registered WebRender image key"),
        FrameItem::Link(_, _) => todo!("links require a hit-test tag mapped to their destination"),
        FrameItem::Tag(_) => todo!("Typst introspection tags have no visual display item"),
    }
}

fn px(length: Abs) -> f32 {
    (length.to_pt() * 96.0 / 72.0) as f32
}

fn bounds(location: Point, rect: Rect) -> LayoutRect {
    let min = location + rect.min;
    let max = location + rect.max;
    LayoutRect::new(
        LayoutPoint::new(px(min.x), px(min.y)),
        LayoutPoint::new(px(max.x), px(max.y)),
    )
}

fn common(bounds: LayoutRect) -> CommonItemProperties {
    CommonItemProperties::new(bounds, SpaceAndClipInfo::root_scroll(PipelineId(0, 0)))
}

fn color(paint: &Paint) -> ColorF {
    match paint {
        Paint::Solid(color) => {
            let (r, g, b, a) = color.to_rgb().into_components();
            ColorF::new(r.clamp(0.0, 1.0), g.clamp(0.0, 1.0), b.clamp(0.0, 1.0), a)
        }
        Paint::Gradient(_) => todo!("gradients require a separate color-stop array"),
        Paint::Tiling(_) => todo!("tilings require rendering and registering a tile resource"),
    }
}

#[cfg(test)]
mod tests;
