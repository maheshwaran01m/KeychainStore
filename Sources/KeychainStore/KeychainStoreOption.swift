//
//  KeychainStoreOption.swift
//  
//
//  Created by MAHESHWARAN on 17/03/24.
//

#if canImport(Foundation)

import Foundation

public enum KeychainStoreOption {
  
  case whenFirstUnlock
  case whenUnlocked
  case always
  case awlaysThisDeviceOnly
  case whenUnlockedThisDeviceOnly
  
  var value: String {
    switch self {
    case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked.stringValue
    case .whenFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock.stringValue
    case .always: return kSecAttrAccessible.stringValue
    case .awlaysThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly.stringValue
    case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly.stringValue
    }
  }
  
  static public let none = kSecAttrAccessibleWhenUnlocked.stringValue
}

// MARK: - CFString Extensions

public extension CFString {
  
  var stringValue: String {
    self as String
  }
}
#endif
