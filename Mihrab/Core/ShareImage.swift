import CoreTransferable
import SwiftUI
import UIKit

/// Transferable wrapper so rendered share cards can go through ShareLink.
struct ShareImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation<ShareImage, Image>(exporting: { Image(uiImage: $0.image) })
    }
}
