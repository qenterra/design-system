#if canImport(ImageIO)
    import Foundation
    import ImageIO

    /// Decodes an original image or an orientation-corrected, bounded thumbnail.
    public enum ImageDataDecoder {
        public static func image(from data: Data, maximumPixelDimension: Int? = nil) -> CGImage? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
            guard let maximumPixelDimension else {
                return CGImageSourceCreateImageAtIndex(source, 0, [
                    kCGImageSourceShouldCacheImmediately: true,
                ] as CFDictionary)
            }
            guard maximumPixelDimension > 0 else { return nil }
            return CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maximumPixelDimension,
            ] as CFDictionary)
        }

        /// RGBA pixel cost used for cache admission; Int.max denotes arithmetic overflow.
        public static func decodedByteCost(of image: CGImage) -> Int {
            let (pixels, pixelOverflow) = image.width.multipliedReportingOverflow(by: image.height)
            let (bytes, byteOverflow) = pixels.multipliedReportingOverflow(by: 4)
            guard !pixelOverflow, !byteOverflow else { return .max }
            return max(bytes, 0)
        }
    }
#endif
