//! One window, one current GL context, two painters in framebuffer order.
use crate::display_list::{self, Resources};
use eframe::egui::Rect;
use egui_glow::{
    EguiGlow,
    glow::{self, HasContext},
};
use glutin::{
    config::{ConfigTemplateBuilder, GlConfig},
    context::{ContextApi, ContextAttributesBuilder, GlProfile, PossiblyCurrentContext, Version},
    display::GetGlDisplay,
    prelude::*,
    surface::{Surface, SurfaceAttributesBuilder, SwapInterval, WindowSurface},
};
use std::{
    ffi::CString,
    num::NonZeroU32,
    sync::{Arc, mpsc},
    time::Duration,
};
use typst_layout::PagedDocument;
use webrender::{
    RenderApi, Renderer, Transaction, WebRenderOptions,
    api::{self, units::*},
};
use winit::{
    dpi::LogicalSize,
    event_loop::{ActiveEventLoop, EventLoopProxy},
    raw_window_handle::HasWindowHandle,
    window::Window,
};

pub enum Wake {
    Repaint(Duration),
}

#[derive(Clone)]
struct Notifier {
    ready: mpsc::Sender<()>,
    proxy: EventLoopProxy<Wake>,
}
impl api::RenderNotifier for Notifier {
    fn clone(&self) -> Box<dyn api::RenderNotifier> {
        Box::new(Clone::clone(self))
    }
    fn wake_up(&self, composite: bool) {
        if composite {
            let _ = self.proxy.send_event(Wake::Repaint(Duration::ZERO));
        }
    }
    fn new_frame_ready(
        &self,
        _: api::DocumentId,
        _: api::FramePublishId,
        _: &api::FrameReadyParams,
    ) {
        let _ = self.ready.send(());
    }
}

pub struct Graphics {
    pub window: Window,
    pub egui: EguiGlow,
    pub render: WebRenderer,
    gl: Arc<glow::Context>,
    surface: Surface<WindowSurface>,
    context: PossiblyCurrentContext,
}

impl Graphics {
    pub fn new(event_loop: &ActiveEventLoop, proxy: EventLoopProxy<Wake>) -> Self {
        let attributes = Window::default_attributes()
            .with_title("zine")
            .with_decorations(false)
            .with_inner_size(LogicalSize::new(1600.0, 984.0))
            .with_min_inner_size(LogicalSize::new(400.0, 300.0))
            .with_visible(false);
        let template = ConfigTemplateBuilder::new()
            .with_alpha_size(8)
            .with_depth_size(0)
            .with_stencil_size(0);
        let (window, config) = glutin_winit::DisplayBuilder::new()
            .with_window_attributes(Some(attributes.clone()))
            .build(event_loop, template, |mut configs| {
                configs
                    .find(|c| c.num_samples() == 0)
                    .expect("a GL configuration without MSAA")
            })
            .expect("create OpenGL window");
        let window = window.unwrap_or_else(|| {
            glutin_winit::finalize_window(event_loop, attributes, &config).expect("create window")
        });
        let display = config.display();
        let handle = window.window_handle().expect("window handle").as_raw();
        let attributes = ContextAttributesBuilder::new()
            .with_profile(GlProfile::Core)
            .with_context_api(ContextApi::OpenGl(Some(Version::new(3, 3))))
            .build(Some(handle));
        let size = window.inner_size();
        let surface_attributes = SurfaceAttributesBuilder::<WindowSurface>::new()
            .with_srgb(Some(false))
            .build(handle, nonzero(size.width), nonzero(size.height));
        // SAFETY: The native window outlives its surface, and both GL loaders use
        // this same current context on the event-loop thread.
        let (surface, context, gl, wr_gl) = unsafe {
            let context = display
                .create_context(&config, &attributes)
                .expect("create GL 3.3 context");
            let surface = display
                .create_window_surface(&config, &surface_attributes)
                .expect("create GL surface");
            let context = context.make_current(&surface).expect("make GL current");
            let load = |name: &str| display.get_proc_address(&CString::new(name).unwrap());
            let gl = Arc::new(glow::Context::from_loader_function(load));
            let wr_gl = gleam::gl::GlFns::load_with(load);
            gl.disable(glow::MULTISAMPLE);
            gl.disable(glow::DITHER);
            gl.disable(glow::FRAMEBUFFER_SRGB);
            (surface, context, gl, wr_gl)
        };
        let _ = surface.set_swap_interval(&context, SwapInterval::Wait(NonZeroU32::MIN));
        let egui = EguiGlow::new(
            event_loop,
            gl.clone(),
            None,
            Some(window.scale_factor() as f32),
            false,
        );
        let repaint_proxy = proxy.clone();
        egui.egui_ctx.set_request_repaint_callback(move |info| {
            let _ = repaint_proxy.send_event(Wake::Repaint(info.delay));
        });
        let (sender, ready) = mpsc::channel();
        let (renderer, sender) = webrender::create_webrender_instance(
            wr_gl,
            Box::new(Notifier {
                ready: sender,
                proxy,
            }),
            WebRenderOptions {
                enable_aa: false,
                enable_subpixel_aa: false,
                enable_dithering: false,
                clear_color: api::ColorF::WHITE,
                ..Default::default()
            },
            None,
        )
        .expect("initialize WebRender");
        let api = sender.create_api();
        let document = api.add_document(DeviceIntSize::new(size.width as i32, size.height as i32));
        let render = WebRenderer {
            renderer: Some(renderer),
            api,
            document,
            ready,
            resources: Resources::default(),
            epoch: 0,
            view: None,
            content_size: LayoutSize::zero(),
        };
        Self {
            window,
            egui,
            render,
            gl,
            surface,
            context,
        }
    }

    pub fn resize(&self) {
        let size = self.window.inner_size();
        if size.width > 0 && size.height > 0 {
            self.surface
                .resize(&self.context, nonzero(size.width), nonzero(size.height));
        }
    }

    pub fn paint(&mut self) {
        let size = self.window.inner_size();
        if size.width == 0 || size.height == 0 {
            return;
        }
        // WebRender resets its GL cache at begin_frame. EguiGlow establishes its
        // own state afterwards. Neither painter is rendered to an intermediate texture.
        unsafe {
            self.gl.bind_framebuffer(glow::FRAMEBUFFER, None);
            self.gl.disable(glow::SCISSOR_TEST);
            self.gl.disable(glow::MULTISAMPLE);
            self.gl.disable(glow::DITHER);
            self.gl.disable(glow::FRAMEBUFFER_SRGB);
        }
        let renderer = self.render.renderer.as_mut().unwrap();
        renderer.update();
        renderer
            .render(DeviceIntSize::new(size.width as i32, size.height as i32), 0)
            .expect("render document");
        unsafe {
            self.gl.bind_framebuffer(glow::FRAMEBUFFER, None);
            self.gl.bind_sampler(0, None);
            self.gl.bind_buffer(glow::PIXEL_UNPACK_BUFFER, None);
            self.gl.pixel_store_i32(glow::UNPACK_ROW_LENGTH, 0);
            self.gl.pixel_store_i32(glow::UNPACK_SKIP_PIXELS, 0);
            self.gl.pixel_store_i32(glow::UNPACK_SKIP_ROWS, 0);
        }
        self.egui.paint(&self.window);
        unsafe {
            self.gl.flush();
        }
    }

    pub fn present(&self) {
        self.surface
            .swap_buffers(&self.context)
            .expect("swap window buffers");
        self.window.set_visible(true);
    }
}

impl Drop for Graphics {
    fn drop(&mut self) {
        self.egui.destroy();
        self.render.api.shut_down(true);
        if let Some(renderer) = self.render.renderer.take() {
            renderer.deinit();
        }
    }
}

fn nonzero(n: u32) -> NonZeroU32 {
    NonZeroU32::new(n).unwrap_or(NonZeroU32::MIN)
}

#[derive(Clone, Copy, PartialEq)]
pub struct View {
    pub rect: Rect,
    pub scroll: f32,
    pub pixels_per_point: f32,
    pub size: [u32; 2],
}

pub struct WebRenderer {
    renderer: Option<Renderer>,
    api: RenderApi,
    document: api::DocumentId,
    ready: mpsc::Receiver<()>,
    resources: Resources,
    epoch: u32,
    view: Option<View>,
    content_size: LayoutSize,
}

impl WebRenderer {
    /// A new document is supplied on every edit/tab switch; scrolling only
    /// rebuilds the tiny enclosing viewport list, reusing the document pipeline.
    pub fn submit(&mut self, document: Option<&PagedDocument>, view: View) {
        if view.size.contains(&0) || (document.is_none() && self.view == Some(view)) {
            return;
        }
        let root = api::PipelineId(0, 0);
        let content = api::PipelineId(0, 1);
        self.epoch += 1;
        let mut txn = Transaction::new();
        if let Some(document) = document {
            self.resources.update(&mut txn, document);
            self.content_size = LayoutSize::new(
                document
                    .pages()
                    .iter()
                    .map(|p| display_list::px(p.frame.width()))
                    .fold(1.0, f32::max),
                document
                    .pages()
                    .iter()
                    .map(|p| display_list::px(p.frame.height()) + display_list::PAGE_GAP)
                    .sum::<f32>()
                    .max(1.0),
            );
            let mut builder = api::DisplayListBuilder::new(content);
            builder.begin();
            builder.push_simple_stacking_context(
                api::SpatialId::root_scroll_node(content),
                Default::default(),
            );
            display_list::to_display_list(&mut builder, document.clone());
            builder.pop_stacking_context();
            txn.set_display_list(api::Epoch(self.epoch), builder.end());
        }
        let mut builder = api::DisplayListBuilder::new(root);
        builder.begin();
        let root_space = api::SpaceAndClipInfo::root_scroll(root);
        builder.push_simple_stacking_context(root_space.spatial_id, Default::default());
        let scale = view.pixels_per_point;
        let clip = LayoutRect::new(
            LayoutPoint::new(view.rect.left() * scale, view.rect.top() * scale),
            LayoutPoint::new(view.rect.right() * scale, view.rect.bottom() * scale),
        );
        let clip = builder.define_clip_rect(root_space.spatial_id, clip);
        let clip_chain_id = builder.define_clip_chain(None, [clip]);
        let transform =
            LayoutTransform::scale(scale, scale, 1.0).then(&LayoutTransform::translation(
                view.rect.left() * scale,
                (view.rect.top() - view.scroll) * scale,
                0.0,
            ));
        let spatial_id = builder.push_reference_frame(
            LayoutPoint::zero(),
            root_space.spatial_id,
            api::TransformStyle::Flat,
            transform.into(),
            api::ReferenceFrameKind::Transform {
                is_2d_scale_translation: true,
                should_snap: true,
                paired_with_perspective: false,
            },
        );
        let bounds = LayoutRect::from_origin_and_size(LayoutPoint::zero(), self.content_size);
        builder.push_iframe(
            bounds,
            bounds,
            &api::SpaceAndClipInfo {
                spatial_id,
                clip_chain_id,
            },
            content,
            true,
        );
        builder.pop_reference_frame();
        builder.pop_stacking_context();
        txn.set_display_list(api::Epoch(self.epoch), builder.end());
        txn.set_root_pipeline(root);
        txn.set_document_view(DeviceIntRect::from_origin_and_size(
            DeviceIntPoint::zero(),
            DeviceIntSize::new(view.size[0] as i32, view.size[1] as i32),
        ));
        txn.generate_frame(
            u64::from(self.epoch),
            true,
            false,
            api::RenderReasons::SCENE,
        );
        self.api.send_transaction(self.document, txn);
        self.api.flush_scene_builder();
        self.ready.recv().expect("WebRender frame ready");
        self.view = Some(view);
    }
}
