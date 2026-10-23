mod display_list;
mod fonts;
mod haskell;

use eframe::CreationContext;
use eframe::egui::{
    self, Align2, Color32, FontFamily, FontId, Frame, Id, Key, Margin, Painter, Rect, ScrollArea,
    Sense, Shape, Stroke, StrokeKind, TextEdit, Ui, UiBuilder, Vec2, pos2, vec2,
};
use egui::scroll_area::ScrollBarVisibility;

const FOREGROUND: Color32 = Color32::BLACK;
const BACKGROUND: Color32 = Color32::WHITE;
const TAB_HEIGHT: f32 = 36.0;
const LISTENER_HEIGHT: f32 = 132.0;
const SCROLLBAR_WIDTH: f32 = 9.0;

fn main() -> eframe::Result {
    eframe::run_native(
        "zine",
        eframe::NativeOptions {
            multisampling: 0,
            dithering: false,
            viewport: egui::ViewportBuilder::default()
                .with_decorations(false)
                .with_inner_size([1600.0, 984.0])
                .with_min_inner_size([400.0, 300.0]),
            ..Default::default()
        },
        Box::new(|CreationContext { egui_ctx: ctx, .. }| {
            ctx.tessellation_options_mut(|options| {
                options.feathering = false;
                options.prerasterized_discs = false;
            });
            fonts::install(ctx);
            ctx.all_styles_mut(|style| {
                style.visuals.panel_fill = BACKGROUND;
                style.visuals.override_text_color = Some(FOREGROUND);
                style.visuals.text_cursor.stroke = Stroke::new(1.0, FOREGROUND);
                style.visuals.selection.bg_fill = FOREGROUND;
                style.visuals.selection.stroke = Stroke::new(1.0, BACKGROUND);
                style
                    .text_styles
                    .insert(egui::TextStyle::Body, FontId::proportional(12.0));
                style.spacing.item_spacing = Vec2::ZERO;
                style.animation_time = 0.0;
            });

            Ok(Box::new(Zine {
                documents: ["main.typ", "references.bib"]
                    .into_iter()
                    .map(|name| Document {
                        name: name.into(),
                        text: String::new(),
                        scroll: 0.0,
                        height: 0.0,
                    })
                    .collect(),
                active: 0,
                scrollbar_grab: 0.0,
            }))
        }),
    )
}

fn paint_stipple(painter: &Painter, rect: Rect) {
    let painter = painter.with_clip_rect(rect);
    painter.rect_filled(rect, 0.0, BACKGROUND);
    let mut mesh = egui::Mesh::default();
    for y in 0..rect.height().ceil() as usize {
        let offset = y % 2;
        for x in (offset..rect.width().ceil() as usize).step_by(2) {
            mesh.add_colored_rect(
                Rect::from_min_size(rect.min + vec2(x as f32, y as f32), Vec2::splat(1.0)),
                FOREGROUND,
            );
        }
    }
    painter.add(mesh);
}

fn paint_tab(painter: &Painter, rect: Rect, active: bool) {
    let corners = vec![
        pos2(rect.left() + 0.5, rect.bottom() - 0.5),
        pos2(rect.left() + 10.5, rect.top() + 0.5),
        pos2(rect.right() - 10.5, rect.top() + 0.5),
        pos2(rect.right() - 0.5, rect.bottom() - 0.5),
    ];
    painter.add(Shape::convex_polygon(
        corners.clone(),
        BACKGROUND,
        Stroke::NONE,
    ));
    for edge in corners.windows(2) {
        painter.line_segment([edge[0], edge[1]], Stroke::new(1.0, FOREGROUND));
    }
    if active {
        // Erase the strip's baseline so the active tab joins the document surface.
        painter.rect_filled(
            Rect::from_min_size(
                pos2(rect.left() + 1.0, rect.bottom() - 1.0),
                vec2(rect.width() - 2.0, 1.0),
            ),
            0.0,
            BACKGROUND,
        );
    } else {
        painter.line_segment([corners[3], corners[0]], Stroke::new(1.0, FOREGROUND));
    }
}

struct Document {
    name: String,
    text: String,
    scroll: f32,
    height: f32,
}

struct Zine {
    documents: Vec<Document>,
    active: usize,
    scrollbar_grab: f32,
}

impl eframe::App for Zine {
    fn ui(&mut self, ui: &mut Ui, _frame: &mut eframe::Frame) {
        egui::Panel::top("tabs")
            .exact_size(TAB_HEIGHT)
            .show_separator_line(false)
            .frame(Frame::NONE.fill(BACKGROUND))
            .show(ui, |ui| {
                let strip = ui.max_rect();
                paint_stipple(ui.painter(), strip);
                ui.painter().hline(
                    strip.x_range(),
                    strip.bottom() - 0.5,
                    Stroke::new(1.0, FOREGROUND),
                );

                ScrollArea::horizontal()
                    .id_salt("tab_scroll")
                    .scroll_bar_visibility(ScrollBarVisibility::AlwaysHidden)
                    .auto_shrink([false, false])
                    .show(ui, |ui| {
                        let width = 8.0 + 166.0 * self.documents.len() as f32 + 10.0 + 34.0 + 12.0;
                        let (bounds, _) =
                            ui.allocate_exact_size(vec2(width, TAB_HEIGHT), Sense::hover());
                        // Back-to-front order makes the raised active tab join the viewport.
                        let order = (0..self.documents.len())
                            .rev()
                            .filter(|&i| i != self.active)
                            .chain(std::iter::once(self.active))
                            .collect::<Vec<_>>();
                        for i in order {
                            let selected = self.active == i;
                            let height = if selected { 32.0 } else { 27.0 };
                            let rect = Rect::from_min_size(
                                pos2(
                                    bounds.left() + 8.0 + i as f32 * 166.0,
                                    bounds.bottom() - height,
                                ),
                                vec2(176.0, height),
                            );
                            paint_tab(ui.painter(), rect, selected);
                            let font = FontId::proportional(12.0);
                            ui.painter().text(
                                pos2(rect.center().x, rect.bottom() - 13.5),
                                Align2::CENTER_CENTER,
                                &self.documents[i].name,
                                font,
                                FOREGROUND,
                            );
                            if ui
                                .interact(rect, Id::unique(("tab", i)), Sense::click())
                                .clicked()
                            {
                                self.active = i;
                            }
                        }
                        let add = Rect::from_min_size(
                            pos2(
                                bounds.left() + 8.0 + 166.0 * self.documents.len() as f32 + 9.0,
                                bounds.bottom() - 27.0,
                            ),
                            vec2(34.0, 27.0),
                        );
                        ui.painter().rect_filled(
                            Rect::from_center_size(add.center() + vec2(0.0, 0.5), vec2(18.0, 20.0)),
                            0.0,
                            BACKGROUND,
                        );
                        ui.painter().text(
                            add.center(),
                            Align2::CENTER_CENTER,
                            "+",
                            FontId::proportional(16.0),
                            FOREGROUND,
                        );
                        if ui
                            .interact(add, Id::unique("new_document"), Sense::click())
                            .on_hover_text("New document")
                            .clicked()
                        {
                            self.documents.push(Document {
                                name: format!("untitled-{}.typ", self.documents.len() - 1),
                                text: String::new(),
                                scroll: 0.0,
                                height: 0.0,
                            });
                            self.active = self.documents.len() - 1;
                            ui.scroll_to_rect(
                                Rect::from_min_size(add.min, vec2(210.0, 27.0)),
                                Some(egui::Align::Max),
                            );
                        }
                    });
            });

        egui::CentralPanel::default()
            .frame(Frame::NONE.fill(BACKGROUND))
            .show(ui, |ui| {
                let bounds = ui.max_rect();
                let track = Rect::from_min_size(bounds.min, vec2(SCROLLBAR_WIDTH, bounds.height()));
                let viewport = Rect::from_min_max(pos2(track.right(), bounds.top()), bounds.max);
                let document = &mut self.documents[self.active];
                let document_height = document.height.max(viewport.height()).max(1.0);
                let max_scroll = (document_height - viewport.height()).max(0.0);
                document.scroll = document.scroll.clamp(0.0, max_scroll);
                let thumb_height = (track.height() * viewport.height() / document_height)
                    .clamp(24.0_f32.min(track.height()), track.height());
                let travel = track.height() - thumb_height;
                let thumb_top = track.top()
                    + if max_scroll > 0.0 {
                        document.scroll / max_scroll * travel
                    } else {
                        0.0
                    };

                let response = ui.interact(
                    track,
                    Id::unique("document_scrollbar"),
                    Sense::click_and_drag(),
                );
                if let Some(pointer) = response.interact_pointer_pos() {
                    if response.drag_started() {
                        self.scrollbar_grab =
                            if (thumb_top..=thumb_top + thumb_height).contains(&pointer.y) {
                                pointer.y - thumb_top
                            } else {
                                thumb_height / 2.0
                            };
                    }
                    let clicked_track = response.clicked()
                        && !(thumb_top..=thumb_top + thumb_height).contains(&pointer.y);
                    if travel > 0.0 && (response.dragged() || clicked_track) {
                        let grab = if response.clicked() {
                            thumb_height / 2.0
                        } else {
                            self.scrollbar_grab
                        };
                        document.scroll = ((pointer.y - track.top() - grab) / travel)
                            .clamp(0.0, 1.0)
                            * max_scroll;
                    }
                }
                if response.hovered() {
                    document.scroll = (document.scroll
                        - ui.input(|input| input.smooth_scroll_delta.y))
                    .clamp(0.0, max_scroll);
                }

                ui.scope_builder(UiBuilder::new().max_rect(viewport), |ui| {
                    let output = ScrollArea::vertical()
                        .id_salt(("document", self.active))
                        .scroll_bar_visibility(ScrollBarVisibility::AlwaysHidden)
                        .vertical_scroll_offset(document.scroll)
                        .auto_shrink([false, false])
                        .show(ui, |ui| {
                            ui.add(
                                TextEdit::multiline(&mut document.text)
                                    .id(Id::unique(("document_text", self.active)))
                                    .desired_width(f32::INFINITY)
                                    .min_size(viewport.size())
                                    .frame(Frame::NONE),
                            );
                        });
                    document.scroll = output.state.clamped_offset().y;
                    document.height = output.content_size.y;
                });

                let max_scroll = (document.height - viewport.height()).max(0.0);
                let thumb_height = (track.height() * viewport.height() / document.height.max(1.0))
                    .clamp(24.0_f32.min(track.height()), track.height());
                let travel = track.height() - thumb_height;
                paint_stipple(ui.painter(), track);
                ui.painter().rect_stroke(
                    track,
                    0.0,
                    Stroke::new(1.0, FOREGROUND),
                    StrokeKind::Inside,
                );
                let top = track.top()
                    + if max_scroll > 0.0 {
                        document.scroll / max_scroll * travel
                    } else {
                        0.0
                    };
                ui.painter().rect_filled(
                    Rect::from_min_size(
                        pos2(track.left(), top),
                        vec2(SCROLLBAR_WIDTH, thumb_height),
                    ),
                    0.0,
                    FOREGROUND,
                );
            });
    }
}

fn listener(ui: &mut Ui) {
    let font = FontId::proportional(12.0);
    let (header, _) = ui.allocate_exact_size(vec2(ui.available_width(), 22.0), Sense::hover());
    ui.painter().rect_filled(header, 0.0, FOREGROUND);
    let title = ui
        .painter()
        .layout_job(egui::text::LayoutJob::single_section(
            "Listener".into(),
            egui::TextFormat {
                font_id: FontId::new(12.0, FontFamily::Name("Orbitron Light".into())),
                color: BACKGROUND,
                italics: true,
                ..Default::default()
            },
        ));
    let title_rect =
        Align2::LEFT_CENTER.anchor_size(header.left_center() + vec2(8.0, 0.0), title.size());
    ui.painter().galley(title_rect.min, title, BACKGROUND);
}
