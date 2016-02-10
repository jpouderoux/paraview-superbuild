include(PVExternalProject)
include(CMakeParseArguments)

#------------------------------------------------------------------------------
# Macro to be used to register versions for any module. This makes it easier to
# consolidate versions for all modules in a single file, if needed.
macro(add_revision name)
  set(${name}_revision "${ARGN}")
endmacro()

#------------------------------------------------------------------------------
# Use this macro instead of the add_revision() macro when adding
# a source repo to add advanced options for the user to change the default
# selections. Currently advanced options are added for
# CVS_REPOSITORY, CVS_MODULE, CVS_TAG, SVN_REVISION, SVN_REVISION,
# GIT_REPOSITORY, GIT_TAG, HG_REPOSITORY, HG_TAG, URL, URL_HASH, and URL_MD5.
#------------------------------------------------------------------------------
function(add_customizable_revision name)
  # ExternalProject_Add arguments
  #[CVS_REPOSITORY cvsroot]    # CVSROOT of CVS repository
  #[CVS_MODULE mod]            # Module to checkout from CVS repo
  #[CVS_TAG tag]               # Tag to checkout from CVS repo
  #[SVN_REPOSITORY url]        # URL of Subversion repo
  #[SVN_REVISION rev]          # Revision to checkout from Subversion repo
  #[SVN_USERNAME john ]        # Username for Subversion checkout and update
  #[SVN_PASSWORD doe ]         # Password for Subversion checkout and update
  #[SVN_TRUST_CERT 1 ]         # Trust the Subversion server site certificate
  #[GIT_REPOSITORY url]        # URL of git repo
  #[GIT_TAG tag]               # Git branch name, commit id or tag
  #[GIT_SUBMODULES modules...] # Git submodules that shall be updated, all if empty
  #[HG_REPOSITORY url]         # URL of mercurial repo
  #[HG_TAG tag]                # Mercurial branch name, commit id or tag
  #[URL /.../src.tgz]          # Full path or URL of source
  #[URL_HASH ALGO=value]       # Hash of file at URL
  #[URL_MD5 md5]               # Equivalent to URL_HASH MD5=md5
  #[SOURCE_DIR]                # Source dir to be used for build

  set (args
    CVS_REPOSITORY CVS_MODULE CVS_TAG
    SVN_REPOSITORY SVN_REVISION
    GIT_REPOSITORY GIT_TAG
    HG_REPOSITORY HG_TAG
    URL URL_HASH URL_MD5
    SOURCE_DIR)
  cmake_parse_arguments(_args "" "${args}" "" ${ARGN})
  set (CUSTOMIZED_ARGN)
  string(TOUPPER "${name}" name_UPPER)
  foreach (key IN LISTS args)
    if (_args_${key})
      set (option_name "${name_UPPER}_${key}")
      set (option_default "${_args_${key}}")
      set(${option_name} "${option_default}" CACHE STRING "${key} for project '${name}'")
      mark_as_advanced(${option_name})
      list(APPEND CUSTOMIZED_ARGN ${key} ${${option_name}})
    endif()
  endforeach()

  set (${name}_revision ${CUSTOMIZED_ARGN} ${_args_UNPARSED_ARGUMENTS} PARENT_SCOPE)
endfunction()

#------------------------------------------------------------------------------
macro(add_external_project _name)
  project_check_name(${_name})
  set(cm-project ${_name})
  set(${cm-project}_DECLARED 1)

  if (build-projects)
    # Here we do two things:
    # - resolve the enabled optional dependencies for the project specified by the
    #   DEPENDS_OPTIONAL argument 
    # - prune the DEPENDS_OPTIONAL and HELP_STRING arguments from the project arguments because
    #   these are unknown to the ExternalProject_Add() command that is ultimately called
    set (arguments)
    set (optional_depends)
    set (accumulate FALSE)
    set (discard FALSE)
    set (project_arguments "${ARGN}") #need quotes to keep empty list items
    foreach(arg IN LISTS project_arguments)
      if (arg STREQUAL "DEPENDS_OPTIONAL")
        set (accumulate TRUE)
      elseif (arg STREQUAL "HELP_STRING")
        set (discard TRUE)
      elseif (arg MATCHES "${_ep_keywords_ExternalProject_Add}")
        set (accumulate FALSE)
        set (discard FALSE)
      elseif (accumulate)
        list(APPEND optional_depends "${arg}")
      endif()

      if (NOT accumulate AND NOT discard)
        list(APPEND arguments "${arg}")
      endif()
    endforeach()

    foreach (op_dep ${optional_depends})
      if (${op_dep}_ENABLED)
        list (APPEND arguments DEPENDS ${op_dep})
        #message(STATUS "OPTIONAL DEPENDENCY ${cm-project}->${op_dep}")
      endif()
    endforeach()
    set(${cm-project}_ARGUMENTS "${arguments}")

    unset(arguments)
    unset(optional_depends)
    unset(accumulate)
  else()
    set(${cm-project}_DEPENDS "")
    set(${cm-project}_ARGUMENTS "")
    set(${cm-project}_NEEDED_BY "")
    set(${cm-project}_DEPENDS_ANY "")
    set(${cm-project}_DEPENDS_OPTIONAL "")
    set(${cm-project}_CAN_USE_SYSTEM 0)
    set(${cm-project}_HELP_STRING "")
    set (doing "")

    set (project_arguments "${ARGN}") #need quotes to keep empty list items
    foreach(arg IN LISTS project_arguments)
      if (arg STREQUAL "DEPENDS")
        set (doing "DEPENDS")
      elseif (arg STREQUAL "DEPENDS_OPTIONAL")
        set (doing "DEPENDS_OPTIONAL")
      elseif (arg STREQUAL "HELP_STRING")
        set (doing "HELP_STRING")
      elseif (arg MATCHES "${_ep_keywords_ExternalProject_Add}")
        set (doing "")
      elseif (doing STREQUAL "DEPENDS")
        list(APPEND ${cm-project}_DEPENDS "${arg}")
      elseif (doing STREQUAL "DEPENDS_OPTIONAL")
        list(APPEND ${cm-project}_DEPENDS_OPTIONAL "${arg}")
      elseif (doing STREQUAL "HELP_STRING")
        set(${cm-project}_HELP_STRING "${arg}")
      endif()

    endforeach()

    set(help_message ${${cm-project}_HELP_STRING})
    if (NOT help_message)
      set(help_message "Request to build project ${cm-project}")
    endif()
    option(ENABLE_${cm-project} "${help_message}" OFF)
    set_property(CACHE ENABLE_${cm-project} PROPERTY TYPE BOOL)
    list(APPEND CM_PROJECTS_ALL "${cm-project}")

    if (USE_SYSTEM_${cm-project})
      set(${cm-project}_DEPENDS "")
      set(${cm-project}_DEPENDS_OPTIONAL "")
    endif()
    set(${cm-project}_DEPENDS_ANY
      ${${cm-project}_DEPENDS} ${${cm-project}_DEPENDS_OPTIONAL})
  endif()
endmacro()

#------------------------------------------------------------------------------
# adds a dummy project to the build, which is a great way to setup a list
# of dependencies as a build option. IE dummy project that turns on all
# third party libraries
macro(add_external_dummy_project _name)
  if (build-projects)
    add_external_project(${_name} "${ARGN}")
  else()
    add_external_project(${_name} "${ARGN}")
    set_property(GLOBAL PROPERTY ${_name}_IS_DUMMY_PROJECT TRUE)
  endif()
endmacro()

#------------------------------------------------------------------------------
# similar to add_external_project, except provides the user with an option to
# use-system installation of the project.
macro(add_external_project_or_use_system _name)
  if (build-projects)
    add_external_project(${_name} "${ARGN}")
  else()
    add_external_project(${_name} "${ARGN}")
    set(${_name}_CAN_USE_SYSTEM 1)

    # add an option an hide it by default. We'll expose it to the user if needed.
    option(USE_SYSTEM_${_name} "Use system ${_name}" OFF)
    set_property(CACHE USE_SYSTEM_${_name} PROPERTY TYPE INTERNAL)
  endif()
endmacro()

#------------------------------------------------------------------------------
# similar to add_external_project, except it disables the project's build as a
# standalone element of the superbuild and, instead, sets paraview's
# PARAVIEW_EXTERNAL_PLUGIN_DIRS to point to the directory, resulting in the
# project being built within ParaView.
macro(add_external_pv_plugin _name)

  # strip out ParaView dependency, since it is automatic and the flag would
  # otherwise break the build order. Avoid using REMOVE, since the element
  # 'paraview' may be used for other arguments (like branch names).
  # Additionally, apply a user-defined plugin name (useful for ENABLE_ flags,
  # where the provided _name is not the same as the plugin.cmake name), if it
  # is provided.
  set (arguments)
  set (filter FALSE)
  set (reject FALSE)
  set (has_plugin_name FALSE)
  set (plugin_name)
  set (project_arguments "${ARGN}") #need quotes to keep empty list items
  foreach(arg IN LISTS project_arguments)
    if (has_plugin_name)
      set (plugin_name ${arg})
      set (has_plugin_name FALSE)
    elseif (arg STREQUAL "PLUGIN_NAME")
      set (has_plugin_name TRUE)
    elseif (arg STREQUAL "DEPENDS")
      set (filter TRUE)
      list(APPEND arguments "${arg}")
    elseif (arg MATCHES "${_ep_keywords_ExternalProject_Add}")
      set (filter FALSE)
      list(APPEND arguments "${arg}")
    elseif (NOT (filter AND arg STREQUAL "paraview"))
      list(APPEND arguments "${arg}")
    endif()
  endforeach()

  if (NOT plugin_name)
    set (plugin_name ${_name})
  endif()

  # add the project, but null out any configure, build and install instructions
  # (this will be handled by ParaView's build)
  add_external_project(${_name}
    ${arguments}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND "")

  set_property(GLOBAL APPEND PROPERTY pv_plugins "${_name}")

  if (NOT plugin_name)
    set (plugin_name ${_name})
  endif()

  add_extra_cmake_args("-DPARAVIEW_BUILD_PLUGIN_${plugin_name}:BOOL=ON")

endmacro()

#------------------------------------------------------------------------------
macro(process_dependencies)
  set (CM_PROJECTS_ENABLED "")
  foreach(cm-project IN LISTS CM_PROJECTS_ALL)
    set(${cm-project}_ENABLED FALSE)
    if (ENABLE_${cm-project})
      list(APPEND CM_PROJECTS_ENABLED ${cm-project})
    endif()
  endforeach()
  list(SORT CM_PROJECTS_ENABLED) # Deterministic order.

  # Order list to satisfy dependencies.
  # First only use the non-optional dependencies.
  include(TopologicalSort)
  topological_sort(CM_PROJECTS_ENABLED "" _DEPENDS)

  # Now generate a project order using both, optional and non-optional
  # dependencies.
  set (CM_PROJECTS_ORDER ${CM_PROJECTS_ENABLED})
  topological_sort(CM_PROJECTS_ORDER "" _DEPENDS_ANY)

  # Update CM_PROJECTS_ENABLED to be in the correct order taking into
  # consideration optional dependencies.
  set (new_order)
  foreach (cm-project IN LISTS CM_PROJECTS_ORDER)
    list(FIND CM_PROJECTS_ENABLED "${cm-project}" found)
    if (found GREATER -1)
      list(APPEND new_order "${cm-project}")
    endif()
  endforeach()
  set (CM_PROJECTS_ENABLED ${new_order})

  # build information about what project needs what.
  foreach (cm-project IN LISTS CM_PROJECTS_ENABLED)
    enable_project(${cm-project} "")
    foreach (dependency IN LISTS ${cm-project}_DEPENDS)
      enable_project(${dependency} "${cm-project}")
    endforeach()
  endforeach()

  foreach (cm-project IN LISTS CM_PROJECTS_ENABLED)
    if (ENABLE_${cm-project})
      message(STATUS "Enabling ${cm-project} as requested.")
      set_property(CACHE ENABLE_${cm-project} PROPERTY TYPE BOOL)
    else()
      list(SORT ${cm-project}_NEEDED_BY)
      list(REMOVE_DUPLICATES ${cm-project}_NEEDED_BY)
      message(STATUS "Enabling ${cm-project} since needed by: ${${cm-project}_NEEDED_BY}")
      set_property(CACHE ENABLE_${cm-project} PROPERTY TYPE INTERNAL)
    endif()
  endforeach()
  message(STATUS "PROJECTS_ENABLED ${CM_PROJECTS_ENABLED}")
  set (build-projects 1)
  foreach (cm-project IN LISTS CM_PROJECTS_ENABLED)
    get_property(is_dummy GLOBAL PROPERTY ${cm-project}_IS_DUMMY_PROJECT)
    if (${cm-project}_CAN_USE_SYSTEM)
      # for every enabled project that can use system, expose the option to the
      # user.
      set_property(CACHE USE_SYSTEM_${cm-project} PROPERTY TYPE BOOL)
      if (USE_SYSTEM_${cm-project})
        add_external_dummy_project_internal(${cm-project})
        include(${cm-project}.use.system OPTIONAL RESULT_VARIABLE rv)
        if (rv STREQUAL "NOTFOUND")
          message(AUTHOR_WARNING "${cm-project}.use.system not found!!!")
        endif()
      else()
        include(${cm-project})
        add_external_project_internal(${cm-project} "${${cm-project}_ARGUMENTS}")
      endif()
    elseif(is_dummy)
      #this project isn't built, just used as a graph node to
      #represent a group of dependencies
      include(${cm-project})
      add_external_dummy_project_internal(${cm-project})
    else()
      include(${cm-project})
      add_external_project_internal(${cm-project} "${${cm-project}_ARGUMENTS}")
    endif()
  endforeach()
  unset (build-projects)
endmacro()
#------------------------------------------------------------------------------
macro(enable_project name needed-by)
  set (${name}_ENABLED TRUE CACHE INTERNAL "" FORCE)
  list (APPEND ${name}_NEEDED_BY "${needed-by}")
endmacro()

#------------------------------------------------------------------------------
# internal macro to validate project names.
macro(project_check_name _name)
  if( NOT "${_name}" MATCHES "^[a-zA-Z][a-zA-Z0-9]*$")
    message(FATAL_ERROR "Invalid project name: ${_name}")
  endif()
endmacro()

#------------------------------------------------------------------------------
# get dependencies for a project, including optional dependencies that are
# currently enabled. Since this macro looks at the ${mod}_ENABLED flag, it
# cannot be used in the 'processing' pass, but the 'build' pass alone.
macro(get_project_depends _name _prefix)
  if (NOT build-projects)
    message(AUTHOR_WARNING "get_project_depends can only be used in build pass")
  endif()
  if (NOT ${_prefix}_${_name}_done)
    set(${_prefix}_${_name}_done 1)

    # process regular dependencies
    foreach (dep ${${_name}_DEPENDS})
      if (NOT ${_prefix}_${dep}_done)
        list(APPEND ${_prefix}_DEPENDS ${dep})
        get_project_depends(${dep} ${_prefix})
      endif()
    endforeach()

    # process optional dependencies (only consider those that are enabled).
    foreach (dep ${${_name}_DEPENDS_OPTIONAL})
      if (${dep}_ENABLED AND NOT ${_prefix}_${dep}_done)
        list(APPEND ${_prefix}_DEPENDS ${dep})
        get_project_depends(${dep} ${_prefix})
      endif()
    endforeach()
  endif()
endmacro()

#------------------------------------------------------------------------------
function(add_external_dummy_project_internal name)
  set(arg_DEPENDS)
  get_project_depends(${name} arg)
  ExternalProject_Add(${name}
  DEPENDS ${arg_DEPENDS}
  DOWNLOAD_COMMAND ""
  SOURCE_DIR ""
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND ""
  )
endfunction()

#------------------------------------------------------------------------------
function(add_external_project_internal name)
  set (cmake_params)
  foreach (flag CMAKE_BUILD_TYPE
                CMAKE_C_FLAGS_DEBUG
                CMAKE_C_FLAGS_MINSIZEREL
                CMAKE_C_FLAGS_RELEASE
                CMAKE_C_FLAGS_RELWITHDEBINFO
                CMAKE_CXX_FLAGS_DEBUG
                CMAKE_CXX_FLAGS_MINSIZEREL
                CMAKE_CXX_FLAGS_RELEASE
                CMAKE_CXX_FLAGS_RELWITHDEBINFO)
    if (flag)
      list (APPEND cmake_params -D${flag}:STRING=${${flag}})
    endif()
  endforeach()

  if (APPLE)
    list (APPEND cmake_params
      -DCMAKE_OSX_ARCHITECTURES:STRING=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
      -DCMAKE_OSX_SYSROOT:PATH=${CMAKE_OSX_SYSROOT})
  endif()

  #get extra-cmake args from every dependent project, if any.
  set(arg_DEPENDS)
  get_project_depends(${name} arg)
  foreach(dependency IN LISTS arg_DEPENDS)
    get_property(args GLOBAL PROPERTY ${dependency}_CMAKE_ARGS)
    list(APPEND cmake_params ${args})
  endforeach()

  # get extra flags added using append_flags(), if any.
  set (extra_c_flags)
  set (extra_cxx_flags)
  set (extra_ld_flags)

  # scan project flags.
  set (_tmp)
  get_property(_tmp GLOBAL PROPERTY ${name}_APPEND_PROJECT_ONLY_FLAGS_CMAKE_C_FLAGS)
  set (extra_c_flags ${extra_c_flags} ${_tmp})
  get_property(_tmp GLOBAL PROPERTY ${name}_APPEND_PROJECT_ONLY_FLAGS_CMAKE_CXX_FLAGS)
  set (extra_cxx_flags ${extra_cxx_flags} ${_tmp})
  get_property(_tmp GLOBAL PROPERTY ${name}_APPEND_PROJECT_ONLY_FLAGS_LDFLAGS)
  set (extra_ld_flags ${extra_ld_flags} ${_tmp})
  unset(_tmp)

  # scan dependecy flags.
  foreach(dependency IN LISTS arg_DEPENDS)
    get_property(_tmp GLOBAL PROPERTY ${dependency}_APPEND_FLAGS_CMAKE_C_FLAGS)
    set (extra_c_flags ${extra_c_flags} ${_tmp})
    get_property(_tmp GLOBAL PROPERTY ${dependency}_APPEND_FLAGS_CMAKE_CXX_FLAGS)
    set (extra_cxx_flags ${extra_cxx_flags} ${_tmp})
    get_property(_tmp GLOBAL PROPERTY ${dependency}_APPEND_FLAGS_LDFLAGS)
    set (extra_ld_flags ${extra_ld_flags} ${_tmp})
  endforeach()

  set (project_c_flags "${cflags}")
  if (extra_c_flags)
    set (project_c_flags "${cflags} ${extra_c_flags}")
  endif()
  set (project_cxx_flags "${cxxflags}")
  if (extra_cxx_flags)
    set (project_cxx_flags "${cxxflags} ${extra_cxx_flags}")
  endif()
  set (project_ld_flags "${ldflags}")
  if (extra_ld_flags)
    set (project_ld_flags "${ldflags} ${extra_ld_flags}")
  endif()

  #message("ARGS ${name} ${ARGN}")

  # refer to documentation for PASS_LD_LIBRARY_PATH_FOR_BUILDS in
  # in root CMakeLists.txt.
  set (ld_library_path_argument)
  if (PASS_LD_LIBRARY_PATH_FOR_BUILDS)
    set (ld_library_path_argument
      LD_LIBRARY_PATH "${ld_library_path}")
  endif ()


  #args needs to be quoted so that empty list items aren't removed
  #if that happens options like INSTALL_COMMAND "" won't work
  set(args "${ARGN}")
  PVExternalProject_Add(${name} "${args}"
    PREFIX ${name}
    DOWNLOAD_DIR ${download_location}
    INSTALL_DIR ${install_location}

    # add url/mdf/git-repo etc. specified in versions.cmake
    ${${name}_revision}

    PROCESS_ENVIRONMENT
      LDFLAGS "${project_ld_flags}"
      CPPFLAGS "${cppflags}"
      CXXFLAGS "${project_cxx_flags}"
      CFLAGS "${project_c_flags}"
# disabling this since it fails when building numpy.
#      MACOSX_DEPLOYMENT_TARGET "${CMAKE_OSX_DEPLOYMENT_TARGET}"
      ${ld_library_path_argument}
      CMAKE_PREFIX_PATH "${prefix_path}"
    CMAKE_ARGS
      -DCMAKE_INSTALL_PREFIX:PATH=${prefix_path}
      -DCMAKE_PREFIX_PATH:PATH=${prefix_path}
      -DCMAKE_C_FLAGS:STRING=${project_c_flags}
      -DCMAKE_CXX_FLAGS:STRING=${project_cxx_flags}
      -DCMAKE_SHARED_LINKER_FLAGS:STRING=${project_ld_flags}
      ${cmake_params}

    LIST_SEPARATOR "${ep_list_separator}"
    )

  get_property(additional_steps GLOBAL PROPERTY ${name}_STEPS)
  if (additional_steps)
     foreach (step ${additional_steps})
       get_property(step_contents GLOBAL PROPERTY ${name}-STEP-${step})
       ExternalProject_Add_Step(${name} ${step} ${step_contents})
     endforeach()
  endif()
endfunction()

macro(add_extra_cmake_args)
  if (build-projects)
    if (NOT cm-project)
      message(AUTHOR_WARNING "add_extra_cmake_args called an incorrect stage.")
      return()
    endif()
    set_property(GLOBAL APPEND PROPERTY ${cm-project}_CMAKE_ARGS ${ARGN})
  else()
    # nothing to do.
  endif()
endmacro()

#------------------------------------------------------------------------------
# in case of OpenMPI on Windows, for example, we need to pass extra compiler
# flags when building projects that use MPI. This provides an experimental
# mechanism for the same.
# There are two kinds for flags, flag to use to build to the project itself, or
# those to use to build any dependencies. The default is latter. For former,
# pass in an optional argument PROJECT_ONLY.
function(append_flags key value)
  if (NOT "x${key}" STREQUAL "xCMAKE_CXX_FLAGS" AND
      NOT "x${key}" STREQUAL "xCMAKE_C_FLAGS" AND
      NOT "x${key}" STREQUAL "xLDFLAGS")
    message(AUTHOR_WARNING
      "Currently, only CMAKE_CXX_FLAGS, CMAKE_C_FLAGS, and LDFLAGS are supported.")
  endif()
  set (project_only FALSE)
  foreach (arg IN LISTS ARGN)
    if ("${arg}" STREQUAL "PROJECT_ONLY")
      set (project_only TRUE)
    else()
      message(AUTHOR_WARNING "Unknown argument to append_flags(), ${arg}.")
    endif()
  endforeach()

  if (build-projects)
    if (NOT cm-project)
      message(AUTHOR_WARNING "add_extra_cmake_args called an incorrect stage.")
      return()
    endif()
    if (project_only)
      set_property(GLOBAL APPEND PROPERTY
        ${cm-project}_APPEND_PROJECT_ONLY_FLAGS_${key} "${value}")
    else ()
      set_property(GLOBAL APPEND PROPERTY
        ${cm-project}_APPEND_FLAGS_${key} "${value}")
    endif()
  else()
    # nothing to do.
  endif()
endfunction()
#------------------------------------------------------------------------------


macro(add_external_project_step name)
  if (build-projects)
    if (NOT cm-project)
      message(AUTHOR_WARNING "add_external_project_step called an incorrect stage.")
      return()
    endif()
    set_property(GLOBAL APPEND PROPERTY ${cm-project}_STEPS "${name}")
    set_property(GLOBAL APPEND PROPERTY ${cm-project}-STEP-${name} ${ARGN})
  else()
    # nothing to do.
  endif()
endmacro()

#------------------------------------------------------------------------------
# When passing string with ";" to add_external_project() macros, we need to
# ensure that the -+- is replaced with the LIST_SEPARATOR.
macro(sanitize_lists_in_string out_var_prefix var)
  string(REPLACE ";" "${ep_list_separator}" command "${${var}}")
  set (${out_var_prefix}${var} "${command}")
endmacro()
