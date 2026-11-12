import CloudKit
import UIKit

/// Presents Apple's sharing sheet for a list: the owner picks a person and sends the link
/// through Messages or Mail. The invitee may add wishes, so the default permission is
/// read and write.
@MainActor
enum CloudSharing {
    /// The sheet's delegate; UIKit holds delegates weakly.
    private static var delegate: SharingDelegate?

    static func present(share: CKShare, title: String) {
        let controller = UICloudSharingController(share: share, container: AppConfig.container)
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        let delegate = SharingDelegate(title: title)
        Self.delegate = delegate
        controller.delegate = delegate
        topController()?.present(controller, animated: true)
    }

    private static func topController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        var top = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

private final class SharingDelegate: NSObject, UICloudSharingControllerDelegate {
    let title: String

    init(title: String) {
        self.title = title
    }

    func itemTitle(for _: UICloudSharingController) -> String? {
        title
    }

    func cloudSharingController(_: UICloudSharingController, failedToSaveShareWithError error: any Error) {
        Log.share.error("Sharing failed: \(error.localizedDescription, privacy: .public)")
    }

    func cloudSharingControllerDidSaveShare(_: UICloudSharingController) {
        Task { await CloudStore.shared.refresh() }
    }

    func cloudSharingControllerDidStopSharing(_: UICloudSharingController) {
        Task { await CloudStore.shared.refresh() }
    }
}
