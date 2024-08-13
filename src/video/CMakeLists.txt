project(gallery_video_src)

set(GALLERY_VIDEO_LIB gallery-video)

include_directories(
    ${gallery_core_src_SOURCE_DIR}
    ${gallery_media_src_SOURCE_DIR}
    ${gallery_util_src_SOURCE_DIR}
    ${CMAKE_BINARY_DIR}
    )

set(gallery_video_SRCS
    video.cpp
    )

add_library(${GALLERY_VIDEO_LIB}
    ${gallery_video_MOC_SRCS}
    ${gallery_video_SRCS}
    )

target_link_libraries(${GALLERY_VIDEO_LIB}
    Qt5::Core
    Qt5::Qml
    Qt5::Widgets
    )
