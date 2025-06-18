# Build the Swift package in release mode for both x86_64 and arm64 architectures
swift build -c release --arch x86_64 --arch arm64

# Copy the built binary-dependencies-manager binary to the Binary directory
cp .build/apple/Products/Release/binary-dependencies-manager ./Binary/binary-dependencies-manager
