use eframe::egui::{
    self, Align, Align2, CentralPanel, Color32, FontId, Frame, Id, Mesh, Painter, Panel, Rect,
    ScrollArea, Sense, Shape, Stroke, StrokeKind, TextStyle, Ui, UiBuilder, Vec2, pos2, vec2,
};
use egui::scroll_area::ScrollBarVisibility;

const FOREGROUND: Color32 = Color32::BLACK;
const BACKGROUND: Color32 = Color32::WHITE;
const TAB_HEIGHT: f32 = 36.0;
const SCROLLBAR_WIDTH: f32 = 9.0;

use crate::manuscript::{Manuscript, Typesetter};
use crate::fonts;
use crate::webrender::{WebRenderer, View};

pub(crate) fn configure(ctx: &egui::Context) {
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
            .insert(TextStyle::Body, FontId::proportional(12.0));
        style.spacing.item_spacing = Vec2::ZERO;
        style.animation_time = 0.0;
    });
}
fn paint_stipple(painter: &Painter, rect: Rect) {
    let painter = painter.with_clip_rect(rect);
    painter.rect_filled(rect, 0.0, BACKGROUND);
    let mut mesh = Mesh::default();
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

pub(crate) struct Zine {
    pub(crate) documents: Vec<Manuscript>,
    pub(crate) active: usize,
    scrollbar_grab: f32,
    typesetter: Typesetter,
    dirty: bool,
    focus_editor: bool,
}

impl Zine {
    pub(crate) fn new() -> Self {
        let names: Vec<String> = std::env::args().skip(1).collect();
        let names = if names.is_empty() {
            vec!["main.typ".into(), "references.bib".into()]
        } else {
            names
        };
        Self {
            documents: names
                .into_iter()
                .map(|name| {
                    let text = std::fs::read_to_string(&name).unwrap_or_default();
                    Manuscript::new(name, text)
                })
                .collect(),
            active: 0,
            scrollbar_grab: 0.0,
            typesetter: Typesetter::new(),
            dirty: true,
            focus_editor: true,
        }
    }

    pub(crate) fn ui(&mut self, ui: &mut Ui, render: &mut WebRenderer, size: [u32; 2]) {
        Panel::top("tabs")
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
                                self.dirty = true;
                                self.focus_editor = true;
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
                            self.documents.push(Manuscript::new(
                                format!("untitled-{}.typ", self.documents.len() - 1),
                                String::new(),
                            ));
                            self.dirty = true;
                            self.focus_editor = true;
                            self.active = self.documents.len() - 1;
                            ui.scroll_to_rect(
                                Rect::from_min_size(add.min, vec2(210.0, 27.0)),
                                Some(Align::Max),
                            );
                        }
                    });
            });

        if !self.documents[self.active].error.is_empty() {
            Panel::bottom("diagnostic")
                .frame(Frame::NONE.fill(BACKGROUND))
                .show(ui, |ui| {
                    ui.label(&self.documents[self.active].error);
                });
        }
        CentralPanel::default().frame(Frame::NONE).show(ui, |ui| {
            let bounds = ui.max_rect();
            let track = Rect::from_min_size(bounds.min, vec2(SCROLLBAR_WIDTH, bounds.height()));
            let viewport = Rect::from_min_max(pos2(track.right(), bounds.top()), bounds.max);
            let editor_id = Id::unique(("document_editor", self.active));
            let response = ui
                .interact(viewport, editor_id, Sense::click_and_drag())
                .on_hover_cursor(egui::CursorIcon::Text);
            if self.focus_editor || response.clicked() || response.drag_started() {
                response.request_focus();
                self.focus_editor = false;
            }
            if response.drag_started()
                && let Some(point) = ui.input(|i| i.pointer.press_origin())
            {
                let document = &mut self.documents[self.active];
                document.click(
                    point - viewport.min.to_vec2() + vec2(0.0, document.scroll),
                    ui.input(|i| i.modifiers.shift),
                );
            }
            if response.has_focus() {
                ui.memory_mut(|m| {
                    m.set_focus_lock_filter(
                        editor_id,
                        egui::EventFilter {
                            tab: true,
                            horizontal_arrows: true,
                            vertical_arrows: true,
                            ..Default::default()
                        },
                    )
                });
            }
            if (response.clicked() || response.dragged())
                && let Some(point) = response.interact_pointer_pos()
            {
                let document = &mut self.documents[self.active];
                document.click(
                    point - viewport.min.to_vec2() + vec2(0.0, document.scroll),
                    response.dragged() || ui.input(|i| i.modifiers.shift),
                );
            }
            let mut view = View {
                rect: viewport,
                scroll: self.documents[self.active].scroll,
                pixels_per_point: ui.ctx().pixels_per_point(),
                size,
            };
            if self.dirty {
                self.typesetter.compile(&mut self.documents, self.active);
                if self.documents[self.active].rendered.is_none() {
                    // An initially invalid tab must clear the preceding tab's page.
                    self.documents[self.active].rendered = Some(typst_layout::PagedDocument::new(
                        Default::default(),
                        Default::default(),
                    ));
                }
                render.submit(self.documents[self.active].rendered.as_ref(), view);
                self.dirty = false;
                ui.ctx().request_repaint();
            }
            if response.has_focus() && ui.ctx().current_pass_index() == 0 {
                for event in ui.input(|i| i.events.clone()) {
                    let cursor = self.documents[self.active].cursor;
                    let edited = self.documents[self.active].event(&event, ui.ctx());
                    if edited {
                        self.typesetter.compile(&mut self.documents, self.active);
                    }
                    if edited || self.documents[self.active].cursor != cursor {
                        self.documents[self.active].reveal_cursor(viewport.height());
                        view.scroll = self.documents[self.active].scroll;
                    }
                    if edited {
                        render.submit(self.documents[self.active].rendered.as_ref(), view);
                        ui.ctx().request_repaint();
                    }
                }
            }
            let document = &mut self.documents[self.active];
            let document_height = document.height().max(viewport.height()).max(1.0);
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

            let scrollbar_response = ui.interact(
                track,
                Id::unique("document_scrollbar"),
                Sense::click_and_drag(),
            );
            if let Some(pointer) = scrollbar_response.interact_pointer_pos() {
                if scrollbar_response.drag_started() {
                    self.scrollbar_grab =
                        if (thumb_top..=thumb_top + thumb_height).contains(&pointer.y) {
                            pointer.y - thumb_top
                        } else {
                            thumb_height / 2.0
                        };
                }
                let clicked_track = scrollbar_response.clicked()
                    && !(thumb_top..=thumb_top + thumb_height).contains(&pointer.y);
                if travel > 0.0 && (scrollbar_response.dragged() || clicked_track) {
                    let grab = if scrollbar_response.clicked() {
                        thumb_height / 2.0
                    } else {
                        self.scrollbar_grab
                    };
                    document.scroll =
                        ((pointer.y - track.top() - grab) / travel).clamp(0.0, 1.0) * max_scroll;
                }
            }
            if scrollbar_response.hovered() {
                document.scroll = (document.scroll - ui.input(|input| input.smooth_scroll_delta.y))
                    .clamp(0.0, max_scroll);
            }

            ui.scope_builder(UiBuilder::new().max_rect(viewport), |ui| {
                let output = ScrollArea::vertical()
                    .id_salt(("document", self.active))
                    .scroll_bar_visibility(ScrollBarVisibility::AlwaysHidden)
                    .vertical_scroll_offset(document.scroll)
                    .auto_shrink([false, false])
                    .show(ui, |ui| {
                        ui.allocate_exact_size(
                            vec2(viewport.width(), document.height().max(viewport.height())),
                            Sense::hover(),
                        );
                    });
                document.scroll = output.state.clamped_offset().y;
            });

            view.scroll = document.scroll;
            render.submit(None, view);
            if response.has_focus() {
                document.paint_cursor(&ui.painter().with_clip_rect(viewport), viewport.min);
                ui.output_mut(|output| {
                    output.mutable_text_under_cursor = response.hovered();
                    output.ime = Some(egui::output::IMEOutput {
                        purpose: egui::IMEPurpose::Normal,
                        rect: viewport,
                        cursor_rect: document.cursor_rect(viewport.min),
                        should_interrupt_composition: false,
                    });
                });
            }

            let max_scroll = (document.height() - viewport.height()).max(0.0);
            let thumb_height = (track.height() * viewport.height() / document.height().max(1.0))
                .clamp(24.0_f32.min(track.height()), track.height());
            let travel = track.height() - thumb_height;
            paint_stipple(ui.painter(), track);
            ui.painter()
                .rect_stroke(track, 0.0, Stroke::new(1.0, FOREGROUND), StrokeKind::Inside);
            let top = track.top()
                + if max_scroll > 0.0 {
                    document.scroll / max_scroll * travel
                } else {
                    0.0
                };
            ui.painter().rect_filled(
                Rect::from_min_size(pos2(track.left(), top), vec2(SCROLLBAR_WIDTH, thumb_height)),
                0.0,
                FOREGROUND,
            );
        });
    }
}
