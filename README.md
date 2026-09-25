<p align="center">
  <img src="https://raw.githubusercontent.com/Coccinella-Labs/xnubuild/main/.github/assets/thumbnail.png" alt="xnubuild" width="100%">
</p>

# XNU Build

[![Build Status](https://github.com/coccinella-labs/xnu-build/actions/workflows/build.yml/badge.svg)](https://github.com/coccinella-labs/xnu-build/actions/workflows/build.yml)

A comprehensive build system for compiling Apple's XNU kernel on macOS, featuring automated environment detection, source management, and compilation fixes for common issues.

## ⚠️ Critical Disclaimers

### System Kernel Replacement Not Possible

Modern macOS uses System Integrity Protection (SIP) and kernel code signing that prevent replacing the system kernel. Attempting to boot custom kernels on production systems can cause system instability or permanent damage.

**Recommendation**

Use this build system for educational and virtual machine testing only. Never attempt kernel replacement on real hardware.

**Example**

In this code, attempting to load a custom kernel on a production system:

```bash
# DANGEROUS - Do not run on real hardware
sudo kextload /path/to/custom/kernel.kext
```

This can cause system crashes, data loss, or require complete OS reinstallation. Instead, use virtual machines:

```bash
# SAFE - Test in QEMU virtual machine
./scripts/test-vm.sh
```

**References**

- Apple Developer: System Integrity Protection Guide
- Apple Security: Kernel Code Signing
- macOS Security Overview

## Requirements

### Missing Build Dependencies

Building XNU requires specific tools and versions. Using incompatible or missing dependencies can result in compilation failures or incorrect kernel binaries.

**Recommendation**

Ensure all required dependencies are installed and at compatible versions before building.

**Example**

In this build attempt, missing Xcode Command Line Tools causes failure:

```bash
$ ./scripts/build-all.sh
ERROR: Xcode Command Line Tools not found
```

Install the required tools:

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcodebuild -version
```

**Required Dependencies**
- **macOS**: 11.0+ (Big Sur or later)
- **Xcode Command Line Tools**: Latest version
- **Git**: For source management
- **Python 3**: For build scripts

**Optional for VM Testing**
- **QEMU**: 6.0+ (for kernel testing)
- **UTM**: For native Apple Silicon support
- **VirtualBox**: For traditional x86_64 testing

**References**

- Apple Developer: Xcode Command Line Tools
- Homebrew: macOS Package Manager
- Git Documentation: Installation Guide

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/coccinella-labs/xnu-build.git
   cd xnu-build
   ```

2. Run environment detection:
   ```bash
   ./scripts/detect-env.sh
   ```

## Usage

Build the complete XNU kernel:

```bash
# Automated build
./scripts/build-all.sh

# Or step-by-step
./scripts/fetch-sources.sh
./scripts/configure-build.sh
./scripts/build-kernel.sh
./scripts/build-tools.sh
```

Custom build with specific options:

```bash
# Build for specific architecture
./build_xnu.sh --arch arm64

# Clean build
./build_xnu.sh --clean

# Verbose output
./build_xnu.sh --verbose
```

## Command Line Interface

### `./scripts/build-all.sh`

Complete automated build script that handles the entire process.

```
Usage: ./scripts/build-all.sh [options]

Options:
  -h, --help          Show this help message
  -c, --clean         Clean build artifacts before building
  -v, --verbose       Enable verbose output
  --arch <arch>       Target architecture (arm64, x86_64)
  --no-tools          Skip building userland tools
```

### `./scripts/fetch-sources.sh`

Fetches XNU and related sources from Apple repositories.

```
Usage: ./scripts/fetch-sources.sh [options]

Options:
  -h, --help          Show this help message
  -f, --force         Force re-fetch even if sources exist
```

### `./scripts/configure-build.sh`

Configures the build environment and generates Makefiles.

```
Usage: ./scripts/configure-build.sh [options]

Options:
  -h, --help          Show this help message
  --sdk <path>        Path to macOS SDK
  --cc <compiler>     C compiler to use
  --cxx <compiler>    C++ compiler to use
```

### `./scripts/build-kernel.sh`

Compiles the XNU kernel components.

```
Usage: ./scripts/build-kernel.sh [options]

Options:
  -h, --help          Show this help message
  -j <jobs>           Number of parallel jobs
  --debug             Build with debug symbols
  --release           Build optimized release version
```

### `./scripts/build-tools.sh`

Builds userland tools and utilities.

```
Usage: ./scripts/build-tools.sh [options]

Options:
  -h, --help          Show this help message
  -j <jobs>           Number of parallel jobs
  --minimal           Build only essential tools
```

### `./build_xnu.sh`

Custom build script with advanced options.

```
Usage: ./build_xnu.sh [options]

Options:
  -h, --help          Show this help message
  -c, --clean         Clean build directory
  -v, --verbose       Verbose output
  --arch <arch>       Target architecture
```

## Build Components

### Core XNU Components
- **XNU Kernel**: The core kernel implementation (Mach + BSD)
  - **Mach Layer**: Low-level microkernel, IPC, memory management
  - **BSD Layer**: POSIX compatibility, system calls, process management
  - **I/O Kit**: Device driver framework

### Required Subprojects
- **libkern**: Kernel library utilities
- **libsyscall**: System call interface
- **dyld**: Dynamic linker (userland)
- **Libc**: C standard library
- **Security**: Security-related kernel components

## Build Phases

### `detect-env.sh` - Environment Detection

Verifies system capabilities and generates build configuration.

**Inputs:**
- macOS version
- Xcode Command Line Tools
- Available compilers

**Outputs:**
- `BUILD_CONFIG.env` with detected settings
- Validation of build requirements

### `fetch-sources.sh` - Source Preparation

Clones official Apple Open Source repositories.

**Inputs:**
- Repository URLs
- Branch/tag specifications

**Outputs:**
- Local clones of XNU, libkern, etc.
- Source directories in expected locations

### `configure-build.sh` - Build Configuration

Sets up build environment with proper flags and paths.

**Inputs:**
- SDK paths
- Compiler settings
- Architecture targets

**Outputs:**
- Generated Makefiles
- Build configuration files
- `build/build-info.sh` with build details

### `build-kernel.sh` - Kernel Compilation

Compiles Mach, BSD, and I/O Kit components.

**Inputs:**
- Source files
- Build configuration
- Compiler flags

**Outputs:**
- Object files in `build/`
- Compiled kernel components

### `build-tools.sh` - Userland Tools

Builds userland tools and utilities.

**Inputs:**
- Tool source code
- Build configuration

**Outputs:**
- Executable tools
- Libraries for userland

### `build-all.sh` - Complete Build

Orchestrates the entire build process.

**Inputs:**
- All build options
- Source repositories

**Outputs:**
- Complete kernel binary
- Debug symbols
- Compressed kernelcache

## XNU Kernel Primer

XNU is Apple's open-source kernel that powers macOS, iOS, and other Darwin-based systems. It combines three major components:

### Mach Microkernel

The foundation layer providing:
- **Memory Management**: Virtual memory, paging, and protection
- **IPC (Inter-Process Communication)**: Message passing between tasks
- **Scheduling**: Thread and task scheduling
- **Low-level Services**: Timers, interrupts, and device drivers

### BSD Layer

Provides POSIX compatibility:
- **System Calls**: Interface between user space and kernel
- **Process Management**: fork, exec, process lifecycle
- **File Systems**: HFS+, APFS, and network file systems
- **Networking**: TCP/IP stack and socket interfaces
- **Security**: User permissions and access control

### I/O Kit

Device driver framework:
- **Driver Matching**: Automatic driver loading for hardware
- **Power Management**: Device power states and transitions
- **Hot Plugging**: Dynamic device attachment/removal
- **User-Space Drivers**: Support for complex device drivers

### Build Process

The build system compiles these components into a unified kernel binary:

1. **Source Integration**: Combines Mach, BSD, and I/O Kit sources
2. **Cross-Compilation**: Uses macOS SDK for kernel compilation
3. **Linking**: Creates Mach-O executable with proper load commands
4. **Compression**: Generates kernelcache for efficient loading

## Build Output

- `output/arm64/kernel`: Uncompressed Mach-O kernel binary
- `output/arm64/kernelcache`: Gzip-compressed kernel for faster booting
- `output/arm64/kernel.dSYM/`: Debug symbols for kernel debugging

## Testing

### Unsafe Kernel Testing Practices

Testing custom kernels on production systems or real hardware can cause system crashes, data corruption, or permanent damage due to kernel panics or incompatible drivers.

**Recommendation**

Always test kernels in virtual machines with proper isolation. Use QEMU or UTM for safe kernel experimentation.

**Example**

Dangerous testing on real hardware:

```bash
# DANGEROUS - Can crash system permanently
sudo reboot  # After installing custom kernel
```

Safe testing in virtual machine:

```bash
# SAFE - Isolated testing environment
./scripts/test-vm.sh
qemu-system-aarch64 -M virt -kernel output/arm64/kernel -nographic
```

**References**

- QEMU Documentation: Virtual Machine Setup
- UTM: Apple Silicon Virtualization
- Apple Developer: Kernel Debugging Guide

## Project Structure

```
xnu-build/
├── scripts/              # Build automation scripts
├── build/                # Build artifacts and temporary files
├── output/               # Final build products
├── README.md             # This file
├── START_HERE.txt        # Quick start guide
└── build_xnu.sh          # Custom build script
```

## Troubleshooting

### Common Issues

- **Environment Detection Fails**: Ensure Xcode Command Line Tools are installed
- **Source Fetching Issues**: Check internet connection and Git configuration
- **Compilation Errors**: Verify SDK paths and compiler versions
- **Build Artifacts Missing**: Check build logs in `build/build.log`

### Build Logs

- Kernel build log: `build/build.log`
- Configuration details: `build/build-info.sh`

## Comparisons to Other XNU Build Methods

While there are several ways to build XNU, this build system provides specific advantages:

### Manual Build Scripts

Traditional approach using Apple's documentation:
- **Pros**: Direct control, follows official methods
- **Cons**: Error-prone, requires deep knowledge, no automation

This system automates the manual process while maintaining compatibility.

### Xcode Projects

Using Xcode for kernel development:
- **Pros**: Integrated IDE, debugging support
- **Cons**: Limited to userland, complex setup for kernel

This system focuses on command-line kernel builds for CI/CD and automation.

### Third-Party Tools

Other build tools and scripts:
- **Pros**: May have additional features
- **Cons**: Often outdated, not maintained, security concerns

This system stays current with Apple's latest sources and security practices.

## Contributing

Any change to build scripts or behavior must come with tests and documentation.

Patches that break builds or reduce reliability will be rejected.

```sh
# to run builds
./scripts/build-all.sh

# to test changes
./scripts/build-kernel.sh --debug

# to check environment
./scripts/detect-env.sh
```

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make changes and test builds
4. Commit changes: `git commit -m "feat: add new feature"`
5. Push to branch: `git push origin feature/new-feature`
6. Create a Pull Request

## Related Projects

- [Apple XNU Source](https://github.com/apple/darwin-xnu)
- [XNU Documentation](https://developer.apple.com/documentation/kernel)

## License

This build system is provided for educational and development purposes. The XNU kernel source code is subject to Apple's licensing terms.

## Disclaimer

This project is not affiliated with Apple Inc. Use at your own risk in virtualized environments only.
