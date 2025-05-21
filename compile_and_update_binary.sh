# Build the Swift package in release mode for both x86_64 and arm64 architectures
swift build -c release --arch x86_64 --arch arm64

# Copy the built BinaryDependenciesManager binary to the Binary directory
cp .build/apple/Products/Release/BinaryDependenciesManager ./Binary/BinaryDependenciesManager