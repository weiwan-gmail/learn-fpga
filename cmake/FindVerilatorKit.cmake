# Shared Verilator kit locator for cmake-system/ and cmake-conan/.
# Same dual-tree find as weiwan-gmail/rtl-learning-plan cmake/RtlLabSim.cmake:
#
# - Locate the Verilator kit; on Windows always drive verilator_bin.exe PE
#   (withlimon: https://github.com/withlimon/verilator-windows). Never the
#   extensionless Perl `verilator` (Explorer/CMD Open-with trap).
# - include(CheckCXXCompilerFlag) before verilate() (caller).
# - On MSVC, strip GCC-only -fcoroutines* flags Verilator may inject.

include_guard(GLOBAL)

set(RTL_LAB_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}")
get_filename_component(RTL_LAB_REPO_ROOT "${RTL_LAB_CMAKE_DIR}/.." ABSOLUTE)

# MSYS2 names a Perl script share/verilator/bin/verilator_bin.exe. withlimon
# and mingw64/bin ship a real PE (MZ). Only the PE may be executed on Windows.
function(rtl_lab_windows_file_is_pe filepath outvar)
  set(_ok FALSE)
  if(EXISTS "${filepath}")
    file(READ "${filepath}" _magic HEX LIMIT 2)
    string(TOUPPER "${_magic}" _magic)
    if(_magic STREQUAL "4D5A")
      set(_ok TRUE)
    endif()
  endif()
  set(${outvar} ${_ok} PARENT_SCOPE)
endfunction()

function(rtl_lab_find_windows_pe outvar)
  unset(RTL_LAB_VERILATOR_BIN CACHE)
  set(_cands "")
  # Known PE bindirs first. $VERILATOR_ROOT/bin on MSYS2 is the Perl wrapper.
  list(APPEND _cands
    "D:/verilator/bin/verilator_bin.exe"
    "C:/msys64/mingw64/bin/verilator_bin.exe")
  if(DEFINED ENV{VERILATOR_ROOT} AND NOT "$ENV{VERILATOR_ROOT}" STREQUAL "")
    list(APPEND _cands
      "$ENV{VERILATOR_ROOT}/bin/verilator_bin.exe"
      "$ENV{VERILATOR_ROOT}/../bin/verilator_bin.exe"
      "$ENV{VERILATOR_ROOT}/../../bin/verilator_bin.exe")
  endif()
  foreach(_c IN LISTS _cands)
    get_filename_component(_abs "${_c}" ABSOLUTE)
    rtl_lab_windows_file_is_pe("${_abs}" _ispe)
    if(_ispe)
      set(${outvar} "${_abs}" PARENT_SCOPE)
      return()
    endif()
  endforeach()
  find_program(_rtl_path_pe NAMES verilator_bin.exe)
  if(_rtl_path_pe)
    rtl_lab_windows_file_is_pe("${_rtl_path_pe}" _ispe)
    if(_ispe)
      set(${outvar} "${_rtl_path_pe}" PARENT_SCOPE)
      return()
    endif()
  endif()
  set(${outvar} "" PARENT_SCOPE)
endfunction()

function(rtl_lab_locate_verilator_kit)
  set(_root "")

  if(WIN32)
    rtl_lab_find_windows_pe(_pe)
    if(NOT _pe)
      message(FATAL_ERROR
        "Windows Verilator PE not found (verilator_bin.exe with MZ header).\n"
        "Install the withlimon build: https://github.com/withlimon/verilator-windows\n"
        "Extract to a short path (e.g. D:\\verilator), then:\n"
        "  VERILATOR_ROOT = D:\\verilator\n"
        "  PATH          += D:\\verilator\\bin\n"
        "Do NOT invoke the extensionless Perl `verilator` (Open-with trap).\n"
        "Do NOT invoke share/verilator/bin/verilator_bin.exe (Perl wrapper with a .exe suffix).\n"
        "PC2023 worker workspace: D:\\CursorWorker")
    endif()
    set(RTL_LAB_VERILATOR_BIN "${_pe}")
  else()
    # Do not pre-set the result variable — find_program skips the search if it
    # is already defined (even as "").
    unset(RTL_LAB_VERILATOR_BIN CACHE)
    find_program(RTL_LAB_VERILATOR_BIN NAMES verilator_bin HINTS
      "$ENV{VERILATOR_ROOT}/bin"
      /usr/bin
      /usr/local/bin)
    if(NOT RTL_LAB_VERILATOR_BIN)
      message(FATAL_ERROR
        "verilator_bin not found. Install Verilator 5.x (e.g. apt install verilator).")
    endif()
  endif()
  set(_pe "${RTL_LAB_VERILATOR_BIN}")

  get_filename_component(_bin "${_pe}" DIRECTORY)
  get_filename_component(_parent "${_bin}" DIRECTORY)
  foreach(_c
      "$ENV{VERILATOR_ROOT}"
      "${_parent}"
      "${_parent}/share/verilator"
      "/usr/share/verilator"
      "/usr/local/share/verilator"
      "D:/verilator"
      "C:/msys64/mingw64/share/verilator")
    if(_c AND EXISTS "${_c}/include/verilated.h")
      set(_root "${_c}")
      break()
    endif()
  endforeach()

  if(NOT _root)
    message(FATAL_ERROR
      "VERILATOR_ROOT kit not found (need include/verilated.h). PE was ${_pe}")
  endif()

  message(STATUS "FindVerilatorKit: VERILATOR_BIN=${_pe}")
  message(STATUS "FindVerilatorKit: VERILATOR_ROOT=${_root}")
  set(RTL_LAB_VERILATOR_BIN "${_pe}" PARENT_SCOPE)
  set(RTL_LAB_VERILATOR_ROOT "${_root}" PARENT_SCOPE)
endfunction()

function(rtl_lab_find_verilator)
  # Pre-seed VERILATOR_BIN so a Debian/Ubuntu verilator-config.cmake does not
  # FATAL (it searches only VERILATOR_ROOT/bin with NO_CMAKE_SYSTEM_PATH), and
  # so an MSYS2 kit config does not pick share/verilator/bin's Perl wrapper.
  if(WIN32)
    rtl_lab_find_windows_pe(_pe_seed)
    if(_pe_seed)
      set(RTL_LAB_VERILATOR_BIN "${_pe_seed}" CACHE FILEPATH "RTL_LAB_VERILATOR_BIN" FORCE)
      set(VERILATOR_BIN "${_pe_seed}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    endif()
  else()
    find_program(RTL_LAB_VERILATOR_BIN NAMES verilator_bin HINTS
      "$ENV{VERILATOR_ROOT}/bin" /usr/bin /usr/local/bin)
    if(RTL_LAB_VERILATOR_BIN)
      set(VERILATOR_BIN "${RTL_LAB_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    endif()
  endif()

  # First find_package() triggers cmake-conan if the provider is registered.
  find_package(verilator QUIET)

  foreach(_pkg_var
      verilator_PACKAGE_FOLDER_RELEASE
      verilator_PACKAGE_FOLDER_RELWITHDEBINFO
      verilator_PACKAGE_FOLDER_DEBUG
      verilator_PACKAGE_FOLDER)
    if(DEFINED ${_pkg_var} AND EXISTS "${${_pkg_var}}/include/verilated.h")
      set(ENV{VERILATOR_ROOT} "${${_pkg_var}}")
      # Prefer the packaged PE (withlimon on Windows) over a stale PATH hit.
      unset(RTL_LAB_VERILATOR_BIN CACHE)
      message(STATUS "FindVerilatorKit: Conan package folder ${${_pkg_var}}")
      break()
    endif()
  endforeach()

  rtl_lab_locate_verilator_kit()
  set(VERILATOR_ROOT "${RTL_LAB_VERILATOR_ROOT}" CACHE PATH "VERILATOR_ROOT" FORCE)
  set(verilator_ROOT "${RTL_LAB_VERILATOR_ROOT}" CACHE PATH "verilator_ROOT" FORCE)
  set(VERILATOR_BIN "${RTL_LAB_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
  set(ENV{VERILATOR_ROOT} "${RTL_LAB_VERILATOR_ROOT}")

  if(NOT COMMAND verilate)
    if(EXISTS "${RTL_LAB_VERILATOR_ROOT}/verilator-config.cmake")
      include("${RTL_LAB_VERILATOR_ROOT}/verilator-config.cmake")
    else()
      message(STATUS
        "FindVerilatorKit: kit has no verilator-config.cmake (typical of withlimon); "
        "using bundled cmake/verilator-config.fallback.cmake")
      include("${RTL_LAB_CMAKE_DIR}/verilator-config.fallback.cmake")
    endif()
  endif()

  # Kit configs may find_program() VERILATOR_ROOT/bin (Perl wrapper on MSYS2).
  # Re-assert the PE after that include so verilate() drives verilator_bin.exe.
  if(WIN32)
    set(VERILATOR_BIN "${RTL_LAB_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    rtl_lab_windows_file_is_pe("${VERILATOR_BIN}" _bin_is_pe)
    if(NOT _bin_is_pe)
      rtl_lab_find_windows_pe(_pe_fix)
      if(NOT _pe_fix)
        message(FATAL_ERROR
          "VERILATOR_BIN is not a PE engine: ${VERILATOR_BIN}\n"
          "Do not use share/verilator/bin/verilator_bin.exe (Perl wrapper).")
      endif()
      set(RTL_LAB_VERILATOR_BIN "${_pe_fix}" CACHE FILEPATH "RTL_LAB_VERILATOR_BIN" FORCE)
      set(VERILATOR_BIN "${_pe_fix}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
      message(STATUS "FindVerilatorKit: replaced non-PE VERILATOR_BIN with ${_pe_fix}")
    endif()
  endif()

  if(NOT COMMAND verilate)
    message(FATAL_ERROR "verilate() missing after Verilator package load")
  endif()
endfunction()

function(rtl_lab_strip_msvc_gcc_flags target)
  if(NOT MSVC)
    return()
  endif()
  foreach(_prop COMPILE_OPTIONS INTERFACE_COMPILE_OPTIONS)
    get_target_property(_opts ${target} ${_prop})
    if(_opts)
      list(FILTER _opts EXCLUDE REGEX "fcoroutines")
      set_property(TARGET ${target} PROPERTY ${_prop} "${_opts}")
    endif()
  endforeach()
endfunction()
