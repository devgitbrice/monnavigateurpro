import Foundation

struct EnvReader {
    private static var cache: [String: String]?

    static func value(forKey key: String) -> String? {
        if cache == nil {
            cache = loadEnv()
        }
        return cache?[key]
    }

    static func reload() {
        cache = loadEnv()
    }

    private static func loadEnv() -> [String: String] {
        var values: [String: String] = [:]

        // Search for .env in known locations
        let paths = envSearchPaths()

        for path in paths {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                print("[EnvReader] Fichier .env trouvé: \(path)")
                for line in content.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    // Skip comments and empty lines
                    if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

                    let parts = trimmed.split(separator: "=", maxSplits: 1)
                    if parts.count == 2 {
                        let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                        var val = String(parts[1]).trimmingCharacters(in: .whitespaces)
                        // Remove surrounding quotes
                        if (val.hasPrefix("\"") && val.hasSuffix("\"")) ||
                           (val.hasPrefix("'") && val.hasSuffix("'")) {
                            val = String(val.dropFirst().dropLast())
                        }
                        if !val.isEmpty {
                            values[key] = val
                        }
                    }
                }
                break // Use the first .env found
            }
        }

        if values.isEmpty {
            print("[EnvReader] Aucun fichier .env trouvé.")
        }

        return values
    }

    private static func envSearchPaths() -> [String] {
        var paths: [String] = []

        // 1. Next to the executable (dev builds)
        if let execURL = Bundle.main.executableURL {
            let projectDir = execURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            paths.append(projectDir.appendingPathComponent(".env").path)
        }

        // 2. Bundle resource
        if let bundlePath = Bundle.main.path(forResource: ".env", ofType: nil) {
            paths.append(bundlePath)
        }

        // 3. Common project locations in Documents
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        paths.append("\(home)/Documents/monnavigateurpro/.env")
        paths.append("\(home)/Developer/monnavigateurpro/.env")
        paths.append("\(home)/Desktop/monnavigateurpro/.env")

        // 4. Source project directory (Xcode sets this via SRCROOT)
        if let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
            paths.append("\(srcRoot)/.env")
        }

        return paths
    }
}
