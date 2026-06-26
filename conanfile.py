from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain
from conan.tools.files import copy
import os


class CWR(ConanFile):
    name = "cwr"
    version = "1.0"
    package_type = "application"
    settings = "os", "compiler", "build_type", "arch"

    def requirements(self):
        # Core libraries
        self.requires("catch2/3.5.2")
        self.requires("cjson/1.7.19")
        self.requires("cli11/2.4.0")
        self.requires("glslang/1.4.350.0")
        self.requires("mimalloc/2.2.4")
        self.requires("stb/cci.20240531")
        self.requires("zstd/1.5.7")

        # Logging
        self.requires("spdlog/1.15.1")

        # Networking
        self.requires("libcurl/8.20.0")

        # UI / Graphics
        self.requires("freetype/2.14.3")
        self.requires("imgui/1.92.8")
        self.requires("sdl/3.4.8")

        # Audio
        self.requires("enkits/1.11")
        self.requires("ogg/1.3.5")
        self.requires("openal-soft/1.23.1")
        self.requires("opus/1.6.1")
        self.requires("vorbis/1.3.7")

        # SIMD abstraction (x86 SSE intrinsics on ARM)
        if self.settings.arch == "armv8":
            self.requires("sse2neon/1.9.1")

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()

        tc = CMakeToolchain(self)
        tc.user_presets_path = False
        tc.generate()

    def configure(self):
        # Enable wchar on Windows
        if self.settings.os == "Windows":
            self.options["spdlog"].wchar = True
