-- =============================================================================
-- Extra Environment Variables - NVIDIA (not tracked by git)
-- =============================================================================

-- NVIDIA VA-API driver
hl.env("LIBVA_DRIVER_NAME", "nvidia")

-- Force NVIDIA GLX vendor
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- NVIDIA Video Decode backend
hl.env("NVD_BACKEND", "direct")

-- WebKitGTK: black windows with the DMA-BUF renderer on NVIDIA
hl.env("WEBKIT_DISABLE_DMABUF_RENDERER", "1")

-- Hybrid systems (Intel + NVIDIA): uncomment and adjust
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu")
