// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import PromiseKit

// MARK: - NSItemProvider wrapper

/// Image provider wrapper around NSItemProvider from LPMetadataProvider
/// Used in HeroImageFetcher
protocol ImageProvider {
    #if os(iOS) && WK_IOS_BEFORE_13
    func loadObject(ofClass: NSItemProviderReading.Type) throws -> Promise<UIImage>
    #else
    func loadObject(ofClass: NSItemProviderReading.Type) async throws -> UIImage
    #endif
}

extension NSItemProvider: ImageProvider {
    #if os(iOS) && WK_IOS_BEFORE_13
    func loadObject(ofClass aClass: NSItemProviderReading.Type) throws -> Promise<UIImage> {
        Promise(.pending) { seal in
            loadObject(ofClass: aClass) { image, error in
                if error == nil {
                    if let image = image as? UIImage {
                        seal.fulfill(image)
                    } else {
                        seal.reject(SiteImageError.unableToDownloadImage("NSItemProviderReading not an image"))
                    }
                } else {
                    seal.reject(SiteImageError.unableToDownloadImage(error.debugDescription.description))
                }
            }
        }
    }
    #else
    func loadObject(ofClass aClass: NSItemProviderReading.Type) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            loadObject(ofClass: aClass) { image, error in
                guard error == nil else {
                    continuation.resume(throwing: SiteImageError.unableToDownloadImage(error.debugDescription.description))
                    return
                }

                guard let image = image as? UIImage else {
                    continuation.resume(throwing: SiteImageError.unableToDownloadImage("NSItemProviderReading not an image"))
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }
    #endif
}
