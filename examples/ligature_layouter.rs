//! Run with `cargo run --example ligature_layouter` for the Unicode arrow demo,
//! or append `-- /path/to/patched-font.ttf` for the illustrative PUA mappings.

#[path = "ligature_layouter/adapter.rs"]
mod adapter;

use eframe::egui::{self, FontData, FontDefinitions, FontFamily, FontId, TextBuffer, TextEdit};

struct Demo {
    source: String,
    font: FontId,
    rules: Vec<(&'static str, char)>,
}

impl eframe::App for Demo {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ui, |ui| {
            ui.label("Select half an arrow, copy it, or move the caret through it.");
            let mut layouter = |ui: &egui::Ui, buffer: &dyn TextBuffer, width: f32| {
                adapter::layout(
                    ui,
                    buffer.as_str(),
                    self.font.clone(),
                    ui.visuals().text_color(),
                    width,
                    &self.rules,
                )
            };
            ui.add(
                TextEdit::multiline(&mut self.source)
                    .font(self.font.clone())
                    .desired_width(f32::INFINITY)
                    .desired_rows(6)
                    .layouter(&mut layouter),
            );
            ui.label("Actual buffer (unchanged by the display substitutions):");
            ui.monospace(format!("{:?}", self.source));
        });
    }
}

fn main() -> eframe::Result {
    let font_bytes = std::env::args_os()
        .nth(1)
        .map(|path| std::fs::read(path).expect("read patched font"));
    eframe::run_native(
        "Ligature layouter example",
        eframe::NativeOptions::default(),
        Box::new(move |cc| {
            let (font, rules) = if let Some(bytes) = font_bytes {
                let mut fonts = FontDefinitions::default();
                fonts
                    .font_data
                    .insert("patched".into(), FontData::from_owned(bytes).into());
                let family = FontFamily::Name("patched".into());
                fonts
                    .families
                    .insert(family.clone(), vec!["patched".into()]);
                cc.egui_ctx.set_fonts(fonts);
                // These assignments must match the cmap in the supplied font.
                (
                    FontId::new(24.0, family),
                    vec![("->", '\u{e000}'), ("=>", '\u{e001}')],
                )
            } else {
                // Demonstrate the adapter without requiring a modified font.
                (FontId::proportional(24.0), vec![("->", '→'), ("=>", '⇒')])
            };
            Ok(Box::new(Demo {
                source: "a -> b => c\nTry typing another -> here.".into(),
                font,
                rules,
            }))
        }),
    )
}
