
cmake_minimum_required(VERSION 3.19)



# dlcache("https://github.com/g-truc/glm/archive/refs/heads/master.zip"
#   SHA256 97198B71B24AD5087114C1FB64DC3111AEE1C7976CB5AE8A7C4476F3EEAB8D69
#   OUT url
# )
# message(STATUS "file loc >>>>> ${url}")


# dlcache("https://..." [SHA256 0123...] [OUT localFileLocVar])
function(dlcache url)
    # https://cmake.org/cmake/help/latest/command/cmake_parse_arguments.html
    cmake_parse_arguments(DL "" "SHA256;OUT" "" ${ARGN} )

    if(WIN32)
        file(TO_CMAKE_PATH $ENV{LocalAppData} appdatadir)
        set(DLCACHEDIR "${appdatadir}/dlcache")
    else()
        set(DLCACHEDIR "$ENV{HOME}/.cache/dlcache")
    endif()
    string(REGEX REPLACE [^A-Za-z0-9/.-] _ urlstripped "${url}")
    set(dlpath "${DLCACHEDIR}/${urlstripped}")

    IF(EXISTS "${dlpath}")
    ELSE()
        IF(DL_SHA256)
            file(DOWNLOAD "${url}" "${dlpath}" STATUS dlstatus)
        ELSE()
            file(DOWNLOAD "${url}" "${dlpath}" STATUS dlstatus)
        ENDIF()
        LIST(GET dlstatus 0 status_code)
        IF(status_code)
            MESSAGE(FATAL_ERROR "${dlstatus} (${url})")
        ENDIF()
    ENDIF()

    IF(DL_SHA256)
        STRING(TOLOWER ${DL_SHA256} DL_SHA256)
        FILE(SHA256 "${dlpath}" cksum)
        STRING(TOLOWER ${cksum} cksum)
        IF(cksum STREQUAL "${DL_SHA256}")
        ELSE()
            FILE(REMOVE "${dlpath}")
            MESSAGE(FATAL_ERROR "CHECKSUM MISMATCH for: ${url}\nEXPECTED: ${DL_SHA256}\nGOT: ${cksum}")
        ENDIF()
    ENDIF()

    IF(DL_OUT)
        set(${DL_OUT} "${dlpath}" PARENT_SCOPE)
    ENDIF()
endfunction()


macro(dlcache2 url sha256)
    dlcache("${url}" SHA256 "${sha256}" OUT "dl_local_path")
endmacro()

# fetch source code zip from github
#
# ${dl_local_path} will contain the file path
#
# project: github-user/project-name
# tag: either 40 chars (commit id) or a ref tag
macro(dlghzip project tag sha256)
    string(LENGTH "${tag}" taglen)
    if(taglen EQUAL 40)
        dlcache("https://github.com/${project}/archive/${tag}.zip" SHA256 "${sha256}" OUT "dl_local_path")
    else()
        dlcache("https://github.com/${project}/archive/refs/tags/${tag}.zip" SHA256 "${sha256}" OUT "dl_local_path")
    endif()
endmacro()


# Examples:
#
# dlcache_assets(
#     LIST
#     https://raw.githubusercontent.com/Overv/VulkanTutorial/master/images/texture.jpg
#     663a43377a9d3b42a1925a17313b12e339b146d219a62c4c07a56c89032858bb
#     https://raw.githubusercontent.com/Overv/VulkanTutorial/master/resources/viking_room.png
#     facb693858cafcb70b7eed264e34107f06bbf3f41805e7b8084e5b42bd914a66
#     OUTDIR textures
# )
# dlcache_assets(
#     LIST
#     https://raw.githubusercontent.com/Overv/VulkanTutorial/master/resources/viking_room.obj
#     0af27cd99ce43f48c89d9c73cff47cbdfc3d29c3754b29bd0ccfe7e3fe7de869
#     OUTDIR models
# )
#
# Writes the given files into textures/modles directories, using the last part of each url as filename.
#
function(dlcache_assets)
    cmake_parse_arguments(DL "EXTRACT_FILENAMES" "OUTDIR" "LIST" ${ARGN})
    if(NOT DL_OUTDIR)
        set(DL_OUTDIR "assets")
    endif()
    list(LENGTH DL_LIST len1)
    math(EXPR len2 "${len1} / 2 - 1")
    foreach(val RANGE ${len2})
        math(EXPR vala "2 * ${val}")
        math(EXPR valb "2 * ${val} + 1")
        list(GET DL_LIST ${vala} val1)
        list(GET DL_LIST ${valb} val2)
        dlcache2("${val1}" "${val2}")
        file(COPY "${dl_local_path}" DESTINATION "${DL_OUTDIR}")
    endforeach()
endfunction()
