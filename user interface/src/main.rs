use winit::application::ApplicationHandler;
use winit::event::{WindowEvent, ElementState};
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::window::{Window, WindowId};
use winit::keyboard::{Key, NamedKey};
use winit::dpi::LogicalSize;

use harfbuzz_rs::{Face, Font, UnicodeBuffer, shape, Owned};
use webrender::{RenderApi, Renderer, Transaction};
use webrender_api::{
    units::*, ColorF, DisplayListBuilder, 
    DocumentId, FontInstanceKey, FontKey,
    RenderNotifier, SpaceAndClipInfo, FontInstanceOptions,
    FontInstancePlatformOptions, PipelineId, IdNamespace,
    FramePublishId, RenderReasons, CommonItemProperties,
    PrimitiveFlags, Epoch, GlyphInstance, FrameReadyParams,
};

use glutin::{
    config::{Config, ConfigTemplateBuilder},
    context::{ContextAttributesBuilder, PossiblyCurrentContext},
    display::GetGlDisplay,
    prelude::*,
    surface::{Surface, SurfaceAttributesBuilder, WindowSurface},
};

use glutin_winit::{DisplayBuilder, GlWindow};

use std::sync::Arc;
use std::ffi::CString;

struct Notifier;
impl RenderNotifier for Notifier {
    fn clone(&self) -> Box<dyn RenderNotifier> {
        Box::new(Notifier)
    }
    
    fn wake_up(&self, _composite_needed: bool) {}
    
    fn new_frame_ready(&self, _: DocumentId, _: FramePublishId, _: &FrameReadyParams) {}
}

// Store shaped glyphs with their positions
struct ShapedGlyph {
    glyph_id: u32,
    x: f32,
    y: f32,
}

struct App {
    window: Option<Arc<Window>>,
    gl_config: Option<Config>,
    gl_surface: Option<Surface<WindowSurface>>,
    gl_context: Option<PossiblyCurrentContext>,
    renderer: Option<Renderer>,
    render_api: Option<RenderApi>,
    document_id: DocumentId,
    pipeline_id: PipelineId,
    epoch: Epoch,
    font_key: Option<FontKey>,
    font_instance_key: Option<FontInstanceKey>,
    hb_font: Owned<Font<'static>>,
    width: u32,
    height: u32,
    cursor_x: f32,
    cursor_y: f32,
    font_size: f32,
    text_buffer: String,
    // Store shaped glyphs for rendering
    shaped_glyphs: Vec<ShapedGlyph>,
}

impl App {
    fn new() -> Self {
        let width = 800;
        let height = 600;
        
        // Load a font for HarfBuzz
        let font_data = include_bytes!("/System/Library/Fonts/Helvetica.ttc");
        let face = Face::from_bytes(font_data, 0);
        let hb_font: Owned<Font> = Font::new(face);
        
        App {
            window: None,
            gl_config: None,
            gl_surface: None,
            gl_context: None,
            renderer: None,
            render_api: None,
            document_id: DocumentId {
                namespace_id: IdNamespace(0),
                id: 0,
            },
            pipeline_id: PipelineId(0, 0),
            epoch: Epoch(0),
            font_key: None,
            font_instance_key: None,
            hb_font,
            width,
            height,
            cursor_x: 10.0,
            cursor_y: 30.0,
            font_size: 24.0,
            text_buffer: String::new(),
            shaped_glyphs: Vec::new(),
        }
    }
    
    fn draw_text(&mut self, text: &str) {
        self.text_buffer.push_str(text);
        
        // Shape the text using HarfBuzz
        let buffer = UnicodeBuffer::new().add_str(text);
        let output = shape(&self.hb_font, buffer, &[]);
        
        let positions = output.get_glyph_positions();
        let infos = output.get_glyph_infos();
        
        // Store shaped glyphs with their positions
        let mut x = self.cursor_x;
        for (i, info) in infos.iter().enumerate() {
            if i < positions.len() {
                self.shaped_glyphs.push(ShapedGlyph {
                    glyph_id: info.codepoint,
                    x,
                    y: self.cursor_y,
                });
                x += positions[i].x_advance as f32 / 64.0;
            }
        }
        
        self.cursor_x = x;
        
        // Wrap to next line if needed
        if self.cursor_x > (self.width as f32 - 20.0) {
            self.cursor_x = 10.0;
            self.cursor_y += 30.0;
        }
        
        // Request redraw
        if let Some(window) = &self.window {
            window.request_redraw();
        }
    }
    
    fn render(&mut self) {
        if let (Some(renderer), Some(render_api)) = (&mut self.renderer, &mut self.render_api) {
            let mut txn = Transaction::new();
            
            let mut builder = DisplayListBuilder::new(self.pipeline_id);
            let content_size = LayoutSize::new(self.width as f32, self.height as f32);
            let root_space_and_clip = SpaceAndClipInfo::root_scroll(self.pipeline_id);
            
            builder.begin();
            
            // Clear background
            let info = CommonItemProperties {
                clip_rect: LayoutRect::from_size(content_size),
                clip_chain_id: root_space_and_clip.clip_chain_id,
                spatial_id: root_space_and_clip.spatial_id,
                flags: PrimitiveFlags::default(),
            };
            
            builder.push_rect(
                &info,
                LayoutRect::from_size(content_size),
                ColorF::new(1.0, 1.0, 1.0, 1.0),
            );
            
            // Render text using shaped glyphs
            if let Some(_font_key) = self.font_key {
                if let Some(font_instance_key) = self.font_instance_key {
                    if !self.shaped_glyphs.is_empty() {
                        let text_info = CommonItemProperties {
                            clip_rect: LayoutRect::from_size(content_size),
                            clip_chain_id: root_space_and_clip.clip_chain_id,
                            spatial_id: root_space_and_clip.spatial_id,
                            flags: PrimitiveFlags::default(),
                        };
                        
                        // Create glyph instances from shaped glyphs
                        let glyph_instances: Vec<GlyphInstance> = self.shaped_glyphs
                            .iter()
                            .map(|glyph| GlyphInstance {
                                index: glyph.glyph_id,
                                point: LayoutPoint::new(glyph.x, glyph.y),
                            })
                            .collect();
                        
                        if !glyph_instances.is_empty() {
                            builder.push_text(
                                &text_info,
                                LayoutRect::from_size(content_size),
                                &glyph_instances,
                                font_instance_key,
                                ColorF::new(0.0, 0.0, 0.0, 1.0),
                                None,
                            );
                        }
                    }
                }
            }
            
            let display_list = builder.end();
            txn.set_display_list(self.epoch, display_list);
            txn.set_root_pipeline(self.pipeline_id);
            txn.generate_frame(0, true, false, RenderReasons::empty());
            render_api.send_transaction(self.document_id, txn);
            
            // Increment epoch for next frame
            self.epoch.0 += 1;
            
            renderer.update();
            let _ = renderer.render(
                DeviceIntSize::new(self.width as i32, self.height as i32),
                0,
            );
            
            if let Some(gl_surface) = &self.gl_surface {
                if let Some(gl_context) = &self.gl_context {
                    gl_surface.swap_buffers(gl_context).unwrap();
                }
            }
        }
    }
}

impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        // Create window with glutin-winit integration
        let window_attributes = Window::default_attributes()
            .with_inner_size(LogicalSize::new(self.width, self.height))
            .with_title("HarfBuzz + WebRender");
            
        let template = ConfigTemplateBuilder::new()
            .with_alpha_size(8);
            
        let display_builder = DisplayBuilder::new().with_window_attributes(Some(window_attributes));
        
        let (window, gl_config) = display_builder
            .build(event_loop, template, |configs| {
                configs.reduce(|acc, config| {
                    if config.num_samples() > acc.num_samples() {
                        config
                    } else {
                        acc
                    }
                })
                .unwrap()
            })
            .unwrap();
            
        let window = window.unwrap();
        let gl_display = gl_config.display();
        
        // Create GL context
        let context_attributes = ContextAttributesBuilder::new().build(None);
        let not_current_context = unsafe {
            gl_display.create_context(&gl_config, &context_attributes).unwrap()
        };
        
        // Create surface
        let surface_attributes_builder = SurfaceAttributesBuilder::<WindowSurface>::new();
        let surface_attributes = window.build_surface_attributes(surface_attributes_builder).unwrap();
        
        let surface = unsafe {
            gl_display.create_window_surface(&gl_config, &surface_attributes).unwrap()
        };
        
        // Make context current
        let gl_context = not_current_context.make_current(&surface).unwrap();
        
        // Initialize gleam GL bindings
        let gl = unsafe {
            gleam::gl::GlFns::load_with(|s| {
                let c_str = CString::new(s).unwrap();
                gl_display.get_proc_address(&c_str) as *const _
            })
        };
        
        // Create WebRender renderer
        let notifier = Box::new(Notifier);
        let device_size = DeviceIntSize::new(self.width as i32, self.height as i32);
        
        let webrender_opts = webrender::WebRenderOptions {
            clear_color: ColorF::new(1.0, 1.0, 1.0, 1.0),
            // Enable subpixel AA for better text rendering
            enable_subpixel_aa: true,
            ..Default::default()
        };
        
        let (renderer, sender) = webrender::create_webrender_instance(
            gl.clone(),
            notifier,
            webrender_opts,
            None,
        ).unwrap();
        
        let mut render_api = sender.create_api();
        let document_id = render_api.add_document(device_size);
        
        // Create pipeline
        let pipeline_id = PipelineId(0, 0);
        
        // Load font into WebRender
        let font_key = render_api.generate_font_key();
        let font_data = include_bytes!("/System/Library/Fonts/Helvetica.ttc").to_vec();
        
        let mut txn = Transaction::new();
        txn.add_raw_font(font_key, font_data, 0);
        render_api.send_transaction(document_id, txn);
        
        // Create font instance with native font rendering
        let font_instance_key = render_api.generate_font_instance_key();
        let mut txn = Transaction::new();
        
        // Configure font instance for proper rendering
        let font_instance_options = FontInstanceOptions {
            render_mode: webrender_api::FontRenderMode::Subpixel,
            flags: webrender_api::FontInstanceFlags::SUBPIXEL_POSITION,
            ..Default::default()
        };
        
        txn.add_font_instance(
            font_instance_key,
            font_key,
            self.font_size,
            Some(font_instance_options),
            Some(FontInstancePlatformOptions::default()),
            vec![],
        );
        render_api.send_transaction(document_id, txn);
        
        
        self.window = Some(Arc::new(window));
        self.gl_config = Some(gl_config);
        self.gl_surface = Some(surface);
        self.gl_context = Some(gl_context);
        self.renderer = Some(renderer);
        self.render_api = Some(render_api);
        self.document_id = document_id;
        self.pipeline_id = pipeline_id;
        self.font_key = Some(font_key);
        self.font_instance_key = Some(font_instance_key);
        
        // Initial render
        self.render();
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
                        },
                        Key::Named(NamedKey::Space) => {
                            self.draw_text(" ");
                        },
                        Key::Named(NamedKey::Enter) => {
                            self.cursor_x = 10.0;
                            self.cursor_y += 30.0;
                            self.text_buffer.push('\n');
                            // Add a shaped glyph for the newline
                            self.shaped_glyphs.push(ShapedGlyph {
                                glyph_id: 0, // Placeholder for newline
                                x: self.cursor_x,
                                y: self.cursor_y,
                            });
                            self.render();
                        },
                        _ => {},
                    }
                }
            },
            WindowEvent::RedrawRequested => {
                self.render();
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