// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import PromiseKit

protocol FaviconURLCache {
    #if os(iOS) && WK_IOS_BEFORE_13
    func getURLFromCache(cacheKey: String) throws -> Promise<URL>
    func cacheURL(cacheKey: String, faviconURL: URL) -> Promise<Void>
    func clearCache() -> Promise<Void>
    #else
    func getURLFromCache(cacheKey: String) async throws -> URL
    func cacheURL(cacheKey: String, faviconURL: URL) async
    func clearCache() async
    #endif
}

actor DefaultFaviconURLCache: FaviconURLCache {
    private enum CacheConstants {
        static let cacheKey = "favicon-url-cache"
        static let daysToExpiration = 30
    }

    static let shared = DefaultFaviconURLCache()
    private let fileManager: URLCacheFileManager
    private var urlCache = [String: FaviconURL]()
    private var preserveTask: Task<Void, Never>?
    private let preserveDebounceTime: UInt64 = 10_000_000_000 // 10 seconds

    init(fileManager: URLCacheFileManager = DefaultURLCacheFileManager()) {
        self.fileManager = fileManager

        Task {
            await retrieveCache()
        }
    }

    #if os(iOS) && WK_IOS_BEFORE_13
    func getURLFromCache(cacheKey: String) throws -> Promise<URL> {
        return firstly {
            _getURLFromCache(cacheKey: cacheKey)
        }
    }
    #else
    func getURLFromCache(cacheKey: String) async throws -> URL {
        return try _getURLFromCache(cacheKey: cacheKey)
    }
    #endif
        
    @inline(__always) func _getURLFromCache(cacheKey: String) throws -> URL {
        guard let favicon = urlCache[cacheKey],
              let url = URL(string: favicon.faviconURL)
        else { throw SiteImageError.noURLInCache }

        // Update the element in the cache so it's time to expire is reset
        // We don't need to wait for this to finish
        Task {
            await cacheURL(cacheKey: cacheKey, faviconURL: url)
        }

        return url
    }

    #if os(iOS) && WK_IOS_BEFORE_13
    func cacheURL(cacheKey: String, faviconURL: URL) -> Promise<Void> {
        return firstly {
            _cacheURL(cacheKey: cacheKey, faviconURL: faviconURL)
        }
    }
    #else
    func cacheURL(cacheKey: String, faviconURL: URL) async {
        _cacheURL(cacheKey: cacheKey, faviconURL: faviconURL)
    }
    #endif
    
    @inline(__always) func _cacheURL(cacheKey: String, faviconURL: URL) {
        let favicon = FaviconURL(cacheKey: cacheKey,
                                 faviconURL: faviconURL.absoluteString,
                                 createdAt: Date())
        urlCache[cacheKey] = favicon
        preserveCache()
    }

    #if os(iOS) && WK_IOS_BEFORE_13
    func clearCache() -> Promise<Void> {
        return firstly {
            _clearCache()
        }
    }
    #else
    func clearCache() async {
        _clearCache()
    }
    #endif
    
    func _clearCache() {
        urlCache = [String: FaviconURL]()
        preserveCache()
    }

    private func preserveCache() {
        preserveTask?.cancel()
        preserveTask = Task {
            try? await Task.sleep(nanoseconds: preserveDebounceTime)
            guard !Task.isCancelled,
                  let data = archiveCacheData()
            else { return }
            await fileManager.saveURLCache(data: data)
        }
    }

    private func archiveCacheData() -> Data? {
        let cacheArray = urlCache.map { _, value in return value }
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        do {
            try archiver.encodeEncodable(cacheArray, forKey: CacheConstants.cacheKey)
        } catch {
            // Intentionally ignoring failure, a fail to save
            // is not catastrophic and the cache can always be rebuilt
        }
        return archiver.encodedData
    }

    #if os(iOS) && WK_IOS_BEFORE_13
    private func retrieveCache() -> Promise<Void> {
        return firstly {
            fileManager.getURLCache()
        }.then { data in
            try? NSKeyedUnarchiver(forReadingFrom: data)
        }.then { unarchiver in
            unarchiver?.decodeDecodable([FaviconURL].self, forKey: CacheConstants.cacheKey)
        }.then { cacheList in
            guard let cacheList = cacheList else { return }
            let today = Date()
            urlCache = cacheList.reduce(into: [String: FaviconURL]()) {
                if numberOfDaysBetween(start: $1.createdAt, end: today) >= CacheConstants.daysToExpiration {
                    return
                }
                $0[$1.cacheKey] = $1
            }
        }
    }
    #else
    private func retrieveCache() async {
        guard let data = await fileManager.getURLCache(),
              let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data),
              let cacheList = unarchiver.decodeDecodable([FaviconURL].self, forKey: CacheConstants.cacheKey)
        else {
            // Intentionally ignoring failure, a fail to retrieve
            // is not catastrophic and the cache can always be rebuilt
            return
        }

        // Ignore elements that are past the expiration time
        let today = Date()
        urlCache = cacheList.reduce(into: [String: FaviconURL]()) {
            if numberOfDaysBetween(start: $1.createdAt, end: today) >= CacheConstants.daysToExpiration {
                return
            }
            $0[$1.cacheKey] = $1
        }
    }
    #endif

    private func numberOfDaysBetween(start: Date, end: Date) -> Int {
        let calendar = NSCalendar.current
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end)
        let numberOfDays = calendar.dateComponents([.day], from: startDate, to: endDate)
        return numberOfDays.day ?? 0
    }
}
