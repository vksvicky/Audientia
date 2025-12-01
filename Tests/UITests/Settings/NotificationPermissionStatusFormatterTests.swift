//
//  NotificationPermissionStatusFormatterTests.swift
//  UITests
//

import UserNotifications
import XCTest

@testable import Audientia

final class NotificationPermissionStatusFormatterTests: XCTestCase {
    
    func testDescriptionForNotDetermined() {
        XCTAssertEqual(
            NotificationPermissionStatusFormatter.description(for: .notDetermined),
            "Not requested yet"
        )
    }
    
    func testDescriptionForDenied() {
        XCTAssertEqual(
            NotificationPermissionStatusFormatter.description(for: .denied),
            "Denied in System Settings"
        )
    }
    
    func testDescriptionForAuthorized() {
        XCTAssertEqual(
            NotificationPermissionStatusFormatter.description(for: .authorized),
            "Allowed"
        )
    }
    
    func testDescriptionForProvisional() {
        XCTAssertEqual(
            NotificationPermissionStatusFormatter.description(for: .provisional),
            "Provisional (temporary)"
        )
    }
    
    func testDescriptionForEphemeral() {
        #if !os(macOS)
        if #available(iOS 14.0, *) {
            XCTAssertEqual(
                NotificationPermissionStatusFormatter.description(for: .ephemeral),
                "Ephemeral"
            )
        }
        #endif
    }
}
