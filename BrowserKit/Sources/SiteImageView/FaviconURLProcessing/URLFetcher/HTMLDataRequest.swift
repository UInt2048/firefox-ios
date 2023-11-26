// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import PromiseKit

protocol HTMLDataRequest {
    #if os(iOS) && WK_IOS_BEFORE_13
    func fetchDataForURL(_ url: URL) throws -> Promise<Data>
    #else
    func fetchDataForURL(_ url: URL) async throws -> Data
    #endif
}

struct DefaultHTMLDataRequest: HTMLDataRequest {
    enum RequestConstants {
        static let timeout: TimeInterval = 5
        static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"
    }

    #if os(iOS) && WK_IOS_BEFORE_13
    func fetchDataForURL(_ url: URL) throws -> Promise<Data> {
        Promise(.pending) { seal in
            _getURLSession().dataTask(with: url) { data, _, error in
                if let data = data, error == nil {
                    seal.fulfill(data)
                } else {
                    seal.reject(SiteImageError.invalidHTML)
                }
            }
        }
    }
    #else
    func fetchDataForURL(_ url: URL) async throws -> Data {
        let urlSession = _getURLSession()
        return try await withCheckedThrowingContinuation { continuation in
            urlSession.dataTask(with: url) { data, _, error in
                guard let data = data,
                      error == nil
                else {
                    continuation.resume(throwing: SiteImageError.invalidHTML)
                    return
                }
                continuation.resume(returning: data)
            }.resume()
        }
    }
    #endif
    
    func _getURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["User-Agent": RequestConstants.userAgent]
        configuration.timeoutIntervalForRequest = RequestConstants.timeout

        return URLSession(configuration: configuration)
    }
    
}
