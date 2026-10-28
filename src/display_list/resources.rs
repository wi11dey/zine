//! WebRender resources are separate from display lists. Content-derived keys let
//! `to_display_list` remain a pure builder operation, without a renderer/global registry.
use std::{collections::HashSet, hash::Hash, sync::Arc};
use typst::foundations::Smart;
use typst::layout::{Frame, GroupItem};
use typst::utils::hash128;
use typst_layout::{Page, PagedDocument};
use webrender::Transaction;
use webrender::api::{
    FontInstanceFlags, FontInstanceOptions, FontKey, FontRenderMode, FontVariation, IdNamespace,
    ImageData, ImageDescriptor, ImageDescriptorFlags, ImageFormat,
};

use super::*;

fn key(value: &impl Hash) -> (IdNamespace, u32) {
    let hash = hash128(value) as u64;
    // Reserve the upper namespace half for our content-addressed resources.
    (IdNamespace((hash >> 32) as u32 | 0x8000_0000), hash as u32)
}

pub(super) fn font_key(text: &TextItem) -> FontInstanceKey {
    let (namespace, id) = key(&(&text.font, text.size));
    FontInstanceKey(namespace, id)
}

fn raw_font_key(text: &TextItem) -> FontKey {
    let (namespace, id) = key(text.font.font());
    FontKey(namespace, id)
}

#[derive(Default)]
pub struct Resources {
    fonts: HashSet<FontKey>,
    instances: HashSet<FontInstanceKey>,
    images: HashSet<ImageKey>,
}

impl Resources {
    /// Register resources before submitting the corresponding display list and
    /// retire resources no longer referenced by the active document.
    pub fn update(&mut self, txn: &mut Transaction, document: &PagedDocument) {
        let mut used = Self::default();
        for page in document.pages() {
            self.visit(
                txn,
                &mut used,
                Point::zero(),
                &FrameItem::Group(GroupItem::new(page.frame.clone())),
                None,
            );
        }
        for key in self.instances.difference(&used.instances) {
            txn.delete_font_instance(*key);
        }
        for key in self.fonts.difference(&used.fonts) {
            txn.delete_font(*key);
        }
        for key in self.images.difference(&used.images) {
            txn.delete_image(*key);
        }
        *self = used;
    }

    fn visit(
        &mut self,
        txn: &mut Transaction,
        used: &mut Self,
        location: Point,
        item: &FrameItem,
        parent: Option<(Size, Transform)>,
    ) {
        if needs_raster(item) {
            if let Some(image) = rasterize(location, item, parent) {
                used.images.insert(image.key);
                if self.images.insert(image.key) {
                    txn.add_image(
                        image.key,
                        ImageDescriptor::new(
                            image.width as i32,
                            image.height as i32,
                            ImageFormat::BGRA8,
                            ImageDescriptorFlags::empty(),
                        ),
                        ImageData::new(image.data.clone()),
                        None,
                    );
                }
            }
            return;
        }
        match item {
            FrameItem::Group(group) => {
                let transform =
                    Transform::translate(location.x, location.y).pre_concat(group.transform);
                let parent = group_parent(parent, group, transform);
                for (point, item) in group.frame.items() {
                    self.visit(txn, used, *point, item, parent);
                }
            }
            FrameItem::Text(text) if !text.glyphs.is_empty() => {
                let font = raw_font_key(text);
                let instance = font_key(text);
                used.fonts.insert(font);
                used.instances.insert(instance);
                if self.fonts.insert(font) {
                    txn.add_raw_font(
                        font,
                        text.font.font().data().to_vec(),
                        text.font.font().index(),
                    );
                }
                if self.instances.insert(instance) {
                    let options = FontInstanceOptions {
                        render_mode: FontRenderMode::Mono,
                        flags: FontInstanceFlags::empty(), // In particular, no SUBPIXEL_POSITION.
                        ..Default::default()
                    };
                    #[allow(unused_mut)]
                    let mut platform = webrender::api::FontInstancePlatformOptions::default();
                    #[cfg(not(any(
                        target_os = "macos",
                        target_os = "ios",
                        target_os = "windows"
                    )))]
                    {
                        platform.hinting = webrender::api::FontHinting::Mono;
                        platform.lcd_filter = webrender::api::FontLCDFilter::None;
                    }
                    let variations = text
                        .font
                        .variations()
                        .0
                        .iter()
                        .map(|(tag, value)| FontVariation {
                            tag: u32::from_be_bytes(tag.to_bytes()),
                            value: value.0,
                        })
                        .collect();
                    txn.add_font_instance(
                        instance,
                        font,
                        px(text.size),
                        Some(options),
                        Some(platform),
                        variations,
                    );
                }
            }
            _ => {}
        }
    }
}

pub(super) struct Raster {
    pub(super) key: ImageKey,
    pub(super) rect: LayoutRect,
    width: u32,
    height: u32,
    pub(super) data: Vec<u8>,
}

/// Rasterize just the unsupported primitive/group, never the WebRender or egui
/// layer. Keep its enclosing hard frame so parent-relative paints remain correct.
#[comemo::memoize]
pub(super) fn rasterize(
    location: Point,
    item: &FrameItem,
    parent: Option<(Size, Transform)>,
) -> Option<Arc<Raster>> {
    use resvg::{tiny_skia, usvg};
    let (size, transform) = parent.unwrap_or((Size::splat(Abs::pt(1.0)), Transform::identity()));
    let mut contents = Frame::soft(size);
    if let FrameItem::Shape(shape, span) = item
        && matches!(shape.geometry, Geometry::Line(end) if end == Point::zero())
        && let Some(stroke) = &shape.stroke
        && stroke.cap == LineCap::Round
    {
        contents.push(
            location - Point::splat(stroke.thickness / 2.0),
            FrameItem::Shape(
                Geometry::Curve(Curve::ellipse(Size::splat(stroke.thickness)))
                    .filled(stroke.paint.clone()),
                *span,
            ),
        );
    } else {
        contents.push(location, item.clone());
    }
    let mut group = GroupItem::new(contents);
    group.transform = transform;
    let mut frame = Frame::hard(size);
    frame.push(Point::zero(), FrameItem::Group(group));
    let page = Page {
        frame,
        bleed: Default::default(),
        fill: Smart::Custom(None),
        numbering: None,
        supplement: Default::default(),
        number: 1,
    };
    let svg = typst_svg::svg(&page, &Default::default()).replace(
        "shape-rendering=\"geometricPrecision\"",
        "shape-rendering=\"crispEdges\"",
    );
    let options = usvg::Options {
        dpi: 72.0,
        shape_rendering: usvg::ShapeRendering::CrispEdges,
        ..Default::default()
    };
    let tree = usvg::Tree::from_str(&svg, &options).expect("Typst generated valid SVG");
    let inverse = transform.invert()?;
    let inverse = tiny_skia::Transform::from_row(
        inverse.sx.get() as f32,
        inverse.ky.get() as f32,
        inverse.kx.get() as f32,
        inverse.sy.get() as f32,
        inverse.tx.to_pt() as f32,
        inverse.ty.to_pt() as f32,
    );
    let bbox = tree.root().abs_stroke_bounding_box().transform(inverse)?;
    if bbox.width() <= 0.0 || bbox.height() <= 0.0 {
        return None;
    }
    let scale = 96.0 / 72.0;
    let min_x = (bbox.x() * scale).floor();
    let min_y = (bbox.y() * scale).floor();
    let width = (bbox.right() * scale).ceil() - min_x;
    let height = (bbox.bottom() * scale).ceil() - min_y;
    let mut pixmap = tiny_skia::Pixmap::new(width as u32, height as u32)?;
    resvg::render(
        &tree,
        inverse
            .post_scale(scale, scale)
            .post_translate(-min_x, -min_y),
        &mut pixmap.as_mut(),
    );
    let mut data = pixmap.take();
    for pixel in data.as_chunks_mut::<4>().0 {
        pixel.swap(0, 2);
    } // premultiplied RGBA -> BGRA
    let (namespace, id) = key(&(location, item, parent));
    Some(Arc::new(Raster {
        key: ImageKey(namespace, id),
        rect: LayoutRect::from_origin_and_size(
            LayoutPoint::new(min_x, min_y),
            LayoutSize::new(width, height),
        ),
        width: width as u32,
        height: height as u32,
        data,
    }))
}

pub(super) fn push_raster(
    builder: &mut DisplayListBuilder,
    location: Point,
    item: &FrameItem,
    state: State,
) {
    if let Some(image) = rasterize(location, item, state.parent) {
        builder.push_image(
            &CommonItemProperties::new(image.rect, state.space),
            image.rect,
            ImageRendering::Pixelated,
            AlphaType::PremultipliedAlpha,
            image.key,
            ColorF::WHITE,
        );
    }
}

pub(super) fn needs_raster(item: &FrameItem) -> bool {
    let paint = |p: &Paint| match p {
        Paint::Tiling(_) => true,
        Paint::Gradient(Gradient::Radial(g)) => g.center != g.focal_center || g.radius.get() == 0.0,
        _ => false,
    };
    match item {
        FrameItem::Image(..) => true,
        FrameItem::Group(g) => {
            g.transform.kx != Ratio::zero()
                || g.transform.ky != Ratio::zero()
                || g.clip.as_ref().is_some_and(|c| curve_rect(c).is_none())
        }
        FrameItem::Text(t) => {
            t.stroke.is_some()
                || !matches!(t.fill, Paint::Solid(_))
                || t.glyphs.iter().any(|g| {
                    typst::text::color::glyph_frame(&t.font, g.id).is_some_and(|f| {
                        matches!(f.item, typst::text::color::GlyphFrameItem::Image(..))
                    })
                })
        }
        FrameItem::Shape(s, _) => {
            s.fill.as_ref().is_some_and(paint)
                || s.stroke.as_ref().is_some_and(|s| paint(&s.paint))
                || match &s.geometry {
                    Geometry::Curve(c) => {
                        curve_rect(c).is_none()
                            || s.stroke.as_ref().is_some_and(|s| {
                                s.dash.is_some()
                                    || s.join != LineJoin::Miter
                                    || s.miter_limit.get() < std::f64::consts::SQRT_2
                            })
                    }
                    Geometry::Rect(_) => s.stroke.as_ref().is_some_and(|s| {
                        s.dash.is_some()
                            || s.join != LineJoin::Miter
                            || s.miter_limit.get() < std::f64::consts::SQRT_2
                    }),
                    Geometry::Line(end) => {
                        end.y != Abs::zero()
                            || s.stroke.as_ref().is_some_and(|s| s.cap == LineCap::Round)
                    }
                }
        }
        _ => false,
    }
}
