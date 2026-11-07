# Dependency security review: swift-snapshot-testing

*Adversarial source review · release 1.19.7 · November 7, 2026*

## Decision summary

| Item | Value |
|---|---|
| Package | `pointfreeco/swift-snapshot-testing`, MIT license |
| Version reviewed | 1.19.7, commit `1488390b0735e726564b948bf08b384398bdab5c` (2026-10-21) |
| Proposed use | `SnapshotTesting` product, linked into test targets exclusively |
| Recommendation | **Approve with conditions** (section 6) |
| Confidence in recommendation | 90% |

Confidence scale: 100% means verified directly against the source or tool output. Lower values are inferences, with the estimated probability that the statement is correct.

## 1. Scope and method

The release was cloned at tag 1.19.7 into an isolated directory, separate from the Wishfully workspace, and read as untrusted data. The review covered the package manifest, the pinned dependency file, and the 34 source files (7,677 lines) of the `SnapshotTesting` target. Each file was searched for these risk categories: process execution, network access, environment access, file writes, dynamic code evaluation, unsafe memory access, deserialization, Objective-C runtime manipulation, build plugins and binary artifacts. Every match was read in context.

The `InlineSnapshotTesting` and `SnapshotTestingCustomDump` targets fall outside the proposed use and were reviewed at manifest level.

## 2. Verified facts (100%)

| Area | Finding |
|---|---|
| Build-time code | The manifest declares zero build-tool plugins, zero binary targets, zero `unsafeFlags` and zero linker settings. |
| Target dependencies | The `SnapshotTesting` target declares zero dependencies. |
| Package dependencies | The package declares `swift-custom-dump` (Point-Free) and `swift-syntax` (Apple); its resolved file adds `xctest-dynamic-overlay` (Point-Free). All three serve the other two products. |
| Process execution | Zero uses of `Process`, `NSTask`, `posix_spawn`, `system`, `popen` or `exec*` in `SnapshotTesting`. |
| Diff tool setting | `SnapshotTestingConfiguration.DiffTool` returns a command **string** for the failure message; the library executes zero commands. |
| Network | Zero uses of `URLSession`, `NWConnection` or sockets. `URLRequest` appears as a value type to snapshot (formatting a request as text). URLs elsewhere are documentation comments. |
| Dynamic evaluation | Zero uses of `JSContext`, `evaluateJavaScript`, `NSExpression`, `NSAppleScript`, `dlopen` or `dlsym`. |
| Environment reads | `SNAPSHOT_TESTING_RECORD` (record mode), `SNAPSHOT_ARTIFACTS` (failure output folder) and `__XCODE_BUILT_PRODUCTS_DIR_PATHS` (Xcode detection). |
| File writes | Reference images go to a `__Snapshots__` folder beside the test file; failure images go to `SNAPSHOT_ARTIFACTS`, defaulting to the temporary directory. Test names pass through `sanitizePathComponent`, which replaces every non-word character run with `-`, so a test name maps to a single path component. |
| Source rewriting | A deprecated inline-snapshot function in `Internal/Deprecations.swift` rewrites the calling test's source file when recording. It runs when that deprecated API is called. |
| Private selectors | Text strategies that dump view hierarchies call private Objective-C selectors (`recursiveDescription`, `_printHierarchy`, `_subtreeDescription`) through `perform(Selector(...))`. They run when those strategies are used. |
| Unsafe memory | Three sites, all in image comparison: a `CGPath` point buffer and two pixel-buffer accesses for Core Graphics contexts. |
| Web views | `WKWebView` is imported to snapshot web views when a test passes one in. |
| Swift Testing | Supported through a `.snapshots` test trait. |
| Integrity | The release commit carries a PGP signature. The tag is lightweight (a pointer to the commit). |

## 3. Inferences

| Statement | Confidence |
|---|---|
| The release commit was created through GitHub's web interface (merge), based on the signing key ID matching GitHub's web-flow key. | 85% |
| Swift Package Manager's target-based resolution fetches `swift-syntax` and `swift-custom-dump` source for version solving and compiles only the `SnapshotTesting` target for this use. Their code runs in Wishfully's build when a target that uses them is linked. | 75% |
| The library is actively maintained: the latest release is from October 2026, and the maintainers have published releases continuously for several years. | 85% |
| The image-comparison unsafe-memory sites carry low risk: they operate on buffers sized from images the test itself renders. | 90% |
| Overall attack surface in the proposed use (test-only, `SnapshotTesting` product, references stored in the repository) is low. | 90% |

## 4. Threat analysis

| Vector | Exposure in proposed use | Residual risk |
|---|---|---|
| Malicious code shipped to users | Linked into test targets exclusively; the shipped app contains zero bytes of it | Very low |
| Compromise of CI through the library | Runs inside the macOS test job; reads three environment variables; writes images to known folders | Low |
| Secret exfiltration from CI | Zero network code; the test job holds zero signing secrets (those live in the protected release environment) | Very low |
| Supply-chain update (a future malicious release) | Exact version pin plus `Package.resolved` revision; Dependabot cooldown of 7 days; maintainer reviews each update's diff | Low, controlled |
| Transitive packages | Fetched for resolution; compiled when their products are used | Low with the conditions below |
| Source rewriting | Deprecated inline API rewrites test files | Removed by condition 3 |
| Private API use | Debug-description strategies; test process only | Very low |

## 5. Alternatives considered

| Option | Trade-off |
|---|---|
| swift-snapshot-testing (`SnapshotTesting` product) | Mature image diffing with tolerances; one dependency-free target |
| Custom helper built on SwiftUI `ImageRenderer` | Zero third-party code; requires writing and maintaining image comparison and tolerance logic |
| Screenshots from UI tests only | Zero dependencies; covers whole screens, misses component states and size or appearance variants |

## 6. Conditions for approval

1. **Product:** depend on the `SnapshotTesting` product alone, declared in the `WishfullyUI` package's `Package.swift`, in test targets exclusively.
2. **Pin:** `exact: "1.19.7"`, with `Package.resolved` committed so the revision hash is fixed.
3. **API surface:** use `assertSnapshot` and the `.snapshots` trait. The deprecated inline APIs and the view-hierarchy text strategies stay out of the codebase; the forbidden-API check enforces this.
4. **Artifacts:** CI sets `SNAPSHOT_ARTIFACTS` to a folder inside the job workspace, uploaded as a build artifact.
5. **Updates:** every Dependabot update to this package receives a diff review against this report's risk categories before the maintainer approves it.
6. **Re-review trigger:** a new dependency in the `SnapshotTesting` target, any build plugin, or any process or network code in a future release reopens this review.

## 7. Recommendation

Approve `swift-snapshot-testing` 1.19.7 under the conditions above. Confidence: 90%. The main residual risk is a future compromised release, which the exact pin, cooldown and diff review address.
