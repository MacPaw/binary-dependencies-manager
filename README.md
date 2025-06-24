# binary-dependencies-manager

binary-dependencies-manager is a Swift-based tool for managing and resolving binary dependencies from GitHub releases. It automates the process of downloading, verifying, and extracting binary artifacts (such as frameworks or libraries) from GitHub repositories, making it easy to integrate prebuilt binaries into your projects.

## Features
- Download binary artifacts from GitHub releases using the GitHub CLI (`gh`)
- Verify artifact integrity using SHA256 checksums
- Extract and organize downloaded binaries into your desired output directory
- Support for selecting specific artifacts, subdirectories, and custom output paths

## Requirements
- Swift 5.9+
- macOS 11+
- [GitHub CLI (`gh`)](https://cli.github.com/) must be installed, authenticated and available in your PATH

## Installation

### mise

1. Add the env to your `.mise.toml` file to allow mise to use GitHub API token to download release assets from the private repo:
    ```toml
    [env]
    MISE_GITHUB_TOKEN = "{{ exec(command='$(which gh || mise which gh) auth token || echo \"\"') }}"
    ```
    > ⚠️ This requires installed and authenticated GitHub CLI (`gh`) tool.

    > ℹ️ mise runs `sh` and PATH env var is not resolved, that's why we need to use `which gh`.
    >
    > `|| echo ""` will not lead to immediate fail while mise is resolving ENV, but will fail when mise attempts to download the binary from the GitHub, if GitHub CLI has no authentication info.

2. Add `binary-dependencies-manager` to the `[tools]` section in your `.mise.toml`
    ```toml
    [tools]
    "ubi:MacPaw/binary-dependencies-manager" = "latest"
    ```

3. Run `mise install`.

### Manual
1. Clone the repository.
2. Build the tool using the provided script:

```sh
./compile_and_update_binary.sh
```

This will build the binary and place it in the `Binary/` directory.

## Usage
Run the tool by specifying the required paths:

```sh
./Binary/binary-dependencies-manager \
  --config path/to/.binary-dependencies.yaml \
  --cache path/to/cache \
  --output path/to/output
```

- `--config`, `-c`: Path to your `.binary-dependencies.yaml` file (see format below)
- `--output`, `-o`: Directory where resolved dependencies will be extracted
- `--cache`: Directory to use for caching downloads

## Example `dependencies.json`
```json
[
  {
    "repo": "MyOrg/MyLibrary",
    "tag": "1.2.3",
    "assets": {
      "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "contents": "XCFrameworks/MyLibrary.xcframework",
      "pattern": "MyLibrary.xcframework.zip",
      "output": "MyLibrary"
    }
  },
  {
    "repo": "AnotherOrg/AnotherBinary",
    "tag": "0.9.0",
    "checksum": "d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2",
    "pattern": "AnotherBinary.zip"
  }
]
```

```yaml
---
minimumVersion: 0.0.5
outputDirectory: Dependencies
cacheDirectory: .cache/binary-dependencies/
dependencies:
  - repo: MyOrg/MyLibrary
    tag: 1.2.3
    assets:
      - contents: XCFrameworks/MyLibrary.xcframework
        checksum: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
        pattern: MyLibrary.xcframework.zip
        output: MyLibrary
  - repo: AnotherOrg/AnotherBinary
    tag: 0.9.0
    checksum: d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2
    pattern: AnotherBinary.zip
```
## Top level parameters
- `minimumVersion` (optional): Minimum required binary-dependencies-manager version. Optional. Defaults to the current version.
- `outputDirectory` (optional): Path to the output directory. Optional. Defaults to `Dependencies/Binary`.
- `cacheDirectory` (optional): Path to the cache directory. Optional. Defaults to the `.cache/binary-dependencies`.


## Dependency Parameters
- `repo` (**required**): GitHub repository in the format `owner/repo` (e.g., `apple/swift-argument-parser`)
- `tag` (**required**): Release tag to download (e.g., `1.0.0`)
- `assets` (optional): A list of multiple binary assets to download from a given repo release.

> ℹ️ If no assets are provided you can specify asset parameters as a dependency parameters to download a single release artifact.

## Asset Parameters
- `checksum` (**required**): SHA256 checksum of the zip archive for integrity verification
- `contents` (optional): If provided, only the contents of this directory inside the archive will be extracted to the output directory
- `pattern` (optional): Pattern to select a specific artifact from the release (useful if multiple assets are present)
- `output` (optional): Subdirectory name to use for this dependency asset in the output directory (useful for organizing multiple artifacts)


## Example Scenarios
- **Download a single artifact:**
  - Specify `repo`, `tag`, `checksum`, and (optionally) `pattern` if the release contains multiple assets.
- **Extract only a subdirectory from the archive:**
  - Use the `contents` field to specify the subdirectory to extract.
- **Organize outputs:**
  - Use the `output` field to place the extracted files in a custom-named subdirectory under your output directory.

## Release

You have two options:
1. Create a new tag locally and push it.
2. Create a release manually on the GitHub.

After tag is created the `Build Multi-Platform Binary` action will be executed. It will build and add all binaries to the release assets.

## License
MIT 
