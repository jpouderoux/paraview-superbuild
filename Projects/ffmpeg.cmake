add_external_project(
  ffmpeg
  DEPENDS zlib
  CONFIGURE_COMMAND "<SOURCE_DIR>/configure
                    --prefix=<INSTALL_DIR>
                    --disable-avdevice
                    --disable-bzlib
                    --disable-decoders
                    --disable-doc
                    --disable-ffplay
                    --disable-ffprobe
                    --disable-ffserver
                    --disable-network
                    --disable-static
                    --enable-shared
                    --disable-yasm
                    --cc=${CMAKE_C_COMPILER}
                    \"--extra-cflags=${cppflags}\"
                    \"--extra-ldflags=${ldflags}\"
                    ${extra_commands}"
  BUILD_IN_SOURCE 1
)
