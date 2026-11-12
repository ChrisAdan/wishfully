import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WishfullyCore

/// The Share sheet's Wishfully entry. It reads the shared link, fills in the product details
/// from the page and saves the wish to the list chosen by the app.
final class ShareViewController: UIViewController {
    private let model = ShareModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        model.finish = { [weak self] saved in
            if saved {
                self?.extensionContext?.completeRequest(returningItems: nil)
            } else {
                self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
            }
        }
        let host = UIHostingController(rootView: ShareView(model: model))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)

        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        Task { await model.load(items) }
    }
}

@MainActor
@Observable
final class ShareModel {
    var draft = WishDraft()
    var isFetching = false
    var isSaving = false
    var message: String?
    let target = ListTarget.loadShareTarget()
    @ObservationIgnored var finish: (Bool) -> Void = { _ in }

    /// Reads the shared link and title, then fetches the page.
    func load(_ items: [NSExtensionItem]) async {
        var texts: [String] = []
        for item in items {
            if let text = item.attributedContentText?.string {
                texts.append(text)
            }
            for provider in item.attachments ?? [] {
                if let text = await Self.text(from: provider) {
                    texts.append(text)
                }
            }
        }
        let shared = texts.map(SharedText.init)
        draft.urlText = shared.lazy.compactMap(\.url).first?.absoluteString ?? ""
        draft.title = shared.lazy.compactMap(\.title).first ?? ""
        await fetch()
    }

    func fetch() async {
        guard let url = draft.url else { return }
        isFetching = true
        let page = await PageFetcher.fetch(url)
        // The page's own title is usually better than the text the app shared.
        if let title = page.metadata.title {
            draft.title = title
        }
        draft.fill(from: page)
        isFetching = false
    }

    func save() async {
        guard let target else { return }
        isSaving = true
        let wish = draft.wish()
        do {
            try await WishWriter.save(wish, photo: draft.photo, to: target, in: AppConfig.container)
            Log.share.info("Saved a wish from the Share sheet")
            finish(true)
        } catch {
            Log.share.error("Share save failed: \(error.localizedDescription, privacy: .public)")
            do {
                try Inbox.add(InboxEntry(wish: wish, target: target), photo: draft.photo)
                message = "Saved on this iPhone. It goes to iCloud the next time you open Wishfully."
            } catch {
                message = "Could not save: \(error.localizedDescription)"
            }
        }
        isSaving = false
    }

    private static func text(from provider: NSItemProvider) async -> String? {
        for type in [UTType.url, UTType.plainText] where provider.hasItemConformingToTypeIdentifier(type.identifier) {
            guard let item = try? await provider.loadItem(forTypeIdentifier: type.identifier) else { continue }
            switch item {
            case let url as URL: return url.absoluteString
            case let text as String: return text
            case let data as Data: return String(data: data, encoding: .utf8)
            default: continue
            }
        }
        return nil
    }
}

struct ShareView: View {
    @Bindable var model: ShareModel

    var body: some View {
        NavigationStack {
            Form {
                if let target = model.target {
                    if let message = model.message {
                        Section { Text(message) }
                    }
                    WishFormFields(draft: $model.draft, isFetching: model.isFetching) {
                        Task { await model.fetch() }
                    }
                    Section {
                        Text("Adds to \(target.title)").foregroundStyle(.secondary)
                    }
                } else {
                    Text("Open Wishfully once and create your list. Then the Share button can add to it.")
                }
            }
            .navigationTitle("Add to Wishfully")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(model.message == nil ? "Cancel" : "Done") { model.finish(model.message != nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isSaving {
                        ProgressView()
                    } else if model.message == nil {
                        Button("Save") { Task { await model.save() } }
                            .disabled(model.target == nil || !model.draft.canSave)
                    }
                }
            }
        }
    }
}
