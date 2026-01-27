use winit::application::ApplicationHandler;
use winit::event::{WindowEvent, ElementState};
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::window::{Window, WindowId};
use winit::keyboard::{Key, NamedKey};
use winit::dpi::LogicalSize;

use cairo::{Context, ImageSurface, Format};
use harfbuzz_rs::{Face, Font, UnicodeBuffer, shape, Owned};
use pixels::{Pixels, SurfaceTexture};

use std::sync::Arc;

struct App<'a> {
    window: Option<Arc<Window>>,
    pixels: Option<Pixels<'a>>,
    cairo_surface: Option<ImageSurface>,
    width: u32,
    height: u32,
    hb_font: Owned<Font<'static>>,
    cursor_x: f64,
    cursor_y: f64,
}

impl<'a> App<'a> {
    fn new() -> Self {
        let width = 800;
        let height = 600;
        
        // Load a font for HarfBuzz
        let font_data = include_bytes!("/System/Library/Fonts/Helvetica.ttc");
        let face = Face::from_bytes(font_data, 0);
        let hb_font: Owned<Font> = Font::new(face);
        
        App {
            window: None,
            pixels: None,
            cairo_surface: None,
            width,
            height,
            hb_font,
            cursor_x: 10.0,
            cursor_y: 30.0,
        }
    }
    
    fn draw_text(&mut self, text: &str) {
        if let Some(cairo_surface) = &self.cairo_surface {
            let cairo_context = Context::new(cairo_surface).unwrap();
            
            // Shape the text using HarfBuzz
            let buffer = UnicodeBuffer::new().add_str(text);
            let output = shape(&self.hb_font, buffer, &[]);
            
            // Set up Cairo for drawing
            cairo_context.set_source_rgb(0.0, 0.0, 0.0);
            cairo_context.set_font_size(24.0);
            
            let positions = output.get_glyph_positions();
            
            // Use Cairo's toy text API
            cairo_context.move_to(self.cursor_x, self.cursor_y);
            cairo_context.show_text(text).unwrap();
            
            // Update cursor position based on HarfBuzz advance
            for position in positions {
                self.cursor_x += position.x_advance as f64 / 64.0;
            }
            
            // Wrap to next line if needed
            if self.cursor_x > (self.width as f64 - 20.0) {
                self.cursor_x = 10.0;
                self.cursor_y += 30.0;
            }
        }
    }
    
    fn update_pixels(&mut self) {
        if let (Some(cairo_surface), Some(pixels)) = (&mut self.cairo_surface, &mut self.pixels) {
            cairo_surface.flush();
            let stride = cairo_surface.stride() as i32;
            let cairo_data = cairo_surface.data().unwrap();
            
            // Get pixels frame
            let frame = pixels.frame_mut();
            
            // Convert BGRA (Cairo) to RGBA (Pixels)
            for y in 0..self.height as i32 {
                for x in 0..self.width as i32 {
                    let cairo_idx = (y * stride / 4 + x) as usize * 4;
                    let pixels_idx = (y * self.width as i32 + x) as usize * 4;
                    
                    if cairo_idx + 3 < cairo_data.len() && pixels_idx + 3 < frame.len() {
                        // Cairo format is BGRA, convert to RGBA
                        frame[pixels_idx] = cairo_data[cairo_idx + 2];     // R
                        frame[pixels_idx + 1] = cairo_data[cairo_idx + 1]; // G
                        frame[pixels_idx + 2] = cairo_data[cairo_idx];     // B
                        frame[pixels_idx + 3] = cairo_data[cairo_idx + 3]; // A
                    }
                }
            }
        }
    }
}

impl<'a> ApplicationHandler for App<'a> {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        let window = Arc::new(event_loop.create_window(
            Window::default_attributes()
                .with_inner_size(LogicalSize::new(self.width, self.height))
                .with_title("Cairo + HarfBuzz + Pixels")
        ).unwrap());
        
        let window_size = window.inner_size();
        let surface_texture = SurfaceTexture::new(window_size.width, window_size.height, window.clone());
        
        self.pixels = Some(Pixels::new(self.width, self.height, surface_texture).unwrap());
        
        // Create Cairo surface
        let cairo_surface = ImageSurface::create(Format::ARgb32, self.width as i32, self.height as i32).unwrap();
        
        // Set white background
        {
            let cairo_context = Context::new(&cairo_surface).unwrap();
            cairo_context.set_source_rgb(1.0, 1.0, 1.0);
            cairo_context.paint().unwrap();
        }
        
        self.cairo_surface = Some(cairo_surface);
        self.window = Some(window);
        
        // Initial render
        self.update_pixels();
    }

    fn window_event(&mut self, event_loop: &ActiveEventLoop, _id: WindowId, event: WindowEvent) {
        match event {
            WindowEvent::CloseRequested => {
                println!("The close button was pressed; stopping");
                event_loop.exit();
            },
            WindowEvent::KeyboardInput { event, .. } => {
                if event.state == ElementState::Pressed {
                    match &event.logical_key {
                        Key::Character(c) => {
                            self.draw_text(c);
                            self.update_pixels();
                            if let Some(window) = &self.window {
                                window.request_redraw();
                            }
                        },
                        Key::Named(NamedKey::Space) => {
                            self.draw_text(" ");
                            self.update_pixels();
                            if let Some(window) = &self.window {
                                window.request_redraw();
                            }
                        },
                        Key::Named(NamedKey::Enter) => {
                            self.cursor_x = 10.0;
                            self.cursor_y += 30.0;
                            if let Some(window) = &self.window {
                                window.request_redraw();
                            }
                        },
                        _ => {},
                    }
                }
            },
            WindowEvent::RedrawRequested => {
                if let Some(pixels) = &mut self.pixels {
                    pixels.render().unwrap();
                }
            },
            _ => (),
        }
    }
}

fn main() {
    let event_loop = EventLoop::new().unwrap();
    event_loop.set_control_flow(ControlFlow::Wait);
    
    let mut app = App::new();
    let _ = event_loop.run_app(&mut app);
}