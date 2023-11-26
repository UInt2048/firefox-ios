// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LinkPresentation
import UIKit
import PromiseKit

protocol HeroImageFetcher {
    /// FetchHeroImage using metadataProvider needs the main thread, hence using @MainActor for it.
    /// LPMetadataProvider is also a one shot object that we need to throw away once used.
    /// - Parameters:
    ///   - siteURL: the url to fetch the hero image with
    ///   - metadataProvider: LPMetadataProvider
    /// - Returns: the hero image
    #if os(iOS) && WK_IOS_BEFORE_13
    @MainActor
    func fetchHeroImage(from siteURL: URL, metadataProvider: LPMetadataProvider) throws -> Promise<UIImage>
    #else
    @MainActor
    func fetchHeroImage(from siteURL: URL, metadataProvider: LPMetadataProvider) async throws -> UIImage
    #endif
}

extension HeroImageFetcher {
    #if os(iOS) && WK_IOS_BEFORE_13
    @MainActor
    func fetchHeroImage(from siteURL: URL, metadataProvider: LPMetadataProvider) throws -> Promise<UIImage> {
        try fetchHeroImage(from: siteURL, metadataProvider: metadataProvider)
    }
    #else
    @MainActor
    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider()
    ) async throws -> UIImage {
        try await fetchHeroImage(from: siteURL, metadataProvider: metadataProvider)
    }
    #endif
}

class DefaultHeroImageFetcher: HeroImageFetcher {
    #if os(iOS) && WK_IOS_BEFORE_13
    @MainActor
    func fetchHeroImage(from siteURL: URL, metadataProvider: LPMetadataProvider) throws -> Promise<UIImage> {
        firstly {
            metadataProvider.startFetchingMetadata(for: siteURL)
        }.then { metadata in
            guard let imageProvider = metadata.imageProvider else {
                throw SiteImageError.unableToDownloadImage("Metadata image provider could not be retrieved.")
            }
            
            return try imageProvider.loadObject(ofClass: UIImage.self)
        }
    }
    #else
    @MainActor
    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider()
    ) async throws -> UIImage {
        do {
            let metadata = try await metadataProvider.startFetchingMetadata(for: siteURL)
            guard let imageProvider = metadata.imageProvider else {
                throw SiteImageError.unableToDownloadImage("Metadata image provider could not be retrieved.")
            }

            return try await imageProvider.loadObject(ofClass: UIImage.self)
        } catch {
            throw error
        }
    }
    #endif
}
