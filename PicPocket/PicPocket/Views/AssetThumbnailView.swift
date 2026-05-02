import ComposableArchitecture
import SwiftUI

struct AssetThumbnailView: View {
    let assetLocalIdentifier: String
    var size = CGSize(width: 96, height: 96)

    @State private var image: UIImage?
    @Dependency(\.photoLibraryClient) var photoLibraryClient

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.secondary.opacity(0.15))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: assetLocalIdentifier) {
            image = await photoLibraryClient.requestImage(assetLocalIdentifier, size)
        }
    }
}
