// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Kingfisher
import UIKit
import PromiseKit

// MARK: - Kingfisher wrapper

/// Image cache wrapper around Kingfisher image cache
/// Used in SiteImageCache
protocol DefaultImageCache {
    #if os(iOS) && WK_IOS_BEFORE_13
    func retrieveImage(forKey key: String) throws -> Promise<UIImage?>
    #else
    func retrieveImage(forKey key: String) async throws -> UIImage?
    #endif

    func store(image: UIImage, forKey key: String)

    func clearCache()
}

extension ImageCache: DefaultImageCache {
    #if os(iOS) && WK_IOS_BEFORE_13
    func retrieveImage(forKey key: String) throws -> Promise<UIImage?> {
        Promise(.pending) { seal in
            retrieveImage(forKey: key) { result in
                switch result {
                case .success(let imageResult):
                    seal.fulfill(imageResult.image)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
    #else
    func retrieveImage(forKey key: String) async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            retrieveImage(forKey: key) { result in
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: imageResult.image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    #endif

    func store(image: UIImage, forKey key: String) {
        self.store(image, forKey: key)
    }

    func clearCache() {
        clearMemoryCache()
        clearDiskCache()
    }
}
