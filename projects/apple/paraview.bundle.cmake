set(paraview_doc_dir "paraview.app/Contents/doc")
set(paraview_data_dir "paraview.app/Contents/data")
include(paraview.bundle.common)

if (NOT paraview_has_gui)
  message(FATAL_ERROR "Creating the Apple package without the GUI is not supported.")
endif ()

superbuild_apple_create_app(
  "\${CMAKE_INSTALL_PREFIX}"
  "paraview.app"
  "${superbuild_install_location}/Applications/paraview.app/Contents/MacOS/paraview"
  CLEAN
  SEARCH_DIRECTORIES "${superbuild_install_location}/lib")

install(
  FILES       "${superbuild_install_location}/Applications/paraview.app/Contents/Resources/pvIcon.icns"
  DESTINATION "paraview.app/Contents/Resources"
  COMPONENT   superbuild)
install(
  FILES       "${superbuild_install_location}/Applications/paraview.app/Contents/Info.plist"
  DESTINATION "paraview.app/Contents"
  COMPONENT   superbuild)

# Remove "paraview" from the list since we just installed it above.
list(REMOVE_ITEM paraview_executables
  paraview)

foreach (executable IN LISTS paraview_executables)
  superbuild_apple_install_utility(
    "\${CMAKE_INSTALL_PREFIX}"
    "paraview.app"
    "${superbuild_install_location}/Applications/paraview.app/Contents/bin/${executable}"
    SEARCH_DIRECTORIES "${superbuild_install_location}/lib")
endforeach ()

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/qt.conf" "")
install(
  FILES       "${CMAKE_CURRENT_BINARY_DIR}/qt.conf"
  DESTINATION "paraview.app/Contents/Resources/qt.conf"
  COMPONENT   superbuild)

if (python_enabled)
  superbuild_apple_install_python(
    "\${CMAKE_INSTALL_PREFIX}"
    "paraview.app"
    MODULES paraview
            vtk
            ${python_modules}
    MODULE_DIRECTORIES
            "${superbuild_install_location}/Applications/paraview.app/Contents/Python"
    SEARCH_DIRECTORIES
            "${superbuild_install_location}/Applications/paraview.app/Contents/Libraries")

  if (matplotlib_enabled)
    install(
      DIRECTORY   "${superbuild_install_location}/lib/python2.7/site-packages/matplotlib/mpl-data/"
      DESTINATION "Python/matplotlib/mpl-data"
      COMPONENT   superbuild)
  endif ()
endif ()

if (mpi_enabled AND NOT USE_SYSTEM_mpi)
  set(mpi_executables
    hydra_pmi_proxy
    mpiexec.hydra)

  foreach (mpi_executable IN LISTS mpi_executables)
    superbuild_apple_install_utility(
      "\${CMAKE_INSTALL_PREFIX}"
      "paraview.app"
      "${superbuild_install_location}/bin/${mpi_executable}"
      SEARCH_DIRECTORIES "${superbuild_install_location}/lib")
  endforeach ()

  file(RENAME
    \"\${CMAKE_INSTALL_PREFIX}/paraview.app/Contents/MacOS/mpiexec.hydra\"
    \"\${CMAKE_INSTALL_PREFIX}/paraview.app/Contents/MacOS/mpiexec\")
endif ()

install(
  FILES       "${CMAKE_CURRENT_LIST_DIR}/files/background.png"
  DESTINATION ".resources/"
  COMPONENT   superbuild)
install(
  FILES       "${CMAKE_CURRENT_LIST_DIR}/DS_Store"
  DESTINATION ".DS_Store"
  COMPONENT   superbuild)
