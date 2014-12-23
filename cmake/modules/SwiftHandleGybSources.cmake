include(SwiftAddCustomCommandTarget)
include(SwiftSetIfArchBitness)

# Create a target to process .gyb files with the 'gyb' tool.
#
# handle_gyb_sources(
#     dependency_out_var_name
#     sources_var_name
#     arch)
#
# Replace, in ${sources_var_name}, the given .gyb-suffixed sources with
# their un-suffixed intermediate files, which will be generated by processing
# the .gyb files with gyb.
#
# dependency_out_var_name
#   The name of a variable, to be set in the parent scope to the list of
#   targets that invoke gyb.  Every target that depends on the generated
#   sources should depend on ${dependency_out_var_name} targets.
#
# arch
#   The architecture that the files will be compiled for.
function(handle_gyb_sources dependency_out_var_name sources_var_name arch)
  set_if_arch_bitness(ptr_size
      ARCH "${arch}"
      CASE_32_BIT "4"
      CASE_64_BIT "8")

  set(gyb_flags
      "--test" # Run gyb's self-tests whenever we use it.  They're cheap
               # enough and it keeps us honest.
      ${SWIFT_GYB_FLAGS}
      "-DCMAKE_SIZEOF_VOID_P=${ptr_size}")

  set(dependency_targets)
  set(de_gybbed_sources)
  set(gyb_sources)
  set(gyb_tool "${SWIFT_SOURCE_DIR}/utils/gyb")
  set(gyb_extra_sources "${SWIFT_SOURCE_DIR}/utils/GYBUnicodeDataUtils.py")
  foreach (src ${${sources_var_name}})
    string(REGEX REPLACE "[.]gyb$" "" src_sans_gyb "${src}")
    if(src STREQUAL src_sans_gyb)
      list(APPEND de_gybbed_sources "${src}")
    else()
      set(dir "${CMAKE_CURRENT_BINARY_DIR}/${ptr_size}")
      set(output_file_name "${dir}/${src_sans_gyb}")
      list(APPEND de_gybbed_sources "${output_file_name}")
      string(MD5 output_file_name_hash "${output_file_name}")
      add_custom_command_target(
          dependency_target
          COMMAND
            "${CMAKE_COMMAND}" -E make_directory "${dir}"
          COMMAND
            "${gyb_tool}" "${gyb_flags}" -o "${output_file_name}.tmp" "${src}"
          COMMAND
            "${CMAKE_COMMAND}" -E copy_if_different "${output_file_name}.tmp" "${output_file_name}"
          COMMAND
            "${CMAKE_COMMAND}" -E remove "${output_file_name}.tmp"
          OUTPUT "${output_file_name}"
          DEPENDS "${gyb_tool}" "${src}" "${gyb_extra_sources}"
          COMMENT "Generating ${src_sans_gyb} from ${src} with ptr size = ${ptr_size}"
          WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
          IDEMPOTENT)
      list(APPEND dependency_targets "${dependency_target}")
    endif()
  endforeach()
  set("${dependency_out_var_name}" "${dependency_targets}" PARENT_SCOPE)
  set("${sources_var_name}" "${de_gybbed_sources}" PARENT_SCOPE)
endfunction()

