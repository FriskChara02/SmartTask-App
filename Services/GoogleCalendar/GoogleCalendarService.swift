//
//  GoogleCalendarService.swift
//  SmartTask
//
//  Created by Loi Nguyen on 17/4/25.
//

import Foundation
import GoogleAPIClientForREST_Calendar
import GTMSessionFetcherCore
import AppAuth
import UIKit

enum GoogleCalendarError: LocalizedError {
    case notSignedIn
    case missingClientID
    case missingUser
    case noEventID
    case unknown
    case tokenRefreshFailed

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Not signed in or authorizer missing"
        case .missingClientID: return "GIDClientID missing in Info.plist"
        case .missingUser: return "User not authenticated"
        case .noEventID: return "No event ID"
        case .unknown: return "An unknown error occurred"
        case .tokenRefreshFailed: return "Failed to refresh access token"
        }
    }
}

// MARK: - Custom Authorizer
class CustomAuthorizer: NSObject, GTMSessionFetcherAuthorizer {
    private let authState: OIDAuthState
    
    init(authState: OIDAuthState) {
        self.authState = authState
        super.init()
    }
    
    func authorizeRequest(_ request: NSMutableURLRequest?, completionHandler: @escaping (Error?) -> Void) {
        guard let request = request else {
            print("❌ No request provided to authorize")
            completionHandler(GoogleCalendarError.unknown)
            return
        }
        
        print("🔍 Authorizing request for URL: \(request.url?.absoluteString ?? "unknown")")
        
        authState.performAction { accessToken, idToken, error in
            if let error = error {
                print("❌ Authorizer error: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            guard let accessToken = accessToken else {
                print("❌ No access token available")
                completionHandler(GoogleCalendarError.tokenRefreshFailed)
                return
            }
            
            print("✅ Access token: \(accessToken.prefix(20))...")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            if let bundleID = Bundle.main.bundleIdentifier {
                request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
                print("✅ Set X-Ios-Bundle-Identifier: \(bundleID)")
            } else {
                print("⚠️ Bundle ID is missing")
            }
            
            print("📤 Request headers: \(request.allHTTPHeaderFields ?? [:])")
            completionHandler(nil)
        }
    }
    
    func authorizeRequest(_ request: NSMutableURLRequest?, delegate: Any, didFinish sel: Selector) {
        print("🔍 authorizeRequest with delegate called for URL: \(request?.url?.absoluteString ?? "unknown")")
        authorizeRequest(request) { error in
            _ = (delegate as AnyObject).perform(sel, with: request, with: error)
        }
    }
    
    func isAuthorizedRequest(_ request: URLRequest) -> Bool {
        let isAuthorized = authState.isAuthorized
        print("🔍 isAuthorizedRequest: \(isAuthorized) for URL: \(request.url?.absoluteString ?? "unknown")")
        return isAuthorized
    }
    
    func isAuthorizingRequest(_ request: URLRequest) -> Bool {
        print("🔍 isAuthorizingRequest: false for URL: \(request.url?.absoluteString ?? "unknown")")
        return false
    }
    
    func stopAuthorization(for request: URLRequest) {
        print("🔍 stopAuthorization called for URL: \(request.url?.absoluteString ?? "unknown")")
    }
    
    func stopAuthorization() {
        print("🔍 stopAuthorization called")
    }
    
    var userEmail: String? {
        guard let idToken = authState.lastTokenResponse?.idToken else { return nil }
        let parts = idToken.split(separator: ".")
        if parts.count > 1,
           let payloadData = Data(base64Encoded: String(parts[1]).base64URLDecoded()),
           let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
           let email = json["email"] as? String {
            return email
        }
        return nil
    }
    
    var isAuthorizingRequest: Bool { return false }
    var isAuthorizedRequest: Bool {
        let isAuthorized = authState.isAuthorized
        print("🔍 isAuthorizedRequest (property): \(isAuthorized)")
        return isAuthorized
    }
}

// MARK: - String Extension for Base64URL Decoding
extension String {
    func base64URLDecoded() -> String {
        var base64 = self.replacingOccurrences(of: "-", with: "+")
                        .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - base64.count % 4
        if padding < 4 {
            base64 += String(repeating: "=", count: padding)
        }
        guard let data = Data(base64Encoded: base64),
              let result = String(data: data, encoding: .utf8) else { return "" }
        return result
    }
}

class GoogleCalendarService: ObservableObject {
    static let shared = GoogleCalendarService()
    
    @Published var isSignedIn = false
    private let service = GTLRCalendarService()
    private var authState: OIDAuthState?
    private let apiKey = Config.googleAPIKey
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private let authStateKey = "GoogleCalendarAuthState"
    
    private init() {
        // Khôi phục authState từ UserDefaults
        if let data = UserDefaults.standard.data(forKey: authStateKey) {
            do {
                if let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) {
                    self.authState = unarchived
                    self.service.authorizer = createAuthorizer(from: unarchived)
                    self.isSignedIn = unarchived.isAuthorized
                    print("✅ Restored Google Calendar session, isAuthorized: \(unarchived.isAuthorized)")
                }
            } catch {
                print("❌ Failed to unarchive authState: \(error)")
                UserDefaults.standard.removeObject(forKey: authStateKey)
            }
        }
    }
    
    // MARK: - Đăng nhập Google
    func signIn(presentingViewController: UIViewController, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let clientID = Bundle.main.infoDictionary?["GIDClientID"] as? String, !clientID.isEmpty else {
            completion(.failure(GoogleCalendarError.missingClientID))
            return
        }
        
        let issuer = URL(string: "https://accounts.google.com")!
        let redirectURI = URL(string: Config.googleRedirectURI)!
        let scopes = [OIDScopeOpenID, OIDScopeProfile, "https://www.googleapis.com/auth/calendar"]
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { config, error in
            guard let config = config else {
                completion(.failure(error ?? GoogleCalendarError.unknown))
                return
            }
            
            let request = OIDAuthorizationRequest(configuration: config,
                                                  clientId: clientID,
                                                  clientSecret: nil,
                                                  scopes: scopes,
                                                  redirectURL: redirectURI,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)
            
            self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: presentingViewController) { authState, error in
                if let authState = authState {
                    self.authState = authState
                    self.service.authorizer = self.createAuthorizer(from: authState)
                    self.isSignedIn = authState.isAuthorized
                    
                    // Lưu authState vào UserDefaults
                    do {
                        let data = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
                        UserDefaults.standard.set(data, forKey: self.authStateKey)
                        print("✅ Saved Google Calendar auth state")
                    } catch {
                        print("❌ Failed to archive authState: \(error)")
                    }
                    
                    print("✅ Signed in using AppAuth")
                    completion(.success(()))
                } else {
                    self.isSignedIn = false
                    completion(.failure(error ?? GoogleCalendarError.unknown))
                }
                self.currentAuthorizationFlow = nil
            }
        }
    }
    
    // MARK: - Tạo Authorizer từ OIDAuthState
    private func createAuthorizer(from authState: OIDAuthState) -> any GTMSessionFetcherAuthorizer {
        return CustomAuthorizer(authState: authState)
    }
    
    // MARK: - Helper
    private func buildEvent(id: String?, title: String, startDate: Date, endDate: Date?, description: String?, attendeeEmail: String?, colorName: String?) -> GTLRCalendar_Event {
        let event = GTLRCalendar_Event()
        event.identifier = id
        event.summary = title
        event.descriptionProperty = description
        
        let startDateTime = GTLRDateTime(date: startDate)
        let endDateTime = GTLRDateTime(date: endDate ?? startDate.addingTimeInterval(3600))
        
        event.start = GTLRCalendar_EventDateTime()
        event.start?.dateTime = startDateTime
        event.start?.timeZone = "Asia/Ho_Chi_Minh"
        
        event.end = GTLRCalendar_EventDateTime()
        event.end?.dateTime = endDateTime
        event.end?.timeZone = "Asia/Ho_Chi_Minh"
        
        if let email = attendeeEmail, !email.isEmpty {
            let attendee = GTLRCalendar_EventAttendee()
            attendee.email = email
            event.attendees = [attendee]
        }
        
        if let colorName = colorName {
            let colorMap: [String: String] = [
                "Tomato": "11", // #DB4437
                "Tangerine": "6", // #F4B400
                "Sage": "10", // #5DA593
                "Peacock": "2", // #4285F4
                "Lavender": "3", // #B388EB
                "Graphite": "8", // #5F6368
                "Flamingo": "4", // #F28B82
                "Banana": "5", // #FBBC04
                "Basil": "9", // #0F9D58
                "Blueberry": "1", // #3367D6
                "Grape": "7" // #7B57F5
            ]
            event.colorId = colorMap[colorName]
        }
        
        return event
    }
    
    // MARK: - Sign Out
    func signOut() {
        authState = nil
        service.authorizer = nil
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: authStateKey)
        print("✅ Google Calendar signed out")
    }
    
    // MARK: - Làm mới token nếu cần
    private func refreshTokenIfNeeded(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let authState = authState else {
            print("❌ No authState available")
            completion(.failure(GoogleCalendarError.notSignedIn))
            return
        }
        
        print("🔍 Forcing token refresh")
        authState.performAction { accessToken, _, error in
            if let error = error {
                print("❌ Token refresh failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let accessToken = accessToken else {
                print("❌ No access token after refresh")
                completion(.failure(GoogleCalendarError.tokenRefreshFailed))
                return
            }
            
            self.service.authorizer = self.createAuthorizer(from: authState)
            print("✅ Token refreshed successfully, new token: \(accessToken.prefix(20))...")
            completion(.success(()))
        }
    }
    
    // MARK: - Fetch Events
    func fetchEvents(from startDate: Date, to endDate: Date, completion: @escaping (Result<[GTLRCalendar_Event], Error>) -> Void) {
        guard isSignedIn else {
            print("❌ Not signed in")
            completion(.failure(GoogleCalendarError.notSignedIn))
            return
        }
        
        if let authState = authState {
            let authorizer = createAuthorizer(from: authState)
            service.authorizer = authorizer
            print("✅ Re-assigned authorizer before fetching events: \(authorizer)")
        } else {
            print("❌ No authState available for authorizer")
            completion(.failure(GoogleCalendarError.notSignedIn))
            return
        }
        
        refreshTokenIfNeeded { result in
            switch result {
            case .success:
                let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
                query.timeMin = GTLRDateTime(date: startDate)
                query.timeMax = GTLRDateTime(date: endDate)
                query.singleEvents = true
                query.orderBy = kGTLRCalendarOrderByStartTime
                query.additionalHTTPHeaders = ["X-Ios-Bundle-Identifier": Bundle.main.bundleIdentifier ?? ""]
                
                let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events?key=\(self.apiKey)&orderBy=startTime&singleEvents=true&timeMin=\(startDate.iso8601String)&timeMax=\(endDate.iso8601String)"
                guard let url = URL(string: urlString) else {
                    print("❌ Invalid URL")
                    completion(.failure(GoogleCalendarError.unknown))
                    return
                }
                
                var request = URLRequest(url: url) // Sử dụng URLRequest thay vì NSMutableURLRequest
                if let authorizer = self.service.authorizer as? CustomAuthorizer {
                    // Tạo NSMutableURLRequest để thêm header
                    let mutableRequest = NSMutableURLRequest(url: url)
                    authorizer.authorizeRequest(mutableRequest) { error in
                        if let error = error {
                            print("❌ Manual authorization failed: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }
                        
                        // Chuyển đổi NSMutableURLRequest thành URLRequest
                        request = mutableRequest as URLRequest
                        let fetcher = GTMSessionFetcher(request: request)
                        fetcher.authorizer = self.service.authorizer
                        
                        print("🔍 Starting fetcher for URL: \(urlString)")
                        fetcher.beginFetch { data, error in
                            if let error = error {
                                print("❌ Fetch events failed: \(error.localizedDescription)")
                                if let nsError = error as NSError?, nsError.domain == "com.google.HTTPStatus", nsError.code == 403 {
                                    if let data = nsError.userInfo[NSUnderlyingErrorKey] as? Data {
                                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                                           let errorDetails = json["error"] as? [String: Any] {
                                            print("🔍 Error details: \(errorDetails)")
                                        }
                                    }
                                }
                                completion(.failure(error))
                                return
                            }
                            
                            guard let data = data else {
                                print("❌ No data returned")
                                completion(.failure(GoogleCalendarError.unknown))
                                return
                            }
                            
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                let eventsObj = GTLRCalendar_Events(json: json)
                                let events = eventsObj.items ?? [] // Không cần optional chaining
                                print("✅ Fetched \(events.count) Google Calendar events")
                                completion(.success(events))
                            } catch {
                                print("❌ Failed to parse response: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    print("❌ No valid authorizer for manual authorization")
                    completion(.failure(GoogleCalendarError.unknown))
                }
            case .failure(let error):
                print("❌ Fetch events failed due to token refresh: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Create Event
    func createEvent(title: String, startDate: Date, endDate: Date?, description: String?, attendeeEmail: String?, colorName: String?, completion: @escaping (Result<String, Error>) -> Void) {
        guard isSignedIn else {
            print("❌ Not signed in")
            completion(.failure(GoogleCalendarError.notSignedIn))
            return
        }
        
        if let authState = authState {
            service.authorizer = createAuthorizer(from: authState)
            print("✅ Re-assigned authorizer before creating event")
        }
        
        refreshTokenIfNeeded { result in
            switch result {
            case .success:
                let event = self.buildEvent(id: nil, title: title, startDate: startDate, endDate: endDate, description: description, attendeeEmail: attendeeEmail, colorName: colorName)
                
                let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events?key=\(self.apiKey)"
                guard let url = URL(string: urlString) else {
                    print("❌ Invalid URL")
                    completion(.failure(GoogleCalendarError.unknown))
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let authorizer = self.service.authorizer as? CustomAuthorizer {
                    let mutableRequest = NSMutableURLRequest(url: url)
                    mutableRequest.httpMethod = "POST"
                    mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    authorizer.authorizeRequest(mutableRequest) { error in
                        if let error = error {
                            print("❌ Manual authorization failed: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }
                        
                        request = mutableRequest as URLRequest
                        
                        // Serialize GTLRCalendar_Event thành JSON
                        guard let eventJson = event.json as? [String: Any] else {
                            print("❌ Event JSON is nil or invalid")
                            completion(.failure(GoogleCalendarError.unknown))
                            return
                        }
                        
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: eventJson, options: [])
                            request.httpBody = jsonData
                            print("✅ Serialized event JSON: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
                        } catch {
                            print("❌ Failed to serialize JSON body: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }
                        
                        let fetcher = GTMSessionFetcher(request: request)
                        fetcher.authorizer = self.service.authorizer
                        
                        print("🔍 Starting fetcher for URL: \(urlString)")
                        fetcher.beginFetch { data, error in
                            if let error = error {
                                print("❌ Create event failed: \(error.localizedDescription)")
                                completion(.failure(error))
                                return
                            }
                            
                            guard let data = data else {
                                print("❌ No data returned")
                                completion(.failure(GoogleCalendarError.unknown))
                                return
                            }
                            
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let eventId = json?["id"] as? String {
                                    print("✅ Created Google Calendar event with ID: \(eventId)")
                                    completion(.success(eventId))
                                } else {
                                    print("❌ No event ID returned")
                                    completion(.failure(GoogleCalendarError.noEventID))
                                }
                            } catch {
                                print("❌ Failed to parse response: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    print("❌ No valid authorizer for manual authorization")
                    completion(.failure(GoogleCalendarError.unknown))
                }
            case .failure(let error):
                print("❌ Create event failed due to token refresh: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Update Event
    func updateEvent(eventId: String, title: String, startDate: Date, endDate: Date?, description: String?, attendeeEmail: String?, colorName: String?, completion: @escaping (Result<String, Error>) -> Void) {
        guard isSignedIn else {
            completion(.failure(GoogleCalendarError.notSignedIn))
            return
        }
        
        refreshTokenIfNeeded { result in
            switch result {
            case .success:
                let event = self.buildEvent(id: eventId, title: title, startDate: startDate, endDate: endDate, description: description, attendeeEmail: attendeeEmail, colorName: colorName)
                
                let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events/\(eventId)?key=\(self.apiKey)"
                guard let url = URL(string: urlString) else {
                    print("❌ Invalid URL")
                    completion(.failure(GoogleCalendarError.unknown))
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let authorizer = self.service.authorizer as? CustomAuthorizer {
                    let mutableRequest = NSMutableURLRequest(url: url)
                    mutableRequest.httpMethod = "PUT"
                    mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    authorizer.authorizeRequest(mutableRequest) { error in
                        if let error = error {
                            print("❌ Manual authorization failed: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }
                        
                        request = mutableRequest as URLRequest
                        
                        // Serialize GTLRCalendar_Event thành JSON
                        guard let eventJson = event.json as? [String: Any] else {
                            print("❌ Event JSON is nil or invalid")
                            completion(.failure(GoogleCalendarError.unknown))
                            return
                        }
                        
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: eventJson, options: [])
                            request.httpBody = jsonData
                            print("✅ Serialized event JSON: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
                        } catch {
                            print("❌ Failed to serialize JSON body: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }
                        
                        let fetcher = GTMSessionFetcher(request: request)
                        fetcher.authorizer = self.service.authorizer
                        
                        print("🔍 Starting fetcher for URL: \(urlString)")
                        fetcher.beginFetch { data, error in
                            if let error = error {
                                print("❌ Update event failed: \(error.localizedDescription)")
                                completion(.failure(error))
                                return
                            }
                            
                            guard let data = data else {
                                print("❌ No data returned")
                                completion(.failure(GoogleCalendarError.unknown))
                                return
                            }
                            
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let updatedId = json?["id"] as? String {
                                    print("✅ Updated Google Calendar event with ID: \(updatedId)")
                                    completion(.success(updatedId))
                                } else {
                                    print("❌ No event ID returned")
                                    completion(.failure(GoogleCalendarError.noEventID))
                                }
                            } catch {
                                print("❌ Failed to parse response: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    print("❌ No valid authorizer for manual authorization")
                    completion(.failure(GoogleCalendarError.unknown))
                }
            case .failure(let error):
                print("❌ Update event failed due to token refresh: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Delete Event
    func deleteEvent(eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard isSignedIn else {
            completion(.failure(GoogleCalendarError.notSignedIn))
            return
        }
        
        refreshTokenIfNeeded { result in
            switch result {
            case .success:
                guard !eventId.isEmpty else {
                    print("⚠️ Event ID is empty")
                    completion(.success(()))
                    return
                }
                
                let urlString = "https://www.googleapis.com/calendar/v3/calendars/primary/events/\(eventId)?key=\(self.apiKey)"
                guard let url = URL(string: urlString) else {
                    print("❌ Invalid URL")
                    completion(.failure(GoogleCalendarError.unknown))
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                
                if let authorizer = self.service.authorizer as? CustomAuthorizer {
                    let mutableRequest = NSMutableURLRequest(url: url)
                    mutableRequest.httpMethod = "DELETE"
                    authorizer.authorizeRequest(mutableRequest) { error in
                        if let error = error {
                            print("❌ Manual authorization failed: \(error.localizedDescription)")
                            completion(.failure(error))
                            return
                        }
                        
                        request = mutableRequest as URLRequest
                        let fetcher = GTMSessionFetcher(request: request)
                        fetcher.authorizer = self.service.authorizer
                        
                        print("🔍 Starting fetcher for URL: \(urlString)")
                        fetcher.beginFetch { data, error in
                            if let error = error {
                                let nsError = error as NSError
                                if [404, 410].contains(nsError.code) {
                                    print("⚠️ Event already deleted or not found: \(eventId)")
                                    completion(.success(()))
                                } else {
                                    print("❌ Delete event failed: \(error.localizedDescription)")
                                    completion(.failure(error))
                                }
                            } else {
                                print("✅ Deleted Google Calendar event: \(eventId)")
                                completion(.success(()))
                            }
                        }
                    }
                } else {
                    print("❌ No valid authorizer for manual authorization")
                    completion(.failure(GoogleCalendarError.unknown))
                }
            case .failure(let error):
                print("❌ Delete event failed due to token refresh: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Check Conflict
    func checkConflict(startDate: Date, endDate: Date?, completion: @escaping (Result<Bool, Error>) -> Void) {
        let end = endDate ?? startDate.addingTimeInterval(3600)
        fetchEvents(from: startDate, to: end) { result in
            switch result {
            case .success(let events):
                let conflict = events.contains { event in
                    guard let start = event.start?.dateTime?.date,
                          let end = event.end?.dateTime?.date else { return false }
                    return (startDate < end && (endDate ?? startDate) > start)
                }
                print("✅ Checked conflict: \(conflict ? "Conflict found" : "No conflict")")
                completion(.success(conflict))
            case .failure(let error):
                print("❌ Check conflict failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Set Access Token (for compatibility with GoogleAuthViewModel)
    func setAccessToken(_ token: String) {
        print("⚠️ setAccessToken called but not used with AppAuth")
    }
}

// Thêm extension để hỗ trợ định dạng ISO8601
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}
