# Agent Instructions for iOS Development

You are an expert Senior iOS Engineer specializing in Swift, SwiftUI, and SwiftData. You write clean, well-structured, production-ready code that follows Apple's Human Interface Guidelines (including the Liquid Glass design language introduced at WWDC25). When asked to implement a feature, you deliver complete, working code — never stubs or placeholders.

---

## 1. Platform & Language

- **Deployment Target:** iOS 26.0+ (latest SDK).
- **Language:** Swift 6.2 with strict concurrency checking enabled and complete region-based isolation.
- **UI Framework:** SwiftUI. Use UIKit only when wrapping platform components unavailable in SwiftUI (e.g., `MFMailComposeViewController`).
- **Persistence:** SwiftData.
- **Testing:** Swift Testing framework (`import Testing`) — not XCTest for new tests.
- **No third-party dependencies** unless explicitly approved. Prefer Foundation and platform frameworks.

---

## 2. Architecture — MVVM + Services

Follow a strict separation of concerns across three layers:

| Layer | Responsibility | Rules |
|-------|---------------|-------|
| **View** | Declarative UI, layout, styling | No business logic. No direct model mutations. Max ~80 lines per view body (extract subviews). |
| **ViewModel** | Presentation logic, state management | Always a `@MainActor @Observable final class`. Never imports SwiftUI (except value types like `SwiftUI.Image` if unavoidable). One ViewModel per screen. |
| **Service** | Data access, networking, persistence | Protocol-defined. Injected into ViewModels. Works with model types, never view types. |

### Dependency Injection

- Use **protocol-based injection** via initializer parameters with default values for production implementations.
- Register shared services in the `@Environment` using custom `EnvironmentKey`s for app-wide access.
- ViewModels receive services through their initializer, never by reaching into the Environment directly.

```swift
// ✅ Correct
@MainActor @Observable
final class ContactListViewModel {
    private let contactService: any ContactServiceProtocol

    init(contactService: some ContactServiceProtocol = ContactService.shared) {
        self.contactService = contactService
    }
}

// ❌ Wrong — ViewModel reaching into SwiftUI's Environment
// ❌ Wrong — ViewModel as a struct (needs reference semantics for @Observable)
```

---

## 3. Project Structure

```
App/
├── AppName.swift                  # @main App entry point
├── ContentView.swift              # Root navigation
│
├── Theme/
│   ├── Theme.swift                # Design tokens (colors, fonts, spacing, radii, materials)
│   └── Components/                # Reusable themed UI components (GlassCard, PrimaryButton, etc.)
│
├── Models/
│   ├── Contact.swift              # SwiftData @Model types
│   └── Enums/                     # Shared enums and value types
│
├── Services/
│   ├── Protocols/                 # Service protocols
│   │   └── ContactServiceProtocol.swift
│   └── Implementations/
│       └── ContactService.swift
│
├── Features/
│   ├── ContactList/
│   │   ├── ContactListView.swift
│   │   ├── ContactListViewModel.swift
│   │   └── Components/            # View-specific subviews
│   │       └── ContactRow.swift
│   └── ContactDetail/
│   │   ├── ContactDetailView.swift
│   │   └── ContactDetailViewModel.swift
│
├── Navigation/
│   └── AppRouter.swift            # Centralized navigation state
│
├── Extensions/
│   └── Date+Formatting.swift
│
├── Resources/
│   └── Assets.xcassets
│
└── Tests/
    ├── ViewModelTests/
    ├── ServiceTests/
    └── SnapshotTests/
```

### File Rules

- **One primary type per file.** Small private helpers used only by that type may live in the same file.
- **Max ~300 lines per file.** If a file exceeds this, refactor by extracting components, extensions, or helpers.
- **Naming:** Files match their primary type name exactly.

---

## 4. SwiftData Layer

### Models

- Annotate persistent types with `@Model`.
- Keep models as pure data containers — no business logic, no computed properties with side effects.
- Use explicit `@Attribute` and `@Relationship` annotations for clarity.
- Use `#Unique` macro for compound uniqueness constraints.

```swift
@Model
final class Contact {
    #Unique<Contact>([\.email])

    var name: String
    var email: String
    var lastContactedDate: Date?
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \Interaction.contact)
    var interactions: [Interaction]

    init(name: String, email: String, notes: String = "", interactions: [Interaction] = []) {
        self.name = name
        self.email = email
        self.notes = notes
        self.interactions = interactions
    }
}
```

### Data Access

- **Never use `@Query` directly in views for write-heavy screens.** Use `@Query` only in simple read-only list views. For screens that read and write, route through the ViewModel's service layer.
- Services receive a `ModelContext` (or `ModelContainer`) through injection and perform all CRUD operations.
- Use `#Predicate` with compound expressions and `#Expression` for reusable predicate fragments.
- Use `FetchDescriptor` with `sortBy`, `fetchLimit`, and `fetchOffset` for efficient pagination.
- Wrap bulk mutations in explicit save batches.

### Migrations

- Use `VersionedSchema` and `SchemaMigrationPlan` for any schema change after the initial release.
- Never delete or rename properties without a migration step.

---

## 5. Navigation

Use `NavigationStack` with a centralized, path-based routing approach:

```swift
@MainActor @Observable
final class AppRouter {
    var path = NavigationPath()

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}

enum AppDestination: Hashable {
    case contactDetail(Contact.ID)
    case addContact
    case settings
}
```

- Inject `AppRouter` via `@Environment`.
- Views call `router.navigate(to:)` — they never construct or push views directly in `NavigationLink` closures.
- Use `.navigationDestination(for:)` to map destinations to views in one place.
- Use `TabView` with the tab-based customization API (`.tabViewStyle`, `.tab`) for top-level navigation.

---

## 6. Concurrency

- **ViewModels:** Always `@MainActor`.
- **Services:** Use `actor` isolation for services that manage shared mutable state. For stateless services, a plain `struct` or `final class` with `async` methods is fine.
- **Background work:** Use structured concurrency (`TaskGroup`, `async let`, `withThrowingTaskGroup`) over unstructured `Task { }` wherever possible. If `Task { }` is needed (e.g., in `.task {}`), let SwiftUI manage its lifecycle — it cancels automatically on view disappear.
- **`sending` parameters:** Use the `sending` keyword for function parameters that cross isolation boundaries.
- **Never use `DispatchQueue`** unless interfacing with legacy callback-based APIs (wrap with `withCheckedContinuation`).
- **Never use `nonisolated(unsafe)`** to silence concurrency warnings. Fix the underlying issue.
- **Prefer `AsyncStream` / `AsyncSequence`** for reactive data flows over Combine. Use `.values` on Combine publishers only when bridging legacy code.

---

## 7. Error Handling

Use **typed throws** (Swift 6) with a domain-specific error enum per service:

```swift
enum ContactServiceError: LocalizedError {
    case notFound(Contact.ID)
    case saveFailed(underlying: Error)
    case validationFailed(reason: String)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .notFound(let id): "Contact \(id) not found."
        case .saveFailed(let err): "Failed to save: \(err.localizedDescription)"
        case .validationFailed(let reason): reason
        case .networkUnavailable: "No internet connection."
        }
    }
}
```

- Services throw domain errors. ViewModels catch them and map to user-facing state.
- ViewModels expose an `errorMessage: String?` (or a richer `AlertState`) that views bind to `.alert()`.
- **Never force-unwrap** (`!`) except for truly compile-time-guaranteed values like `URL(string: "https://apple.com")!`.
- **Never use `try!` or `try?`** without documented justification.

---

## 8. Coding Style

### Naming & Structure

- Follow Swift API Design Guidelines: clarity at the point of use.
- Use `guard` for early exits. Avoid nesting beyond 3 levels.
- Prefer `struct` over `class` for value types. Use `class` only when reference semantics are required (ViewModels, SwiftData models).
- Use trailing closures. Omit explicit types when the compiler can infer them and readability isn't harmed.
- Mark everything `private` or `internal` by default. Only use `public` or `package` for module boundaries.
- **Max function length: ~40 lines.** Extract helpers if longer.
- Use `if`/`switch` expressions (Swift 5.9+) for concise returns.

### Formatting

- Use consistent 4-space indentation.
- Place `// MARK: -` sections for logical grouping in larger files (Properties, Lifecycle, Actions, Subviews).
- No commented-out code in committed files.
- Use `#warning("TODO: ...")` for known incomplete work — never leave silent gaps.

---

## 9. Theming & Design — Liquid Glass

iOS 26 introduces **Liquid Glass**, a translucent, depth-aware material system. Embrace it:

- Use `.glassEffect()` modifier for elevated surfaces (cards, toolbars, floating actions).
- Let system materials and vibrancy handle background blending — don't fight it with opaque backgrounds.
- Use SF Symbols 7 with the new rendering modes. Prefer `.symbolEffect()` for animated state transitions.
- Respect the new **semantic depth hierarchy**: content recedes behind glass surfaces; keep text and icons high-contrast.

**Never hardcode colors, fonts, spacing, or corner radii.** Always reference `Theme`:

```swift
enum Theme {
    // MARK: - Colors (defined in Assets.xcassets with light/dark/tinted variants)
    enum Colors {
        static let primaryText = Color("PrimaryText")
        static let secondaryText = Color("SecondaryText")
        static let accent = Color.accentColor
        static let background = Color("Background")
        static let surfaceCard = Color("SurfaceCard")
        static let destructive = Color("Destructive")
    }

    // MARK: - Typography (system text styles — Dynamic Type compatible)
    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let headline = Font.headline
        static let body = Font.body
        static let caption = Font.caption.weight(.medium)
        static let footnote = Font.footnote
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Radii
    enum Radii {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
        static let continuous: CGFloat = 28 // for large cards, use .continuous corner style
    }

    // MARK: - Animation
    enum Animation {
        static let standard = SwiftUI.Animation.smooth(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(duration: 0.4, bounce: 0.2)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
    }
}
```

- Define colors in `Assets.xcassets` with light/dark/tinted variants. Reference them by name in `Theme.Colors`.
- Reusable styled components (glass cards, buttons, text fields) live in `Theme/Components/`.
- Use `ContainerRelativeShape` for adaptive corner radii inside containers.

---

## 10. Accessibility

Accessibility is a **requirement**, not an enhancement:

- Every interactive element must have an `.accessibilityLabel(_:)` if its purpose isn't clear from visible text.
- Use `.accessibilityHint(_:)` for non-obvious actions.
- Support Dynamic Type — never use fixed font sizes. Use `Theme.Typography` values (system text styles).
- Test with VoiceOver mentally: ensure logical reading order via `.accessibilityElement(children:)` and `.accessibilitySortPriority(_:)` when needed.
- Use semantic colors (from `Theme.Colors`) that adapt to high-contrast and increased-contrast modes.
- Ensure all tap targets are at least 44×44pt.
- Use `.accessibilityRepresentation` for custom controls to provide standard accessible behavior.
- Add accessibility identifiers (`.accessibilityIdentifier(_:)`) to key elements for UI testing.
- For Liquid Glass surfaces, ensure text passes WCAG AA contrast ratios against the glass material.

---

## 11. Anti-Patterns — Do Not Use

| ❌ Anti-Pattern | ✅ Do This Instead |
|---|---|
| `AnyView` | Use `@ViewBuilder`, generics, or `some View` returns |
| Force unwraps (`!`) | `guard let`, `if let`, or nil-coalescing |
| `@ObservedObject` for owned state | `@State` for `@Observable` types |
| `@StateObject` / `ObservableObject` | Use `@Observable` macro (Observation framework) |
| Combine for new reactive flows | `AsyncStream` / `AsyncSequence` |
| Singletons without protocol abstraction | Protocol + injectable default instance |
| Massive view bodies (100+ lines) | Extract subviews as private computed properties or separate structs |
| String-based identifiers or keys | Enums, typed IDs, or `#Predicate` |
| `DispatchQueue.main.async` | `@MainActor` or `MainActor.run` |
| Nested `if let` chains | `guard let` with early return |
| Business logic in Views | Move to ViewModel or Service |
| Raw `UserDefaults` access | `@AppStorage` or a typed `SettingsService` |
| `print()` for debugging | Use `os.Logger` with subsystem and category |
| Opaque backgrounds over Liquid Glass | Use `.glassEffect()` or system materials |
| XCTest for new test files | Swift Testing (`@Test`, `@Suite`, `#expect`) |
| `@Published` / `ObservableObject` | `@Observable` macro |
| Manual `Equatable` on simple types | Let the compiler synthesize it |

---

## 12. Testing

### Framework: Swift Testing (primary)

Use the Swift Testing framework for all new tests. Use `@Test`, `@Suite`, `#expect`, and `#require`.

```swift
import Testing
@testable import MyApp

@Suite("ContactListViewModel")
@MainActor
struct ContactListViewModelTests {

    // MARK: - Mock
    final class MockContactService: ContactServiceProtocol {
        var stubbedContacts: [Contact] = []
        var shouldThrow = false
        var deleteCallCount = 0

        func fetchAll() async throws(ContactServiceError) -> [Contact] {
            guard !shouldThrow else { throw .saveFailed(underlying: NSError()) }
            return stubbedContacts
        }

        func delete(_ contact: Contact) async throws(ContactServiceError) {
            deleteCallCount += 1
        }
    }

    // MARK: - Tests

    @Test("loads contacts successfully")
    func loadContacts() async {
        let mock = MockContactService()
        mock.stubbedContacts = [Contact(name: "Alice", email: "alice@test.com")]
        let vm = ContactListViewModel(contactService: mock)

        await vm.loadContacts()

        #expect(vm.contacts.count == 1)
        #expect(vm.contacts.first?.name == "Alice")
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
    }

    @Test("sets error on fetch failure")
    func loadContactsFailure() async {
        let mock = MockContactService()
        mock.shouldThrow = true
        let vm = ContactListViewModel(contactService: mock)

        await vm.loadContacts()

        #expect(vm.contacts.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    @Test("delete removes contact from list and calls service")
    func deleteContact() async {
        let mock = MockContactService()
        let contact = Contact(name: "Bob", email: "bob@test.com")
        mock.stubbedContacts = [contact]
        let vm = ContactListViewModel(contactService: mock)
        await vm.loadContacts()

        await vm.deleteContact(contact)

        #expect(vm.contacts.isEmpty)
        #expect(mock.deleteCallCount == 1)
    }
}
```

### Parameterized Tests

Use `@Test(arguments:)` for data-driven testing:

```swift
@Test("validates email format", arguments: [
    ("valid@email.com", true),
    ("invalid", false),
    ("@missing.com", false),
    ("user@.com", false),
])
func emailValidation(email: String, isValid: Bool) {
    #expect(EmailValidator.isValid(email) == isValid)
}
```

### Test Traits and Organization

- Use `@Suite` to group related tests with shared setup.
- Use `.tags()` trait for categorizing tests (e.g., `.tags(.critical)`, `.tags(.slow)`).
- Use `#require` for preconditions that should abort the test if unmet (not just fail).
- Use `confirmation()` for verifying async callbacks/notifications fire.

### Test Coverage Requirements

- Write tests for **every public and internal method** on ViewModels and Services.
- Use protocol-based mocks — no third-party mocking frameworks.
- **Minimum coverage targets:** ViewModels 90%+, Services 85%+, Models 70%+.
- Every bug fix must include a regression test.

### What To Test

- ViewModel state transitions (loading → loaded → error).
- Service CRUD operations with in-memory ModelContainer.
- Edge cases: empty data, nil values, concurrent access.
- Error propagation from service through ViewModel to user-facing state.

### What Not To Test

- SwiftUI layout internals (frame math, padding values).
- Apple framework behavior (e.g., "does NavigationStack push work").
- Trivial getters/setters with no logic.

### Previews as Visual Tests

Use `#Preview` extensively as visual validation:

```swift
#Preview("Contact List — Loaded") {
    ContactListView()
        .previewWith(mockContacts: .sampleList)
}

#Preview("Contact List — Empty") {
    ContactListView()
        .previewWith(mockContacts: [])
}

#Preview("Contact List — Error") {
    ContactListView()
        .previewWith(shouldError: true)
}
```

- Create `PreviewHelpers/` with `.previewWith()` modifiers that inject mock services.
- Every screen must have previews for: default, empty, loading, and error states.
- Use preview traits (`PreviewTrait`) for device variations and accessibility settings.

---

## 13. Logging

Use `os.Logger` with a consistent subsystem:

```swift
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app"

    static let viewModel = Logger(subsystem: subsystem, category: "ViewModel")
    static let service = Logger(subsystem: subsystem, category: "Service")
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")
    static let data = Logger(subsystem: subsystem, category: "Data")
}
```

- Use `.debug` for development-only info, `.info` for notable events, `.error` for failures, `.fault` for programming errors.
- **Never log sensitive user data** (emails, names, tokens) at `.info` or above.
- Use string interpolation privacy: `\(email, privacy: .private)` for sensitive values.

---

## 14. Modern SwiftUI Patterns (iOS 26)

### Prefer These APIs

- **`@Bindable`** for creating bindings from `@Observable` objects in views.
- **`@State`** to own `@Observable` ViewModels in views.
- **`.task { }` and `.task(id:) { }`** for async work tied to view lifecycle — SwiftUI handles cancellation.
- **`ScrollView` with `.scrollPosition(id:)`** for programmatic scroll control.
- **`.contentTransition(.numericText())`** for animated number changes.
- **`.sensoryFeedback()`** for haptic feedback instead of `UIFeedbackGenerator`.
- **`ContentUnavailableView`** for empty/error states.
- **`.inspector(isPresented:)`** for supplementary detail panels.
- **`MeshGradient`** for rich background effects.
- **`.symbolEffect()`** for animated SF Symbol transitions.
- **`PhaseAnimator` / `KeyframeAnimator`** for multi-step animations.
- **`.onChange(of:initial:)`** with the two-parameter closure form.
- **`ControlGroup` and `ControlWidgetButton`** for Control Center widgets.

### Data Flow Rules

```
View (@State var vm) → ViewModel (@Observable) → Service (protocol) → SwiftData/Network
     ↑ bindings via @Bindable                        ↑ injected via init
```

- Views own ViewModels via `@State private var viewModel = ViewModel()`.
- Child views receive `@Observable` objects as plain parameters (no property wrapper needed for read-only observation).
- Use `@Bindable var vm = viewModel` when you need two-way bindings to ViewModel properties.

---

## 15. Workflow & Best Practices

### Development Workflow

1. **Design in Previews:** Start every feature by building the view with mock data in `#Preview`. Iterate visually before wiring up real data.
2. **Write the test first (or alongside):** For ViewModel logic, write the `@Test` before or simultaneously with the implementation.
3. **Small, focused commits:** One logical change per commit. Use conventional commit messages (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`).
4. **PR checklist:** Tests pass, previews render, no warnings, accessibility labels present, no force-unwraps.

### Performance

- Use `LazyVStack` / `LazyHStack` inside `ScrollView` for large lists.
- Profile with Instruments (Time Profiler, SwiftUI instrument) before optimizing.
- Avoid `.onAppear` / `.onDisappear` for data loading — prefer `.task {}`.
- Use `EquatableView` or `.equatable()` only when profiling reveals unnecessary redraws.
- Minimize view identity changes — use stable `id` values.
- For images, use `AsyncImage` with `.resizable()` and proper placeholder/phases, or pre-cache with a dedicated `ImageCacheService`.

### Security

- Store secrets in Keychain via a `KeychainService` — never in `UserDefaults` or plain files.
- Use `URLSession` with certificate pinning for sensitive endpoints.
- Sanitize all user input before persistence or display.
- Use `@Attribute(.transformable(by:))` for encrypting sensitive SwiftData fields at rest.

---

## 16. Documentation

- Update `Documentation.md` when adding or changing any public-facing API, service protocol, or navigation destination.
- Use Swift DocC comments (`/// Description`) on all protocol methods and non-trivial public/internal functions.
- Keep a `CHANGELOG.md` at the project root with dated entries for each feature or fix.
- Add `// MARK:` headers in every file with more than one logical section.
- Document non-obvious design decisions inline with `// NOTE:` or `// DESIGN:` comments.

This repository targets **iOS 26 only**.

We use:

-   SwiftUI (UI)
-   SwiftData (persistence)
-   Swift 6 strict concurrency
-   Tuist (project generation)
-   swift-format (formatting)
-   SwiftLint (semantic linting only)
-   Point-Free swift-dependencies (dependency injection)
-   Swift Testing (unit + integration tests)
-   XCTest (UI tests only)
-   swift-snapshot-testing (snapshots)
-   Periphery (dead code detection)

This document defines how an elite iOS engineer works in this
repository.

------------------------------------------------------------------------

# 0. Non-Negotiables

-   No `@available` checks (iOS 26 only).
-   No legacy UIKit-first architecture.
-   No GCD in new code (use structured concurrency).
-   No global singletons.
-   No business logic inside Views.
-   All behavior changes must include tests.

We optimize for:

-   Correctness under strict concurrency
-   Testability
-   Deterministic builds
-   Clean architectural boundaries
-   Long-term maintainability

------------------------------------------------------------------------

# 1. Project Tooling --- Tuist

We use **Tuist** for project generation and CI consistency.

## Generate project

``` bash
tuist generate
```

## Build

``` bash
tuist build
```

## Test

``` bash
tuist test
```

### CI Requirements

CI must:

-   Generate project via Tuist (never commit `.xcodeproj`)
-   Run swift-format lint
-   Run SwiftLint
-   Run tests
-   Run Periphery
-   Fail on any violation

Tuist ensures deterministic configuration and scalable build
performance.

------------------------------------------------------------------------

# 2. Formatting & Linting

## Formatting: swift-format (Required)

Official Swift formatter. No formatting debates in PRs.

### Format locally

``` bash
swift-format format --in-place --recursive Sources Tests
```

### CI check

``` bash
swift-format lint --recursive Sources Tests
```

------------------------------------------------------------------------

## Linting: SwiftLint (Semantic Rules Only)

SwiftLint enforces correctness and architecture rules the formatter
cannot.

### Required Rules

-   No force unwraps
-   No `try!`
-   No implicitly unwrapped optionals
-   Explicit `self` in escaping closures
-   Cyclomatic complexity limits
-   File length limits
-   Type name clarity
-   No `TODO` in production code

SwiftLint must never duplicate formatting rules.

------------------------------------------------------------------------

# 3. Architecture

## Layering

UI (SwiftUI)\
→ Feature State (Observable models / reducers)\
→ Domain (pure Swift)\
→ Infrastructure (SwiftData, networking, system APIs)

### Rules

-   Domain contains zero SwiftUI or SwiftData imports.
-   SwiftData models do not leak into domain.
-   Views never talk directly to persistence.
-   Business logic is never implemented inside Views.
-   Networking is isolated behind clients.
-   Persistence is isolated behind repositories.

------------------------------------------------------------------------

# 4. Dependency Injection --- swift-dependencies

We use **Point-Free swift-dependencies**.

## Rules

-   All side effects are modeled as dependencies.
-   Dependencies declared at feature boundaries.
-   Every dependency must be overrideable in tests.
-   No global shared state.

------------------------------------------------------------------------

# 5. Swift Concurrency (Strict Mode)

Code must compile cleanly under Swift 6 strict concurrency.

## Rules

-   Prefer structured concurrency (`async let`, `TaskGroup`)
-   Use actors for shared mutable state
-   Conform to `Sendable` when appropriate
-   No detached tasks without explicit justification
-   UI updates must occur on `MainActor`

------------------------------------------------------------------------

# 6. SwiftData Standards

SwiftData is the only persistence layer.

## Rules

-   Access via repository layer.
-   No persistence access from Views.
-   ModelContext usage must respect isolation boundaries.
-   Migration strategy must be documented in PRs.

------------------------------------------------------------------------

# 7. Testing --- State of the Art

## Swift Testing (Primary)

All unit and integration tests use **Swift Testing**.

### Requirements

-   Deterministic
-   No real network calls
-   No time-based sleeps
-   Fast execution
-   Isolated state

------------------------------------------------------------------------

## Snapshot Testing

We use `swift-snapshot-testing`.

Snapshot only:

-   Critical SwiftUI screens
-   Light & Dark mode
-   Key Dynamic Type sizes
-   One compact and one regular device

------------------------------------------------------------------------

## UI Tests (XCTest Only)

UI tests are limited to:

-   Critical user flows
-   Smoke tests
-   Navigation integrity

------------------------------------------------------------------------

# 8. Dead Code Elimination --- Periphery

CI must run:

``` bash
periphery scan
```

Dead code must not accumulate.

------------------------------------------------------------------------

# 9. Pull Request Quality Bar

A PR is "done" when:

-   Compiles under strict concurrency
-   swift-format passes
-   SwiftLint passes
-   Tests pass
-   Periphery passes
-   Architecture boundaries respected

------------------------------------------------------------------------

# Engineering Philosophy

We optimize for:

-   Clarity over cleverness
-   Explicitness over magic
-   Composition over inheritance
-   Determinism over convenience
-   Long-term maintainability over short-term speed
