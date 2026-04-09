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
        cache = nil
    }

    private static func loadEnv() -> [String: String] {
        var values: [String: String] = [:]

        let paths = envSearchPaths()
        print("[EnvReader] Recherche .env dans: \(paths)")

        for path in paths {
            if FileManager.default.fileExists(atPath: path),
               let content = try? String(contentsOfFile: path, encoding: .utf8) {
                print("[EnvReader] .env trouvé: \(path)")
                values = parseEnv(content)
                break
            }
        }

        if values.isEmpty {
            print("[EnvReader] Aucun .env trouvé ou fichier vide.")
        } else {
            print("[EnvReader] \(values.count) clefs chargées: \(Array(values.keys))")
        }

        return values
    }

    private static func parseEnv(_ content: String) -> [String: String] {
        var values: [String: String] = [:]
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[trimmed.startIndex..<equalsIndex])
                .trimmingCharacters(in: .whitespaces)
            var val = String(trimmed[trimmed.index(after: equalsIndex)...])
                .trimmingCharacters(in: .whitespaces)

            // Remove surrounding quotes
            if val.count >= 2 {
                if (val.hasPrefix("\"") && val.hasSuffix("\"")) ||
                   (val.hasPrefix("'") && val.hasSuffix("'")) {
                    val = String(val.dropFirst().dropLast())
                }
            }

            if !val.isEmpty {
                values[key] = val
            }
        }
        return values
    }

    private static func envSearchPaths() -> [String] {
        var paths: [String] = []

        // 1. SRCROOT (Xcode sets this during build/run)
        if let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
            paths.append("\(srcRoot)/.env")
        }

        // 2. Real home directory (bypasses sandbox container)
        if let pw = getpwuid(getuid()) {
            let realHome = String(cString: pw.pointee.pw_dir)
            paths.append("\(realHome)/Documents/monnavigateurpro/.env")
            paths.append("\(realHome)/Desktop/monnavigateurpro/.env")
            paths.append("\(realHome)/Developer/monnavigateurpro/.env")
        }

        // 3. Sandbox home (fallback)
        let sandboxHome = NSHomeDirectory()
        paths.append("\(sandboxHome)/Documents/monnavigateurpro/.env")

        // 4. Next to the app bundle
        if let bundlePath = Bundle.main.bundlePath.components(separatedBy: "/Build/").first {
            paths.append("\(bundlePath)/.env")
        }

        // 5. Bundle resource
        if let bundlePath = Bundle.main.path(forResource: ".env", ofType: nil) {
            paths.append(bundlePath)
        }

        return paths
    }
}
