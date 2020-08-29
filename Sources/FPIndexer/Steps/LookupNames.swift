import Foundation
import AsyncHTTPClient
import NIO

import FPCore

class LookupNames {
    static let nameClient = HTTPClient(eventLoopGroupProvider: .shared(eventGroup))
    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()
    static var reverseNameLookupUrl = ""

    static func run(_ items: [FpMedia]) -> [FpMedia] {
        var media = items
        let bulkItems = items
            .filter { $0.location != nil }
            .map { ReverseNameBulkItemRequest(lat: $0.location!.latitude, lon: $0.location!.longitude) }
        if bulkItems.count == 0 {
            return items
        }

        let future = query(ReverseNameBulkRequest(bulkItems))
        do {
            let response = try future.wait()
            var bulkIndex = 0
            for (mediaIndex, _) in items.enumerated() {
                if media[mediaIndex].location == nil {
                    continue
                }
                let bulkItem = response.items[bulkIndex]
                bulkIndex += 1

                if let err = bulkItem.error {
                    IndexingFailures.append("ReverseNameLookup returned an error for for \(media[mediaIndex].path): \(err)")
                } else if let placename = bulkItem.placename {
                    media[mediaIndex].locationCountryName = placename.countryName
                    media[mediaIndex].locationCountryCode = placename.countryCode
                    media[mediaIndex].locationStateName = placename.state
                    media[mediaIndex].locationCityName = placename.city
                    if let sites = placename.sites {
                        media[mediaIndex].locationSiteName = sites.joined(separator: ", ")
                    } else {
                        media[mediaIndex].locationSiteName = nil
                    }
                    media[mediaIndex].locationHierarchicalName = 
                        [media[mediaIndex].locationSiteName, media[mediaIndex].locationCityName, 
                        media[mediaIndex].locationStateName, media[mediaIndex].locationCountryName]
                        .compactMap({ return $0?.isEmpty == true ? nil : $0 })
                        .joined(separator: ", ")
                    media[mediaIndex].locationPlaceName = media[mediaIndex].locationHierarchicalName
                    media[mediaIndex].locationDisplayName = media[mediaIndex].locationHierarchicalName
                } else {
                    IndexingFailures.append("WTF: Neither error nor placename set")
                }
            }
        } catch {
            IndexingFailures.append("ReverseNameLookup failed for \(media[0].path): \(error)")
        }
        return media
    }

    static func query(_ bulkRequest: ReverseNameBulkRequest) -> EventLoopFuture<ReverseNameBulkResponse> {
        let promise = eventLoop.makePromise(of: ReverseNameBulkResponse.self)

        do {
            let data = try encoder.encode(bulkRequest)
            var request = try HTTPClient.Request(url: "\(reverseNameLookupUrl)/api/v1/bulk", method: .POST)
            request.headers.add(name: "Content-Type", value: "application/json")
            request.body = .data(data)
            nameClient.execute(request: request).whenComplete { result in
                switch result {
                    case .failure(let error):
                        promise.fail(error)
                        break
                    case .success(let response):
                        var responded = false
                        if var buffer = response.body {
                            if let bytes = buffer.readBytes(length: buffer.readableBytes) {
                                let data = Data(bytes)

                                if response.status == .ok {
                                    do {
                                        let nameResponse = try decoder.decode(ReverseNameBulkResponse.self, from: data)
                                        promise.succeed(nameResponse)
                                    } catch {
                                        promise.fail(error)
                                    }
                                } else {
                                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                                    promise.fail(RangicError.http(response.status, bodyText))
                                }
                                responded = true
                            }
                        }

                        if !responded {
                            promise.fail(RangicError.http(response.status, "<No body returned>"))
                        }
                        break
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }

        return promise.futureResult
    }

/*
    static func run(_ items: [FpMedia]) -> [FpMedia] {
        var media = items
// let startTime = Date()
        let futures: [EventLoopFuture<ReverseNameResponse>?] = media.map { 
                if let l = $0.location {
                    return run(l.latitude, l.longitude)
                } else {
                    return nil
                }
            }
        for index in 0..<futures.count {
            let f = futures[index]
            if f != nil {
                do {
                    let nameResponse = try f!.wait()
                    media[index].locationCountryName = nameResponse.countryName
                    media[index].locationCountryCode = nameResponse.countryCode
                    media[index].locationStateName = nameResponse.state
                    media[index].locationCityName = nameResponse.city
                    media[index].locationSiteName = (nameResponse.sites ?? []).joined(separator: ", ")
                    media[index].locationHierarchicalName = 
                        [media[index].locationSiteName, media[index].locationCityName, 
                        media[index].locationStateName, media[index].locationCountryName]
                        .compactMap({ return $0?.isEmpty == true ? nil : $0 })
                        .joined(separator: ", ")
                    media[index].locationPlaceName = media[index].locationHierarchicalName
                    media[index].locationDisplayName = media[index].locationHierarchicalName
                } catch {
                    IndexingFailures.append("ReverseNameLookup failed for \(media[index].path) [\(media[index].location!)]: \(error)")
                }
            }
        }

// print("LN: \(media.count) items -> \(Int(Date().timeIntervalSince(startTime))) seconds")
        return media
    }

    static func run(_ latitude: Double, _ longitude: Double) -> EventLoopFuture<ReverseNameResponse> {
        let promise = eventLoop.makePromise(of: ReverseNameResponse.self)

        // EventLoopFuture<Response>
        nameClient.get(url: "\(nameHost)/api/v1/name?country=true&lat=\(latitude)&lon=\(longitude)")
            .whenComplete { result in
                switch result {
                    case .failure(let error):
                        promise.fail(error)
                        break
                    case .success(let response):
                        var responded = false
                        if var buffer = response.body {
                            if let bytes = buffer.readBytes(length: buffer.readableBytes) {
                                let data = Data(bytes)

                                if response.status == .ok {
                                    do {
                                        let nameResponse = try decoder.decode(ReverseNameResponse.self, from: data)
                                        promise.succeed(nameResponse)
                                    } catch {
                                        promise.fail(error)
                                    }
                                } else {
                                    let bodyText = String(data: data, encoding: .utf8) ?? ""
                                    promise.fail(RangicError.http(response.status, bodyText))
                                }
                                responded = true
                            }
                        }

                        if !responded {
                            promise.fail(RangicError.http(response.status, "<No body returned>"))
                        }
                        break
                }
            }

        return promise.futureResult
    }
*/
}
