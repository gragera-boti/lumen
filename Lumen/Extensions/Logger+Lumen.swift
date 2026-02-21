import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.gragera.lumen"

    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    static let service = Logger(subsystem: subsystem, category: "Service")
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let background = Logger(subsystem: subsystem, category: "Background")
    static let widget = Logger(subsystem: subsystem, category: "Widget")
}
