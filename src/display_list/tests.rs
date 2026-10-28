use super::*;
use typst::foundations::{Bytes, Smart};
use typst::introspection::{Location, Tag, TagFlags};
use typst::layout::{Angle, Em, Frame, GroupItem};
use typst::syntax::Span;
use typst::text::{Font, Glyph, Lang};
use typst::visualize::{
    ConicGradient, DashPattern, FixedStroke, LinearGradient, ProcessColorSpace, RadialGradient,
    Shape,
};
use webrender::api::{
    BuiltDisplayList, DisplayItem, PipelineId, PropertyBinding, ReferenceTransformBinding,
    SpatialTreeItem,
};

fn convert_item((location, item): (Point, FrameItem)) -> BuiltDisplayList {
    let mut builder = DisplayListBuilder::new(PipelineId(0, 0));
    builder.begin();
    push_item(
        &mut builder,
        location,
        &item,
        State {
            space: state_root(),
            parent: None,
        },
    );
    builder.end().1
}

fn point(x: f64, y: f64) -> Point {
    Point::new(Abs::pt(x), Abs::pt(y))
}
fn size(x: f64, y: f64) -> Size {
    Size::new(Abs::pt(x), Abs::pt(y))
}
fn shape(shape: Shape) -> FrameItem {
    FrameItem::Shape(shape, Span::detached())
}
fn convert(shape_: Shape) -> BuiltDisplayList {
    convert_item((point(12.0, 24.0), shape(shape_)))
}
fn items(list: &BuiltDisplayList) -> Vec<DisplayItem> {
    let mut iter = list.iter();
    let mut result = Vec::new();
    while let Some(item) = iter.next() {
        result.push(*item.item());
    }
    result
}
fn transforms(list: &BuiltDisplayList) -> Vec<LayoutTransform> {
    let mut result = Vec::new();
    list.iter_spatial_tree(|item| {
        if let SpatialTreeItem::ReferenceFrame(frame) = item
            && let ReferenceTransformBinding::Static {
                binding: PropertyBinding::Value(transform),
            } = frame.reference_frame.transform
        {
            result.push(transform);
        }
    });
    result
}
fn assert_bounds(bounds: LayoutRect, min: [f32; 2], max: [f32; 2]) {
    assert_eq!(bounds.min, LayoutPoint::new(min[0], min[1]));
    assert_eq!(bounds.max, LayoutPoint::new(max[0], max[1]));
}
fn linear(angle: f64, relative: RelativeTo) -> Gradient {
    Gradient::Linear(std::sync::Arc::new(LinearGradient {
        stops: vec![(Color::BLACK, Ratio::zero()), (Color::WHITE, Ratio::one())],
        angle: Angle::deg(angle),
        space: ProcessColorSpace::Srgb.into(),
        relative: Smart::Custom(relative),
        anti_alias: true,
    }))
}

#[test]
fn rectangle_preserves_position_size_alpha_and_root_space() {
    let list = convert(Geometry::Rect(size(72.0, 36.0)).filled(Color::from_u8(255, 128, 0, 128)));
    let [DisplayItem::Rectangle(item)] = items(&list)[..] else {
        panic!("expected a rectangle")
    };
    assert_bounds(item.bounds, [16.0, 32.0], [112.0, 80.0]);
    assert_eq!(
        item.color,
        PropertyBinding::Value(ColorF::new(1.0, 128.0 / 255.0, 0.0, 128.0 / 255.0))
    );
    assert_eq!(item.common.clip_rect, item.bounds);
    assert_eq!(item.common.clip_chain_id, ClipChainId::INVALID);
    assert_eq!(item.common.spatial_id, state_root().spatial_id);
}
fn state_root() -> SpaceAndClipInfo {
    SpaceAndClipInfo::root_scroll(PipelineId(0, 0))
}

#[test]
fn negative_rectangle_dimensions_are_normalized() {
    let list = convert(Geometry::Rect(size(-9.0, -18.0)).filled(Color::BLACK));
    let [DisplayItem::Rectangle(item)] = items(&list)[..] else {
        panic!("expected a rectangle")
    };
    assert_bounds(item.bounds, [4.0, 8.0], [16.0, 32.0]);
}

#[test]
fn fill_precedes_the_centered_rectangle_outline() {
    let list = convert(Geometry::Rect(size(72.0, 36.0)).filled_and_stroked(
        Color::WHITE,
        FixedStroke::from_pair(Color::BLACK, Abs::pt(3.0)),
    ));
    let [DisplayItem::Rectangle(fill), DisplayItem::Border(border)] = items(&list)[..] else {
        panic!("expected fill then border")
    };
    assert_bounds(fill.bounds, [16.0, 32.0], [112.0, 80.0]);
    assert_bounds(border.bounds, [14.0, 30.0], [114.0, 82.0]);
    assert_eq!(border.widths, LayoutSideOffsets::new_all_same(4.0));
}

#[test]
fn nested_groups_keep_transforms_and_clips_scoped() {
    let mut inner = Frame::soft(size(18.0, 18.0));
    inner.push(
        point(3.0, 6.0),
        shape(Geometry::Rect(size(9.0, 9.0)).filled(Color::BLACK)),
    );
    let mut group = GroupItem::new(inner);
    group.transform = Transform::scale(Ratio::new(2.0), Ratio::new(3.0));
    group.clip = Some(Curve::rect(size(18.0, 18.0)));
    let mut outer = Frame::hard(size(72.0, 72.0));
    outer.push(point(9.0, 12.0), FrameItem::Group(group));
    outer.push(
        Point::zero(),
        shape(Geometry::Rect(size(3.0, 3.0)).filled(Color::WHITE)),
    );
    let list = convert_item((point(12.0, 24.0), FrameItem::Group(GroupItem::new(outer))));
    let transforms = transforms(&list);
    assert_eq!(transforms.len(), 2);
    assert_eq!(
        transforms[0]
            .transform_point2d(LayoutPoint::zero())
            .unwrap(),
        LayoutPoint::new(16.0, 32.0)
    );
    assert_eq!(
        transforms[1]
            .transform_point2d(LayoutPoint::new(4.0, 8.0))
            .unwrap(),
        LayoutPoint::new(20.0, 40.0)
    );
    let all = items(&list);
    let rectangles: Vec<_> = all
        .iter()
        .filter_map(|i| {
            if let DisplayItem::Rectangle(r) = i {
                Some(r)
            } else {
                None
            }
        })
        .collect();
    assert_ne!(
        rectangles[0].common.spatial_id,
        rectangles[1].common.spatial_id
    );
    assert_ne!(rectangles[0].common.clip_chain_id, ClipChainId::INVALID);
    assert_eq!(rectangles[1].common.clip_chain_id, ClipChainId::INVALID);
    assert_eq!(
        all.iter()
            .filter(|i| matches!(i, DisplayItem::PushReferenceFrame(_)))
            .count(),
        all.iter()
            .filter(|i| matches!(i, DisplayItem::PopReferenceFrame))
            .count()
    );
}

#[test]
fn diagonal_and_round_lines_are_crisp_registered_images() {
    for end in [point(9.0, 12.0), point(-9.0, 0.0), point(0.0, -9.0)] {
        let item = shape(Geometry::Line(end).stroked(FixedStroke {
            cap: LineCap::Round,
            thickness: Abs::pt(3.0),
            ..Default::default()
        }));
        let list = convert_item((point(12.0, 24.0), item.clone()));
        let [DisplayItem::Image(image)] = items(&list)[..] else {
            panic!("image primitive")
        };
        let raster = resources::rasterize(point(12.0, 24.0), &item, None).unwrap();
        assert_eq!(image.image_key, raster.key);
        assert!(raster.data.as_chunks::<4>().0.iter().any(|p| p[3] == 255));
        assert!(
            raster
                .data
                .as_chunks::<4>()
                .0
                .iter()
                .all(|p| p[3] == 0 || p[3] == 255)
        );
        assert!(raster.rect.contains(LayoutPoint::new(16.0, 32.0)));
        assert!(raster.rect.contains(LayoutPoint::new(
            px(Abs::pt(12.0) + end.x),
            px(Abs::pt(24.0) + end.y)
        )));
    }
}

#[test]
fn dash_phase_odd_arrays_and_zero_length_dots_are_preserved() {
    assert_eq!(
        dash_segments(12.0, &[3.0, 2.0], 1.0),
        vec![(0.0, 2.0), (4.0, 7.0), (9.0, 12.0)]
    );
    assert_eq!(
        dash_segments(12.0, &[3.0], 0.0),
        vec![(0.0, 3.0), (6.0, 9.0)]
    );
    assert_eq!(
        dash_segments(7.0, &[0.0, 3.0], 0.0),
        vec![(0.0, 0.0), (3.0, 3.0), (6.0, 6.0)]
    );
}

#[test]
fn square_dash_caps_are_merged_before_alpha_compositing() {
    let list = convert(Geometry::Line(point(9.0, 0.0)).stroked(FixedStroke {
        cap: LineCap::Square,
        thickness: Abs::pt(3.0),
        paint: Color::from_u8(0, 0, 0, 128).into(),
        dash: Some(DashPattern {
            array: vec![Abs::pt(2.0), Abs::pt(1.0)],
            phase: Abs::zero(),
        }),
        ..Default::default()
    }));
    assert_eq!(
        items(&list)
            .iter()
            .filter(|i| matches!(i, DisplayItem::Rectangle(_)))
            .count(),
        1
    );
}

#[test]
fn zero_length_round_line_is_a_dot() {
    let item = shape(Geometry::Line(Point::zero()).stroked(FixedStroke {
        cap: LineCap::Round,
        thickness: Abs::pt(3.0),
        ..Default::default()
    }));
    let raster = resources::rasterize(Point::zero(), &item, None).unwrap();
    assert_bounds(raster.rect, [-2.0, -2.0], [2.0, 2.0]);
    assert!(raster.data.as_chunks::<4>().0.iter().any(|p| p[3] == 255));
    assert!(
        raster
            .data
            .as_chunks::<4>()
            .0
            .iter()
            .all(|p| p[3] == 0 || p[3] == 255)
    );
}

#[test]
fn conic_gradient_preserves_physical_angles_in_non_square_boxes() {
    let angle = Angle::deg(30.0);
    let gradient = Gradient::Conic(std::sync::Arc::new(ConicGradient {
        stops: vec![(Color::BLACK, Ratio::zero()), (Color::WHITE, Ratio::one())],
        angle,
        center: typst::layout::Axes::splat(Ratio::new(0.5)),
        space: ProcessColorSpace::Srgb.into(),
        relative: Smart::Auto,
        anti_alias: true,
    }));
    let list = convert(Geometry::Rect(size(72.0, 36.0)).filled(gradient));
    let all = items(&list);
    let item = all
        .iter()
        .find_map(|i| {
            if let DisplayItem::ConicGradient(g) = i {
                Some(g)
            } else {
                None
            }
        })
        .unwrap();
    let transform = transforms(&list)[0];
    assert!((transform.m11 - 1.0).abs() < 0.0001);
    assert!((transform.m22 - 1.0).abs() < 0.0001);
    assert_eq!(item.gradient.center, LayoutPoint::new(48.0, 24.0));
    // WebRender starts at twelve o'clock; Typst starts at nine o'clock.
    let shader_angle = std::f32::consts::FRAC_PI_2 - item.gradient.angle;
    assert!((shader_angle - (std::f32::consts::PI - angle.to_rad() as f32)).abs() < 0.0001);
}

#[test]
fn linear_gradient_serializes_stops_and_uses_typst_angle_convention() {
    let list = convert(Geometry::Rect(size(72.0, 36.0)).filled(linear(0.0, RelativeTo::Self_)));
    let mut iter = list.iter();
    let mut found = false;
    while let Some(item) = iter.next() {
        if let DisplayItem::Gradient(g) = item.item() {
            found = true;
            assert_eq!(g.gradient.start_point, LayoutPoint::zero());
            assert_eq!(g.gradient.end_point, LayoutPoint::new(1.0, 0.0));
            let stops: Vec<_> = item.gradient_stops().iter().collect();
            assert_eq!(stops.first().unwrap().color, ColorF::BLACK);
            assert_eq!(stops.last().unwrap().color, ColorF::WHITE);
        }
    }
    assert!(found);
    assert_eq!(
        transforms(&list)[0]
            .transform_point2d(LayoutPoint::new(1.0, 1.0))
            .unwrap(),
        LayoutPoint::new(112.0, 80.0)
    );
}

#[test]
fn parent_relative_gradient_stays_anchored_through_soft_groups() {
    let mut inner = Frame::soft(size(12.0, 12.0));
    inner.push(
        point(3.0, 0.0),
        shape(Geometry::Rect(size(9.0, 9.0)).filled(linear(0.0, RelativeTo::Parent))),
    );
    let mut outer = Frame::hard(size(72.0, 36.0));
    outer.push(point(12.0, 0.0), FrameItem::Group(GroupItem::new(inner)));
    let list = convert_item((Point::zero(), FrameItem::Group(GroupItem::new(outer))));
    let all = transforms(&list);
    assert_eq!(all.len(), 3);
    assert_eq!(
        all[2].transform_point2d(LayoutPoint::zero()).unwrap(),
        LayoutPoint::new(-16.0, 0.0)
    );
    assert_eq!(
        all[2]
            .transform_point2d(LayoutPoint::new(1.0, 1.0))
            .unwrap(),
        LayoutPoint::new(80.0, 48.0)
    );
}

#[test]
fn concentric_radial_gradient_keeps_focal_radius() {
    let gradient = Gradient::Radial(std::sync::Arc::new(RadialGradient {
        stops: vec![(Color::BLACK, Ratio::zero()), (Color::WHITE, Ratio::one())],
        center: typst::layout::Axes::splat(Ratio::new(0.5)),
        focal_center: typst::layout::Axes::splat(Ratio::new(0.5)),
        radius: Ratio::new(0.5),
        focal_radius: Ratio::new(0.25),
        space: ProcessColorSpace::Srgb.into(),
        relative: Smart::Auto,
        anti_alias: true,
    }));
    let list = convert(Geometry::Rect(size(72.0, 36.0)).filled(gradient));
    let mut iter = list.iter();
    let mut found = false;
    while let Some(item) = iter.next() {
        if let DisplayItem::RadialGradient(g) = item.item() {
            found = true;
            assert_eq!(g.gradient.start_offset, 0.5);
            assert_eq!(g.gradient.end_offset, 1.0);
        }
    }
    assert!(found);
}

fn text() -> TextItem {
    let font = Font::new(
        Bytes::new(include_bytes!("../../assets/fonts/ChicagoFLF-XY-test.ttf").as_slice()),
        0,
    )
    .unwrap();
    let font = font.instantiate(Default::default(), Abs::pt(12.0), &Default::default());
    let id = font.ttf().glyph_index('A').unwrap().0;
    let glyph = Glyph {
        id,
        x_advance: Em::new(0.5),
        x_offset: Em::new(0.125),
        y_advance: Em::new(0.25),
        y_offset: Em::new(0.125),
        range: 0..1,
        span: (Span::detached(), 0),
    };
    TextItem {
        font,
        size: Abs::pt(12.0),
        fill: Color::BLACK.into(),
        stroke: None,
        lang: Lang::ENGLISH,
        region: None,
        text: "AA".into(),
        glyphs: vec![glyph.clone(), glyph],
    }
}

#[test]
fn text_glyph_positions_preserve_shaping_offsets_and_invert_y() {
    let text = text();
    let glyphs = text_glyphs(point(12.0, 24.0), &text);
    assert_eq!(glyphs.len(), 2);
    assert_eq!(glyphs[0].index, u32::from(text.glyphs[0].id));
    assert_eq!(glyphs[0].point, LayoutPoint::new(18.0, 30.0));
    assert_eq!(glyphs[1].point, LayoutPoint::new(26.0, 26.0));
}

#[test]
fn visible_text_uses_registered_monochrome_font_key() {
    let text = text();
    let list = convert_item((Point::zero(), FrameItem::Text(text.clone())));
    let all = items(&list);
    let DisplayItem::Text(item) = all[0] else {
        panic!("text primitive")
    };
    assert_eq!(item.font_key, font_key(&text));
    assert_eq!(
        item.glyph_options.unwrap().render_mode,
        webrender::api::FontRenderMode::Mono
    );
}

#[test]
fn empty_text_and_tags_emit_no_primitives() {
    let mut empty = text();
    empty.glyphs.clear();
    assert!(items(&convert_item((Point::zero(), FrameItem::Text(empty)))).is_empty());
    let tag = Tag::End(
        Location::new(1),
        0,
        TagFlags {
            introspectable: true,
            tagged: false,
        },
    );
    assert!(items(&convert_item((Point::zero(), FrameItem::Tag(tag)))).is_empty());
}

fn document(source: &str) -> PagedDocument {
    let typesetter = crate::manuscript::Typesetter::new();
    let mut docs = vec![crate::manuscript::Manuscript::new(
        "render-test.typ".into(),
        source.into(),
    )];
    typesetter.compile(&mut docs, 0);
    assert!(docs[0].error.is_empty(), "{}", docs[0].error);
    docs.remove(0).rendered.unwrap()
}

#[test]
fn all_pages_append_to_the_callers_builder_and_pipeline() {
    let doc =
        document("#set page(width: 100pt, height: 100pt, margin: 10pt)\nFirst#pagebreak()Second");
    assert_eq!(doc.pages().len(), 2);
    let pipeline = PipelineId(19, 42);
    let mut builder = DisplayListBuilder::new(pipeline);
    builder.begin();
    let rect = LayoutRect::from_origin_and_size(LayoutPoint::zero(), LayoutSize::new(5.0, 5.0));
    builder.push_rect(
        &CommonItemProperties::new(rect, SpaceAndClipInfo::root_scroll(pipeline)),
        rect,
        ColorF::BLACK,
    );
    to_display_list(&mut builder, doc);
    let (id, list) = builder.end();
    assert_eq!(id, pipeline);
    assert!(matches!(items(&list)[0], DisplayItem::Rectangle(_)));
    let all = items(&list);
    assert_eq!(
        all.iter()
            .filter(|i| matches!(i, DisplayItem::Text(_)))
            .count(),
        2
    );
    assert!(
        transforms(&list)
            .iter()
            .any(|t| (t.m42 - (100.0 * 4.0 / 3.0 + PAGE_GAP)).abs() < 0.001)
    );
}

#[test]
fn resource_uploads_match_display_items_are_cached_and_retired() {
    use webrender::{ResourceUpdate, Transaction};
    let doc = document("Hello $x^2$ #circle(radius: 8pt, fill: black) #rotate(20deg)[Turn]");
    let mut resources = Resources::default();
    let mut txn = Transaction::new();
    resources.update(&mut txn, &doc);
    let mut builder = DisplayListBuilder::new(PipelineId(0, 1));
    builder.begin();
    to_display_list(&mut builder, doc.clone());
    for item in items(&builder.end().1) {
        match item {
            DisplayItem::Text(text) => assert!(txn.resource_updates.iter().any(|r| matches!(r,
                ResourceUpdate::AddFontInstance(f) if f.key == text.font_key && f.options.unwrap().render_mode == webrender::api::FontRenderMode::Mono))),
            DisplayItem::Image(image) => assert!(txn.resource_updates.iter().any(|r| matches!(r, ResourceUpdate::AddImage(i) if i.key == image.image_key))),
            _ => {}
        }
    }
    let mut again = Transaction::new();
    resources.update(&mut again, &doc);
    assert!(again.resource_updates.is_empty());
    resources.update(
        &mut again,
        &PagedDocument::new(Default::default(), Default::default()),
    );
    assert!(
        again
            .resource_updates
            .iter()
            .any(|r| matches!(r, ResourceUpdate::DeleteFont(_)))
    );
    assert!(
        again
            .resource_updates
            .iter()
            .any(|r| matches!(r, ResourceUpdate::DeleteImage(_)))
    );
}
