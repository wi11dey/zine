#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * Special value handled in this wrapper layer to signify a redundant clip chain.
 */
#define ROOT_CLIP_CHAIN ~0

enum WrExternalImageType {
  RawData,
  NativeTexture,
  Invalid,
};
typedef uint32_t WrExternalImageType;

/**
 * Used to indicate if an image is opaque, or has an alpha channel.
 */
enum OpacityType {
  Opaque = 0,
  HasAlphaChannel = 1,
};
typedef uint8_t OpacityType;

enum WrAnimationType {
  Transform = 0,
  Opacity = 1,
  BackgroundColor = 2,
};
typedef uint32_t WrAnimationType;

enum WrRotation {
  Degree0,
  Degree90,
  Degree180,
  Degree270,
};
typedef uint8_t WrRotation;

enum WrReferenceFrameKind {
  Transform,
  Perspective,
};
typedef uint8_t WrReferenceFrameKind;

/**
 * Whether a border should be antialiased.
 */
typedef enum AntialiasBorder {
  No = 0,
  Yes,
} AntialiasBorder;

typedef struct Arc_VecU8 Arc_VecU8;

typedef struct DocumentHandle DocumentHandle;

typedef struct Vec_u8 Vec_u8;

typedef struct WrChunkPool WrChunkPool;

typedef struct WrGlyphRasterThread WrGlyphRasterThread;

typedef struct WrProgramCache WrProgramCache;

/**
 * A wrapper around a strong reference to a Shaders object, and around the
 * Device object that was used to create the shaders.
 *
 * We store the device to avoid repeated GL function lookups.
 */
typedef struct WrShaders WrShaders;

typedef struct WrState WrState;

typedef struct WrThreadPool WrThreadPool;

typedef struct WrVecU8 {
  /**
   * `data` must always be valid for passing to Vec::from_raw_parts.
   * In particular, it must be non-null even if capacity is zero.
   */
  uint8_t *data;
  uintptr_t length;
  uintptr_t capacity;
} WrVecU8;

typedef struct ByteSlice {
  const uint8_t *buffer;
  uintptr_t len;
} ByteSlice;

typedef struct WrExternalImage {
  WrExternalImageType image_type;
  uint32_t handle;
  float u0;
  float v0;
  float u1;
  float v1;
  const uint8_t *buff;
  uintptr_t size;
} WrExternalImage;

typedef struct WrWindowId {
  uint64_t mHandle;
} WrWindowId;

typedef PipelineId WrPipelineId;

typedef DocumentId WrDocumentId;

typedef Epoch WrEpoch;

typedef struct WrPipelineEpoch {
  WrPipelineId pipeline_id;
  WrDocumentId document_id;
  WrEpoch epoch;
} WrPipelineEpoch;

typedef struct WrRemovedPipeline {
  WrPipelineId pipeline_id;
  WrDocumentId document_id;
} WrRemovedPipeline;

typedef struct WrPipelineInfo {
  /**
   * This contains an entry for each pipeline that was rendered, along with
   * the epoch at which it was rendered. Rendered pipelines include the root
   * pipeline and any other pipelines that were reachable via IFrame display
   * items from the root pipeline.
   */
  ThinVec<WrPipelineEpoch> epochs;
  /**
   * This contains an entry for each pipeline that was removed during the
   * last transaction. These pipelines would have been explicitly removed by
   * calling remove_pipeline on the transaction object; the pipeline showing
   * up in this array means that the data structures have been torn down on
   * the webrender side, and so any remaining data structures on the caller
   * side can now be torn down also.
   */
  ThinVec<WrRemovedPipeline> removed_pipelines;
} WrPipelineInfo;

typedef struct WrExternalImageHandler {
  void *external_image_obj;
} WrExternalImageHandler;

typedef struct WrAnimationPropertyValue_f32 {
  uint64_t id;
  float value;
} WrAnimationPropertyValue_f32;

typedef struct WrAnimationPropertyValue_f32 WrOpacityProperty;

typedef struct WrAnimationPropertyValue_LayoutTransform {
  uint64_t id;
  LayoutTransform value;
} WrAnimationPropertyValue_LayoutTransform;

typedef struct WrAnimationPropertyValue_LayoutTransform WrTransformProperty;

typedef struct WrAnimationPropertyValue_ColorF {
  uint64_t id;
  ColorF value;
} WrAnimationPropertyValue_ColorF;

typedef struct WrAnimationPropertyValue_ColorF WrColorProperty;

typedef ImageKey WrImageKey;

typedef struct WrImageDescriptor {
  ImageFormat format;
  int32_t width;
  int32_t height;
  int32_t stride;
  OpacityType opacity;
  bool prefer_compositor_surface;
} WrImageDescriptor;

typedef FontKey WrFontKey;

typedef FontInstanceKey WrFontInstanceKey;

typedef IdNamespace WrIdNamespace;

typedef struct WrSpatialId {
  uintptr_t id;
} WrSpatialId;

typedef enum WrStackingContextClip_Tag {
  None,
  ClipChain,
} WrStackingContextClip_Tag;

typedef struct WrStackingContextClip {
  WrStackingContextClip_Tag tag;
  union {
    struct {
      uint64_t clip_chain;
    };
  };
} WrStackingContextClip;

typedef struct WrAnimationProperty {
  WrAnimationType effect_type;
  uint64_t id;
  SpatialTreeItemKey key;
} WrAnimationProperty;

typedef struct WrComputedTransformData {
  LayoutSize scale_from;
  bool vertical_flip;
  WrRotation rotation;
  SpatialTreeItemKey key;
} WrComputedTransformData;

/**
 * IMPORTANT: If you add fields to this struct, you need to also add initializers
 * for those fields in WebRenderAPI.h.
 */
typedef struct WrStackingContextParams {
  struct WrStackingContextClip clip;
  const struct WrAnimationProperty *animation;
  const float *opacity;
  const struct WrComputedTransformData *computed_transform;
  const SnapshotInfo *snapshot;
  TransformStyle transform_style;
  WrReferenceFrameKind reference_frame_kind;
  bool is_2d_scale_translation;
  bool should_snap;
  bool paired_with_perspective;
  const uint64_t *scrolling_relative_to;
  PrimitiveFlags prim_flags;
  MixBlendMode mix_blend_mode;
  StackingContextFlags flags;
} WrStackingContextParams;

typedef struct WrTransformInfo {
  LayoutTransform transform;
  SpatialTreeItemKey key;
} WrTransformInfo;

typedef struct WrFilterData {
  ComponentTransferFuncType funcR_type;
  float *R_values;
  uintptr_t R_values_count;
  ComponentTransferFuncType funcG_type;
  float *G_values;
  uintptr_t G_values_count;
  ComponentTransferFuncType funcB_type;
  float *B_values;
  uintptr_t B_values_count;
  ComponentTransferFuncType funcA_type;
  float *A_values;
  uintptr_t A_values_count;
} WrFilterData;

typedef struct WrClipId {
  uintptr_t id;
} WrClipId;

typedef struct WrSpaceAndClipChain {
  struct WrSpatialId space;
  uint64_t clip_chain;
} WrSpaceAndClipChain;

typedef ColorDepth WrColorDepth;

typedef YuvColorSpace WrYuvColorSpace;

typedef ColorRange WrColorRange;

typedef struct WrBorderImage {
  LayoutSideOffsets widths;
  WrImageKey image;
  ImageRendering image_rendering;
  int32_t width;
  int32_t height;
  bool fill;
  DeviceIntSideOffsets slice;
  RepeatMode repeat_horizontal;
  RepeatMode repeat_vertical;
} WrBorderImage;

typedef struct HitResult {
  WrPipelineId pipeline_id;
  uint64_t scroll_id;
  uint64_t animation_id;
  uint16_t hit_info;
} HitResult;

typedef struct Vec_u8 VecU8;

typedef struct Arc_VecU8 ArcVecU8;

typedef struct MutByteSlice {
  uint8_t *buffer;
  uintptr_t len;
} MutByteSlice;

extern int __android_log_write(int prio, const char *tag, const char *text);

void wr_vec_u8_push_bytes(struct WrVecU8 *v, struct ByteSlice bytes);

void wr_vec_u8_reserve(struct WrVecU8 *v, uintptr_t len);

void wr_vec_u8_free(struct WrVecU8 v);

extern struct WrExternalImage wr_renderer_lock_external_image(void *renderer,
                                                              ExternalImageId external_image_id,
                                                              uint8_t channel_index,
                                                              bool is_composited);

extern void wr_renderer_unlock_external_image(void *renderer,
                                              ExternalImageId external_image_id,
                                              uint8_t channel_index);

extern bool is_in_compositor_thread(void);

extern bool is_in_render_thread(void);

extern bool is_in_main_thread(void);

extern bool is_glcontext_gles(void *glcontext_ptr);

extern bool is_glcontext_angle(void *glcontext_ptr);

extern const char *gfx_wr_resource_path_override(void);

extern bool gfx_wr_use_optimized_shaders(void);

extern void gfx_critical_error(const char *msg);

extern void gfx_critical_note(const char *msg);

extern void gfx_wr_set_crash_annotation(CrashAnnotation annotation, const char *value);

extern void gfx_wr_clear_crash_annotation(CrashAnnotation annotation);

extern void wr_notifier_wake_up(struct WrWindowId window_id, bool composite_needed);

extern void wr_notifier_new_frame_ready(struct WrWindowId window_id,
                                        FramePublishId publish_id,
                                        const FrameReadyParams *params);

extern void wr_notifier_external_event(struct WrWindowId window_id, uintptr_t raw_event);

extern void wr_schedule_render(struct WrWindowId window_id, RenderReasons reasons);

extern void wr_schedule_frame_after_scene_build(struct WrWindowId window_id,
                                                struct WrPipelineInfo *pipeline_info);

extern void wr_transaction_notification_notified(uintptr_t handler, Checkpoint when);

void wr_renderer_set_clear_color(Renderer *renderer, ColorF color);

void wr_renderer_set_external_image_handler(Renderer *renderer,
                                            struct WrExternalImageHandler *external_image_handler);

void wr_renderer_update(Renderer *renderer);

void wr_renderer_set_target_frame_publish_id(Renderer *renderer, FramePublishId publish_id);

bool wr_renderer_render(Renderer *renderer,
                        int32_t width,
                        int32_t height,
                        uintptr_t buffer_age,
                        RendererStats *out_stats,
                        ThinVec<DeviceIntRect> *out_dirty_rects,
                        bool *out_did_rasterize);

void wr_renderer_force_redraw(Renderer *renderer);

bool wr_renderer_record_frame(Renderer *renderer,
                              ImageFormat image_format,
                              RecordedFrameHandle *out_handle,
                              int32_t *out_width,
                              int32_t *out_height);

bool wr_renderer_map_recorded_frame(Renderer *renderer,
                                    RecordedFrameHandle handle,
                                    uint8_t *dst_buffer,
                                    uintptr_t dst_buffer_len,
                                    uintptr_t dst_stride);

void wr_renderer_release_composition_recorder_structures(Renderer *renderer);

AsyncScreenshotHandle wr_renderer_get_screenshot_async(Renderer *renderer,
                                                       int32_t window_x,
                                                       int32_t window_y,
                                                       int32_t window_width,
                                                       int32_t window_height,
                                                       int32_t buffer_width,
                                                       int32_t buffer_height,
                                                       ImageFormat image_format,
                                                       int32_t *screenshot_width,
                                                       int32_t *screenshot_height);

bool wr_renderer_map_and_recycle_screenshot(Renderer *renderer,
                                            AsyncScreenshotHandle handle,
                                            uint8_t *dst_buffer,
                                            uintptr_t dst_buffer_len,
                                            uintptr_t dst_stride);

void wr_renderer_release_profiler_structures(Renderer *renderer);

void wr_renderer_readback(Renderer *renderer,
                          int32_t width,
                          int32_t height,
                          ImageFormat format,
                          uint8_t *dst_buffer,
                          uintptr_t buffer_size);

void wr_renderer_set_profiler_ui(Renderer *renderer, const uint8_t *ui_str, uintptr_t ui_str_len);

void wr_renderer_delete(Renderer *renderer);

void wr_renderer_accumulate_memory_report(Renderer *renderer, MemoryReport *report, void *swgl);

void wr_renderer_flush_pipeline_info(Renderer *renderer, struct WrPipelineInfo *out);

extern bool gecko_profiler_thread_is_being_profiled(void);

extern void apz_register_updater(struct WrWindowId window_id);

extern void apz_pre_scene_swap(struct WrWindowId window_id);

extern void apz_post_scene_swap(struct WrWindowId window_id,
                                const struct WrPipelineInfo *pipeline_info);

extern void apz_run_updater(struct WrWindowId window_id);

extern void apz_deregister_updater(struct WrWindowId window_id);

extern void apz_register_sampler(struct WrWindowId window_id);

extern void apz_sample_transforms(struct WrWindowId window_id,
                                  const uint64_t *generated_frame_id,
                                  Transaction *transaction);

extern void apz_deregister_sampler(struct WrWindowId window_id);

extern void omta_register_sampler(struct WrWindowId window_id);

extern void omta_sample(struct WrWindowId window_id, Transaction *transaction);

extern void omta_deregister_sampler(struct WrWindowId window_id);

extern void wr_register_thread_local_arena(void);

struct WrThreadPool *wr_thread_pool_new(bool low_priority);

void wr_thread_pool_delete(struct WrThreadPool *thread_pool);

struct WrChunkPool *wr_chunk_pool_new(void);

void wr_chunk_pool_delete(struct WrChunkPool *pool);

void wr_chunk_pool_purge(const struct WrChunkPool *pool);

struct WrProgramCache *wr_program_cache_new(const nsAString *prof_path,
                                            struct WrThreadPool *thread_pool);

void wr_program_cache_delete(struct WrProgramCache *program_cache);

void wr_try_load_startup_shaders_from_disk(struct WrProgramCache *program_cache);

bool remove_program_binary_disk_cache(const nsAString *prof_path);

extern void wr_compositor_create_surface(void *compositor,
                                         NativeSurfaceId id,
                                         DeviceIntPoint virtual_offset,
                                         DeviceIntSize tile_size,
                                         bool is_opaque);

extern void wr_compositor_create_swapchain_surface(void *compositor,
                                                   NativeSurfaceId id,
                                                   DeviceIntSize size,
                                                   bool is_opaque,
                                                   bool needs_sync_dcomp_commit);

extern void wr_compositor_resize_swapchain(void *compositor,
                                           NativeSurfaceId id,
                                           DeviceIntSize size);

extern void wr_compositor_create_external_surface(void *compositor,
                                                  NativeSurfaceId id,
                                                  bool is_opaque);

extern void wr_compositor_create_backdrop_surface(void *compositor,
                                                  NativeSurfaceId id,
                                                  ColorF color);

extern void wr_compositor_destroy_surface(void *compositor, NativeSurfaceId id);

extern void wr_compositor_create_tile(void *compositor, NativeSurfaceId id, int32_t x, int32_t y);

extern void wr_compositor_destroy_tile(void *compositor, NativeSurfaceId id, int32_t x, int32_t y);

extern void wr_compositor_attach_external_image(void *compositor,
                                                NativeSurfaceId id,
                                                ExternalImageId external_image);

extern void wr_compositor_bind(void *compositor,
                               NativeTileId id,
                               DeviceIntPoint *offset,
                               uint32_t *fbo_id,
                               DeviceIntRect dirty_rect,
                               DeviceIntRect valid_rect);

extern void wr_compositor_unbind(void *compositor);

extern void wr_compositor_begin_frame(void *compositor);

extern void wr_compositor_add_surface(void *compositor,
                                      NativeSurfaceId id,
                                      const CompositorSurfaceTransform *transform,
                                      DeviceIntRect clip_rect,
                                      ImageRendering image_rendering,
                                      DeviceIntRect rounded_clip_rect,
                                      ClipRadius rounded_clip_radii);

extern void wr_compositor_start_compositing(void *compositor,
                                            ColorF clear_color,
                                            const DeviceIntRect *dirty_rects,
                                            uintptr_t num_dirty_rects,
                                            const DeviceIntRect *opaque_rects,
                                            uintptr_t num_opaque_rects);

extern void wr_compositor_end_frame(void *compositor);

extern void wr_compositor_enable_native_compositor(void *compositor, bool enable);

extern void wr_compositor_deinit(void *compositor);

extern void wr_compositor_get_capabilities(void *compositor, CompositorCapabilities *caps);

extern void wr_compositor_get_window_visibility(void *compositor, WindowVisibility *caps);

extern void wr_compositor_get_window_properties(void *compositor, WindowProperties *props);

extern void wr_compositor_bind_swapchain(void *compositor,
                                         NativeSurfaceId id,
                                         const DeviceIntRect *dirty_rects,
                                         uintptr_t num_dirty_rects);

extern void wr_compositor_present_swapchain(void *compositor,
                                            NativeSurfaceId id,
                                            const DeviceIntRect *dirty_rects,
                                            uintptr_t num_dirty_rects);

extern void wr_compositor_map_tile(void *compositor,
                                   NativeTileId id,
                                   DeviceIntRect dirty_rect,
                                   DeviceIntRect valid_rect,
                                   void **data,
                                   int32_t *stride);

extern void wr_compositor_unmap_tile(void *compositor);

extern void wr_partial_present_compositor_set_buffer_damage_region(void *compositor,
                                                                   const DeviceIntRect *rects,
                                                                   uintptr_t n_rects);

extern bool wr_swgl_lock_composite_surface(void *ctx,
                                           ExternalImageId external_image_id,
                                           SWGLCompositeSurfaceInfo *composite_info);

extern void wr_swgl_unlock_composite_surface(void *ctx, ExternalImageId external_image_id);

struct WrGlyphRasterThread *wr_glyph_raster_thread_new(void);

void wr_glyph_raster_thread_delete(struct WrGlyphRasterThread *thread);

bool wr_window_new(struct WrWindowId window_id,
                   int32_t window_width,
                   int32_t window_height,
                   bool is_main_window,
                   bool support_low_priority_transactions,
                   bool support_low_priority_threadpool,
                   bool allow_texture_swizzling,
                   bool allow_scissored_cache_clears,
                   void *swgl_context,
                   void *gl_context,
                   bool surface_origin_is_top_left,
                   struct WrProgramCache *program_cache,
                   struct WrShaders *shaders,
                   struct WrThreadPool *thread_pool,
                   struct WrThreadPool *thread_pool_low_priority,
                   const struct WrChunkPool *chunk_pool,
                   const struct WrGlyphRasterThread *glyph_raster_thread,
                   VoidPtrToSizeFn size_of_op,
                   VoidPtrToSizeFn enclosing_size_of_op,
                   uint32_t document_id,
                   void *compositor,
                   bool use_native_compositor,
                   bool use_partial_present,
                   uintptr_t max_partial_present_rects,
                   bool draw_previous_partial_present_regions,
                   struct DocumentHandle **out_handle,
                   Renderer **out_renderer,
                   int32_t *out_max_texture_size,
                   char **out_err,
                   bool enable_gpu_markers,
                   bool panic_on_gl_error,
                   int32_t picture_tile_width,
                   int32_t picture_tile_height,
                   bool reject_software_rasterizer,
                   bool low_quality_pinch_zoom,
                   int32_t max_shared_surface_size,
                   bool enable_subpixel_aa,
                   bool use_layer_compositor);

void wr_api_free_error_msg(char *msg);

void wr_api_delete_document(struct DocumentHandle *dh);

void wr_api_clone(struct DocumentHandle *dh, struct DocumentHandle **out_handle);

void wr_api_delete(struct DocumentHandle *dh);

void wr_api_stop_render_backend(struct DocumentHandle *dh);

void wr_api_shut_down(struct DocumentHandle *dh);

void wr_api_notify_memory_pressure(struct DocumentHandle *dh);

void wr_api_set_debug_flags(struct DocumentHandle *dh, DebugFlags flags);

void wr_api_set_bool(struct DocumentHandle *dh, BoolParameter param_name, bool val);

void wr_api_set_int(struct DocumentHandle *dh, IntParameter param_name, int32_t val);

void wr_api_set_float(struct DocumentHandle *dh, FloatParameter param_name, float val);

void wr_api_accumulate_memory_report(struct DocumentHandle *dh,
                                     MemoryReport *report,
                                     uintptr_t (*size_of_op)(const void *ptr),
                                     uintptr_t (*enclosing_size_of_op)(const void *ptr));

void wr_api_clear_all_caches(struct DocumentHandle *dh);

void wr_api_enable_native_compositor(struct DocumentHandle *dh, bool enable);

void wr_api_set_batching_lookback(struct DocumentHandle *dh, uint32_t count);

Transaction *wr_transaction_new(bool do_async);

void wr_transaction_delete(Transaction *txn);

void wr_transaction_set_low_priority(Transaction *txn, bool low_priority);

bool wr_transaction_is_empty(const Transaction *txn);

bool wr_transaction_resource_updates_is_empty(const Transaction *txn);

bool wr_transaction_is_rendered_frame_invalidated(const Transaction *txn);

void wr_transaction_notify(Transaction *txn, Checkpoint when, uintptr_t event);

void wr_transaction_update_epoch(Transaction *txn, WrPipelineId pipeline_id, WrEpoch epoch);

void wr_transaction_set_root_pipeline(Transaction *txn, WrPipelineId pipeline_id);

void wr_transaction_remove_pipeline(Transaction *txn, WrPipelineId pipeline_id);

void wr_transaction_set_display_list(Transaction *txn,
                                     WrEpoch epoch,
                                     WrPipelineId pipeline_id,
                                     BuiltDisplayListDescriptor dl_descriptor,
                                     struct WrVecU8 *dl_items_data,
                                     struct WrVecU8 *dl_cache_data,
                                     struct WrVecU8 *dl_spatial_tree_data);

void wr_transaction_set_document_view(Transaction *txn, const DeviceIntRect *doc_rect);

void wr_transaction_generate_frame(Transaction *txn,
                                   uint64_t id,
                                   bool present,
                                   bool tracked,
                                   RenderReasons reasons);

void wr_transaction_invalidate_rendered_frame(Transaction *txn, RenderReasons reasons);

void wr_transaction_render_offscreen(Transaction *txn, WrPipelineId pipeline_id);

void wr_transaction_append_dynamic_properties(Transaction *txn,
                                              const WrOpacityProperty *opacity_array,
                                              uintptr_t opacity_count,
                                              const WrTransformProperty *transform_array,
                                              uintptr_t transform_count,
                                              const WrColorProperty *color_array,
                                              uintptr_t color_count);

void wr_transaction_append_transform_properties(Transaction *txn,
                                                const WrTransformProperty *transform_array,
                                                uintptr_t transform_count);

void wr_transaction_scroll_layer(Transaction *txn,
                                 ExternalScrollId scroll_id,
                                 const ThinVec<SampledScrollOffset> *sampled_scroll_offsets);

void wr_transaction_set_is_transform_async_zooming(Transaction *txn,
                                                   uint64_t animation_id,
                                                   bool is_zooming);

void wr_transaction_add_minimap_data(Transaction *txn,
                                     ExternalScrollId scroll_id,
                                     MinimapData minimap_data);

void wr_transaction_set_quality_settings(Transaction *txn, bool force_subpixel_aa_where_possible);

void wr_resource_updates_add_image(Transaction *txn,
                                   WrImageKey image_key,
                                   const struct WrImageDescriptor *descriptor,
                                   struct WrVecU8 *bytes);

void wr_resource_updates_add_blob_image(Transaction *txn,
                                        BlobImageKey image_key,
                                        const struct WrImageDescriptor *descriptor,
                                        uint16_t tile_size,
                                        struct WrVecU8 *bytes,
                                        DeviceIntRect visible_rect);

void wr_resource_updates_add_external_image(Transaction *txn,
                                            WrImageKey image_key,
                                            const struct WrImageDescriptor *descriptor,
                                            ExternalImageId external_image_id,
                                            const ExternalImageType *image_type,
                                            uint8_t channel_index,
                                            bool normalized_uvs);

void wr_resource_updates_update_image(Transaction *txn,
                                      WrImageKey key,
                                      const struct WrImageDescriptor *descriptor,
                                      struct WrVecU8 *bytes);

void wr_resource_updates_set_blob_image_visible_area(Transaction *txn,
                                                     BlobImageKey key,
                                                     const DeviceIntRect *area);

void wr_resource_updates_update_external_image(Transaction *txn,
                                               WrImageKey key,
                                               const struct WrImageDescriptor *descriptor,
                                               ExternalImageId external_image_id,
                                               const ExternalImageType *image_type,
                                               uint8_t channel_index,
                                               bool normalized_uvs);

void wr_resource_updates_update_external_image_with_dirty_rect(Transaction *txn,
                                                               WrImageKey key,
                                                               const struct WrImageDescriptor *descriptor,
                                                               ExternalImageId external_image_id,
                                                               const ExternalImageType *image_type,
                                                               uint8_t channel_index,
                                                               bool normalized_uvs,
                                                               DeviceIntRect dirty_rect);

void wr_resource_updates_update_blob_image(Transaction *txn,
                                           BlobImageKey image_key,
                                           const struct WrImageDescriptor *descriptor,
                                           struct WrVecU8 *bytes,
                                           DeviceIntRect visible_rect,
                                           LayoutIntRect dirty_rect);

void wr_resource_updates_delete_image(Transaction *txn, WrImageKey key);

void wr_resource_updates_delete_blob_image(Transaction *txn, BlobImageKey key);

void wr_resource_updates_add_snapshot_image(Transaction *txn, SnapshotImageKey image_key);

void wr_resource_updates_delete_snapshot_image(Transaction *txn, SnapshotImageKey key);

void wr_api_send_transaction(struct DocumentHandle *dh, Transaction *transaction, bool is_async);

void wr_transaction_clear_display_list(Transaction *txn, WrEpoch epoch, WrPipelineId pipeline_id);

void wr_api_send_external_event(struct DocumentHandle *dh, uintptr_t evt);

void wr_resource_updates_add_raw_font(Transaction *txn,
                                      WrFontKey key,
                                      struct WrVecU8 *bytes,
                                      uint32_t index);

void wr_api_capture(struct DocumentHandle *dh,
                    const char *path,
                    const char *moz_revision,
                    uint32_t bits_raw);

void wr_api_start_capture_sequence(struct DocumentHandle *dh,
                                   const char *path,
                                   const char *moz_revision,
                                   uint32_t bits_raw);

void wr_api_stop_capture_sequence(struct DocumentHandle *dh);

void wr_resource_updates_add_font_descriptor(Transaction *txn,
                                             WrFontKey key,
                                             struct WrVecU8 *bytes,
                                             uint32_t index);

void wr_resource_updates_delete_font(Transaction *txn, WrFontKey key);

void wr_resource_updates_add_font_instance(Transaction *txn,
                                           WrFontInstanceKey key,
                                           WrFontKey font_key,
                                           float glyph_size,
                                           const FontInstanceOptions *options,
                                           const FontInstancePlatformOptions *platform_options,
                                           struct WrVecU8 *variations);

void wr_resource_updates_delete_font_instance(Transaction *txn, WrFontInstanceKey key);

void wr_resource_updates_clear(Transaction *txn);

WrIdNamespace wr_api_get_namespace(struct DocumentHandle *dh);

void wr_api_wake_scene_builder(struct DocumentHandle *dh);

void wr_api_flush_scene_builder(struct DocumentHandle *dh);

struct WrState *wr_state_new(WrPipelineId pipeline_id);

void wr_state_delete(struct WrState *state);

void wr_dp_save(struct WrState *state);

void wr_dp_restore(struct WrState *state);

void wr_dp_clear_save(struct WrState *state);

struct WrSpatialId wr_dp_push_stacking_context(struct WrState *state,
                                               LayoutRect bounds,
                                               struct WrSpatialId spatial_id,
                                               const struct WrStackingContextParams *params,
                                               const struct WrTransformInfo *transform,
                                               const FilterOp *filters,
                                               uintptr_t filter_count,
                                               const struct WrFilterData *filter_datas,
                                               uintptr_t filter_datas_count,
                                               RasterSpace glyph_raster_space);

void wr_dp_push_debug(struct WrState *state, uint32_t val);

void wr_dp_pop_stacking_context(struct WrState *state, bool is_reference_frame);

uint64_t wr_dp_define_clipchain(struct WrState *state,
                                const uint64_t *parent_clipchain_id,
                                const struct WrClipId *clips,
                                uintptr_t clips_count);

struct WrClipId wr_dp_define_image_mask_clip_with_parent_clip_chain(struct WrState *state,
                                                                    struct WrSpatialId space,
                                                                    ImageMask mask,
                                                                    const LayoutPoint *points,
                                                                    uintptr_t point_count,
                                                                    FillRule fill_rule);

struct WrClipId wr_dp_define_rounded_rect_clip(struct WrState *state,
                                               struct WrSpatialId space,
                                               ComplexClipRegion complex);

struct WrClipId wr_dp_define_rect_clip(struct WrState *state,
                                       struct WrSpatialId space,
                                       LayoutRect clip_rect);

struct WrSpatialId wr_dp_define_sticky_frame(struct WrState *state,
                                             struct WrSpatialId parent_spatial_id,
                                             LayoutRect content_rect,
                                             const float *top_margin,
                                             const float *right_margin,
                                             const float *bottom_margin,
                                             const float *left_margin,
                                             StickyOffsetBounds vertical_bounds,
                                             StickyOffsetBounds horizontal_bounds,
                                             LayoutVector2D applied_offset,
                                             SpatialTreeItemKey key,
                                             const struct WrAnimationProperty *animation);

struct WrSpatialId wr_dp_define_scroll_layer(struct WrState *state,
                                             uint64_t external_scroll_id,
                                             const struct WrSpatialId *parent,
                                             LayoutRect content_rect,
                                             LayoutRect clip_rect,
                                             LayoutVector2D scroll_offset,
                                             APZScrollGeneration scroll_offset_generation,
                                             HasScrollLinkedEffect has_scroll_linked_effect,
                                             SpatialTreeItemKey key);

void wr_dp_push_iframe(struct WrState *state,
                       LayoutRect rect,
                       LayoutRect clip,
                       bool _is_backface_visible,
                       const struct WrSpaceAndClipChain *parent,
                       WrPipelineId pipeline_id,
                       bool ignore_missing_pipeline);

void wr_dp_push_rect(struct WrState *state,
                     LayoutRect rect,
                     LayoutRect clip,
                     bool is_backface_visible,
                     bool force_antialiasing,
                     bool is_checkerboard,
                     const struct WrSpaceAndClipChain *parent,
                     ColorF color);

void wr_dp_push_rect_with_animation(struct WrState *state,
                                    LayoutRect rect,
                                    LayoutRect clip,
                                    bool is_backface_visible,
                                    const struct WrSpaceAndClipChain *parent,
                                    ColorF color,
                                    const struct WrAnimationProperty *animation);

void wr_dp_push_backdrop_filter(struct WrState *state,
                                LayoutRect rect,
                                LayoutRect clip,
                                bool is_backface_visible,
                                const struct WrSpaceAndClipChain *parent,
                                const FilterOp *filters,
                                uintptr_t filter_count,
                                const struct WrFilterData *filter_datas,
                                uintptr_t filter_datas_count);

void wr_dp_push_hit_test(struct WrState *state,
                         LayoutRect rect,
                         LayoutRect clip,
                         bool is_backface_visible,
                         const struct WrSpaceAndClipChain *parent,
                         uint64_t scroll_id,
                         uint16_t hit_info);

void wr_dp_push_image(struct WrState *state,
                      LayoutRect bounds,
                      LayoutRect clip,
                      bool is_backface_visible,
                      bool force_antialiasing,
                      const struct WrSpaceAndClipChain *parent,
                      ImageRendering image_rendering,
                      WrImageKey key,
                      bool premultiplied_alpha,
                      ColorF color,
                      bool prefer_compositor_surface,
                      bool supports_external_compositing);

void wr_dp_push_repeating_image(struct WrState *state,
                                LayoutRect bounds,
                                LayoutRect clip,
                                bool is_backface_visible,
                                const struct WrSpaceAndClipChain *parent,
                                LayoutSize stretch_size,
                                LayoutSize tile_spacing,
                                ImageRendering image_rendering,
                                WrImageKey key,
                                bool premultiplied_alpha,
                                ColorF color);

/**
 * Push a 3 planar yuv image.
 */
void wr_dp_push_yuv_planar_image(struct WrState *state,
                                 LayoutRect bounds,
                                 LayoutRect clip,
                                 bool is_backface_visible,
                                 const struct WrSpaceAndClipChain *parent,
                                 WrImageKey image_key_0,
                                 WrImageKey image_key_1,
                                 WrImageKey image_key_2,
                                 WrColorDepth color_depth,
                                 WrYuvColorSpace color_space,
                                 WrColorRange color_range,
                                 ImageRendering image_rendering,
                                 bool prefer_compositor_surface,
                                 bool supports_external_compositing);

/**
 * Push a 2 planar NV12 image.
 */
void wr_dp_push_yuv_NV12_image(struct WrState *state,
                               LayoutRect bounds,
                               LayoutRect clip,
                               bool is_backface_visible,
                               const struct WrSpaceAndClipChain *parent,
                               WrImageKey image_key_0,
                               WrImageKey image_key_1,
                               WrColorDepth color_depth,
                               WrYuvColorSpace color_space,
                               WrColorRange color_range,
                               ImageRendering image_rendering,
                               bool prefer_compositor_surface,
                               bool supports_external_compositing);

/**
 * Push a 2 planar P010 image.
 */
void wr_dp_push_yuv_P010_image(struct WrState *state,
                               LayoutRect bounds,
                               LayoutRect clip,
                               bool is_backface_visible,
                               const struct WrSpaceAndClipChain *parent,
                               WrImageKey image_key_0,
                               WrImageKey image_key_1,
                               WrColorDepth color_depth,
                               WrYuvColorSpace color_space,
                               WrColorRange color_range,
                               ImageRendering image_rendering,
                               bool prefer_compositor_surface,
                               bool supports_external_compositing);

/**
 * Push a 2 planar NV16 image.
 */
void wr_dp_push_yuv_NV16_image(struct WrState *state,
                               LayoutRect bounds,
                               LayoutRect clip,
                               bool is_backface_visible,
                               const struct WrSpaceAndClipChain *parent,
                               WrImageKey image_key_0,
                               WrImageKey image_key_1,
                               WrColorDepth color_depth,
                               WrYuvColorSpace color_space,
                               WrColorRange color_range,
                               ImageRendering image_rendering,
                               bool prefer_compositor_surface,
                               bool supports_external_compositing);

/**
 * Push a yuv interleaved image.
 */
void wr_dp_push_yuv_interleaved_image(struct WrState *state,
                                      LayoutRect bounds,
                                      LayoutRect clip,
                                      bool is_backface_visible,
                                      const struct WrSpaceAndClipChain *parent,
                                      WrImageKey image_key_0,
                                      WrColorDepth color_depth,
                                      WrYuvColorSpace color_space,
                                      WrColorRange color_range,
                                      ImageRendering image_rendering,
                                      bool prefer_compositor_surface,
                                      bool supports_external_compositing);

void wr_dp_push_text(struct WrState *state,
                     LayoutRect bounds,
                     LayoutRect clip,
                     bool is_backface_visible,
                     const struct WrSpaceAndClipChain *parent,
                     ColorF color,
                     WrFontInstanceKey font_key,
                     const GlyphInstance *glyphs,
                     uint32_t glyph_count,
                     const GlyphOptions *glyph_options);

void wr_dp_push_shadow(struct WrState *state,
                       LayoutRect _bounds,
                       LayoutRect _clip,
                       bool _is_backface_visible,
                       const struct WrSpaceAndClipChain *parent,
                       Shadow shadow,
                       bool should_inflate);

void wr_dp_pop_all_shadows(struct WrState *state);

void wr_dp_push_line(struct WrState *state,
                     const LayoutRect *clip,
                     bool is_backface_visible,
                     const struct WrSpaceAndClipChain *parent,
                     const LayoutRect *bounds,
                     float wavy_line_thickness,
                     LineOrientation orientation,
                     const ColorF *color,
                     LineStyle style);

void wr_dp_push_border(struct WrState *state,
                       LayoutRect rect,
                       LayoutRect clip,
                       bool is_backface_visible,
                       const struct WrSpaceAndClipChain *parent,
                       enum AntialiasBorder do_aa,
                       LayoutSideOffsets widths,
                       BorderSide top,
                       BorderSide right,
                       BorderSide bottom,
                       BorderSide left,
                       BorderRadius radius);

void wr_dp_push_border_image(struct WrState *state,
                             LayoutRect rect,
                             LayoutRect clip,
                             bool is_backface_visible,
                             const struct WrSpaceAndClipChain *parent,
                             const struct WrBorderImage *params);

void wr_dp_push_border_gradient(struct WrState *state,
                                LayoutRect rect,
                                LayoutRect clip,
                                bool is_backface_visible,
                                const struct WrSpaceAndClipChain *parent,
                                LayoutSideOffsets widths,
                                int32_t width,
                                int32_t height,
                                bool fill,
                                DeviceIntSideOffsets slice,
                                LayoutPoint start_point,
                                LayoutPoint end_point,
                                const GradientStop *stops,
                                uintptr_t stops_count,
                                ExtendMode extend_mode);

void wr_dp_push_border_radial_gradient(struct WrState *state,
                                       LayoutRect rect,
                                       LayoutRect clip,
                                       bool is_backface_visible,
                                       const struct WrSpaceAndClipChain *parent,
                                       LayoutSideOffsets widths,
                                       bool fill,
                                       LayoutPoint center,
                                       LayoutSize radius,
                                       const GradientStop *stops,
                                       uintptr_t stops_count,
                                       ExtendMode extend_mode);

void wr_dp_push_border_conic_gradient(struct WrState *state,
                                      LayoutRect rect,
                                      LayoutRect clip,
                                      bool is_backface_visible,
                                      const struct WrSpaceAndClipChain *parent,
                                      LayoutSideOffsets widths,
                                      bool fill,
                                      LayoutPoint center,
                                      float angle,
                                      const GradientStop *stops,
                                      uintptr_t stops_count,
                                      ExtendMode extend_mode);

void wr_dp_push_linear_gradient(struct WrState *state,
                                LayoutRect rect,
                                LayoutRect clip,
                                bool is_backface_visible,
                                const struct WrSpaceAndClipChain *parent,
                                LayoutPoint start_point,
                                LayoutPoint end_point,
                                const GradientStop *stops,
                                uintptr_t stops_count,
                                ExtendMode extend_mode,
                                LayoutSize tile_size,
                                LayoutSize tile_spacing);

void wr_dp_push_radial_gradient(struct WrState *state,
                                LayoutRect rect,
                                LayoutRect clip,
                                bool is_backface_visible,
                                const struct WrSpaceAndClipChain *parent,
                                LayoutPoint center,
                                LayoutSize radius,
                                const GradientStop *stops,
                                uintptr_t stops_count,
                                ExtendMode extend_mode,
                                LayoutSize tile_size,
                                LayoutSize tile_spacing);

void wr_dp_push_conic_gradient(struct WrState *state,
                               LayoutRect rect,
                               LayoutRect clip,
                               bool is_backface_visible,
                               const struct WrSpaceAndClipChain *parent,
                               LayoutPoint center,
                               float angle,
                               const GradientStop *stops,
                               uintptr_t stops_count,
                               ExtendMode extend_mode,
                               LayoutSize tile_size,
                               LayoutSize tile_spacing);

void wr_dp_push_box_shadow(struct WrState *state,
                           LayoutRect _rect,
                           LayoutRect clip,
                           bool is_backface_visible,
                           const struct WrSpaceAndClipChain *parent,
                           LayoutRect box_bounds,
                           LayoutVector2D offset,
                           ColorF color,
                           float blur_radius,
                           float spread_radius,
                           BorderRadius border_radius,
                           BorderRadius shadow_radius,
                           BoxShadowClipMode clip_mode);

void wr_dp_start_item_group(struct WrState *state);

void wr_dp_cancel_item_group(struct WrState *state, bool discard);

bool wr_dp_finish_item_group(struct WrState *state, ItemKey key);

void wr_dp_push_reuse_items(struct WrState *state, ItemKey key);

void wr_dp_set_cache_size(struct WrState *state, uintptr_t cache_size);

uintptr_t wr_dump_display_list(struct WrState *state,
                               uintptr_t indent,
                               const uintptr_t *start,
                               const uintptr_t *end);

void wr_dump_serialized_display_list(struct WrState *state);

void wr_api_begin_builder(struct WrState *state);

void wr_api_end_builder(struct WrState *state,
                        BuiltDisplayListDescriptor *dl_descriptor,
                        struct WrVecU8 *dl_items_data,
                        struct WrVecU8 *dl_cache_data,
                        struct WrVecU8 *dl_spatial_tree);

void wr_api_hit_test(struct DocumentHandle *dh, WorldPoint point, ThinVec<HitResult> *out_results);

const VecU8 *wr_add_ref_arc(const ArcVecU8 *arc);

void wr_dec_ref_arc(const VecU8 *arc);

extern bool wr_moz2d_render_cb(struct ByteSlice blob,
                               ImageFormat format,
                               const LayoutIntRect *render_rect,
                               const DeviceIntRect *visible_rect,
                               uint16_t tile_size,
                               const TileOffset *tile_offset,
                               const LayoutIntRect *dirty_rect,
                               struct MutByteSlice output);

struct WrSpatialId wr_root_scroll_node_id(void);

struct WrClipId wr_root_clip_id(void);

void wr_device_delete(Device *device);

struct WrShaders *wr_shaders_new(void *gl_context,
                                 struct WrProgramCache *program_cache,
                                 bool precache_shaders);

void wr_shaders_delete(struct WrShaders *shaders);

/**
 * Perform one step of shader warmup.
 *
 * Returns true if another call is needed, false if warmup is finished.
 */
bool wr_shaders_resume_warmup(struct WrShaders *shaders);

uintptr_t wr_program_cache_report_memory(const struct WrProgramCache *cache,
                                         VoidPtrToSizeFn size_of_op);

extern bool HasFontData(WrFontKey key);

extern void AddFontData(WrFontKey key,
                        const uint8_t *data,
                        uintptr_t size,
                        uint32_t index,
                        const ArcVecU8 *vec);

extern void AddNativeFontHandle(WrFontKey key, void *handle, uint32_t index);

extern void DeleteFontData(WrFontKey key);

extern void AddBlobFont(WrFontInstanceKey instance_key,
                        WrFontKey font_key,
                        float size,
                        const FontInstanceOptions *options,
                        const FontInstancePlatformOptions *platform_options,
                        const FontVariation *variations,
                        uintptr_t num_variations);

extern void DeleteBlobFont(WrFontInstanceKey key);

extern void ClearBlobImageResources(WrIdNamespace namespace_);

extern void gfx_wr_set_crash_annotation(CrashAnnotation annotation, const char *value);

void *wr_swgl_create_context(void);

void wr_swgl_reference_context(void *ctx);

void wr_swgl_destroy_context(void *ctx);

void wr_swgl_make_current(void *ctx);

void wr_swgl_init_default_framebuffer(void *ctx,
                                      int32_t x,
                                      int32_t y,
                                      int32_t width,
                                      int32_t height,
                                      int32_t stride,
                                      void *buf);

void wr_swgl_resolve_framebuffer(void *ctx, uint32_t fbo);

uint32_t wr_swgl_gen_texture(void *ctx);

void wr_swgl_delete_texture(void *ctx, uint32_t tex);

void wr_swgl_set_texture_parameter(void *ctx, uint32_t tex, uint32_t pname, int32_t param);

void wr_swgl_set_texture_buffer(void *ctx,
                                uint32_t tex,
                                uint32_t internal_format,
                                int32_t width,
                                int32_t height,
                                int32_t stride,
                                void *buf,
                                int32_t min_width,
                                int32_t min_height);

void wr_swgl_clear_color_rect(void *ctx,
                              uint32_t fbo,
                              int32_t x,
                              int32_t y,
                              int32_t width,
                              int32_t height,
                              float r,
                              float g,
                              float b,
                              float a);
