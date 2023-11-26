// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import PromiseKit

protocol FaviconURLHandler {
    #if os(iOS) && WK_IOS_BEFORE_13
    func getFaviconURL(site: SiteImageModel) throws -> Promise<SiteImageModel>
    #else
    func getFaviconURL(site: SiteImageModel) async throws -> SiteImageModel
    #endif
    func cacheFaviconURL(cacheKey: String, faviconURL: URL)
    func clearCache()
}

struct DefaultFaviconURLHandler: FaviconURLHandler {
    private let urlFetcher: FaviconURLFetcher
    private let urlCache: FaviconURLCache

    init(urlFetcher: FaviconURLFetcher = DefaultFaviconURLFetcher(),
         urlCache: FaviconURLCache = DefaultFaviconURLCache.shared) {
        self.urlFetcher = urlFetcher
        self.urlCache = urlCache
    }

    #if os(iOS) && WK_IOS_BEFORE_13
    func getFaviconURL(site: SiteImageModel) throws -> Promise<SiteImageModel> {
        // Don't fetch favicon URL if we don't have a URL or domain for it
        guard let siteURL = site.siteURL else {
            throw SiteImageError.noFaviconURLFound
        }

        var imageModel = site
        
        firstly {
            try urlCache.getURLFromCache(cacheKey: imageModel.cacheKey)
            imageModel.faviconURL = url
        }.recover {
            urlFetcher.fetchFaviconURL(siteURL: siteURL).then {
                urlCache.cacheURL(cacheKey: imageModel.cacheKey, faviconURL: url)
                imageModel.faviconURL = url
            }.catch {
                throw SiteImageError.noFaviconURLFound
            }
        }.then {
            return imageModel
        }
    }
    #else
    func getFaviconURL(site: SiteImageModel) async throws -> SiteImageModel {
        // Don't fetch favicon URL if we don't have a URL or domain for it
        guard let siteURL = site.siteURL else {
            throw SiteImageError.noFaviconURLFound
        }

        var imageModel = site
        do {
            let url = try await urlCache.getURLFromCache(cacheKey: imageModel.cacheKey)
            imageModel.faviconURL = url
            return imageModel
        } catch {
            do {
                let url = try await urlFetcher.fetchFaviconURL(siteURL: siteURL)
                await urlCache.cacheURL(cacheKey: imageModel.cacheKey, faviconURL: url)
                imageModel.faviconURL = url
                return imageModel
            } catch {
                throw SiteImageError.noFaviconURLFound
            }
        }
    }
    #endif

    func cacheFaviconURL(cacheKey: String, faviconURL: URL) {
        Task {
            await urlCache.cacheURL(cacheKey: cacheKey, faviconURL: faviconURL)
        }
    }

    func clearCache() {
        Task {
            await urlCache.clearCache()
        }
    }
}
