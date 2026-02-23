import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.gragera.lumen"

    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    static let data = Logger(subsystem: subsystem, category: "Data")
}
