//
//  DeepLinkParser.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 10/17/23.
//

import Foundation

public class DeepLinkParser {
    public init() {
    }

    public func parseDeepLink(url: URL) throws -> DeepLinkAction {
        guard let action = url.host(percentEncoded: false) else {
            throw DeepLinkError.unsupportedURL(unsupportedURL: url)
        }

        let pathComponents = url.pathComponents.filter({ $0 != "/" })

            let queryParameters = convertQueryParametersToDictionary(from: url)

            if action == CreateLooperDeepLink.actionName {
                let deepLink = try CreateLooperDeepLink(pathParts: pathComponents, queryParameters: queryParameters)
                return .addLooper(deepLink: deepLink)
            } else if action == SelectLooperDeepLink.actionName {
                let deepLink = try SelectLooperDeepLink(pathParts: pathComponents, queryParameters: queryParameters)
                return .selectLooper(deepLink: deepLink)
            } else if action == SelectLooperErrorDeepLink.actionName {
                let deepLink = try SelectLooperErrorDeepLink(pathParts: pathComponents, queryParameters: queryParameters)
                return .selectLooperError(deepLink: deepLink)
            } else if action == RequestWatchConfigurationDeepLink.actionName {
                let deepLink = try RequestWatchConfigurationDeepLink(pathParts: pathComponents, queryParameters: queryParameters)
                return .requestWatchConfigurationDeepLink(deepLink: deepLink)
            } else {
                throw DeepLinkError.unknownAction(actionName: action)
            }
        }

    private func convertQueryParametersToDictionary(from url: URL) -> [String: String] {
        var queryDict = [String: String]()

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let queryItems = components.queryItems {
                for item in queryItems {
                    queryDict[item.name] = item.value ?? ""
                }
            }
        }

        return queryDict
    }

    enum DeepLinkError: LocalizedError {
        case unsupportedURL(unsupportedURL: URL)
        case unknownAction(actionName: String)

        var errorDescription: String? {
            switch self {
            case .unsupportedURL(let url):
                return "Unsupported URL: \(url)"
            case .unknownAction(let actionName):
                return "Unknown Action: \(actionName)"
            }
        }
    }
}

public enum DeepLinkAction {
    case selectLooper(deepLink: SelectLooperDeepLink)
    case selectLooperError(deepLink: SelectLooperErrorDeepLink)
    case addLooper(deepLink: CreateLooperDeepLink)
    case requestWatchConfigurationDeepLink(deepLink: RequestWatchConfigurationDeepLink)
}

public protocol DeepLink {
    var url: URL { get }
    static var host: String { get }
    static var actionName: String { get }
}

public extension DeepLink {
    static var host: String {
        return "caregiver"
    }
}

public struct SelectLooperDeepLink: DeepLink {
    public let looperUUID: String
    public let url: URL

    public init(looperUUID: String) {
        self.looperUUID = looperUUID
        self.url = URL(string: "\(Self.host)://\(Self.actionName)/\(looperUUID)")!
    }

    public init(pathParts: [String], queryParameters: [String: String]) throws {
        guard let uuid = pathParts.first, !uuid.isEmpty else {
            throw SelectLooperDeepLink.SelectLooperDeepLinkError.widgetConfigurationRequired
        }
        self = SelectLooperDeepLink(looperUUID: uuid)
    }

    public static let actionName = "selectLooper"

    enum SelectLooperDeepLinkError: LocalizedError {
        case widgetConfigurationRequired

        var errorDescription: String? {
            switch self {
            case .widgetConfigurationRequired:
                return "This widget requires configuration."
            }
        }
    }
}

public struct SelectLooperErrorDeepLink: DeepLink {
    public let url: URL
    public let error: Error

    public init(errorMessage: String) {
        self.url = URL(string: "\(Self.host)://\(Self.actionName)/\(errorMessage)")!
        self.error = SelectLooperError.error(errorMessage)
    }

    public init(pathParts: [String], queryParameters: [String: String]) throws {
        guard let errorMessage = pathParts.first, !errorMessage.isEmpty else {
            throw SelectLooperErrorDeepLinkError.missingErrorMessage
        }
        self = SelectLooperErrorDeepLink(errorMessage: errorMessage)
    }

    public static let actionName = "selectLooperError"
    
    enum SelectLooperError: LocalizedError {
        case error(String)
        
        var errorDescription: String? {
            switch self {
            case .error(let errorMessage):
                return errorMessage
            }
        }
    }

    enum SelectLooperErrorDeepLinkError: LocalizedError {
        case missingErrorMessage

        var errorDescription: String? {
            switch self {
            case .missingErrorMessage:
                return "Missing Error Message."
            }
        }
    }
}

public struct CreateLooperDeepLink: DeepLink {
    public let name: String
    public let nsURL: URL
    public let secretKey: String
    public let otpURL: URL
    public let url: URL

    public static let actionName = "createLooper"
    
    public init(name: String, nsURL: URL, secretKey: String, otpURLString: String) throws {
        self.name = name
        self.nsURL = nsURL
        self.secretKey = secretKey
        
        guard let otpURL = URL(string: otpURLString) else {
            throw CreateLooperDeepLinkError.missingOTPURL
        }
        self.otpURL = otpURL
        
        guard let otpURLStringEncoded = otpURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            throw CreateLooperDeepLinkError.urlEncodingError(url: otpURL.absoluteString)
        }
        
        guard let nsURLStringEncoded = nsURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            throw CreateLooperDeepLinkError.urlEncodingError(url: nsURL.absoluteString)
        }
        // TODO: The date is appended to each deep link to ensure we have a unique message received by the watch.
        // See https://stackoverflow.com/a/47915741
        let url = URL(string: "\(Self.host)://\(Self.actionName)?name=\(name)&secretKey=\(secretKey)&nsURL=\(nsURLStringEncoded)&otpURL=\(otpURLStringEncoded)&createdDate=\(Date())")!
        
        self.url = url
    }

    public init(pathParts: [String], queryParameters: [String: String]) throws {
        guard let name = queryParameters["name"], !name.isEmpty else {
            throw CreateLooperDeepLinkError.missingName
        }

        guard let nightscoutURLString = queryParameters["nsURL"]?.removingPercentEncoding?.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
              let nightscoutURL = URL(string: nightscoutURLString)
        else {
            throw CreateLooperDeepLinkError.missingNSURL
        }

        guard let apiSecret = queryParameters["secretKey"]?.trimmingCharacters(in: .whitespacesAndNewlines), !apiSecret.isEmpty else {
            throw CreateLooperDeepLinkError.missingNSSecretKey
        }

        guard let otpURLString = queryParameters["otpURL"]?.removingPercentEncoding, !otpURLString.isEmpty else {
            throw CreateLooperDeepLinkError.missingOTPURL
        }
        
        self = try CreateLooperDeepLink(name: name, nsURL: nightscoutURL, secretKey: apiSecret, otpURLString: otpURLString)
    }
    
    public static func deepLinkWithLooper(_ looper: Looper) throws -> CreateLooperDeepLink {
        return try CreateLooperDeepLink(name: looper.name, nsURL: looper.nightscoutCredentials.url, secretKey: looper.nightscoutCredentials.secretKey, otpURLString: looper.nightscoutCredentials.otpURL)
    }

    enum CreateLooperDeepLinkError: LocalizedError, Equatable {
        case missingOTPURL
        case missingName
        case missingNSSecretKey
        case missingNSURL
        case urlEncodingError(url: String)

        var errorDescription: String? {
            switch self {
            case .missingName:
                return "Include the Loopers name in the URL"
            case .missingNSSecretKey:
                return "Include the NS secret key in the URL"
            case .missingNSURL:
                return "Include the NS URL in the URL"
            case .missingOTPURL:
                return "Include the OTP URL in the URL"
            case .urlEncodingError(let url):
                return "Could not URL encode the URL: \(url)"
            }
        }
    }
}

public struct RequestWatchConfigurationDeepLink: DeepLink {
    public let url: URL
    
    public init() {
        // TODO: The date is appended to each deep link to ensure we have a unique message received by the watch each time.
        self.url = URL(string: "\(Self.host)://\(Self.actionName)?createdDate=\(Date())")!
    }

    public init(pathParts: [String], queryParameters: [String: String]) throws {
        self = RequestWatchConfigurationDeepLink()
    }

    public static let actionName = "requestWatchConfiguration"
}

public extension GlucoseTimeLineEntry {
    func selectLooperDeepLink() -> DeepLink {
        switch self {
        case .success(let glucoseEntry):
            return SelectLooperDeepLink(looperUUID: glucoseEntry.looper.id)
        case .failure(let error):
            if let looper = error.looper {
                return SelectLooperDeepLink(looperUUID: looper.id)
            } else {
                return SelectLooperErrorDeepLink(errorMessage: error.localizedDescription)
            }
        }
    }
}
