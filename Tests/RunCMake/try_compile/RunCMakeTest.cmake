include(RunCMake)

run_cmake(CopyFileErrorNoCopyFile)
run_cmake(NoArgs)
run_cmake(OneArg)
run_cmake(TwoArgs)
run_cmake(NoCopyFile)
run_cmake(NoCopyFile2)
run_cmake(NoCopyFileError)
run_cmake(NoOutputVariable)
run_cmake(NoOutputVariable2)
run_cmake(NoSources)
run_cmake(BadLinkLibraries)
run_cmake(BadSources1)
run_cmake(BadSources2)
run_cmake(NonSourceCopyFile)
run_cmake(NonSourceCompileDefinitions)

run_cmake(EnvConfig)

set(RunCMake_TEST_OPTIONS --debug-trycompile)
run_cmake(PlatformVariables)
run_cmake(WarnDeprecated)
unset(RunCMake_TEST_OPTIONS)

run_cmake(TargetTypeExe)
run_cmake(TargetTypeInvalid)
run_cmake(TargetTypeStatic)

if (CMAKE_SYSTEM_NAME MATCHES "^(Linux|Darwin|Windows)$" AND
    CMAKE_C_COMPILER_ID MATCHES "^(MSVC|GNU|LCC|Clang|AppleClang)$")
  set (RunCMake_TEST_OPTIONS -DRunCMake_C_COMPILER_ID=${CMAKE_C_COMPILER_ID})
  run_cmake(LinkOptions)
  unset (RunCMake_TEST_OPTIONS)
endif()

if(CMAKE_C_STANDARD_DEFAULT)
  run_cmake(CStandard)
elseif(DEFINED CMAKE_C_STANDARD_DEFAULT)
  run_cmake(CStandardNoDefault)
endif()
if(CMAKE_OBJC_STANDARD_DEFAULT)
  run_cmake(ObjCStandard)
endif()
if(CMAKE_CXX_STANDARD_DEFAULT)
  run_cmake(CxxStandard)
elseif(DEFINED CMAKE_CXX_STANDARD_DEFAULT)
  run_cmake(CxxStandardNoDefault)
endif()
if(CMAKE_OBJCXX_STANDARD_DEFAULT)
  run_cmake(ObjCxxStandard)
endif()
if(CMake_TEST_CUDA)
  run_cmake(CudaStandard)
endif()
if(CMake_TEST_ISPC)
  run_cmake(ISPCTargets)
  run_cmake(ISPCInvalidTarget)
  set(ninja "")
  if(RunCMake_GENERATOR MATCHES "Ninja")
    set(ninja "Ninja")
  endif()
  run_cmake(ISPCDuplicateTarget${ninja})
endif()
if((CMAKE_C_COMPILER_ID MATCHES "GNU" AND NOT CMAKE_C_COMPILER_VERSION VERSION_LESS 4.4) OR CMAKE_C_COMPILER_ID MATCHES "LCC")
  run_cmake(CStandardGNU)
endif()
if((CMAKE_CXX_COMPILER_ID MATCHES "GNU" AND NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.4) OR CMAKE_C_COMPILER_ID MATCHES "LCC")
  run_cmake(CxxStandardGNU)
endif()

run_cmake(CMP0056)
run_cmake(CMP0066)
run_cmake(CMP0067)

if(RunCMake_GENERATOR MATCHES "Make|Ninja")
  # Use a single build tree for a few tests without cleaning.
  set(RunCMake_TEST_BINARY_DIR ${RunCMake_BINARY_DIR}/RerunCMake-build)
  set(RunCMake_TEST_NO_CLEAN 1)
  file(REMOVE_RECURSE "${RunCMake_TEST_BINARY_DIR}")
  file(MAKE_DIRECTORY "${RunCMake_TEST_BINARY_DIR}")
  set(in_tc  "${RunCMake_TEST_BINARY_DIR}/TryCompileInput.c")
  file(WRITE "${in_tc}" "int main(void) { return 0; }\n")

  # Older Ninja keeps all rerun output on stdout
  set(ninja "")
  if(RunCMake_GENERATOR STREQUAL "Ninja")
    execute_process(COMMAND ${RunCMake_MAKE_PROGRAM} --version
      OUTPUT_VARIABLE ninja_version OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(ninja_version VERSION_LESS 1.5)
      set(ninja -ninja-no-console)
    endif()
  endif()

  message(STATUS "RerunCMake: first configuration...")
  run_cmake(RerunCMake)
  if(NOT CMake_TEST_FILESYSTEM_1S)
    set(RunCMake_TEST_OUTPUT_MERGE 1)
    run_cmake_command(RerunCMake-nowork${ninja} ${CMAKE_COMMAND} --build .)
    unset(RunCMake_TEST_OUTPUT_MERGE)
  endif()

  execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 1) # handle 1s resolution
  message(STATUS "RerunCMake: modify try_compile input...")
  file(WRITE "${in_tc}" "does-not-compile\n")
  run_cmake_command(RerunCMake-rerun${ninja} ${CMAKE_COMMAND} --build .)
  if(NOT CMake_TEST_FILESYSTEM_1S)
    set(RunCMake_TEST_OUTPUT_MERGE 1)
    run_cmake_command(RerunCMake-nowork${ninja} ${CMAKE_COMMAND} --build .)
    unset(RunCMake_TEST_OUTPUT_MERGE)
  endif()

  unset(RunCMake_TEST_BINARY_DIR)
  unset(RunCMake_TEST_NO_CLEAN)
endif()

# Lookup CMAKE_CXX_EXTENSIONS_DEFAULT.
# FIXME: Someday we could move this to the top of the file and use it in
# place of some of the values passed by 'Tests/RunCMake/CMakeLists.txt'.
run_cmake(Inspect)
include("${RunCMake_BINARY_DIR}/Inspect-build/info.cmake")

# FIXME: Support more compilers and default standard levels.
if (CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|AppleClang)$"
    AND DEFINED CMAKE_CXX_STANDARD_DEFAULT
    AND DEFINED CMAKE_CXX_EXTENSIONS_DEFAULT
    )
  run_cmake(CMP0128-WARN)
  if(NOT CMAKE_CXX_STANDARD_DEFAULT EQUAL 11)
    run_cmake(CMP0128-NEW)
  endif()
endif()

if(UNIX)
  run_cmake(CleanupNoFollowSymlink)
endif()
