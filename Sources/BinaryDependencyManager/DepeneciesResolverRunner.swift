import CryptoKit
import Foundation

struct DependenciesResolverRunner {
    let dependenciesJSONPath: String

    let cacheDirectoryPath: String

    let outputDirectoryPath: String

    func run() throws {
        let dependencies = try runThrowable("Reading dependencies") { try readDependencies() }

        // resolve dependencies one by one
        for dependency in dependencies {
            try runThrowable("Resolving \(dependency.repo)") { try resolve(dependency) }
        }
    }

    private func resolve(_ dependency: Dependency) throws {
        guard shouldResolve(dependency) else { return }
        try runThrowable("Downloading \(dependency.repo)") { try download(dependency) }
        try runThrowable("Unzipping \(dependency.repo)") { try unzip(dependency) }
        try markAsResolved(dependency)
    }

    private func download(_ dependency: Dependency) throws {
        let uniqueDir = downloadDirectory(for: dependency)
        let filePath = downloadPath(for: dependency)

        try createDirectoryIfNeeded(at: uniqueDir)

        guard try !isFileDownloaded(for: dependency) else { return }

        let githubCommandLineToolPath = try resolveGithibCLIPath()
        try downlodWithGithubCommandLineTool(githubCommandLineToolPath, dependency: dependency, filePath: filePath)

        let checksum = try runThrowable("Calculating checksum") { try calculateChecksum(path: filePath) }

        guard checksum == dependency.checksum else {
            throw NSError(domain: "Checksum is incorrect. \(checksum) != \(dependency.checksum)", code: 0)
        }
    }

    private func downlodWithGithubCommandLineTool(_ cliPath: String, dependency: Dependency, filePath: String) throws {
        let githubCommandLineTool = URL(fileURLWithPath: cliPath)
        let arguments: [String] = [
            ["release"],
            ["download"],
            ["\(dependency.tag)"],
            dependency.pattern.map { ["--pattern", "\($0)"] } ?? [],
            ["-R", "\(dependency.repo)"],
            ["-O", "\(filePath)"]
        ].flatMap { $0 }

        Logger.log("[Download] ⬇️  \(dependency.repo) with tag \(dependency.tag) to \(filePath)")
        Logger.log("[Download] \(cliPath) \(arguments.joined(separator: " "))")

        let process = try Process.run(githubCommandLineTool, arguments: arguments)
        process.waitUntilExit()
    }

    private func resolveGithibCLIPath() throws -> String {
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = ["gh"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let githubCommandLineToolPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw NSError(domain: "Can't find github command line tool", code: 0)
        }
        return githubCommandLineToolPath
    }

    private func shouldResolve(_ dependency: Dependency) -> Bool {
        let outputDirectoryHashFile = outputDirectoryHashFile(for: dependency)
        let hash = try? String(contentsOf: URL(fileURLWithPath: outputDirectoryHashFile), encoding: .utf8)
        if hash == dependency.checksum {
            Logger.log("[Resolve] \(outputDirectoryHashFile). Skipped ✅")
            return false
        }
        return true
    }

    private func markAsResolved(_ dependency: Dependency) throws {
        let outputDirectoryHashFile = outputDirectoryHashFile(for: dependency)
        // Create hash file which will be used as a marker that dependency is resolved
        try dependency.checksum.write(toFile: outputDirectoryHashFile, atomically: true, encoding: .utf8)
    }

    private func unzip(_ dependency: Dependency) throws {
        guard shouldResolve(dependency) else { return }
        let tempRootDir = NSTemporaryDirectory() + "/PrivateDownloads/"

        let tempDir = tempRootDir + NSUUID().uuidString
        try createDirectoryIfNeeded(at: tempDir)

        defer {
            try? FileManager.default.removeItem(atPath: tempRootDir)
        }

        let filePath = downloadPath(for: dependency)
        let process = try Process.run(URL(fileURLWithPath: "/usr/bin/unzip"), arguments: ["-q", filePath, "-d", tempDir])
        process.waitUntilExit()

        // if we have additional contents directory from dependency, we should use it
        let contentsDirectory = if let contents = dependency.contents {
            tempDir + "/" + contents
        } else {
            tempDir
        }

        let contents = try FileManager.default.contentsOfDirectory(atPath: contentsDirectory)

        let outputDirectory = outputDirectory(for: dependency)
        if FileManager.default.fileExists(atPath: outputDirectory) {
            Logger.log("[Unzip] Removing \(outputDirectory).")
            try FileManager.default.removeItem(atPath: outputDirectory)
        }

        try createDirectoryIfNeeded(at: outputDirectory)

        for item in contents {
            let itemPath = contentsDirectory + "/" + item
            let destinationPath = outputDirectory + "/" + item
            try FileManager.default.copyItem(atPath: itemPath, toPath: destinationPath)
        }

        Logger.log("[Unzip] Successfully unzipped \(dependency.repo) to \(outputDirectory)")
    }

    private func isFileDownloaded(for dependency: Dependency) throws -> Bool {
        let filePath = downloadPath(for: dependency)
        guard FileManager.default.fileExists(atPath: filePath) else { return false }
        Logger.log("[Download] File \(filePath) is already downloaded. Verifying checksum")
        let checksum = try runThrowable("Calculating checksum") { try calculateChecksum(path: filePath) }

        guard checksum == dependency.checksum else {
            Logger.log("[Download] Checksum is incorrect. \(checksum) != \(dependency.checksum). Redownloading")
            try FileManager.default.removeItem(atPath: filePath)
            return false
        }

        Logger.log("[Download] Checksum is correct. Skipping")
        return true
    }

    // MARK: - Reading dependencies

    private func readDependencies() throws -> [Dependency] {
        // Get the contents of the file
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: dependenciesJSONPath), options: .mappedIfSafe)

        let decoder = JSONDecoder()
        let dependencies = try decoder.decode([Dependency].self, from: jsonData)
        let depedenciesInfo = dependencies.map { "   \($0.repo)(\($0.tag))" }.joined(separator: "\n")
        Logger.log(
            "[Read] Found \(dependencies.count) dependencies:\n\(depedenciesInfo)"
        )

        return dependencies
    }

    // MARK: - Locations

    /// Location of directory where the downloaded dependency will be placed
    private func downloadDirectory(for dependency: Dependency) -> String {
        [downloadsDirectory, dependency.repo, dependency.tag].joined(separator: "/")
    }

    /// Location of the file where the downloaded dependency will be placed
    private func downloadPath(for dependency: Dependency) -> String {
        downloadDirectory(for: dependency) + "/" + dependency.checksum + ".zip"
    }

    private func outputDirectory(for dependency: Dependency) -> String {
        [outputDirectoryPath, dependency.repo, dependency.output]
            .compactMap { $0 }
            .joined(separator: "/")
    }

    private func outputDirectoryHashFile(for dependency: Dependency) -> String {
        outputDirectory(for: dependency) + "/.hash"
    }

    private var downloadsDirectory: String {
        cacheDirectoryPath + "/.downloads"
    }

    private func createDirectoryIfNeeded(at path: String) throws {
        if !FileManager.default.fileExists(atPath: path) {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
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

    private func calculateChecksum(path: String) throws -> String {
        let handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let nextChunk = handle.readData(ofLength: 1024 * 1024)
            guard !nextChunk.isEmpty else { return false }
            hasher.update(data: nextChunk)
            return true
        }) {}
        let digest = hasher.finalize()
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
