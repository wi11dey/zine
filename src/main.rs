mod display_list;
mod editor;
mod fonts;
mod haskell;
mod render;
mod ui;

use render::{Graphics, Wake};
use std::time::{Duration, Instant};
use ui::{Zine, configure};
use winit::{
    application::ApplicationHandler,
    event::{StartCause, WindowEvent},
    event_loop::{ActiveEventLoop, ControlFlow, EventLoop, EventLoopProxy},
    window::WindowId,
};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let event_loop = EventLoop::<Wake>::with_user_event().build()?;
    let mut app = App {
        graphics: None,
        zine: Zine::new(),
        proxy: event_loop.create_proxy(),
        repaint_at: None,
    };
    event_loop.run_app(&mut app)?;
    Ok(())
}

struct App {
    graphics: Option<Graphics>,
    zine: Zine,
    proxy: EventLoopProxy<Wake>,
    repaint_at: Option<Instant>,
}

impl ApplicationHandler<Wake> for App {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        if self.graphics.is_none() {
            let graphics = Graphics::new(event_loop, self.proxy.clone());
            configure(&graphics.egui.egui_ctx);
            graphics.window.request_redraw();
            self.graphics = Some(graphics);
        }
    }

    fn window_event(&mut self, event_loop: &ActiveEventLoop, _: WindowId, event: WindowEvent) {
        let Some(graphics) = &mut self.graphics else {
            return;
        };
        match event {
            WindowEvent::CloseRequested => event_loop.exit(),
            WindowEvent::RedrawRequested => {
                self.repaint_at = None;
                let size: [u32; 2] = graphics.window.inner_size().into();
                if size.contains(&0) {
                    return;
                }
                let Graphics {
                    egui,
                    window,
                    render,
                    ..
                } = graphics;
                egui.run(window, |ui| self.zine.ui(ui, render, size));
                graphics.paint();
                graphics.present();
            }
            _ => {
                if matches!(event, WindowEvent::Resized(_)) {
                    graphics.resize();
                }
                let response = graphics.egui.on_window_event(&graphics.window, &event);
                if response.repaint {
                    graphics.window.request_redraw();
                }
            }
        }
    }

    fn user_event(&mut self, event_loop: &ActiveEventLoop, Wake::Repaint(delay): Wake) {
        if let Some(at) = Instant::now().checked_add(delay) {
            self.repaint_at = Some(self.repaint_at.map_or(at, |old| old.min(at)));
        }
        if delay == Duration::ZERO
            && let Some(graphics) = &self.graphics
        {
            graphics.window.request_redraw();
        }
        event_loop.set_control_flow(
            self.repaint_at
                .map_or(ControlFlow::Wait, ControlFlow::WaitUntil),
        );
    }

    fn new_events(&mut self, _: &ActiveEventLoop, cause: StartCause) {
        if matches!(cause, StartCause::ResumeTimeReached { .. })
            && let Some(graphics) = &self.graphics
        {
            graphics.window.request_redraw();
        }
    }

    fn about_to_wait(&mut self, event_loop: &ActiveEventLoop) {
        event_loop.set_control_flow(
            self.repaint_at
                .map_or(ControlFlow::Wait, ControlFlow::WaitUntil),
        );
    }

    fn exiting(&mut self, _: &ActiveEventLoop) {
        self.graphics.take();
    }
}
