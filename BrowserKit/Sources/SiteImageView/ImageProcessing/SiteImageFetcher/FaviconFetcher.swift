// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Kingfisher
import PromiseKit

protocol FaviconFetcher {
    /// Fetches a favicon image from a specific URL
    /// - Parameters:
    ///   - imageURL: Given a certain image URL
    ///   - imageDownloader: The SiteImageDownloader the image will be downloaded with
    /// - Returns: An image or an image error following Result type
    #if os(iOS) && WK_IOS_BEFORE_13
    func fetchFavicon(from imageURL: URL,
                      imageDownloader: SiteImageDownloader) throws -> Promise<UIImage>
    #else
    func fetchFavicon(from imageURL: URL,
                      imageDownloader: SiteImageDownloader) async throws -> UIImage
    #endif
}

extension FaviconFetcher {
    #if os(iOS) && WK_IOS_BEFORE_13
    func fetchFavicon(from imageURL: URL,
                      imageDownloader: SiteImageDownloader = DefaultSiteImageDownloader()) throws -> Promise<UIImage> {
        return fetchFavicon(from: imageURL, imageDownloader: imageDownloader)
    }
    #else
    func fetchFavicon(from imageURL: URL,
                      imageDownloader: SiteImageDownloader = DefaultSiteImageDownloader()) async throws -> UIImage {
        return try await fetchFavicon(from: imageURL, imageDownloader: imageDownloader)
    }
    #endif
}

struct DefaultFaviconFetcher: FaviconFetcher {
    #if os(iOS) && WK_IOS_BEFORE_13
    func fetchFavicon(from imageURL: URL,
                      imageDownloader: SiteImageDownloader = DefaultSiteImageDownloader()) throws -> Promise<UIImage> {
        firstly {
            try imageDownloader.downloadImage(with: imageURL)
        }.then { result in
            return result.image
        }.catch {
            if let err = error as KingfisherError {
                throw SiteImageError.unableToDownloadImage(error.errorDescription ?? "No description")
            } else if let err = error as SiteImageError {
                throw err
            } else {
                throw SiteImageError.unableToDownloadImage("No description")
            }
        }
    }
    #else
    func fetchFavicon(from imageURL: URL,
                      imageDownloader: SiteImageDownloader = DefaultSiteImageDownloader()) async throws -> UIImage {
        do {
            let result = try await imageDownloader.downloadImage(with: imageURL)
            return result.image
        } catch let error as KingfisherError {
            throw SiteImageError.unableToDownloadImage(error.errorDescription ?? "No description")
        } catch let error as SiteImageError {
            throw error
        } catch {
            throw SiteImageError.unableToDownloadImage("No description")
        }
    }
    #endif
}
