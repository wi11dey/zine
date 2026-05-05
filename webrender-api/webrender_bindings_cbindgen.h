#include <stdint.h>
#include "cbindgen_stubs.h"

#define MAX_CAP ~0

#define AUTO_ARRAY_HEADER_OFFSET 8

/**
 * Defined here for cbindgen
 */
#define MAX_RENDER_TASK_SIZE 16384

/**
 * Maximum number of SVGFE filters in one graph, this is constant size to avoid
 * allocating anything, and the SVG spec allows us to drop all filters on an
 * item if the graph is excessively complex - a graph this large will never be
 * a good user experience, performance-wise.
 */
#define SVGFE_GRAPH_MAX 256

#define POLYGON_CLIP_VERTEX_MAX 32

#define MAX_TEXT_RUN_LENGTH 2040

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
 * Crash annotations included in crash reports.
 */
enum CrashAnnotation {
  CompileShader = 0,
  DrawShader = 1,
  FontFile = 2,
};

/**
 * A stage of the rendering pipeline.
 */
enum Checkpoint {
  /**
   *
   */
  SceneBuilt,
  /**
   *
   */
  FrameBuilt,
  /**
   *
   */
  FrameTexturesUpdated,
  /**
   *
   */
  FrameRendered,
  /**
   * NotificationRequests get notified with this if they get dropped without having been
   * notified. This provides the guarantee that if a request is created it will get notified.
   */
  TransactionDropped,
};
typedef uint32_t Checkpoint;

/**
 * Specifies the format of a series of pixels, in driver terms.
 */
enum ImageFormat {
  /**
   * One-channel, byte storage. The "red" doesn't map to the color
   * red per se, and is just the way that OpenGL has historically referred
   * to single-channel buffers.
   */
  R8 = 1,
  /**
   * One-channel, short storage
   */
  R16 = 2,
  /**
   * Four channels, byte storage.
   */
  BGRA8 = 3,
  /**
   * Four channels, float storage.
   */
  RGBAF32 = 4,
  /**
   * Two-channels, byte storage. Similar to `R8`, this just means
   * "two channels" rather than "red and green".
   */
  RG8 = 5,
  /**
   * Two-channels, short storage. Similar to `R16`, this just means
   * "two channels" rather than "red and green".
   */
  RG16 = 6,
  /**
   * Four channels, signed integer storage.
   */
  RGBAI32 = 7,
  /**
   * Four channels, byte storage.
   */
  RGBA8 = 8,
};
typedef uint8_t ImageFormat;

enum ImageRendering {
  Auto = 0,
  CrispEdges = 1,
  Pixelated = 2,
};
typedef uint8_t ImageRendering;

/**
 * Boolean configuration option.
 */
enum BoolParameter {
  PboUploads = 0,
  Multithreading = 1,
  BatchedUploads = 2,
  DrawCallsForTextureCopy = 3,
};
typedef uint32_t BoolParameter;

/**
 * Integer configuration option.
 */
enum IntParameter {
  BatchedUploadThreshold = 0,
};
typedef uint32_t IntParameter;

/**
 * Floating point configuration option.
 */
enum FloatParameter {
  /**
   * The minimum time for the CPU portion of a frame to be considered slow
   */
  SlowCpuFrameThreshold = 0,
};
typedef uint32_t FloatParameter;

/**
 * Used to indicate if an image is opaque, or has an alpha channel.
 */
enum OpacityType {
  Opaque = 0,
  HasAlphaChannel = 1,
};
typedef uint8_t OpacityType;

/**
 * Specifies the type of texture target in driver terms.
 */
enum ImageBufferKind {
  /**
   * Standard texture. This maps to GL_TEXTURE_2D in OpenGL.
   */
  Texture2D = 0,
  /**
   * Rectangle texture. This maps to GL_TEXTURE_RECTANGLE in OpenGL. This
   * is similar to a standard texture, with a few subtle differences
   * (no mipmaps, non-power-of-two dimensions, different coordinate space)
   * that make it useful for representing the kinds of textures we use
   * in WebRender. See https://www.khronos.org/opengl/wiki/Rectangle_Texture
   * for background on Rectangle textures.
   */
  TextureRect = 1,
  /**
   * External texture. This maps to GL_TEXTURE_EXTERNAL_OES in OpenGL, which
   * is an extension. This is used for image formats that OpenGL doesn't
   * understand, particularly YUV. See
   * https://www.khronos.org/registry/OpenGL/extensions/OES/OES_EGL_image_external.txt
   */
  TextureExternal = 2,
  /**
   * External texture which is forced to be converted from YUV to RGB using BT709 colorspace.
   * This maps to GL_TEXTURE_EXTERNAL_OES in OpenGL, using the EXT_YUV_TARGET extension.
   * https://registry.khronos.org/OpenGL/extensions/EXT/EXT_YUV_target.txt
   */
  TextureExternalBT709 = 3,
};
typedef uint8_t ImageBufferKind;

enum FontRenderMode {
  Mono = 0,
  Alpha,
  Subpixel,
};
typedef uint8_t FontRenderMode;

enum FontLCDFilter {
  None,
  Default,
  Light,
  Legacy,
};
typedef uint8_t FontLCDFilter;

enum FontHinting {
  None,
  Mono,
  Light,
  Normal,
  LCD,
};
typedef uint8_t FontHinting;

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

enum TransformStyle {
  Flat = 0,
  Preserve3D = 1,
};
typedef uint8_t TransformStyle;

enum WrReferenceFrameKind {
  Transform,
  Perspective,
};
typedef uint8_t WrReferenceFrameKind;

enum MixBlendMode {
  Normal = 0,
  Multiply = 1,
  Screen = 2,
  Overlay = 3,
  Darken = 4,
  Lighten = 5,
  ColorDodge = 6,
  ColorBurn = 7,
  HardLight = 8,
  SoftLight = 9,
  Difference = 10,
  Exclusion = 11,
  Hue = 12,
  Saturation = 13,
  Color = 14,
  Luminosity = 15,
  PlusLighter = 16,
};
typedef uint8_t MixBlendMode;

enum ComponentTransferFuncType {
  Identity = 0,
  Table = 1,
  Discrete = 2,
  Linear = 3,
  Gamma = 4,
};
typedef uint8_t ComponentTransferFuncType;

enum FillRule {
  Nonzero = 1,
  Evenodd = 2,
};
typedef uint8_t FillRule;

enum ClipMode {
  Clip,
  ClipOut,
};

/**
 * A flag in each scrollable frame to represent whether the owner of the frame document
 * has any scroll-linked effect.
 * See https://firefox-source-docs.mozilla.org/performance/scroll-linked_effects.html
 * for a definition of scroll-linked effect.
 */
enum HasScrollLinkedEffect {
  Yes,
  No,
};
typedef uint8_t HasScrollLinkedEffect;

/**
 * Specifies the color depth of an image. Currently only used for YUV images.
 */
enum ColorDepth {
  /**
   * 8 bits image (most common)
   */
  Color8,
  /**
   * 10 bits image
   */
  Color10,
  /**
   * 12 bits image
   */
  Color12,
  /**
   * 16 bits image
   */
  Color16,
};
typedef uint8_t ColorDepth;

enum YuvColorSpace {
  Rec601 = 0,
  Rec709 = 1,
  Rec2020 = 2,
  Identity = 3,
};
typedef uint8_t YuvColorSpace;

enum ColorRange {
  Limited = 0,
  Full = 1,
};
typedef uint8_t ColorRange;

enum LineOrientation {
  Vertical,
  Horizontal,
};
typedef uint8_t LineOrientation;

enum LineStyle {
  Solid,
  Dotted,
  Dashed,
  Wavy,
};
typedef uint8_t LineStyle;

/**
 * Whether a border should be antialiased.
 */
enum AntialiasBorder {
  No = 0,
  Yes,
};

enum BorderStyle {
  None = 0,
  Solid = 1,
  Double = 2,
  Dotted = 3,
  Dashed = 4,
  Hidden = 5,
  Groove = 6,
  Ridge = 7,
  Inset = 8,
  Outset = 9,
};
typedef uint32_t BorderStyle;

enum RepeatMode {
  Stretch,
  Repeat,
  Round,
  Space,
};
typedef uint8_t RepeatMode;

enum ExtendMode {
  Clamp,
  Repeat,
};
typedef uint8_t ExtendMode;

enum BoxShadowClipMode {
  Outset = 0,
  Inset = 1,
};
typedef uint8_t BoxShadowClipMode;

struct Arc_VecU8;

struct ClipChainId;

struct DocumentHandle;

/**
 * Various flags that are part of an image descriptor.
 */
struct ImageDescriptorFlags;

struct Vec_u8;

struct WrChunkPool;

struct WrGlyphRasterThread;

struct WrProgramCache;

/**
 * A wrapper around a strong reference to a Shaders object, and around the
 * Device object that was used to create the shaders.
 *
 * We store the device to avoid repeated GL function lookups.
 */
struct WrShaders;

struct WrState;

struct WrThreadPool;

struct WrVecU8 {
  /**
   * `data` must always be valid for passing to Vec::from_raw_parts.
   * In particular, it must be non-null even if capacity is zero.
   */
  uint8_t *data;
  uintptr_t length;
  uintptr_t capacity;
};

struct ByteSlice {
  const uint8_t *buffer;
  uintptr_t len;
};

struct WrExternalImage {
  WrExternalImageType image_type;
  uint32_t handle;
  float u0;
  float v0;
  float u1;
  float v1;
  const uint8_t *buff;
  uintptr_t size;
};

/**
 * An arbitrary identifier for an external image provided by the
 * application. It must be a unique identifier for each external
 * image.
 */
struct ExternalImageId {
  uint64_t _0;
};

struct WrWindowId {
  uint64_t mHandle;
};

struct FramePublishId {
  uint64_t _0;
};
/**
 * An invalid sentinel FramePublishId, which will always compare less than
 * any valid FrameId.
 */
#define FramePublishId_INVALID (FramePublishId){ ._0 = 0 }

struct FrameReadyParams {
  bool present;
  bool render;
  bool scrolled;
  /**
   * Firefox uses this to indicate that the frame does not participate
   * in the frame throttling mechanism.
   * Frames from off-screen transactions are not tracked.
   */
  bool tracked;
};

/**
 * Flags to track why we are rendering.
 */
struct RenderReasons {
  uint32_t _0;
};
/**
 * Equivalent of empty() for the C++ side.
 */
#define RenderReasons_NONE (RenderReasons){ ._0 = (uint32_t)0 }
#define RenderReasons_SCENE (RenderReasons){ ._0 = (uint32_t)(1 << 0) }
#define RenderReasons_ANIMATED_PROPERTY (RenderReasons){ ._0 = (uint32_t)(1 << 1) }
#define RenderReasons_RESOURCE_UPDATE (RenderReasons){ ._0 = (uint32_t)(1 << 2) }
#define RenderReasons_ASYNC_IMAGE (RenderReasons){ ._0 = (uint32_t)(1 << 3) }
#define RenderReasons_CLEAR_RESOURCES (RenderReasons){ ._0 = (uint32_t)(1 << 4) }
#define RenderReasons_APZ (RenderReasons){ ._0 = (uint32_t)(1 << 5) }
/**
 * Window resize
 */
#define RenderReasons_RESIZE (RenderReasons){ ._0 = (uint32_t)(1 << 6) }
/**
 * Various widget-related reasons
 */
#define RenderReasons_WIDGET (RenderReasons){ ._0 = (uint32_t)(1 << 7) }
/**
 * See Frame::must_be_drawn
 */
#define RenderReasons_TEXTURE_CACHE_FLUSH (RenderReasons){ ._0 = (uint32_t)(1 << 8) }
#define RenderReasons_SNAPSHOT (RenderReasons){ ._0 = (uint32_t)(1 << 9) }
#define RenderReasons_POST_RESOURCE_UPDATES_HOOK (RenderReasons){ ._0 = (uint32_t)(1 << 10) }
#define RenderReasons_CONFIG_CHANGE (RenderReasons){ ._0 = (uint32_t)(1 << 11) }
#define RenderReasons_CONTENT_SYNC (RenderReasons){ ._0 = (uint32_t)(1 << 12) }
#define RenderReasons_FLUSH (RenderReasons){ ._0 = (uint32_t)(1 << 13) }
#define RenderReasons_TESTING (RenderReasons){ ._0 = (uint32_t)(1 << 14) }
#define RenderReasons_OTHER (RenderReasons){ ._0 = (uint32_t)(1 << 15) }
/**
 * Vsync isn't actually "why" we render but it can be useful
 * to see which frames were driven by the vsync scheduler so
 * we store a bit for it.
 */
#define RenderReasons_VSYNC (RenderReasons){ ._0 = (uint32_t)(1 << 16) }
#define RenderReasons_SKIPPED_COMPOSITE (RenderReasons){ ._0 = (uint32_t)(1 << 17) }
/**
 * Gecko does some special things when it starts observing vsync
 * so it can be useful to know what frames are associated with it.
 */
#define RenderReasons_START_OBSERVING_VSYNC (RenderReasons){ ._0 = (uint32_t)(1 << 18) }
#define RenderReasons_ASYNC_IMAGE_COMPOSITE_UNTIL (RenderReasons){ ._0 = (uint32_t)(1 << 19) }
#define RenderReasons_NUM_BITS 17

typedef uintptr_t SizeType;

typedef uint32_t SizeType;

struct Header {
  SizeType _len;
  SizeType _cap;
};

/**
 * See the crate's top level documentation for a description of this type.
 */
struct ThinVec_WrPipelineEpoch {
  struct Header *ptr;
};

/**
 * See the crate's top level documentation for a description of this type.
 */
struct ThinVec_WrRemovedPipeline {
  struct Header *ptr;
};

struct WrPipelineInfo {
  /**
   * This contains an entry for each pipeline that was rendered, along with
   * the epoch at which it was rendered. Rendered pipelines include the root
   * pipeline and any other pipelines that were reachable via IFrame display
   * items from the root pipeline.
   */
  struct ThinVec_WrPipelineEpoch epochs;
  /**
   * This contains an entry for each pipeline that was removed during the
   * last transaction. These pipelines would have been explicitly removed by
   * calling remove_pipeline on the transaction object; the pipeline showing
   * up in this array means that the data structures have been torn down on
   * the webrender side, and so any remaining data structures on the caller
   * side can now be torn down also.
   */
  struct ThinVec_WrRemovedPipeline removed_pipelines;
};

/**
 * Represents RGBA screen colors with floating point numbers.
 *
 * All components must be between 0.0 and 1.0.
 * An alpha value of 1.0 is opaque while 0.0 is fully transparent.
 */
struct ColorF {
  float r;
  float g;
  float b;
  float a;
};
#define ColorF_BLACK (ColorF){ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 }
#define ColorF_TRANSPARENT (ColorF){ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 }
#define ColorF_WHITE (ColorF){ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }

struct WrExternalImageHandler {
  void *external_image_obj;
};

/**
 * See the crate's top level documentation for a description of this type.
 */
struct ThinVec_DeviceIntRect {
  struct Header *ptr;
};

/**
 * A 2d Point tagged with a unit.
 */
struct Point2D_i32__DevicePixel {
  int32_t x;
  int32_t y;
};

typedef struct Point2D_i32__DevicePixel DeviceIntPoint;

/**
 * A 2d size tagged with a unit.
 */
struct Size2D_i32__DevicePixel {
  /**
   * The extent of the element in the `U` units along the `x` axis (usually horizontal).
   */
  int32_t width;
  /**
   * The extent of the element in the `U` units along the `y` axis (usually vertical).
   */
  int32_t height;
};

typedef struct Size2D_i32__DevicePixel DeviceIntSize;

/**
 * A 2d axis aligned rectangle represented by its minimum and maximum coordinates.
 *
 * # Representation
 *
 * This struct is similar to [`Rect`], but stores rectangle as two endpoints
 * instead of origin point and size. Such representation has several advantages over
 * [`Rect`] representation:
 * - Several operations are more efficient with `Box2D`, including [`intersection`],
 *   [`union`], and point-in-rect.
 * - The representation is less susceptible to overflow. With [`Rect`], computation
 *   of second point can overflow for a large range of values of origin and size.
 *   However, with `Box2D`, computation of [`size`] cannot overflow if the coordinates
 *   are signed and the resulting size is unsigned.
 *
 * A known disadvantage of `Box2D` is that translating the rectangle requires translating
 * both points, whereas translating [`Rect`] only requires translating one point.
 *
 * # Empty box
 *
 * A box is considered empty (see [`is_empty`]) if any of the following is true:
 * - it's area is empty,
 * - it's area is negative (`min.x > max.x` or `min.y > max.y`),
 * - it contains NaNs.
 *
 * [`intersection`]: Self::intersection
 * [`is_empty`]: Self::is_empty
 * [`union`]: Self::union
 * [`size`]: Self::size
 */
struct Box2D_i32__DevicePixel {
  struct Point2D_i32__DevicePixel min;
  struct Point2D_i32__DevicePixel max;
};

typedef struct Box2D_i32__DevicePixel DeviceIntRect;

/**
 * A C function that takes a pointer to a heap allocation and returns its size.
 *
 * This is borrowed from the malloc_size_of crate, upon which we want to avoid
 * a dependency from WebRender.
 */
typedef uintptr_t (*VoidPtrToSizeFn)(const void *ptr);

/**
 * Flags to enable/disable various builtin debugging tools.
 */
struct DebugFlags {
  uint64_t _0;
};
/**
 * Display the frame profiler on screen.
 */
#define DebugFlags_PROFILER_DBG (DebugFlags){ ._0 = (uint64_t)(1 << 0) }
/**
 * Display intermediate render targets on screen.
 */
#define DebugFlags_RENDER_TARGET_DBG (DebugFlags){ ._0 = (uint64_t)(1 << 1) }
/**
 * Display all texture cache pages on screen.
 */
#define DebugFlags_TEXTURE_CACHE_DBG (DebugFlags){ ._0 = (uint64_t)(1 << 2) }
/**
 * Display GPU timing results.
 */
#define DebugFlags_GPU_TIME_QUERIES (DebugFlags){ ._0 = (uint64_t)(1 << 3) }
/**
 * Query the number of pixels that pass the depth test divided and show it
 * in the profiler as a percentage of the number of pixels in the screen
 * (window width times height).
 */
#define DebugFlags_GPU_SAMPLE_QUERIES (DebugFlags){ ._0 = (uint64_t)(1 << 4) }
/**
 * Render each quad with their own draw call.
 *
 * Terrible for performance but can help with understanding the drawing
 * order when inspecting renderdoc or apitrace recordings.
 */
#define DebugFlags_DISABLE_BATCHING (DebugFlags){ ._0 = (uint64_t)(1 << 5) }
/**
 * Display the pipeline epochs.
 */
#define DebugFlags_EPOCHS (DebugFlags){ ._0 = (uint64_t)(1 << 6) }
/**
 * Print driver messages to stdout.
 */
#define DebugFlags_ECHO_DRIVER_MESSAGES (DebugFlags){ ._0 = (uint64_t)(1 << 7) }
/**
 * Show an overlay displaying overdraw amount.
 */
#define DebugFlags_SHOW_OVERDRAW (DebugFlags){ ._0 = (uint64_t)(1 << 8) }
/**
 * Display the contents of GPU cache.
 */
#define DebugFlags_GPU_CACHE_DBG (DebugFlags){ ._0 = (uint64_t)(1 << 9) }
/**
 * Clear evicted parts of the texture cache for debugging purposes.
 */
#define DebugFlags_TEXTURE_CACHE_DBG_CLEAR_EVICTED (DebugFlags){ ._0 = (uint64_t)(1 << 10) }
/**
 * Show picture caching debug overlay
 */
#define DebugFlags_PICTURE_CACHING_DBG (DebugFlags){ ._0 = (uint64_t)(1 << 11) }
/**
 * Draw a zoom widget showing part of the framebuffer zoomed in.
 */
#define DebugFlags_ZOOM_DBG (DebugFlags){ ._0 = (uint64_t)(1 << 13) }
/**
 * Scale the debug renderer down for a smaller screen. This will disrupt
 * any mapping between debug display items and page content, so shouldn't
 * be used with overlays like the picture caching or primitive display.
 */
#define DebugFlags_SMALL_SCREEN (DebugFlags){ ._0 = (uint64_t)(1 << 14) }
/**
 * Disable various bits of the WebRender pipeline, to help narrow
 * down where slowness might be coming from.
 */
#define DebugFlags_DISABLE_OPAQUE_PASS (DebugFlags){ ._0 = (uint64_t)(1 << 15) }
/**
 *
 */
#define DebugFlags_DISABLE_ALPHA_PASS (DebugFlags){ ._0 = (uint64_t)(1 << 16) }
/**
 *
 */
#define DebugFlags_DISABLE_CLIP_MASKS (DebugFlags){ ._0 = (uint64_t)(1 << 17) }
/**
 *
 */
#define DebugFlags_DISABLE_TEXT_PRIMS (DebugFlags){ ._0 = (uint64_t)(1 << 18) }
/**
 *
 */
#define DebugFlags_DISABLE_GRADIENT_PRIMS (DebugFlags){ ._0 = (uint64_t)(1 << 19) }
/**
 *
 */
#define DebugFlags_OBSCURE_IMAGES (DebugFlags){ ._0 = (uint64_t)(1 << 20) }
/**
 * Taint the transparent area of the glyphs with a random opacity to easily
 * see when glyphs are re-rasterized.
 */
#define DebugFlags_GLYPH_FLASHING (DebugFlags){ ._0 = (uint64_t)(1 << 21) }
/**
 * The profiler only displays information that is out of the ordinary.
 */
#define DebugFlags_SMART_PROFILER (DebugFlags){ ._0 = (uint64_t)(1 << 22) }
/**
 * If set, dump picture cache invalidation debug to console.
 */
#define DebugFlags_INVALIDATION_DBG (DebugFlags){ ._0 = (uint64_t)(1 << 23) }
/**
 * Collect and dump profiler statistics to captures.
 */
#define DebugFlags_PROFILER_CAPTURE (DebugFlags){ ._0 = (uint64_t)(1 << 25) }
/**
 * Invalidate picture tiles every frames (useful when inspecting GPU work in external tools).
 */
#define DebugFlags_FORCE_PICTURE_INVALIDATION (DebugFlags){ ._0 = (uint64_t)(1 << 26) }
/**
 * Display window visibility on screen.
 */
#define DebugFlags_WINDOW_VISIBILITY_DBG (DebugFlags){ ._0 = (uint64_t)(1 << 27) }
/**
 * Render large blobs with at a smaller size (incorrectly). This is a temporary workaround for
 * fuzzing.
 */
#define DebugFlags_RESTRICT_BLOB_SIZE (DebugFlags){ ._0 = (uint64_t)(1 << 28) }
/**
 * Enable surface promotion logging.
 */
#define DebugFlags_SURFACE_PROMOTION_LOGGING (DebugFlags){ ._0 = (uint64_t)(1 << 29) }
/**
 * Show picture caching debug overlay.
 */
#define DebugFlags_PICTURE_BORDERS (DebugFlags){ ._0 = (uint64_t)(1 << 30) }
/**
 * Panic when a attempting to display a missing stacking context snapshot.
 */
#define DebugFlags_MISSING_SNAPSHOT_PANIC (DebugFlags){ ._0 = (uint64_t)((uint64_t)1 << 31) }
/**
 * Panic when a attempting to display a missing stacking context snapshot.
 */
#define DebugFlags_MISSING_SNAPSHOT_PINK (DebugFlags){ ._0 = (uint64_t)((uint64_t)1 << 32) }
/**
 * Highlight backdrop filters
 */
#define DebugFlags_HIGHLIGHT_BACKDROP_FILTERS (DebugFlags){ ._0 = (uint64_t)((uint64_t)1 << 33) }
/**
 * Show external composite border rects in debug overlay.
 * TODO: Add native compositor support
 */
#define DebugFlags_EXTERNAL_COMPOSITE_BORDERS (DebugFlags){ ._0 = (uint64_t)((uint64_t)1 << 34) }

/**
 * This type carries no valuable semantics for WR. However, it reflects the fact that
 * clients (Servo) may generate pipelines by different semi-independent sources.
 * These pipelines still belong to the same `IdNamespace` and the same `DocumentId`.
 * Having this extra Id field enables them to generate `PipelineId` without collision.
 */
typedef uint32_t PipelineSourceId;

/**
 * From the point of view of WR, `PipelineId` is completely opaque and generic as long as
 * it's clonable, serializable, comparable, and hashable.
 */
struct PipelineId {
  PipelineSourceId mNamespace;
  uint32_t mHandle;
};
#define PipelineId_INVALID (PipelineId){  }

typedef struct PipelineId WrPipelineId;

/**
 * An epoch identifies the state of a pipeline in time.
 *
 * This is mostly used as a synchronization mechanism to observe how/when particular pipeline
 * updates propagate through WebRender and are applied at various stages.
 */
struct Epoch {
  uint32_t mHandle;
};

typedef struct Epoch WrEpoch;

enum GeckoDisplayListType_Tag {
  None,
  Partial,
  Full,
};

struct GeckoDisplayListType {
  enum GeckoDisplayListType_Tag tag;
  union {
    struct {
      double partial;
    };
    struct {
      double full;
    };
  };
};

/**
 * Describes the memory layout of a display list.
 *
 * A display list consists of some number of display list items, followed by a number of display
 * items.
 */
struct BuiltDisplayListDescriptor {
  /**
   * Gecko specific information about the display list.
   */
  struct GeckoDisplayListType gecko_display_list_type;
  /**
   * The first IPC time stamp: before any work has been done
   */
  uint64_t builder_start_time;
  /**
   * The second IPC time stamp: after serialization
   */
  uint64_t builder_finish_time;
  /**
   * The third IPC time stamp: just before sending
   */
  uint64_t send_start_time;
  /**
   * The amount of clipping nodes created while building this display list.
   */
  uintptr_t total_clip_nodes;
  /**
   * The amount of spatial nodes created while building this display list.
   */
  uintptr_t total_spatial_nodes;
  /**
   * The size of the cache for this display list.
   */
  uintptr_t cache_size;
};

struct WrAnimationPropertyValue_f32 {
  uint64_t id;
  float value;
};

typedef struct WrAnimationPropertyValue_f32 WrOpacityProperty;

/**
 * A 3d transform stored as a column-major 4 by 4 matrix.
 *
 * Transforms can be parametrized over the source and destination units, to describe a
 * transformation from a space to another.
 * For example, `Transform3D<f32, WorldSpace, ScreenSpace>::transform_point3d`
 * takes a `Point3D<f32, WorldSpace>` and returns a `Point3D<f32, ScreenSpace>`.
 *
 * Transforms expose a set of convenience methods for pre- and post-transformations.
 * Pre-transformations (`pre_*` methods) correspond to adding an operation that is
 * applied before the rest of the transformation, while post-transformations (`then_*`
 * methods) add an operation that is applied after.
 *
 * When translating `Transform3D` into general matrix representations, consider that the
 * representation follows the column major notation with column vectors.
 *
 * ```text
 *  |x'|   | m11 m12 m13 m14 |   |x|
 *  |y'|   | m21 m22 m23 m24 |   |y|
 *  |z'| = | m31 m32 m33 m34 | x |z|
 *  |w |   | m41 m42 m43 m44 |   |1|
 * ```
 *
 * The translation terms are `m41`, `m42` and `m43`.
 */
struct Transform3D_f32__LayoutPixel__LayoutPixel {
  float m11;
  float m12;
  float m13;
  float m14;
  float m21;
  float m22;
  float m23;
  float m24;
  float m31;
  float m32;
  float m33;
  float m34;
  float m41;
  float m42;
  float m43;
  float m44;
};

typedef struct Transform3D_f32__LayoutPixel__LayoutPixel LayoutTransform;

struct WrAnimationPropertyValue_LayoutTransform {
  uint64_t id;
  LayoutTransform value;
};

typedef struct WrAnimationPropertyValue_LayoutTransform WrTransformProperty;

struct WrAnimationPropertyValue_ColorF {
  uint64_t id;
  struct ColorF value;
};

typedef struct WrAnimationPropertyValue_ColorF WrColorProperty;

/**
 * An external identifier that uniquely identifies a scroll frame independent of its ClipId, which
 * may change from frame to frame. This should be unique within a pipeline. WebRender makes no
 * attempt to ensure uniqueness. The zero value is reserved for use by the root scroll node of
 * every pipeline, which always has an external id.
 *
 * When setting display lists with the `preserve_frame_state` this id is used to preserve scroll
 * offsets between different sets of SpatialNodes which are ScrollFrames.
 */
struct ExternalScrollId {
  uint64_t _0;
  struct PipelineId _1;
};

/**
 * See the crate's top level documentation for a description of this type.
 */
struct ThinVec_SampledScrollOffset {
  struct Header *ptr;
};

/**
 * A 2d Point tagged with a unit.
 */
struct Point2D_f32__LayoutPixel {
  float x;
  float y;
};

/**
 * A 2d axis aligned rectangle represented by its minimum and maximum coordinates.
 *
 * # Representation
 *
 * This struct is similar to [`Rect`], but stores rectangle as two endpoints
 * instead of origin point and size. Such representation has several advantages over
 * [`Rect`] representation:
 * - Several operations are more efficient with `Box2D`, including [`intersection`],
 *   [`union`], and point-in-rect.
 * - The representation is less susceptible to overflow. With [`Rect`], computation
 *   of second point can overflow for a large range of values of origin and size.
 *   However, with `Box2D`, computation of [`size`] cannot overflow if the coordinates
 *   are signed and the resulting size is unsigned.
 *
 * A known disadvantage of `Box2D` is that translating the rectangle requires translating
 * both points, whereas translating [`Rect`] only requires translating one point.
 *
 * # Empty box
 *
 * A box is considered empty (see [`is_empty`]) if any of the following is true:
 * - it's area is empty,
 * - it's area is negative (`min.x > max.x` or `min.y > max.y`),
 * - it contains NaNs.
 *
 * [`intersection`]: Self::intersection
 * [`is_empty`]: Self::is_empty
 * [`union`]: Self::union
 * [`size`]: Self::size
 */
struct Box2D_f32__LayoutPixel {
  struct Point2D_f32__LayoutPixel min;
  struct Point2D_f32__LayoutPixel max;
};

typedef struct Box2D_f32__LayoutPixel LayoutRect;

struct MinimapData {
  bool is_root_content;
  LayoutRect visual_viewport;
  LayoutRect layout_viewport;
  LayoutRect scrollable_rect;
  LayoutRect displayport;
  LayoutTransform zoom_transform;
  struct PipelineId root_content_pipeline_id;
  uint64_t root_content_scroll_id;
};

/**
 * ID namespaces uniquely identify different users of WebRender's API.
 *
 * For example in Gecko each content process uses a separate id namespace.
 */
struct IdNamespace {
  uint32_t mHandle;
};
#define IdNamespace_DEBUGGER (IdNamespace){  }

/**
 * An opaque identifier describing an image registered with WebRender.
 * This is used as a handle to reference images, and is used as the
 * hash map key for the actual image storage in the `ResourceCache`.
 */
struct ImageKey {
  struct IdNamespace mNamespace;
  uint32_t mHandle;
};
/**
 * Placeholder Image key, used to represent None.
 */
#define ImageKey_DUMMY (ImageKey){  }

typedef struct ImageKey WrImageKey;

struct WrImageDescriptor {
  ImageFormat format;
  int32_t width;
  int32_t height;
  int32_t stride;
  OpacityType opacity;
  bool prefer_compositor_surface;
};

/**
 * An opaque identifier describing a blob image registered with WebRender.
 * This is used as a handle to reference blob images, and can be used as an
 * image in display items.
 */
struct BlobImageKey {
  struct ImageKey _0;
};

/**
 * Storage format identifier for externally-managed images.
 */
enum ExternalImageType_Tag {
  /**
   * The image is texture-backed.
   */
  TextureHandle,
  /**
   * The image is heap-allocated by the embedding.
   */
  Buffer,
};
typedef uint8_t ExternalImageType_Tag;

union ExternalImageType {
  ExternalImageType_Tag tag;
  struct {
    ExternalImageType_Tag texture_handle_tag;
    ImageBufferKind texture_handle;
  };
};

/**
 * A 2d Point tagged with a unit.
 */
struct Point2D_i32__LayoutPixel {
  int32_t x;
  int32_t y;
};

/**
 * A 2d axis aligned rectangle represented by its minimum and maximum coordinates.
 *
 * # Representation
 *
 * This struct is similar to [`Rect`], but stores rectangle as two endpoints
 * instead of origin point and size. Such representation has several advantages over
 * [`Rect`] representation:
 * - Several operations are more efficient with `Box2D`, including [`intersection`],
 *   [`union`], and point-in-rect.
 * - The representation is less susceptible to overflow. With [`Rect`], computation
 *   of second point can overflow for a large range of values of origin and size.
 *   However, with `Box2D`, computation of [`size`] cannot overflow if the coordinates
 *   are signed and the resulting size is unsigned.
 *
 * A known disadvantage of `Box2D` is that translating the rectangle requires translating
 * both points, whereas translating [`Rect`] only requires translating one point.
 *
 * # Empty box
 *
 * A box is considered empty (see [`is_empty`]) if any of the following is true:
 * - it's area is empty,
 * - it's area is negative (`min.x > max.x` or `min.y > max.y`),
 * - it contains NaNs.
 *
 * [`intersection`]: Self::intersection
 * [`is_empty`]: Self::is_empty
 * [`union`]: Self::union
 * [`size`]: Self::size
 */
struct Box2D_i32__LayoutPixel {
  struct Point2D_i32__LayoutPixel min;
  struct Point2D_i32__LayoutPixel max;
};

typedef struct Box2D_i32__LayoutPixel LayoutIntRect;

/**
 * An opaque identifier describing a snapshot image registered with WebRender.
 * This is used as a handle to reference snapshot images, and can be used as an
 * image in display items.
 */
struct SnapshotImageKey {
  struct ImageKey _0;
};

struct FontKey {
  struct IdNamespace mNamespace;
  uint32_t mHandle;
};

typedef struct FontKey WrFontKey;

struct FontInstanceKey {
  struct IdNamespace mNamespace;
  uint32_t mHandle;
};

typedef struct FontInstanceKey WrFontInstanceKey;

struct FontInstanceFlags {
  uint32_t _0;
};
#define FontInstanceFlags_SYNTHETIC_BOLD (FontInstanceFlags){ ._0 = (uint32_t)(1 << 1) }
#define FontInstanceFlags_EMBEDDED_BITMAPS (FontInstanceFlags){ ._0 = (uint32_t)(1 << 2) }
#define FontInstanceFlags_SUBPIXEL_BGR (FontInstanceFlags){ ._0 = (uint32_t)(1 << 3) }
#define FontInstanceFlags_TRANSPOSE (FontInstanceFlags){ ._0 = (uint32_t)(1 << 4) }
#define FontInstanceFlags_FLIP_X (FontInstanceFlags){ ._0 = (uint32_t)(1 << 5) }
#define FontInstanceFlags_FLIP_Y (FontInstanceFlags){ ._0 = (uint32_t)(1 << 6) }
#define FontInstanceFlags_SUBPIXEL_POSITION (FontInstanceFlags){ ._0 = (uint32_t)(1 << 7) }
#define FontInstanceFlags_VERTICAL (FontInstanceFlags){ ._0 = (uint32_t)(1 << 8) }
#define FontInstanceFlags_MULTISTRIKE_BOLD (FontInstanceFlags){ ._0 = (uint32_t)(1 << 9) }
#define FontInstanceFlags_TRANSFORM_GLYPHS (FontInstanceFlags){ ._0 = (uint32_t)(1 << 12) }
#define FontInstanceFlags_TEXTURE_PADDING (FontInstanceFlags){ ._0 = (uint32_t)(1 << 13) }
#define FontInstanceFlags_FORCE_GDI (FontInstanceFlags){ ._0 = (uint32_t)(1 << 16) }
#define FontInstanceFlags_FORCE_SYMMETRIC (FontInstanceFlags){ ._0 = (uint32_t)(1 << 17) }
#define FontInstanceFlags_NO_SYMMETRIC (FontInstanceFlags){ ._0 = (uint32_t)(1 << 18) }
#define FontInstanceFlags_FONT_SMOOTHING (FontInstanceFlags){ ._0 = (uint32_t)(1 << 16) }
#define FontInstanceFlags_FORCE_AUTOHINT (FontInstanceFlags){ ._0 = (uint32_t)(1 << 16) }
#define FontInstanceFlags_NO_AUTOHINT (FontInstanceFlags){ ._0 = (uint32_t)(1 << 17) }
#define FontInstanceFlags_VERTICAL_LAYOUT (FontInstanceFlags){ ._0 = (uint32_t)(1 << 18) }
#define FontInstanceFlags_LCD_VERTICAL (FontInstanceFlags){ ._0 = (uint32_t)(1 << 19) }

struct SyntheticItalics {
  int16_t angle;
};
#define SyntheticItalics_ANGLE_SCALE 256.0

struct FontInstanceOptions {
  struct FontInstanceFlags flags;
  struct SyntheticItalics synthetic_italics;
  FontRenderMode render_mode;
  uint8_t _padding;
};

struct FontInstancePlatformOptions {
  uint16_t gamma;
  uint8_t contrast;
  uint8_t cleartype_level;
};

struct FontInstancePlatformOptions {
  uint32_t unused;
};

struct FontInstancePlatformOptions {
  FontLCDFilter lcd_filter;
  FontHinting hinting;
};

typedef struct IdNamespace WrIdNamespace;

struct WrSpatialId {
  uintptr_t id;
};

enum WrStackingContextClip_Tag {
  None,
  ClipChain,
};

struct WrStackingContextClip {
  enum WrStackingContextClip_Tag tag;
  union {
    struct {
      uint64_t clip_chain;
    };
  };
};

/**
 * Defines a caller provided key that is unique for a given spatial node, and is stable across
 * display lists. WR uses this to determine which spatial nodes are added / removed for a new
 * display list. The content itself is arbitrary and opaque to WR, the only thing that matters
 * is that it's unique and stable between display lists.
 */
struct SpatialTreeItemKey {
  uint64_t key0;
  uint64_t key1;
};

struct WrAnimationProperty {
  WrAnimationType effect_type;
  uint64_t id;
  struct SpatialTreeItemKey key;
};

/**
 * A 2d size tagged with a unit.
 */
struct Size2D_f32__LayoutPixel {
  /**
   * The extent of the element in the `U` units along the `x` axis (usually horizontal).
   */
  float width;
  /**
   * The extent of the element in the `U` units along the `y` axis (usually vertical).
   */
  float height;
};

typedef struct Size2D_f32__LayoutPixel LayoutSize;

struct WrComputedTransformData {
  LayoutSize scale_from;
  bool vertical_flip;
  WrRotation rotation;
  struct SpatialTreeItemKey key;
};

/**
 * If passed in a stacking context display item, inform WebRender that
 * the contents of the stacking context should be retained into a texture
 * and associated to an image key.
 *
 * Image display items can then display the cached snapshot using the
 * same image key.
 *
 * The flow for creating/using/deleting snapshots is the same as with
 * regular images:
 *  - The image key must have been created with `Transaction::add_snapshot_image`.
 *  - The current scene must not contain references to the snapshot when
 *    `Transaction::delete_snapshot_image` is called.
 */
struct SnapshotInfo {
  /**
   * The image key to associate the snapshot with.
   */
  struct SnapshotImageKey key;
  /**
   * The bounds of the snapshot in local space.
   *
   * This rectangle is relative to the same coordinate space as the
   * child items of the stacking context.
   */
  LayoutRect area;
  /**
   * If true, detach the stacking context from the scene and only
   * render it into the snapshot.
   * If false, the stacking context rendered in the frame normally
   * in addition to being cached into the snapshot.
   */
  bool detached;
};

struct PrimitiveFlags {
  uint8_t _0;
};
/**
 * The CSS backface-visibility property (yes, it can be really granular)
 */
#define PrimitiveFlags_IS_BACKFACE_VISIBLE (PrimitiveFlags){ ._0 = (uint8_t)(1 << 0) }
/**
 * If set, this primitive represents a scroll bar container
 */
#define PrimitiveFlags_IS_SCROLLBAR_CONTAINER (PrimitiveFlags){ ._0 = (uint8_t)(1 << 1) }
/**
 * This is used as a performance hint - this primitive may be promoted to a native
 * compositor surface under certain (implementation specific) conditions. This
 * is typically used for large videos, and canvas elements.
 */
#define PrimitiveFlags_PREFER_COMPOSITOR_SURFACE (PrimitiveFlags){ ._0 = (uint8_t)(1 << 2) }
/**
 * If set, this primitive can be passed directly to the compositor via its
 * ExternalImageId, and the compositor will use the native image directly.
 * Used as a further extension on top of PREFER_COMPOSITOR_SURFACE.
 */
#define PrimitiveFlags_SUPPORTS_EXTERNAL_COMPOSITOR_SURFACE (PrimitiveFlags){ ._0 = (uint8_t)(1 << 3) }
/**
 * This flags disables snapping and forces anti-aliasing even if the primitive is axis-aligned.
 */
#define PrimitiveFlags_ANTIALISED (PrimitiveFlags){ ._0 = (uint8_t)(1 << 4) }
/**
 * If true, this primitive is used as a background for checkerboarding
 */
#define PrimitiveFlags_CHECKERBOARD_BACKGROUND (PrimitiveFlags){ ._0 = (uint8_t)(1 << 5) }

struct StackingContextFlags {
  uint8_t _0;
};
/**
 * If true, this stacking context is a blend container than contains
 * mix-blend-mode children (and should thus be isolated).
 */
#define StackingContextFlags_IS_BLEND_CONTAINER (StackingContextFlags){ ._0 = (uint8_t)(1 << 0) }
/**
 * If true, this stacking context is a wrapper around a backdrop-filter (e.g. for
 * a clip-mask). This is needed to allow the correct selection of a backdrop root
 * since a clip-mask stacking context creates a parent surface.
 */
#define StackingContextFlags_WRAPS_BACKDROP_FILTER (StackingContextFlags){ ._0 = (uint8_t)(1 << 1) }
/**
 * If true, this stacking context must be isolated from parent by a surface.
 */
#define StackingContextFlags_FORCED_ISOLATION (StackingContextFlags){ ._0 = (uint8_t)(1 << 2) }

/**
 * IMPORTANT: If you add fields to this struct, you need to also add initializers
 * for those fields in WebRenderAPI.h.
 */
struct WrStackingContextParams {
  struct WrStackingContextClip clip;
  const struct WrAnimationProperty *animation;
  const float *opacity;
  const struct WrComputedTransformData *computed_transform;
  const struct SnapshotInfo *snapshot;
  TransformStyle transform_style;
  WrReferenceFrameKind reference_frame_kind;
  bool is_2d_scale_translation;
  bool should_snap;
  bool paired_with_perspective;
  const uint64_t *scrolling_relative_to;
  struct PrimitiveFlags prim_flags;
  MixBlendMode mix_blend_mode;
  struct StackingContextFlags flags;
};

struct WrTransformInfo {
  LayoutTransform transform;
  struct SpatialTreeItemKey key;
};

/**
 * A key to identify an animated property binding.
 */
struct PropertyBindingId {
  struct IdNamespace namespace_;
  uint32_t uid;
};

/**
 * A unique key that is used for connecting animated property
 * values to bindings in the display list.
 */
struct PropertyBindingKey_f32 {
  /**
   *
   */
  struct PropertyBindingId id;
};

/**
 * A binding property can either be a specific value
 * (the normal, non-animated case) or point to a binding location
 * to fetch the current value from.
 * Note that Binding has also a non-animated value, the value is
 * used for the case where the animation is still in-delay phase
 * (i.e. the animation doesn't produce any animation values).
 */
enum PropertyBinding_f32_Tag {
  /**
   * Non-animated value.
   */
  Value_f32,
  /**
   * Animated binding.
   */
  Binding_f32,
};

struct Binding_Body_f32 {
  struct PropertyBindingKey_f32 _0;
  float _1;
};

struct PropertyBinding_f32 {
  enum PropertyBinding_f32_Tag tag;
  union {
    struct {
      float value;
    };
    struct Binding_Body_f32 binding;
  };
};

/**
 * A 2d Vector tagged with a unit.
 */
struct Vector2D_f32__LayoutPixel {
  /**
   * The `x` (traditionally, horizontal) coordinate.
   */
  float x;
  /**
   * The `y` (traditionally, vertical) coordinate.
   */
  float y;
};

typedef struct Vector2D_f32__LayoutPixel LayoutVector2D;

struct Shadow {
  LayoutVector2D offset;
  struct ColorF color;
  float blur_radius;
};

enum FilterOpGraphPictureBufferId_Tag {
  /**
   * empty slot in feMerge inputs
   */
  None,
  /**
   * reference to another (earlier) node in filter graph
   */
  BufferId,
};

struct FilterOpGraphPictureBufferId {
  enum FilterOpGraphPictureBufferId_Tag tag;
  union {
    struct {
      int16_t buffer_id;
    };
  };
};

struct FilterOpGraphPictureReference {
  /**
   * Id of the picture in question in a namespace unique to this filter DAG
   */
  struct FilterOpGraphPictureBufferId buffer_id;
};

struct FilterOpGraphNode {
  /**
   * True if color_interpolation_filter == LinearRgb; shader will convert
   * sRGB texture pixel colors on load and convert back on store, for correct
   * interpolation
   */
  bool linear;
  /**
   * virtualized picture input binding 1 (i.e. texture source), typically
   * this is used, but certain filters do not use it
   */
  struct FilterOpGraphPictureReference input;
  /**
   * virtualized picture input binding 2 (i.e. texture sources), only certain
   * filters use this
   */
  struct FilterOpGraphPictureReference input2;
  /**
   * rect this node will render into, in filter space
   */
  LayoutRect subregion;
};

enum FilterOp_Tag {
  /**
   * Filter that does no transformation of the colors, needed for
   * debug purposes, and is the default value in impl_default_for_enums.
   * parameters: none
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Identity,
  /**
   * apply blur effect
   * parameters: stdDeviationX, stdDeviationY
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Blur,
  /**
   * apply brightness effect
   * parameters: amount
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Brightness,
  /**
   * apply contrast effect
   * parameters: amount
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Contrast,
  /**
   * fade image toward greyscale version of image
   * parameters: amount
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Grayscale,
  /**
   * fade image toward hue-rotated version of image (rotate RGB around color wheel)
   * parameters: angle
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  HueRotate,
  /**
   * fade image toward inverted image (1 - RGB)
   * parameters: amount
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Invert,
  /**
   * multiplies color and alpha by opacity
   * parameters: amount
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Opacity,
  /**
   * multiply saturation of colors
   * parameters: amount
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Saturate,
  /**
   * fade image toward sepia tone version of image
   * parameters: amount
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  Sepia,
  /**
   * add drop shadow version of image to the image
   * parameters: shadow
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  DropShadow,
  /**
   * transform color and alpha in image through 4x5 color matrix (transposed for efficiency)
   * parameters: matrix[5][4]
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  ColorMatrix,
  /**
   * internal use - convert sRGB input to linear output
   * parameters: none
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  SrgbToLinear,
  /**
   * internal use - convert linear input to sRGB output
   * parameters: none
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  LinearToSrgb,
  /**
   * remap RGBA with color gradients and component swizzle
   * parameters: FilterData
   * CSS filter semantics - operates on previous picture, uses sRGB space (non-linear)
   */
  ComponentTransfer,
  /**
   * replace image with a solid color
   * NOTE: UNUSED; Gecko never produces this filter
   * parameters: color
   * CSS filter semantics - operates on previous picture,uses sRGB space (non-linear)
   */
  Flood,
  /**
   * Filter that copies the SourceGraphic image into the specified subregion,
   * This is intentionally the only way to get SourceGraphic into the graph,
   * as the filter region must be applied before it is used.
   * parameters: FilterOpGraphNode
   * SVG filter semantics - no inputs, no linear
   */
  SVGFESourceGraphic,
  /**
   * Filter that copies the SourceAlpha image into the specified subregion,
   * This is intentionally the only way to get SourceGraphic into the graph,
   * as the filter region must be applied before it is used.
   * parameters: FilterOpGraphNode
   * SVG filter semantics - no inputs, no linear
   */
  SVGFESourceAlpha,
  /**
   * Filter that does no transformation of the colors, used for subregion
   * cropping only.
   */
  SVGFEIdentity,
  /**
   * represents CSS opacity property as a graph node like the rest of the SVGFE* filters
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   */
  SVGFEOpacity,
  /**
   * convert a color image to an alpha channel - internal use; generated by
   * SVGFilterInstance::GetOrCreateSourceAlphaIndex().
   */
  SVGFEToAlpha,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_DARKEN
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feBlendElement
   */
  SVGFEBlendDarken,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_LIGHTEN
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feBlendElement
   */
  SVGFEBlendLighten,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_MULTIPLY
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feBlendElement
   */
  SVGFEBlendMultiply,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_NORMAL
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feBlendElement
   */
  SVGFEBlendNormal,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_SCREEN
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feBlendElement
   */
  SVGFEBlendScreen,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_OVERLAY
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendOverlay,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_COLOR_DODGE
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendColorDodge,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_COLOR_BURN
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendColorBurn,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_HARD_LIGHT
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendHardLight,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_SOFT_LIGHT
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendSoftLight,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_DIFFERENCE
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendDifference,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_EXCLUSION
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendExclusion,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_HUE
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendHue,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_SATURATION
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendSaturation,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_COLOR
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendColor,
  /**
   * combine 2 images with SVG_FEBLEND_MODE_LUMINOSITY
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Source: https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode
   */
  SVGFEBlendLuminosity,
  /**
   * transform colors of image through 5x4 color matrix (transposed for efficiency)
   * parameters: FilterOpGraphNode, matrix[5][4]
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feColorMatrixElement
   */
  SVGFEColorMatrix,
  /**
   * transform colors of image through configurable gradients with component swizzle
   * parameters: FilterOpGraphNode, FilterData
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feComponentTransferElement
   */
  SVGFEComponentTransfer,
  /**
   * composite 2 images with chosen composite mode with parameters for that mode
   * parameters: FilterOpGraphNode, k1, k2, k3, k4
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feCompositeElement
   */
  SVGFECompositeArithmetic,
  /**
   * composite 2 images with chosen composite mode with parameters for that mode
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feCompositeElement
   */
  SVGFECompositeATop,
  /**
   * composite 2 images with chosen composite mode with parameters for that mode
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feCompositeElement
   */
  SVGFECompositeIn,
  /**
   * composite 2 images with chosen composite mode with parameters for that mode
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Docs: https://developer.mozilla.org/en-US/docs/Web/SVG/Element/feComposite
   */
  SVGFECompositeLighter,
  /**
   * composite 2 images with chosen composite mode with parameters for that mode
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feCompositeElement
   */
  SVGFECompositeOut,
  /**
   * composite 2 images with chosen composite mode with parameters for that mode
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feCompositeElement
   */
  SVGFECompositeOver,
  /**
   * composite 2 images with chosen composite mode with parameters for that mode
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feCompositeElement
   */
  SVGFECompositeXOR,
  /**
   * transform image through convolution matrix of up to 25 values (spec
   * allows more but for performance reasons we do not)
   * parameters: FilterOpGraphNode, orderX, orderY, kernelValues[25],
   *  divisor, bias, targetX, targetY, kernelUnitLengthX, kernelUnitLengthY,
   *  preserveAlpha
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feConvolveMatrixElement
   */
  SVGFEConvolveMatrixEdgeModeDuplicate,
  /**
   * transform image through convolution matrix of up to 25 values (spec
   * allows more but for performance reasons we do not)
   * parameters: FilterOpGraphNode, orderX, orderY, kernelValues[25],
   *  divisor, bias, targetX, targetY, kernelUnitLengthX, kernelUnitLengthY,
   *  preserveAlpha
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feConvolveMatrixElement
   */
  SVGFEConvolveMatrixEdgeModeNone,
  /**
   * transform image through convolution matrix of up to 25 values (spec
   * allows more but for performance reasons we do not)
   * parameters: FilterOpGraphNode, orderX, orderY, kernelValues[25],
   *  divisor, bias, targetX, targetY, kernelUnitLengthX, kernelUnitLengthY,
   * preserveAlpha
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#feConvolveMatrixElement
   */
  SVGFEConvolveMatrixEdgeModeWrap,
  /**
   * calculate lighting based on heightmap image with provided values for a
   * distant light source with specified direction
   * parameters: FilterOpGraphNode, surfaceScale, diffuseConstant,
   *  kernelUnitLengthX, kernelUnitLengthY, azimuth, elevation
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEDiffuseLightingElement
   *  https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEDistantLightElement
   */
  SVGFEDiffuseLightingDistant,
  /**
   * calculate lighting based on heightmap image with provided values for a
   * point light source at specified location
   * parameters: FilterOpGraphNode, surfaceScale, diffuseConstant,
   *  kernelUnitLengthX, kernelUnitLengthY, x, y, z
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEDiffuseLightingElement
   *  https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEPointLightElement
   */
  SVGFEDiffuseLightingPoint,
  /**
   * calculate lighting based on heightmap image with provided values for a
   * spot light source at specified location pointing at specified target
   * location with specified hotspot sharpness and cone angle
   * parameters: FilterOpGraphNode, surfaceScale, diffuseConstant,
   *  kernelUnitLengthX, kernelUnitLengthY, x, y, z, pointsAtX, pointsAtY,
   *  pointsAtZ, specularExponent, limitingConeAngle
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEDiffuseLightingElement
   * https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFESpotLightElement
   */
  SVGFEDiffuseLightingSpot,
  /**
   * calculate a distorted version of first input image using offset values
   * from second input image at specified intensity
   * parameters: FilterOpGraphNode, scale, xChannelSelector, yChannelSelector
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEDisplacementMapElement
   */
  SVGFEDisplacementMap,
  /**
   * create and merge a dropshadow version of the specified image's alpha
   * channel with specified offset and blur radius
   * parameters: FilterOpGraphNode, flood_color, flood_opacity, dx, dy,
   *  stdDeviationX, stdDeviationY
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEDropShadowElement
   */
  SVGFEDropShadow,
  /**
   * synthesize a new image of specified size containing a solid color
   * parameters: FilterOpGraphNode, color
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEFloodElement
   */
  SVGFEFlood,
  /**
   * create a blurred version of the input image
   * parameters: FilterOpGraphNode, stdDeviationX, stdDeviationY
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEGaussianBlurElement
   */
  SVGFEGaussianBlur,
  /**
   * synthesize a new image based on a url (i.e. blob image source)
   * parameters: FilterOpGraphNode, sampling_filter (see SamplingFilter in Types.h), transform
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEImageElement
   */
  SVGFEImage,
  /**
   * create a new image based on the input image with the contour stretched
   * outward (dilate operator)
   * parameters: FilterOpGraphNode, radiusX, radiusY
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEMorphologyElement
   */
  SVGFEMorphologyDilate,
  /**
   * create a new image based on the input image with the contour shrunken
   * inward (erode operator)
   * parameters: FilterOpGraphNode, radiusX, radiusY
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEMorphologyElement
   */
  SVGFEMorphologyErode,
  /**
   * create a new image that is a scrolled version of the input image, this
   * is basically a no-op as we support offset in the graph node
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEOffsetElement
   */
  SVGFEOffset,
  /**
   * calculate lighting based on heightmap image with provided values for a
   * distant light source with specified direction
   * parameters: FilerData, surfaceScale, specularConstant, specularExponent,
   *  kernelUnitLengthX, kernelUnitLengthY, azimuth, elevation
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFESpecularLightingElement
   * https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEDistantLightElement
   */
  SVGFESpecularLightingDistant,
  /**
   * calculate lighting based on heightmap image with provided values for a
   * point light source at specified location
   * parameters: FilterOpGraphNode, surfaceScale, specularConstant,
   *  specularExponent, kernelUnitLengthX, kernelUnitLengthY, x, y, z
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFESpecularLightingElement
   *  https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFEPointLightElement
   */
  SVGFESpecularLightingPoint,
  /**
   * calculate lighting based on heightmap image with provided values for a
   * spot light source at specified location pointing at specified target
   * location with specified hotspot sharpness and cone angle
   * parameters: FilterOpGraphNode, surfaceScale, specularConstant,
   *  specularExponent, kernelUnitLengthX, kernelUnitLengthY, x, y, z,
   *  pointsAtX, pointsAtY, pointsAtZ, specularExponent, limitingConeAngle
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFESpecularLightingElement
   *  https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFESpotLightElement
   */
  SVGFESpecularLightingSpot,
  /**
   * create a new image based on the input image, repeated throughout the
   * output rectangle
   * parameters: FilterOpGraphNode
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFETileElement
   */
  SVGFETile,
  /**
   * synthesize a new image based on Fractal Noise (Perlin) with the chosen
   * stitching mode
   * parameters: FilterOpGraphNode, baseFrequencyX, baseFrequencyY,
   *  numOctaves, seed
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFETurbulenceElement
   */
  SVGFETurbulenceWithFractalNoiseWithNoStitching,
  /**
   * synthesize a new image based on Fractal Noise (Perlin) with the chosen
   * stitching mode
   * parameters: FilterOpGraphNode, baseFrequencyX, baseFrequencyY,
   *  numOctaves, seed
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFETurbulenceElement
   */
  SVGFETurbulenceWithFractalNoiseWithStitching,
  /**
   * synthesize a new image based on Turbulence Noise (offset vectors)
   * parameters: FilterOpGraphNode, baseFrequencyX, baseFrequencyY,
   *  numOctaves, seed
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFETurbulenceElement
   */
  SVGFETurbulenceWithTurbulenceNoiseWithNoStitching,
  /**
   * synthesize a new image based on Turbulence Noise (offset vectors)
   * parameters: FilterOpGraphNode, baseFrequencyX, baseFrequencyY,
   *  numOctaves, seed
   * SVG filter semantics - selectable input(s), selectable between linear
   * (default) and sRGB color space for calculations
   * Spec: https://www.w3.org/TR/filter-effects-1/#InterfaceSVGFETurbulenceElement
   */
  SVGFETurbulenceWithTurbulenceNoiseWithStitching,
};

struct Blur_Body {
  float _0;
  float _1;
};

struct Opacity_Body {
  struct PropertyBinding_f32 _0;
  float _1;
};

struct SVGFESourceGraphic_Body {
  struct FilterOpGraphNode node;
};

struct SVGFESourceAlpha_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEIdentity_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEOpacity_Body {
  struct FilterOpGraphNode node;
  struct PropertyBinding_f32 valuebinding;
  float value;
};

struct SVGFEToAlpha_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendDarken_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendLighten_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendMultiply_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendNormal_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendScreen_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendOverlay_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendColorDodge_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendColorBurn_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendHardLight_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendSoftLight_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendDifference_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendExclusion_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendHue_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendSaturation_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendColor_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEBlendLuminosity_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEColorMatrix_Body {
  struct FilterOpGraphNode node;
  float values[20];
};

struct SVGFEComponentTransfer_Body {
  struct FilterOpGraphNode node;
};

struct SVGFECompositeArithmetic_Body {
  struct FilterOpGraphNode node;
  float k1;
  float k2;
  float k3;
  float k4;
};

struct SVGFECompositeATop_Body {
  struct FilterOpGraphNode node;
};

struct SVGFECompositeIn_Body {
  struct FilterOpGraphNode node;
};

struct SVGFECompositeLighter_Body {
  struct FilterOpGraphNode node;
};

struct SVGFECompositeOut_Body {
  struct FilterOpGraphNode node;
};

struct SVGFECompositeOver_Body {
  struct FilterOpGraphNode node;
};

struct SVGFECompositeXOR_Body {
  struct FilterOpGraphNode node;
};

struct SVGFEConvolveMatrixEdgeModeDuplicate_Body {
  struct FilterOpGraphNode node;
  int32_t order_x;
  int32_t order_y;
  float kernel[25];
  float divisor;
  float bias;
  int32_t target_x;
  int32_t target_y;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  int32_t preserve_alpha;
};

struct SVGFEConvolveMatrixEdgeModeNone_Body {
  struct FilterOpGraphNode node;
  int32_t order_x;
  int32_t order_y;
  float kernel[25];
  float divisor;
  float bias;
  int32_t target_x;
  int32_t target_y;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  int32_t preserve_alpha;
};

struct SVGFEConvolveMatrixEdgeModeWrap_Body {
  struct FilterOpGraphNode node;
  int32_t order_x;
  int32_t order_y;
  float kernel[25];
  float divisor;
  float bias;
  int32_t target_x;
  int32_t target_y;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  int32_t preserve_alpha;
};

struct SVGFEDiffuseLightingDistant_Body {
  struct FilterOpGraphNode node;
  float surface_scale;
  float diffuse_constant;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  float azimuth;
  float elevation;
};

struct SVGFEDiffuseLightingPoint_Body {
  struct FilterOpGraphNode node;
  float surface_scale;
  float diffuse_constant;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  float x;
  float y;
  float z;
};

struct SVGFEDiffuseLightingSpot_Body {
  struct FilterOpGraphNode node;
  float surface_scale;
  float diffuse_constant;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  float x;
  float y;
  float z;
  float points_at_x;
  float points_at_y;
  float points_at_z;
  float cone_exponent;
  float limiting_cone_angle;
};

struct SVGFEDisplacementMap_Body {
  struct FilterOpGraphNode node;
  float scale;
  uint32_t x_channel_selector;
  uint32_t y_channel_selector;
};

struct SVGFEDropShadow_Body {
  struct FilterOpGraphNode node;
  struct ColorF color;
  float dx;
  float dy;
  float std_deviation_x;
  float std_deviation_y;
};

struct SVGFEFlood_Body {
  struct FilterOpGraphNode node;
  struct ColorF color;
};

struct SVGFEGaussianBlur_Body {
  struct FilterOpGraphNode node;
  float std_deviation_x;
  float std_deviation_y;
};

struct SVGFEImage_Body {
  struct FilterOpGraphNode node;
  uint32_t sampling_filter;
  float matrix[6];
};

struct SVGFEMorphologyDilate_Body {
  struct FilterOpGraphNode node;
  float radius_x;
  float radius_y;
};

struct SVGFEMorphologyErode_Body {
  struct FilterOpGraphNode node;
  float radius_x;
  float radius_y;
};

struct SVGFEOffset_Body {
  struct FilterOpGraphNode node;
  float offset_x;
  float offset_y;
};

struct SVGFESpecularLightingDistant_Body {
  struct FilterOpGraphNode node;
  float surface_scale;
  float specular_constant;
  float specular_exponent;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  float azimuth;
  float elevation;
};

struct SVGFESpecularLightingPoint_Body {
  struct FilterOpGraphNode node;
  float surface_scale;
  float specular_constant;
  float specular_exponent;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  float x;
  float y;
  float z;
};

struct SVGFESpecularLightingSpot_Body {
  struct FilterOpGraphNode node;
  float surface_scale;
  float specular_constant;
  float specular_exponent;
  float kernel_unit_length_x;
  float kernel_unit_length_y;
  float x;
  float y;
  float z;
  float points_at_x;
  float points_at_y;
  float points_at_z;
  float cone_exponent;
  float limiting_cone_angle;
};

struct SVGFETile_Body {
  struct FilterOpGraphNode node;
};

struct SVGFETurbulenceWithFractalNoiseWithNoStitching_Body {
  struct FilterOpGraphNode node;
  float base_frequency_x;
  float base_frequency_y;
  uint32_t num_octaves;
  uint32_t seed;
};

struct SVGFETurbulenceWithFractalNoiseWithStitching_Body {
  struct FilterOpGraphNode node;
  float base_frequency_x;
  float base_frequency_y;
  uint32_t num_octaves;
  uint32_t seed;
};

struct SVGFETurbulenceWithTurbulenceNoiseWithNoStitching_Body {
  struct FilterOpGraphNode node;
  float base_frequency_x;
  float base_frequency_y;
  uint32_t num_octaves;
  uint32_t seed;
};

struct SVGFETurbulenceWithTurbulenceNoiseWithStitching_Body {
  struct FilterOpGraphNode node;
  float base_frequency_x;
  float base_frequency_y;
  uint32_t num_octaves;
  uint32_t seed;
};

struct FilterOp {
  enum FilterOp_Tag tag;
  union {
    struct Blur_Body blur;
    struct {
      float brightness;
    };
    struct {
      float contrast;
    };
    struct {
      float grayscale;
    };
    struct {
      float hue_rotate;
    };
    struct {
      float invert;
    };
    struct Opacity_Body opacity;
    struct {
      float saturate;
    };
    struct {
      float sepia;
    };
    struct {
      struct Shadow drop_shadow;
    };
    struct {
      float color_matrix[20];
    };
    struct {
      struct ColorF flood;
    };
    struct SVGFESourceGraphic_Body svgfe_source_graphic;
    struct SVGFESourceAlpha_Body svgfe_source_alpha;
    struct SVGFEIdentity_Body svgfe_identity;
    struct SVGFEOpacity_Body svgfe_opacity;
    struct SVGFEToAlpha_Body svgfe_to_alpha;
    struct SVGFEBlendDarken_Body svgfe_blend_darken;
    struct SVGFEBlendLighten_Body svgfe_blend_lighten;
    struct SVGFEBlendMultiply_Body svgfe_blend_multiply;
    struct SVGFEBlendNormal_Body svgfe_blend_normal;
    struct SVGFEBlendScreen_Body svgfe_blend_screen;
    struct SVGFEBlendOverlay_Body svgfe_blend_overlay;
    struct SVGFEBlendColorDodge_Body svgfe_blend_color_dodge;
    struct SVGFEBlendColorBurn_Body svgfe_blend_color_burn;
    struct SVGFEBlendHardLight_Body svgfe_blend_hard_light;
    struct SVGFEBlendSoftLight_Body svgfe_blend_soft_light;
    struct SVGFEBlendDifference_Body svgfe_blend_difference;
    struct SVGFEBlendExclusion_Body svgfe_blend_exclusion;
    struct SVGFEBlendHue_Body svgfe_blend_hue;
    struct SVGFEBlendSaturation_Body svgfe_blend_saturation;
    struct SVGFEBlendColor_Body svgfe_blend_color;
    struct SVGFEBlendLuminosity_Body svgfe_blend_luminosity;
    struct SVGFEColorMatrix_Body svgfe_color_matrix;
    struct SVGFEComponentTransfer_Body svgfe_component_transfer;
    struct SVGFECompositeArithmetic_Body svgfe_composite_arithmetic;
    struct SVGFECompositeATop_Body svgfe_composite_a_top;
    struct SVGFECompositeIn_Body svgfe_composite_in;
    struct SVGFECompositeLighter_Body svgfe_composite_lighter;
    struct SVGFECompositeOut_Body svgfe_composite_out;
    struct SVGFECompositeOver_Body svgfe_composite_over;
    struct SVGFECompositeXOR_Body svgfe_composite_xor;
    struct SVGFEConvolveMatrixEdgeModeDuplicate_Body svgfe_convolve_matrix_edge_mode_duplicate;
    struct SVGFEConvolveMatrixEdgeModeNone_Body svgfe_convolve_matrix_edge_mode_none;
    struct SVGFEConvolveMatrixEdgeModeWrap_Body svgfe_convolve_matrix_edge_mode_wrap;
    struct SVGFEDiffuseLightingDistant_Body svgfe_diffuse_lighting_distant;
    struct SVGFEDiffuseLightingPoint_Body svgfe_diffuse_lighting_point;
    struct SVGFEDiffuseLightingSpot_Body svgfe_diffuse_lighting_spot;
    struct SVGFEDisplacementMap_Body svgfe_displacement_map;
    struct SVGFEDropShadow_Body svgfe_drop_shadow;
    struct SVGFEFlood_Body svgfe_flood;
    struct SVGFEGaussianBlur_Body svgfe_gaussian_blur;
    struct SVGFEImage_Body svgfe_image;
    struct SVGFEMorphologyDilate_Body svgfe_morphology_dilate;
    struct SVGFEMorphologyErode_Body svgfe_morphology_erode;
    struct SVGFEOffset_Body svgfe_offset;
    struct SVGFESpecularLightingDistant_Body svgfe_specular_lighting_distant;
    struct SVGFESpecularLightingPoint_Body svgfe_specular_lighting_point;
    struct SVGFESpecularLightingSpot_Body svgfe_specular_lighting_spot;
    struct SVGFETile_Body svgfe_tile;
    struct SVGFETurbulenceWithFractalNoiseWithNoStitching_Body svgfe_turbulence_with_fractal_noise_with_no_stitching;
    struct SVGFETurbulenceWithFractalNoiseWithStitching_Body svgfe_turbulence_with_fractal_noise_with_stitching;
    struct SVGFETurbulenceWithTurbulenceNoiseWithNoStitching_Body svgfe_turbulence_with_turbulence_noise_with_no_stitching;
    struct SVGFETurbulenceWithTurbulenceNoiseWithStitching_Body svgfe_turbulence_with_turbulence_noise_with_stitching;
  };
};

struct WrFilterData {
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
};

/**
 * Configure whether the contents of a stacking context
 * should be rasterized in local space or screen space.
 * Local space rasterized pictures are typically used
 * when we want to cache the output, and performance is
 * important. Note that this is a performance hint only,
 * which WR may choose to ignore.
 */
enum RasterSpace_Tag {
  Local,
  Screen,
};
typedef uint8_t RasterSpace_Tag;

union RasterSpace {
  RasterSpace_Tag tag;
  struct {
    RasterSpace_Tag local_tag;
    float local;
  };
};

struct WrClipId {
  uintptr_t id;
};

struct ImageMask {
  struct ImageKey image;
  LayoutRect rect;
};

typedef struct Point2D_f32__LayoutPixel LayoutPoint;

struct BorderRadius {
  LayoutSize top_left;
  LayoutSize top_right;
  LayoutSize bottom_left;
  LayoutSize bottom_right;
};

struct ComplexClipRegion {
  /**
   * The boundaries of the rectangle.
   */
  LayoutRect rect;
  /**
   * Border radii of this rectangle.
   */
  struct BorderRadius radii;
  /**
   * Whether we are clipping inside or outside
   * the region.
   */
  enum ClipMode mode;
};

/**
 * The minimum and maximum allowable offset for a sticky frame in a single dimension.
 */
struct StickyOffsetBounds {
  /**
   * The minimum offset for this frame, typically a negative value, which specifies how
   * far in the negative direction the sticky frame can offset its contents in this
   * dimension.
   */
  float min;
  /**
   * The maximum offset for this frame, typically a positive value, which specifies how
   * far in the positive direction the sticky frame can offset its contents in this
   * dimension.
   */
  float max;
};

typedef uint64_t APZScrollGeneration;

struct WrSpaceAndClipChain {
  struct WrSpatialId space;
  uint64_t clip_chain;
};

typedef ColorDepth WrColorDepth;

typedef YuvColorSpace WrYuvColorSpace;

typedef ColorRange WrColorRange;

typedef uint32_t GlyphIndex;

struct GlyphInstance {
  GlyphIndex index;
  LayoutPoint point;
};

struct GlyphOptions {
  FontRenderMode render_mode;
  struct FontInstanceFlags flags;
};

/**
 * A group of 2D side offsets, which correspond to top/right/bottom/left for borders, padding,
 * and margins in CSS, optionally tagged with a unit.
 */
struct SideOffsets2D_f32__LayoutPixel {
  float top;
  float right;
  float bottom;
  float left;
};

typedef struct SideOffsets2D_f32__LayoutPixel LayoutSideOffsets;

struct BorderSide {
  struct ColorF color;
  BorderStyle style;
};

/**
 * A group of 2D side offsets, which correspond to top/right/bottom/left for borders, padding,
 * and margins in CSS, optionally tagged with a unit.
 */
struct SideOffsets2D_i32__DevicePixel {
  int32_t top;
  int32_t right;
  int32_t bottom;
  int32_t left;
};

typedef struct SideOffsets2D_i32__DevicePixel DeviceIntSideOffsets;

struct WrBorderImage {
  LayoutSideOffsets widths;
  WrImageKey image;
  ImageRendering image_rendering;
  int32_t width;
  int32_t height;
  bool fill;
  DeviceIntSideOffsets slice;
  RepeatMode repeat_horizontal;
  RepeatMode repeat_vertical;
};

struct GradientStop {
  float offset;
  struct ColorF color;
};

/**
 * An identifier used to refer to previously sent display items. Currently it
 * refers to individual display items, but this may change later.
 */
typedef uint16_t ItemKey;

/**
 * A 2d Point tagged with a unit.
 */
struct Point2D_f32__WorldPixel {
  float x;
  float y;
};

typedef struct Point2D_f32__WorldPixel WorldPoint;

/**
 * See the crate's top level documentation for a description of this type.
 */
struct ThinVec_HitResult {
  struct Header *ptr;
};

typedef struct Vec_u8 VecU8;

typedef struct Arc_VecU8 ArcVecU8;

/**
 * A 2d Point tagged with a unit.
 */
struct Point2D_i32__Tiles {
  int32_t x;
  int32_t y;
};

typedef struct Point2D_i32__Tiles TileOffset;

struct MutByteSlice {
  uint8_t *buffer;
  uintptr_t len;
};

struct FontVariation {
  uint32_t tag;
  float value;
};

/**
 * Width and height in device pixels of image tiles.
 */
typedef uint16_t TileSize;



/**
 * The default tile size for blob images and regular images larger than
 * the maximum texture size.
 */
#define DEFAULT_TILE_SIZE 512





extern int __android_log_write(int prio, const char *tag, const char *text);

void wr_vec_u8_push_bytes(struct WrVecU8 *v, struct ByteSlice bytes);

void wr_vec_u8_reserve(struct WrVecU8 *v, uintptr_t len);

void wr_vec_u8_free(struct WrVecU8 v);

extern struct WrExternalImage wr_renderer_lock_external_image(void *renderer,
                                                              struct ExternalImageId external_image_id,
                                                              uint8_t channel_index,
                                                              bool is_composited);

extern void wr_renderer_unlock_external_image(void *renderer,
                                              struct ExternalImageId external_image_id,
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

extern void gfx_wr_set_crash_annotation(enum CrashAnnotation annotation, const char *value);

extern void gfx_wr_clear_crash_annotation(enum CrashAnnotation annotation);

extern void wr_notifier_wake_up(struct WrWindowId window_id, bool composite_needed);

extern void wr_notifier_new_frame_ready(struct WrWindowId window_id,
                                        struct FramePublishId publish_id,
                                        const struct FrameReadyParams *params);

extern void wr_notifier_external_event(struct WrWindowId window_id, uintptr_t raw_event);

extern void wr_schedule_render(struct WrWindowId window_id, struct RenderReasons reasons);

extern void wr_schedule_frame_after_scene_build(struct WrWindowId window_id,
                                                struct WrPipelineInfo *pipeline_info);

extern void wr_transaction_notification_notified(uintptr_t handler, Checkpoint when);

void wr_renderer_set_clear_color(Renderer *renderer, struct ColorF color);

void wr_renderer_set_external_image_handler(Renderer *renderer,
                                            struct WrExternalImageHandler *external_image_handler);

void wr_renderer_update(Renderer *renderer);

void wr_renderer_set_target_frame_publish_id(Renderer *renderer, struct FramePublishId publish_id);

bool wr_renderer_render(Renderer *renderer,
                        int32_t width,
                        int32_t height,
                        uintptr_t buffer_age,
                        RendererStats *out_stats,
                        struct ThinVec_DeviceIntRect *out_dirty_rects,
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
                                                  struct ColorF color);

extern void wr_compositor_destroy_surface(void *compositor, NativeSurfaceId id);

extern void wr_compositor_create_tile(void *compositor, NativeSurfaceId id, int32_t x, int32_t y);

extern void wr_compositor_destroy_tile(void *compositor, NativeSurfaceId id, int32_t x, int32_t y);

extern void wr_compositor_attach_external_image(void *compositor,
                                                NativeSurfaceId id,
                                                struct ExternalImageId external_image);

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
                                            struct ColorF clear_color,
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
                                           struct ExternalImageId external_image_id,
                                           SWGLCompositeSurfaceInfo *composite_info);

extern void wr_swgl_unlock_composite_surface(void *ctx, struct ExternalImageId external_image_id);

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

void wr_api_set_debug_flags(struct DocumentHandle *dh, struct DebugFlags flags);

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
                                     struct BuiltDisplayListDescriptor dl_descriptor,
                                     struct WrVecU8 *dl_items_data,
                                     struct WrVecU8 *dl_cache_data,
                                     struct WrVecU8 *dl_spatial_tree_data);

void wr_transaction_set_document_view(Transaction *txn, const DeviceIntRect *doc_rect);

void wr_transaction_generate_frame(Transaction *txn,
                                   uint64_t id,
                                   bool present,
                                   bool tracked,
                                   struct RenderReasons reasons);

void wr_transaction_invalidate_rendered_frame(Transaction *txn, struct RenderReasons reasons);

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
                                 struct ExternalScrollId scroll_id,
                                 const struct ThinVec_SampledScrollOffset *sampled_scroll_offsets);

void wr_transaction_set_is_transform_async_zooming(Transaction *txn,
                                                   uint64_t animation_id,
                                                   bool is_zooming);

void wr_transaction_add_minimap_data(Transaction *txn,
                                     struct ExternalScrollId scroll_id,
                                     struct MinimapData minimap_data);

void wr_transaction_set_quality_settings(Transaction *txn, bool force_subpixel_aa_where_possible);

void wr_resource_updates_add_image(Transaction *txn,
                                   WrImageKey image_key,
                                   const struct WrImageDescriptor *descriptor,
                                   struct WrVecU8 *bytes);

void wr_resource_updates_add_blob_image(Transaction *txn,
                                        struct BlobImageKey image_key,
                                        const struct WrImageDescriptor *descriptor,
                                        uint16_t tile_size,
                                        struct WrVecU8 *bytes,
                                        DeviceIntRect visible_rect);

void wr_resource_updates_add_external_image(Transaction *txn,
                                            WrImageKey image_key,
                                            const struct WrImageDescriptor *descriptor,
                                            struct ExternalImageId external_image_id,
                                            const union ExternalImageType *image_type,
                                            uint8_t channel_index,
                                            bool normalized_uvs);

void wr_resource_updates_update_image(Transaction *txn,
                                      WrImageKey key,
                                      const struct WrImageDescriptor *descriptor,
                                      struct WrVecU8 *bytes);

void wr_resource_updates_set_blob_image_visible_area(Transaction *txn,
                                                     struct BlobImageKey key,
                                                     const DeviceIntRect *area);

void wr_resource_updates_update_external_image(Transaction *txn,
                                               WrImageKey key,
                                               const struct WrImageDescriptor *descriptor,
                                               struct ExternalImageId external_image_id,
                                               const union ExternalImageType *image_type,
                                               uint8_t channel_index,
                                               bool normalized_uvs);

void wr_resource_updates_update_external_image_with_dirty_rect(Transaction *txn,
                                                               WrImageKey key,
                                                               const struct WrImageDescriptor *descriptor,
                                                               struct ExternalImageId external_image_id,
                                                               const union ExternalImageType *image_type,
                                                               uint8_t channel_index,
                                                               bool normalized_uvs,
                                                               DeviceIntRect dirty_rect);

void wr_resource_updates_update_blob_image(Transaction *txn,
                                           struct BlobImageKey image_key,
                                           const struct WrImageDescriptor *descriptor,
                                           struct WrVecU8 *bytes,
                                           DeviceIntRect visible_rect,
                                           LayoutIntRect dirty_rect);

void wr_resource_updates_delete_image(Transaction *txn, WrImageKey key);

void wr_resource_updates_delete_blob_image(Transaction *txn, struct BlobImageKey key);

void wr_resource_updates_add_snapshot_image(Transaction *txn, struct SnapshotImageKey image_key);

void wr_resource_updates_delete_snapshot_image(Transaction *txn, struct SnapshotImageKey key);

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
                                           const struct FontInstanceOptions *options,
                                           const struct FontInstancePlatformOptions *platform_options,
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
                                               const struct FilterOp *filters,
                                               uintptr_t filter_count,
                                               const struct WrFilterData *filter_datas,
                                               uintptr_t filter_datas_count,
                                               union RasterSpace glyph_raster_space);

void wr_dp_push_debug(struct WrState *state, uint32_t val);

void wr_dp_pop_stacking_context(struct WrState *state, bool is_reference_frame);

uint64_t wr_dp_define_clipchain(struct WrState *state,
                                const uint64_t *parent_clipchain_id,
                                const struct WrClipId *clips,
                                uintptr_t clips_count);

struct WrClipId wr_dp_define_image_mask_clip_with_parent_clip_chain(struct WrState *state,
                                                                    struct WrSpatialId space,
                                                                    struct ImageMask mask,
                                                                    const LayoutPoint *points,
                                                                    uintptr_t point_count,
                                                                    FillRule fill_rule);

struct WrClipId wr_dp_define_rounded_rect_clip(struct WrState *state,
                                               struct WrSpatialId space,
                                               struct ComplexClipRegion complex);

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
                                             struct StickyOffsetBounds vertical_bounds,
                                             struct StickyOffsetBounds horizontal_bounds,
                                             LayoutVector2D applied_offset,
                                             struct SpatialTreeItemKey key,
                                             const struct WrAnimationProperty *animation);

struct WrSpatialId wr_dp_define_scroll_layer(struct WrState *state,
                                             uint64_t external_scroll_id,
                                             const struct WrSpatialId *parent,
                                             LayoutRect content_rect,
                                             LayoutRect clip_rect,
                                             LayoutVector2D scroll_offset,
                                             APZScrollGeneration scroll_offset_generation,
                                             HasScrollLinkedEffect has_scroll_linked_effect,
                                             struct SpatialTreeItemKey key);

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
                     struct ColorF color);

void wr_dp_push_rect_with_animation(struct WrState *state,
                                    LayoutRect rect,
                                    LayoutRect clip,
                                    bool is_backface_visible,
                                    const struct WrSpaceAndClipChain *parent,
                                    struct ColorF color,
                                    const struct WrAnimationProperty *animation);

void wr_dp_push_backdrop_filter(struct WrState *state,
                                LayoutRect rect,
                                LayoutRect clip,
                                bool is_backface_visible,
                                const struct WrSpaceAndClipChain *parent,
                                const struct FilterOp *filters,
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
                      struct ColorF color,
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
                                struct ColorF color);

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
                     struct ColorF color,
                     WrFontInstanceKey font_key,
                     const struct GlyphInstance *glyphs,
                     uint32_t glyph_count,
                     const struct GlyphOptions *glyph_options);

void wr_dp_push_shadow(struct WrState *state,
                       LayoutRect _bounds,
                       LayoutRect _clip,
                       bool _is_backface_visible,
                       const struct WrSpaceAndClipChain *parent,
                       struct Shadow shadow,
                       bool should_inflate);

void wr_dp_pop_all_shadows(struct WrState *state);

void wr_dp_push_line(struct WrState *state,
                     const LayoutRect *clip,
                     bool is_backface_visible,
                     const struct WrSpaceAndClipChain *parent,
                     const LayoutRect *bounds,
                     float wavy_line_thickness,
                     LineOrientation orientation,
                     const struct ColorF *color,
                     LineStyle style);

void wr_dp_push_border(struct WrState *state,
                       LayoutRect rect,
                       LayoutRect clip,
                       bool is_backface_visible,
                       const struct WrSpaceAndClipChain *parent,
                       enum AntialiasBorder do_aa,
                       LayoutSideOffsets widths,
                       struct BorderSide top,
                       struct BorderSide right,
                       struct BorderSide bottom,
                       struct BorderSide left,
                       struct BorderRadius radius);

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
                                const struct GradientStop *stops,
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
                                       const struct GradientStop *stops,
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
                                      const struct GradientStop *stops,
                                      uintptr_t stops_count,
                                      ExtendMode extend_mode);

void wr_dp_push_linear_gradient(struct WrState *state,
                                LayoutRect rect,
                                LayoutRect clip,
                                bool is_backface_visible,
                                const struct WrSpaceAndClipChain *parent,
                                LayoutPoint start_point,
                                LayoutPoint end_point,
                                const struct GradientStop *stops,
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
                                const struct GradientStop *stops,
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
                               const struct GradientStop *stops,
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
                           struct ColorF color,
                           float blur_radius,
                           float spread_radius,
                           struct BorderRadius border_radius,
                           struct BorderRadius shadow_radius,
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
                        struct BuiltDisplayListDescriptor *dl_descriptor,
                        struct WrVecU8 *dl_items_data,
                        struct WrVecU8 *dl_cache_data,
                        struct WrVecU8 *dl_spatial_tree);

void wr_api_hit_test(struct DocumentHandle *dh,
                     WorldPoint point,
                     struct ThinVec_HitResult *out_results);

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
                        const struct FontInstanceOptions *options,
                        const struct FontInstancePlatformOptions *platform_options,
                        const struct FontVariation *variations,
                        uintptr_t num_variations);

extern void DeleteBlobFont(WrFontInstanceKey key);

extern void ClearBlobImageResources(WrIdNamespace namespace_);

extern void gfx_wr_set_crash_annotation(enum CrashAnnotation annotation, const char *value);

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
