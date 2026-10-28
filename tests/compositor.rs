//! Opt-in native test: ZINE_GL_TEST=1 cargo test --test compositor
#![allow(dead_code, unused_imports)]
// Load the binary's modules with their original submodule paths.
#[path = "../src"]
mod app {
    pub mod display_list;
    pub mod editor;
    pub mod fonts;
    pub mod render;
    pub mod ui;
}
use app::{display_list, editor, fonts, render, ui};
use editor::Document;
use eframe::egui::{self, Color32, Rect, pos2, vec2};
use render::{Graphics, Wake};
use ui::{Zine, configure};
use winit::{
    application::ApplicationHandler,
    event::WindowEvent,
    event_loop::{ActiveEventLoop, EventLoop, EventLoopProxy},
    window::WindowId,
};

use egui_glow::glow::{self, HasContext};

struct Check {
    proxy: EventLoopProxy<Wake>,
    failed: bool,
}
impl Check {
    fn check(&self, event_loop: &ActiveEventLoop) {
        let mut graphics = Graphics::new(event_loop, self.proxy.clone());
        configure(&graphics.egui.egui_ctx);
        let mut zine = Zine::new();
        zine.documents = vec![
            Document::new("compositor.typ".into(),
                "#set page(width: 240pt, height: 600pt, margin: 20pt, fill: rgb(\"0000ff\"))\n#set text(size: 20pt, fill: black)\nHello $x^2$ #circle(radius: 12pt, fill: black)\n#pagebreak()\nSecond page".into()),
            Document::new("blank.typ".into(), String::new()),
        ];
        let first_id = zine.documents[0].source.id();
        for step in 0..4 {
            graphics.egui.egui_winit.egui_input_mut().focused = true;
            if step == 1 {
                zine.documents[0].scroll = 100.0;
            }
            if step == 2 {
                zine.documents[0].scroll = 0.0;
                graphics.egui.egui_winit.egui_input_mut().events.extend([
                    egui::Event::Key {
                        key: egui::Key::End,
                        physical_key: None,
                        pressed: true,
                        repeat: false,
                        modifiers: egui::Modifiers {
                            command: true,
                            ..Default::default()
                        },
                    },
                    egui::Event::Text(" Edited".into()),
                ]);
            }
            if step == 3 {
                let point = pos2(250.0, 20.0);
                graphics.egui.egui_winit.egui_input_mut().events.extend([
                    egui::Event::PointerMoved(point),
                    egui::Event::PointerButton {
                        pos: point,
                        button: egui::PointerButton::Primary,
                        pressed: true,
                        modifiers: Default::default(),
                    },
                    egui::Event::PointerButton {
                        pos: point,
                        button: egui::PointerButton::Primary,
                        pressed: false,
                        modifiers: Default::default(),
                    },
                    egui::Event::Text("Typed in blank tab".into()),
                ]);
            }
            let size: [u32; 2] = graphics.window.inner_size().into();
            let Graphics {
                egui,
                window,
                render,
                ..
            } = &mut graphics;
            egui.run(window, |ui| {
                zine.ui(ui, render, size);
                ui.painter().rect_filled(
                    Rect::from_min_size(pos2(20.0, 40.0), vec2(80.0, 16.0)),
                    0.0,
                    Color32::RED,
                );
            });
            graphics.paint();
            let scale = graphics.egui.egui_ctx.pixels_per_point();
            let gl = graphics.egui.painter.gl();
            let mut pixels = vec![0u8; (size[0] * size[1] * 4) as usize];
            unsafe {
                gl.read_pixels(
                    0,
                    0,
                    size[0] as i32,
                    size[1] as i32,
                    glow::RGBA,
                    glow::UNSIGNED_BYTE,
                    glow::PixelPackData::Slice(Some(&mut pixels)),
                );
                assert_eq!(gl.get_error(), glow::NO_ERROR);
            }
            let pixel = |x: f32, y: f32| {
                let x = (x * scale) as usize;
                let y = size[1] as usize - 1 - (y * scale) as usize;
                let i = (y * size[0] as usize + x) * 4;
                &pixels[i..i + 3]
            };
            assert_eq!(pixel(25.0, 45.0), [255, 0, 0], "egui overlays WebRender");
            assert_eq!(
                pixel(400.0, 100.0),
                [255, 255, 255],
                "page width is preserved"
            );
            assert_ne!(
                pixel(4.0, 50.0),
                [0, 0, 255],
                "egui scrollbar clips the document"
            );
            if step == 0 {
                assert_eq!(pixel(310.0, 60.0), [0, 0, 255], "WebRender page is visible");
                let mut black = 0;
                for y in 60..150 {
                    for x in 40..250 {
                        let p = pixel(x as f32, y as f32);
                        assert!(
                            p == [0, 0, 0] || p == [0, 0, 255],
                            "no font or shape AA: {p:?}"
                        );
                        if p == [0, 0, 0] {
                            black += 1;
                        }
                    }
                }
                assert!(black > 10, "Typst glyphs and circle render");
                if let Some(path) = std::env::var_os("ZINE_GL_CAPTURE") {
                    let flipped = pixels
                        .chunks_exact(size[0] as usize * 4)
                        .rev()
                        .flatten()
                        .copied()
                        .collect();
                    resvg::tiny_skia::Pixmap::from_vec(
                        flipped,
                        resvg::tiny_skia::IntSize::from_wh(size[0], size[1]).unwrap(),
                    )
                    .unwrap()
                    .save_png(path)
                    .unwrap();
                }
            }
            if step == 1 {
                assert!((zine.documents[0].scroll - 100.0).abs() < 1.0);
            }
            if step >= 2 {
                assert!(
                    zine.documents[0].source.text().ends_with(" Edited"),
                    "keyboard edits the active Source (step {step}, cursor {}, source {:?}, focused {:?})",
                    zine.documents[0].cursor,
                    zine.documents[0].source.text(),
                    graphics.egui.egui_ctx.memory(|m| m.focused())
                );
                assert_eq!(zine.documents[0].source.id(), first_id);
                assert!(zine.documents[0].error.is_empty());
            }
            if step == 3 {
                assert_eq!(zine.active, 1);
                assert_eq!(zine.documents[1].source.text(), "Typed in blank tab");
                assert!(zine.documents[1].error.is_empty());
                assert_eq!(
                    pixel(310.0, 60.0),
                    [255, 255, 255],
                    "tab switch replaces the page"
                );
            }
            graphics.present();
        }
        println!(
            "Native GL composition, mono pixels, scrolling, keyboard edits and tab switching passed"
        );
    }
}

impl ApplicationHandler<Wake> for Check {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        self.failed =
            std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| self.check(event_loop)))
                .is_err();
        event_loop.exit();
    }
    fn window_event(&mut self, _: &ActiveEventLoop, _: WindowId, _: WindowEvent) {}
}

fn main() {
    if std::env::var_os("ZINE_GL_TEST").is_none() {
        println!("compositor: skipped (set ZINE_GL_TEST=1 to test the native GL window)");
        return;
    }
    let event_loop = EventLoop::<Wake>::with_user_event().build().unwrap();
    let mut check = Check {
        proxy: event_loop.create_proxy(),
        failed: false,
    };
    event_loop.run_app(&mut check).unwrap();
    if check.failed {
        std::process::exit(1);
    }
}
