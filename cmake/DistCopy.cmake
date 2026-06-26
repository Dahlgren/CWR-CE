# DistCopy.cmake — Helper to copy build artifacts to dist/<preset>/
#
# Usage:
#   include(${CMAKE_SOURCE_DIR}/cmake/DistCopy.cmake)
#   dist_copy(PoseidonGame)                              # copy binary + PDB
#   dist_copy(TcPbo RENAME pbo${WCX_SUFFIX})             # copy with rename
#   dist_copy(TcPbo EXTRA pluginst.inf)                  # copy extra file from source dir

# Conan's CMakeDeps generator makes e.g. OpenAL::OpenAL an INTERFACE target
# with no IMPORTED_LOCATION of its own; the real imported target (which does
# carry IMPORTED_LOCATION[_<CONFIG>]) is reached only through
# INTERFACE_LINK_LIBRARIES (named CONAN_LIB::<pkg>_<lib>_<CONFIG>). Walk that
# indirection to find the actual shared library file on disk.
function(_dist_copy_resolve_imported_location TARGET_NAME OUT_VAR)
    if(NOT TARGET ${TARGET_NAME})
        return()
    endif()

    get_target_property(_location ${TARGET_NAME} IMPORTED_LOCATION)
    if(NOT _location AND CMAKE_BUILD_TYPE)
        string(TOUPPER "${CMAKE_BUILD_TYPE}" _config_upper)
        get_target_property(_location ${TARGET_NAME} IMPORTED_LOCATION_${_config_upper})
    endif()
    if(_location)
        set(${OUT_VAR} "${_location}" PARENT_SCOPE)
        return()
    endif()

    get_target_property(_link_libraries ${TARGET_NAME} INTERFACE_LINK_LIBRARIES)
    if(_link_libraries)
        string(REGEX MATCHALL "CONAN_LIB::[A-Za-z0-9_+.-]+" _candidates "${_link_libraries}")
        list(REMOVE_DUPLICATES _candidates)
        foreach(_candidate IN LISTS _candidates)
            _dist_copy_resolve_imported_location(${_candidate} _resolved)
            if(_resolved)
                set(${OUT_VAR} "${_resolved}" PARENT_SCOPE)
                return()
            endif()
        endforeach()
    endif()
endfunction()

function(dist_copy TARGET)
    cmake_parse_arguments(ARG "" "RENAME" "EXTRA" ${ARGN})

    if(ARG_RENAME)
        set(_dst "${DIST_DIR}/${ARG_RENAME}")
    else()
        set(_dst "${DIST_DIR}/$<TARGET_FILE_NAME:${TARGET}>")
    endif()

    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory ${DIST_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:${TARGET}> ${_dst}
        COMMENT "Copying ${TARGET} to ${DIST_DIR}"
        VERBATIM
    )

    get_target_property(_type ${TARGET} TYPE)

    if(WIN32)
        if(_type STREQUAL "EXECUTABLE" OR _type STREQUAL "SHARED_LIBRARY")
            add_custom_command(TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    $<TARGET_PDB_FILE:${TARGET}> ${DIST_DIR}/
                VERBATIM
            )
        endif()
    endif()

    if(UNIX AND NOT APPLE AND CMAKE_BUILD_TYPE STREQUAL "Release" AND CMAKE_OBJCOPY AND CMAKE_STRIP)
        if(_type STREQUAL "EXECUTABLE" OR _type STREQUAL "SHARED_LIBRARY" OR _type STREQUAL "MODULE_LIBRARY")
            set(_debug_dst "${_dst}.debug")
            add_custom_command(TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_OBJCOPY} --only-keep-debug $<TARGET_FILE:${TARGET}> ${_debug_dst}
                COMMAND ${CMAKE_STRIP} --strip-debug --strip-unneeded ${_dst}
                COMMAND ${CMAKE_OBJCOPY} --add-gnu-debuglink=${_debug_dst} ${_dst}
                COMMENT "Writing debug symbols and stripping ${TARGET} in ${DIST_DIR}"
                VERBATIM
            )
        endif()
    endif()

    # Copy runtime DLLs (e.g., OpenAL32.dll or libopenal.dylib — LGPL dynamic linkage)
    set(_copy_openal_runtime OFF)
    get_target_property(_link_libraries ${TARGET} LINK_LIBRARIES)
    if(_link_libraries)
        foreach(_link_library IN LISTS _link_libraries)
            if(_link_library STREQUAL "PoseidonOpenAL" OR _link_library STREQUAL "OpenAL::OpenAL")
                set(_copy_openal_runtime ON)
            endif()
        endforeach()
    endif()
    if((WIN32 OR APPLE) AND TARGET OpenAL::OpenAL AND _copy_openal_runtime)
        _dist_copy_resolve_imported_location(OpenAL::OpenAL _openal_lib)
        if(_openal_lib AND (WIN32 AND _openal_lib MATCHES "\\.dll$") OR (APPLE AND _openal_lib MATCHES "\\.dylib$"))
            if(WIN32)
                add_custom_command(TARGET ${TARGET} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                        "${_openal_lib}" "${DIST_DIR}/OpenAL32.dll"
                    VERBATIM
                )
            elseif(APPLE)
                add_custom_command(TARGET ${TARGET} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${_openal_lib}" "${DIST_DIR}/libopenal.dylib"
                    VERBATIM
                )
            endif()

            # Conan lays out openal-soft as <package_folder>/{bin,lib}/<file> and
            # <package_folder>/licenses/COPYING.
            get_filename_component(_openal_bin_dir "${_openal_lib}" DIRECTORY)
            get_filename_component(_openal_package_dir "${_openal_bin_dir}" DIRECTORY)
            set(_openal_copyright "${_openal_package_dir}/licenses/COPYING")
            if(EXISTS "${_openal_copyright}")
                add_custom_command(TARGET ${TARGET} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                        "${_openal_copyright}" "${DIST_DIR}/OpenAL-Soft.LICENSE.txt"
                    VERBATIM
                )
            endif()
        endif()
        unset(_openal_lib)
        unset(_openal_bin_dir)
        unset(_openal_package_dir)
        unset(_openal_copyright)
    endif()
    unset(_copy_openal_runtime)
    unset(_link_libraries)
    unset(_link_library)

    # Copy extra files from the target's source directory
    foreach(_extra ${ARG_EXTRA})
        get_filename_component(_name "${_extra}" NAME)
        add_custom_command(TARGET ${TARGET} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${CMAKE_CURRENT_SOURCE_DIR}/${_extra} ${DIST_DIR}/${_name}
            VERBATIM
        )
    endforeach()
endfunction()
