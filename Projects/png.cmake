add_external_project_or_use_system(png
  DEPENDS zlib

  CMAKE_ARGS
    -DPNG_TESTS:BOOL=OFF
    # VTK uses API that gets hidden when PNG_NO_STDIO is TRUE (default).
    -DPNG_NO_STDIO:BOOL=OFF
  )
