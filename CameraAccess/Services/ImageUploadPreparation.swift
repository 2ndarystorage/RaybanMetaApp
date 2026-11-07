import UIKit

/// Bound upload dimensions in pixels, preserving the full frame and its orientation.
enum ImageUploadPreparation {
    enum Purpose {
        case scene
        case document

        var maximumDimension: CGFloat { self == .scene ? 1280 : 2048 }
        var quality: CGFloat { self == .scene ? 0.7 : 0.85 }
    }

    nonisolated static func jpeg(_ image: UIImage, purpose: Purpose) -> Data? {
        guard image.size.width > 0, image.size.height > 0 else { return nil }
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let ratio = min(1, purpose.maximumDimension / max(pixels.width, pixels.height))
        let size = CGSize(width: max(1, floor(pixels.width * ratio)), height: max(1, floor(pixels.height * ratio)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let prepared = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return prepared.jpegData(compressionQuality: purpose.quality)
    }
}
