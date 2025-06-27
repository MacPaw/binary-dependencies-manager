import Crypto
import Foundation
import Yams
import Utils

public struct DependenciesResolverRunner {
    /// A list of dependencies to resolve.
    let dependencies: [Dependency]

    /// Path to the directory where downloaded dependencies will be placed.
    let outputDirectoryURL: URL

    /// Path to the directory where downloaded dependencies will be cached.
    let cacheDirectoryURL: URL

    /// File manager to use for file operations.
    let fileManager: FileManagerProtocol

    /// Downloader for binary dependencies. If nil, it will use the default CLI.GH downloader.
    let dependenciesDownloader: any BinaryDependenciesDownloader

    /// Unarchiver for downloaded zip archives.
    let unarchiver: any UnarchiverProtocol

    /// Check sum calculator for downloaded and cached files.
    let checksumCalculator: any ChecksumCalculatorProtocol

    /// A unique identifier for the current run, used to create temporary directories.
    let uuidString: String

    public init(
        dependencies: [Dependency],
        outputDirectoryURL: URL,
        cacheDirectoryURL: URL,
        fileManager: FileManagerProtocol = FileManager.default,
        uuidString: String = UUID().uuidString,
        dependenciesDownloader: any BinaryDependenciesDownloader,
        unarchiver: any UnarchiverProtocol,
        checksumCalculator: any ChecksumCalculatorProtocol
    ) {
        self.dependencies = dependencies
        self.outputDirectoryURL = outputDirectoryURL
        self.cacheDirectoryURL = cacheDirectoryURL
        self.fileManager = fileManager
        self.uuidString = uuidString
        self.dependenciesDownloader = dependenciesDownloader
        self.unarchiver = unarchiver
        self.checksumCalculator = checksumCalculator
    }

    public func run() throws {
        var dependenciesToResolve: [Dependency] = []
        for dependency in dependencies {
            let assetsToResolve = try dependency.assets.filter { try shouldResolve(dependency, asset: $0) }

            guard !assetsToResolve.isEmpty else { continue }

            let newDependency = Dependency(repo: dependency.repo, tag: dependency.tag, assets: assetsToResolve)

            dependenciesToResolve.append(newDependency)
        }

        // resolve dependencies one by one
        for dependency in dependenciesToResolve {
            try runThrowable("Resolving \(dependency.repo)") { try resolve(dependency, downloader: dependenciesDownloader) }
        }
    }

    func resolve(_ dependency: Dependency, downloader: any BinaryDependenciesDownloader) throws {
        for asset in dependency.assets {
            try runThrowable("Downloading \(dependency.repo)") { try download(dependency, asset: asset, with: downloader) }
            try runThrowable("Unzipping \(dependency.repo)") { try unzip(dependency, asset: asset) }
            try markAsResolved(dependency, asset: asset)
        }
    }

    func download(_ dependency: Dependency, asset: Dependency.Asset, with downloader: some BinaryDependenciesDownloader) throws {
        let uniqueDir = downloadDirectoryURL(for: dependency, asset: asset)
        let downloadFileURL = downloadURL(for: dependency, asset: asset)
        try createDirectoryIfNeeded(at: uniqueDir)

        guard try !isFileDownloaded(for: dependency, asset: asset) else { return }

        try downloader.downloadReleaseAsset(
            repo: dependency.repo,
            tag: dependency.tag,
            pattern: asset.pattern,
            outputFilePath: downloadFileURL.path(percentEncoded: false)
        )

        let checksum = try runThrowable("Calculating checksum") { try calculateChecksum(fileURL: downloadFileURL) }

        guard checksum == asset.checksum else {
            throw NSError(domain: "Checksum is incorrect. \(checksum) != \(asset.checksum)", code: 0)
        }
    }

    func shouldResolve(_ dependency: Dependency, asset: Dependency.Asset) throws -> Bool {
        let outputDirectoryHashFile = try outputDirectoryHashFile(for: dependency, asset: asset)
        guard let hashFileData = fileManager.contents(at: outputDirectoryHashFile) else { return true }
        guard let hash = String(bytes: hashFileData, encoding: .utf8) else { return true }

        if hash == asset.checksum {
            Logger.log("[Resolve] \(outputDirectoryHashFile.relativeFilePath). Skipped ✅")
            return false
        }
        return true
    }

    func markAsResolved(_ dependency: Dependency, asset: Dependency.Asset) throws {

        let outputDirectoryHashFile = try outputDirectoryHashFile(for: dependency, asset: asset)
        // Create hash file which will be used as a marker that dependency is resolved
        if !fileManager.createFile(at: outputDirectoryHashFile, contents: Data(asset.checksum.utf8)) {
            // fileManager.createFile is used for test purpose.

            // Try to write the checksum to the file directly with a string method to get error if it fails.
            try asset.checksum.write(to: outputDirectoryHashFile, atomically: true, encoding: .utf8)
        }
    }

    func unzip(_ dependency: Dependency, asset: Dependency.Asset) throws {
        guard try shouldResolve(dependency, asset: asset) else { return }
        let tempRootDirURL = fileManager.privateDownloadsDirectoryURL

        let tempDir = tempRootDirURL.appending(path: uuidString, directoryHint: .isDirectory)
        try createDirectoryIfNeeded(at: tempDir)

        defer {
            try? fileManager.removeItem(at: tempRootDirURL)
        }

        // Unpack downloaded file to the temporary dir, so we can traverse through the contents and copy only specified `asset.contents`.
        let downloadedFileURL = downloadURL(for: dependency, asset: asset)
        try unarchiver.unzip(archivePath: downloadedFileURL.path(percentEncoded: false), outputFilePath: tempDir.path(percentEncoded: false))

        // if we have additional contents directory from dependency, we should use it
        let contentsDirectoryURL = tempDir.appending(path: asset.contents ?? "", directoryHint: .isDirectory)

        let contents = try fileManager.contentsOfDirectory(at: contentsDirectoryURL)

        let outputDirectory = outputDirectoryURL(for: dependency, asset: asset)

        try createDirectoryIfNeeded(at: outputDirectory)

        for item in contents {
            let downloadedFileURL = contentsDirectoryURL.appending(path: item, directoryHint: .notDirectory)
            let destinationFileURL = outputDirectory.appending(path: item, directoryHint: .notDirectory)
            if fileManager.fileExists(at: destinationFileURL) {
                Logger.log("[Unzip] Removing \(destinationFileURL.relativeFilePath).")
                try fileManager.removeItem(at: destinationFileURL)
            }

            Logger.log("[Unzip] Copying \(downloadedFileURL.relativeFilePath) to \(destinationFileURL.relativeFilePath).")
            try fileManager.copyItem(at: downloadedFileURL, to: destinationFileURL)

            Logger.log("[Unzip] Removing temporary file at \(downloadedFileURL.relativeFilePath).")
            try? fileManager.removeItem(at: downloadedFileURL)
        }

        Logger.log("[Unzip] Successfully unzipped \(dependency.repo) to \(outputDirectory.relativeFilePath)")
    }
    
    func isFileDownloaded(for dependency: Dependency, asset: Dependency.Asset) throws -> Bool {
        let downloadedFileURL = downloadURL(for: dependency, asset: asset)
        guard fileManager.fileExists(at: downloadedFileURL) else { return false }
        Logger.log("[Download] File \(downloadedFileURL.relativeFilePath) is already downloaded. Verifying checksum")
        let checksum = try runThrowable("Calculating checksum") { try calculateChecksum(fileURL: downloadedFileURL) }

        guard checksum == asset.checksum else {
            Logger.log("[Download] Checksum is incorrect. \(checksum) != \(asset.checksum). Redownloading")
            try fileManager.removeItem(at: downloadedFileURL)
            return false
        }

        Logger.log("[Download] Checksum is correct. Skipping")
        return true
    }

    // MARK: - Locations

    /// Location of directory where the downloaded dependency will be placed
    func downloadDirectoryURL(for dependency: Dependency, asset: Dependency.Asset) -> URL {
        downloadsDirectoryURL
            .appending(components: dependency.repo, dependency.tag, asset.outputDirectory ?? "", directoryHint: .isDirectory)
    }

    /// Location of the file where the downloaded dependency will be placed
    func downloadURL(for dependency: Dependency, asset: Dependency.Asset) -> URL {
        downloadDirectoryURL(for: dependency, asset: asset)
            .appending(path: asset.checksum + ".zip", directoryHint: .notDirectory)
    }

    func outputDirectoryURL(for dependency: Dependency, asset: Dependency.Asset) -> URL {
        outputDirectoryURL
            .appending(components: dependency.repo, asset.outputDirectory ?? "", directoryHint: .isDirectory)
    }

    func outputDirectoryHashFile(for dependency: Dependency, asset: Dependency.Asset) throws -> URL {
        var filename = [asset.pattern, asset.contents]
            .compactMap { $0 }
            .joined(separator: "_")
            // Normalize the filename to be safe for file systems: replace non-alphanumeric characters with underscores
            .components(separatedBy: .alphanumerics.inverted)
            .joined(separator: "_")

        guard !filename.isEmpty else {
            throw GenericError("Asset \(asset) not found in dependency \(dependency.repo)")
        }

        filename = ".\(filename).hash"

        return outputDirectoryURL(for: dependency, asset: asset)
            .appending(path: filename, directoryHint: .notDirectory)
    }

    var downloadsDirectoryURL: URL {
        cacheDirectoryURL.appending(path: ".downloads", directoryHint: .isDirectory)
    }

    func createDirectoryIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(at: url) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    // MARK: - Utils

    private func runThrowable<T>(_ message: String = "", run: () throws -> T) rethrows -> T {
        do {
            return try run()
        } catch {
            Logger.log("Error: \(message) has failed.\n\(error)")
            throw error
        }
    }

    private func calculateChecksum(fileURL: URL) throws -> String {
        try checksumCalculator.calculateChecksum(fileURL: fileURL)
    }
}


extension FileManagerProtocol {
    var privateDownloadsDirectoryURL: URL {
        temporaryDirectory.appending(path: "PrivateDownloads", directoryHint: .isDirectory)
    }
}
