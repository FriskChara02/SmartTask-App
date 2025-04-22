//
//  GoogleAuthViewModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 17/4/25.
//

import Foundation
import SwiftUI
import UIKit

class GoogleAuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool {
        didSet {
            UserDefaults.standard.set(isSignedIn, forKey: "GoogleCalendarSync")
            // Đồng bộ với GoogleCalendarService
            GoogleCalendarService.shared.isSignedIn = isSignedIn
        }
    }

    private let calendarService = GoogleCalendarService.shared

    init() {
        // Khởi tạo từ UserDefaults hoặc trạng thái của GoogleCalendarService
        self.isSignedIn = UserDefaults.standard.bool(forKey: "GoogleCalendarSync") || GoogleCalendarService.shared.isSignedIn
    }

    // MARK: - Đăng nhập Google
    func signIn(presentingViewController: UIViewController, completion: @escaping (Result<Void, Error>) -> Void) {
        calendarService.signIn(presentingViewController: presentingViewController) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.isSignedIn = true
                    print("✅ Google Sign-In succeeded.")
                    completion(.success(()))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isSignedIn = false
                    print("❌ Google Sign-In failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Đăng xuất
    func signOut() {
        calendarService.signOut()
        isSignedIn = false
        print("✅ Google Signed out.")
    }
}
