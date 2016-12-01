//
//  HTTPServerExConfig.swift
//  PerfectHTTPServer
//
//  Created by Kyle Jessup on 2016-11-29.
//

import PerfectHTTP
import PerfectLib
import PerfectNet
import Foundation

// HERE BE DRAGONS
private typealias ReturnsRequestHandler = () throws -> RequestHandler
private typealias ReturnsRequestHandlerGivenData = ([String:Any]) throws -> RequestHandler

private func templateWithData(data: [String:Any]) throws -> RequestHandler {
	fatalError("nope")
}

private func templateWithData(data: [String:Any]) throws -> HTTPResponseFilter {
	fatalError("nope")
}

private func templateWithData(data: [String:Any]) throws -> HTTPRequestFilter {
	fatalError("nope")
}

private struct swift_func_object {
	var original_type_ptr: UnsafeMutablePointer<uintptr_t>
	var unknown: UnsafeMutablePointer<UInt64>
	var address: uintptr_t
	var selfPtr: UnsafeMutablePointer<uintptr_t>
}

private struct swift_func_wrapper {
	var trampolinePtr: UnsafeMutablePointer<uintptr_t>
	var functionObject: UnsafeMutablePointer<swift_func_object>
}

//__TZFV17PerfectHTTPServer11HTTPHandler8redirectfzT4dataGVs10DictionarySSP___FTP11PerfectHTTP11HTTPRequest_PS2_12HTTPResponse__T_
private let symbolPrefixes = ["_TF", "_TFV", "_TZFC", "_TZFO", "_TZFOV", "_TZFV"]
private let exeHandle = dlopen(nil, RTLD_NOW)

private func findFunc(_ named: String, suffixes: [String]) -> UnsafeMutableRawPointer? {
	let names = named.characters.split(separator: ".")
	let preName = names.map { "\($0.count)\(String($0))" }.joined()
	let someDataSuffixes = ["FzT4dataGVs10DictionarySSP___", "fzT4dataGVs10DictionarySSP___"]
	
	var rcheck = ""
	
	for prefix in symbolPrefixes {
		for dataSuffix in someDataSuffixes {
			for suffix in suffixes {
				let check = "\(prefix)\(preName)\(dataSuffix)\(suffix)"
				rcheck += check + "\n"
				if let sym = dlsym(exeHandle, check) {
					return sym
				}
			}
		}
	}
	print(rcheck)
	return nil
}

private extension Route {
	init(data: [String:Any]) throws {
		guard let uri = data["uri"] as? String else {
			throw PerfectError.apiError("Route data did not contain a uri")
		}
		guard let handlerName = data["handler"] as? String else {
			throw PerfectError.apiError("Route data did not contain a handler name")
		}
		guard let handler = try Route.lookupHandler(named: handlerName, data: data) else {
			throw PerfectError.apiError("Route could not find handler \(handlerName). Ensure it is spelled correctly and fully qualified with its module name.")
		}
		if let methodStr = data["method"] as? String {
			self.init(method: HTTPMethod.from(string: methodStr.uppercased()), uri: uri, handler: handler)
		} else if let methodsAry = data["methods"] as? [String] {
			self.init(methods: methodsAry.map { HTTPMethod.from(string: $0.uppercased()) }, uri: uri, handler: handler)
		} else {
			self.init(uri: uri, handler: handler)
		}
	}
	
	private static func lookupHandler(named: String, data: [String:Any]) throws -> RequestHandler? {
		if let sym = findFunc(named, suffixes: ["FTP11PerfectHTTP11HTTPRequest_PS1_12HTTPResponse__T_",
		                                        "FTP11PerfectHTTP11HTTPRequest_PS2_12HTTPResponse__T_"]) {
			return try callWithData(sym, data: data)
		}
		return nil
	}
	
	private static func callWithData(_ ptr: UnsafeMutableRawPointer?, data: [String:Any]) throws -> RequestHandler? {
		guard let ptr = ptr else {
			return nil
		}
		let fn = UnsafeMutablePointer<ReturnsRequestHandlerGivenData>.allocate(capacity: 1)
		defer {
			fn.deinitialize(count: 1)
			fn.deallocate(capacity: 1)
		}
		fn.initialize(to: templateWithData)
		let p = UnsafeMutableRawPointer(fn).assumingMemoryBound(to: swift_func_wrapper.self)
		p.pointee.functionObject.pointee.address = unsafeBitCast(ptr, to: UInt.self)
		let callMe = fn.pointee
		return try callMe(data)
	}
}

extension Routes {
	init(data: [[String:Any]]) throws {
		self.init(try data.map { try Route(data: $0) })
	}
}

extension OpenSSLVerifyMode {
	init?(string: String) {
		switch string {
		case "sslVerifyNone": self = .sslVerifyNone
		case "sslVerifyPeer": self = .sslVerifyPeer
		case "sslVerifyFailIfNoPeerCert": self = .sslVerifyFailIfNoPeerCert
		case "sslVerifyClientOnce": self = .sslVerifyClientOnce
		case "sslVerifyPeerWithFailIfNoPeerCert": self = .sslVerifyPeerWithFailIfNoPeerCert
		case "sslVerifyPeerClientOnce": self = .sslVerifyPeerClientOnce
		case "sslVerifyPeerWithFailIfNoPeerCertClientOnce": self = .sslVerifyPeerWithFailIfNoPeerCertClientOnce
		default:
			return nil
		}
	}
}

extension TLSConfiguration {
	init?(data: [String:Any]) {
		guard let certPath = data["certPath"] as? String else {
			return nil
		}
		self.init(certPath: certPath,
		          keyPath: data["keyPath"] as? String,
		          caCertPath: data["caCertPath"] as? String,
		          certVerifyMode: OpenSSLVerifyMode(string: data["verifyMode"] as? String ?? ""),
		          cipherList: data["cipherList"] as? [String] ?? TLSConfiguration.defaultCipherList)
	}
}

private func findRequestFilter(_ named: String, data: [String:Any]) throws -> HTTPRequestFilter? {
	if let sym = findFunc(named, suffixes: ["P11PerfectHTTP17HTTPRequestFilter_"]) {
		let fn = UnsafeMutablePointer<([String:Any]) throws -> HTTPRequestFilter>.allocate(capacity: 1)
		defer {
			fn.deinitialize(count: 1)
			fn.deallocate(capacity: 1)
		}
		fn.initialize(to: templateWithData)
		let p = UnsafeMutableRawPointer(fn).assumingMemoryBound(to: swift_func_wrapper.self)
		p.pointee.functionObject.pointee.address = unsafeBitCast(sym, to: UInt.self)
		let callMe = fn.pointee
		return try callMe(data)
	}
	return nil
}

private func findResponseFilter(_ named: String, data: [String:Any]) throws -> HTTPResponseFilter? {
	if let sym = findFunc(named, suffixes: ["P11PerfectHTTP18HTTPResponseFilter_"]) {
		let fn = UnsafeMutablePointer<([String:Any]) throws -> HTTPResponseFilter>.allocate(capacity: 1)
		defer {
			fn.deinitialize(count: 1)
			fn.deallocate(capacity: 1)
		}
		fn.initialize(to: templateWithData)
		let p = UnsafeMutableRawPointer(fn).assumingMemoryBound(to: swift_func_wrapper.self)
		p.pointee.functionObject.pointee.address = unsafeBitCast(sym, to: UInt.self)
		let callMe = fn.pointee
		return try callMe(data)
	}
	return nil
}

private let kv: [String:HTTPFilterPriority] = ["low":.low, "medium":.medium, "high":.high]

func filtersFrom(data: [[String:Any]]) throws -> [(HTTPRequestFilter, HTTPFilterPriority)] {
	var ret = [(HTTPRequestFilter, HTTPFilterPriority)]()
	for e in data {
		guard let type = e["type"] as? String, type == "request" else {
			continue
		}
		let prio = kv[e["priority"] as? String ?? "high"] ?? .high
		guard let name = e["name"] as? String else {
			throw PerfectError.apiError("A filter needs a name")
		}
		guard let filterObj = try findRequestFilter(name, data: e) else {
			throw PerfectError.apiError("The filter \(name) was not found")
		}
		ret.append((filterObj, prio))
	}
	return ret
}

func filtersFrom(data: [[String:Any]]) throws -> [(HTTPResponseFilter, HTTPFilterPriority)] {
	var ret = [(HTTPResponseFilter, HTTPFilterPriority)]()
	for e in data {
		guard let type = e["type"] as? String, type == "response" else {
			continue
		}
		let prio = kv[e["priority"] as? String ?? "high"] ?? .high
		guard let name = e["name"] as? String else {
			throw PerfectError.apiError("A filter needs a name")
		}
		guard let filterObj = try findResponseFilter(name, data: e) else {
			throw PerfectError.apiError("The filter \(name) was not found")
		}
		ret.append((filterObj, prio))
	}
	return ret
}

// -------------------------------------------

public extension HTTPHandler {
	public static func staticFiles(data: [String:Any]) throws -> RequestHandler {
		let documentRoot = data["documentRoot"] as? String ?? "./webroot"
		let allowResponseFilters = data["allowResponseFilters"] as? Bool ?? false
		return {
			req, resp in
			StaticFileHandler(documentRoot: documentRoot, allowResponseFilters: allowResponseFilters)
				.handleRequest(request: req, response: resp)
		}
	}
	
	public static func redirect(data: [String:Any]) throws -> RequestHandler {
		guard let base = data["base"] as? String else {
			fatalError("HTTPHandler.redirect(data: [String:Any]) requires a value for key \"base\".")
		}
		return {
			req, resp in
			resp.status = .movedPermanently
			resp.setHeader(.location, value: base + req.uri)
			resp.completed()
		}
	}
}

public struct HTTPFilter {
	public func custom404(data: [String:Any]) throws -> HTTPResponseFilter {
		guard let path = data["path"] as? String else {
			fatalError("HTTPFilter.custom404(data: [String:Any]) requires a value for key \"path\".")
		}
		struct Filter404: HTTPResponseFilter {
			let path: String
			func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
				if case .notFound = response.status {
					do {
						response.setBody(string: try File(path).readString())
					} catch {
						response.setBody(string: "An error occurred but I could not find the error file. \(response.status)")
					}
					response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
				}
				return callback(.continue)
			}
			func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
				callback(.continue)
			}
		}
		return Filter404(path: path)
	}
	
	public func customReqFilter(data: [String:Any]) throws -> HTTPRequestFilter {
		struct ReqFilter: HTTPRequestFilter {
			func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {
				callback(.continue(request, response))
			}
		}
		return ReqFilter()
	}
}

//testing
public func uniqueName(data: [String:Any]) throws -> RequestHandler { throw PerfectError.apiError("hi") }
public struct UniqueStruct {
	public static func uniqueName(data: [String:Any]) throws -> RequestHandler { throw PerfectError.apiError("hi") }
	public enum UniqueNestedEnum {
		public static func uniqueName(data: [String:Any]) throws -> RequestHandler { throw PerfectError.apiError("hi") }
	}
}
public enum UniqueEnum {
	public static func uniqueName(data: [String:Any]) throws -> RequestHandler { throw PerfectError.apiError("hi") }
}
public class UniqueClass {
	public static func uniqueName(data: [String:Any]) throws -> RequestHandler { throw PerfectError.apiError("hi") }
}
