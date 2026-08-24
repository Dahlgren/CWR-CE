set(CMAKE_SYSTEM_NAME Windows)

# Find LLVM compilers dynamically
include(${CMAKE_CURRENT_LIST_DIR}/../FindLLVMSanitizer.cmake)
find_llvm_compilers("arm64")

set(CMAKE_EXE_LINKER_FLAGS_INIT    "/machine:arm64")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "/machine:arm64")
set(CMAKE_STATIC_LINKER_FLAGS_INIT "/machine:arm64")

# Ensure correct cpu type is set for libpng neon
set(CMAKE_SYSTEM_PROCESSOR ARM64 CACHE STRING "")
