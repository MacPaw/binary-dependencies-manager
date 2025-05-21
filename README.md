# BinaryDependenciesManager

BinaryDependenciesManager is a Swift-based tool for managing and resolving binary dependencies from GitHub releases. It automates the process of downloading, verifying, and extracting binary artifacts (such as frameworks or libraries) from GitHub repositories, making it easy to integrate prebuilt binaries into your projects.

## Features
- Download binary artifacts from GitHub releases using the GitHub CLI (`gh`)
- Verify artifact integrity using SHA256 checksums
- Extract and organize downloaded binaries into your desired output directory
- Support for selecting specific artifacts, subdirectories, and custom output paths

## Requirements
- Swift 5.9+
- macOS 11+
- [GitHub CLI (`gh`)](https://cli.github.com/) must be installed and available in your PATH

## Installation
Build the tool using the provided script:

```sh
./compile_and_update_binary.sh
```

This will build the binary and place it in the `Binary/` directory.

## Usage
Run the tool by specifying the required paths:

```sh
./Binary/BinaryDependenciesManager \
  --dependencies path/to/dependencies.json \
  --cache path/to/cache \
  --output path/to/output
```

- `--dependencies`: Path to your `dependencies.json` file (see format below)
- `--cache`: Directory to use for caching downloads
- `--output`: Directory where resolved dependencies will be extracted

## Example `dependencies.json`
```json
[
  {
    "repo": "MyOrg/MyLibrary",
    "tag": "1.2.3",
    "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "contents": "XCFrameworks/MyLibrary.xcframework",
    "pattern": "MyLibrary.xcframework.zip",
    "output": "MyLibrary"
  },
  {
    "repo": "AnotherOrg/AnotherBinary",
    "tag": "0.9.0",
    "checksum": "d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2",
    "pattern": "AnotherBinary.zip"
  }
]
```

## Dependency Parameters
- `repo` (**required**): GitHub repository in the format `owner/repo` (e.g., `apple/swift-argument-parser`)
- `tag` (**required**): Release tag to download (e.g., `1.0.0`)
- `checksum` (**required**): SHA256 checksum of the zip archive for integrity verification
- `contents` (optional): If provided, only the contents of this directory inside the archive will be extracted to the output directory
- `pattern` (optional): Pattern to select a specific artifact from the release (useful if multiple assets are present)
- `output` (optional): Subdirectory name to use for this dependency in the output directory (useful for organizing multiple artifacts)

## Example Scenarios
- **Download a single artifact:**
  - Specify `repo`, `tag`, `checksum`, and (optionally) `pattern` if the release contains multiple assets.
- **Extract only a subdirectory from the archive:**
  - Use the `contents` field to specify the subdirectory to extract.
- **Organize outputs:**
  - Use the `output` field to place the extracted files in a custom-named subdirectory under your output directory.

## License
MIT 