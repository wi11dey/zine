mod pango;

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
// An empty document still has scrollable extent; at the design's 816 px viewport
// height this gives the original 208 px scroll thumb.
const DOCUMENT_HEIGHT: f32 = 3200.0;

fn main() -> eframe::Result {
    eframe::run_native(
        "zine",
        eframe::NativeOptions {
            multisampling: 0,
            dithering: false,
            viewport: egui::ViewportBuilder::default()
                .with_inner_size([1600.0, 984.0])
                .with_min_inner_size([400.0, 300.0]),
            ..Default::default()
        },
        Box::new(|cc| {
            configure(&cc.egui_ctx);
            Ok(Box::new(Zine::default()))
        }),
    )
}

fn configure(ctx: &egui::Context) {
    ctx.tessellation_options_mut(|options| {
        options.feathering = false;
        options.prerasterized_discs = false;
    });
    pango::install(ctx);
    ctx.set_visuals(egui::Visuals::light());
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
    painter.add(Shape::convex_polygon(corners.clone(), BACKGROUND, Stroke::NONE));
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
    scroll: f32,
}

struct Zine {
    documents: Vec<Document>,
    active: usize,
    scrollbar_grab: f32,
    transcript: Vec<String>,
    command: String,
}

impl Default for Zine {
    fn default() -> Self {
        Self {
            documents: ["main.typ", "references.bib"]
                .into_iter()
                .map(|name| Document {
                    name: name.into(),
                    scroll: 0.0,
                })
                .collect(),
            active: 0,
            scrollbar_grab: 0.0,
            // Sample transcript from the frame. No evaluator is connected yet.
            transcript: vec![
                "Command: Inspect Figure 1".into(),
                "ripple-01 → surface → mesh → vertex [12, 4]".into(),
            ],
            command: String::new(),
        }
    }
}

impl eframe::App for Zine {
    fn ui(&mut self, ui: &mut Ui, _frame: &mut eframe::Frame) {
        egui::Panel::top("tabs")
            .exact_size(TAB_HEIGHT)
            .show_separator_line(false)
            .frame(Frame::NONE.fill(BACKGROUND))
            .show(ui, |ui| self.tabs(ui));

        egui::Panel::bottom("listener")
            .exact_size(LISTENER_HEIGHT)
            .show_separator_line(false)
            .frame(Frame::NONE.fill(BACKGROUND))
            .show(ui, |ui| self.listener(ui));

        egui::CentralPanel::default()
            .frame(Frame::NONE.fill(BACKGROUND))
            .show(ui, |ui| self.viewport(ui));
    }
}

impl Zine {
    fn tabs(&mut self, ui: &mut Ui) {
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
                let (bounds, _) = ui.allocate_exact_size(vec2(width, TAB_HEIGHT), Sense::hover());
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
                    let font = if selected {
                        FontId::new(12.0, FontFamily::Name("Droid Sans Bold".into()))
                    } else {
                        FontId::proportional(12.0)
                    };
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
                        scroll: 0.0,
                    });
                    self.active = self.documents.len() - 1;
                    ui.scroll_to_rect(
                        Rect::from_min_size(add.min, vec2(210.0, 27.0)),
                        Some(egui::Align::Max),
                    );
                }
            });
    }

    fn viewport(&mut self, ui: &mut Ui) {
        let bounds = ui.max_rect();
        let track = Rect::from_min_size(bounds.min, vec2(SCROLLBAR_WIDTH, bounds.height()));
        let viewport = Rect::from_min_max(pos2(track.right(), bounds.top()), bounds.max);
        let document = &mut self.documents[self.active];
        let max_scroll = (DOCUMENT_HEIGHT - viewport.height()).max(0.0);
        document.scroll = document.scroll.clamp(0.0, max_scroll);
        let thumb_height = (track.height() * viewport.height() / DOCUMENT_HEIGHT)
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
                self.scrollbar_grab = if (thumb_top..=thumb_top + thumb_height).contains(&pointer.y)
                {
                    pointer.y - thumb_top
                } else {
                    thumb_height / 2.0
                };
            }
            let clicked_track =
                response.clicked() && !(thumb_top..=thumb_top + thumb_height).contains(&pointer.y);
            if travel > 0.0 && (response.dragged() || clicked_track) {
                let grab = if response.clicked() {
                    thumb_height / 2.0
                } else {
                    self.scrollbar_grab
                };
                document.scroll =
                    ((pointer.y - track.top() - grab) / travel).clamp(0.0, 1.0) * max_scroll;
            }
        }
        if response.hovered() {
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
                    ui.set_min_size(vec2(viewport.width(), DOCUMENT_HEIGHT));
                });
            document.scroll = output.state.clamped_offset().y;
        });

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
    }

    fn listener(&mut self, ui: &mut Ui) {
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
        Frame::NONE
            .inner_margin(Margin {
                left: 12,
                right: 12,
                top: 6,
                bottom: 0,
            })
            .show(ui, |ui| {
                ScrollArea::vertical()
                    .id_salt("transcript")
                    .min_scrolled_height(48.0)
                    .max_height(48.0)
                    .auto_shrink([false, false])
                    .stick_to_bottom(true)
                    .show(ui, |ui| {
                        for line in &self.transcript {
                            let (rect, _) = ui.allocate_exact_size(
                                vec2(ui.available_width(), 24.0),
                                Sense::hover(),
                            );
                            ui.painter().text(
                                rect.left_center(),
                                Align2::LEFT_CENTER,
                                line,
                                FontId::proportional(12.0),
                                FOREGROUND,
                            );
                        }
                    });
                ui.allocate_ui_with_layout(
                    vec2(ui.available_width(), 35.0),
                    egui::Layout::left_to_right(egui::Align::Center),
                    |ui| {
                        ui.spacing_mut().item_spacing.x = 7.0;
                        ui.label(
                            egui::RichText::new("Command:")
                                .font(FontId::proportional(12.0))
                                .color(FOREGROUND),
                        );
                        let input = ui.add(
                            TextEdit::singleline(&mut self.command)
                                .id(Id::unique("command_input"))
                                .font(FontId::proportional(12.0))
                                .desired_width(f32::INFINITY)
                                .margin(Vec2::ZERO)
                                .frame(Frame::NONE),
                        );
                        if self.command.is_empty() && !input.has_focus() {
                            ui.painter().rect_stroke(
                                Rect::from_min_size(
                                    pos2(input.rect.left(), input.rect.center().y - 8.0),
                                    vec2(7.0, 16.0),
                                ),
                                0.0,
                                Stroke::new(1.0, FOREGROUND),
                                StrokeKind::Inside,
                            );
                        }
                        if input.lost_focus() && ui.input(|input| input.key_pressed(Key::Enter)) {
                            let command = self.command.trim();
                            if command == "clear" {
                                self.transcript.clear();
                            } else if !command.is_empty() {
                                self.transcript.push(format!("Command: {command}"));
                            }
                            self.command.clear();
                            input.request_focus();
                        }
                    },
                );
            });
    }
}
