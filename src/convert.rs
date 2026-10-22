use typst::layout::{FrameItem, Point};
use webrender::api::DisplayItem;

pub fn to_displayitem((location, frame_item): (Point, FrameItem)) -> DisplayItem {
    match frame_item {
        FrameItem::Group(_) => todo!(),
        FrameItem::Text(_) => todo!(),
        FrameItem::Shape(_, _) => todo!(),
        FrameItem::Image(_, _, _) => todo!(),
        FrameItem::Link(_, _) => todo!(),
        FrameItem::Tag(_) => todo!(),
    }
}
