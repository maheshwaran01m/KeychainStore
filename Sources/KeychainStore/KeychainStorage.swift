//
//  KeychainStorage.swift
//  
//
//  Created by MAHESHWARAN on 17/03/24.
//

#if canImport(SwiftUI)

import SwiftUI

public struct KeychainStoreManager: EnvironmentKey {
  
  static public let defaultValue: KeychainStore = KeychainStore()
}

@available(iOS 13.0, macOS 10.15, *)
public extension EnvironmentValues {
  
  var keychain: KeychainStore {
    get { self[KeychainStoreManager.self] }
    set { self[KeychainStoreManager.self] = newValue }
  }
}

// MARK: - KeychainStorage

@propertyWrapper
@available(iOS 13.0, macOS 10.15, *)
public struct KeychainStorage<T: Codable>: DynamicProperty {
  
  @State private var value: T?
  
  private let key: String
  
  private let keychain: KeychainStore
  
  public var wrappedValue: T? {
    get { value }
    nonmutating set { save(newValue) }
  }
  
  // MARK: - ProjectedValue
  
  public var projectedValue: Binding<T?> {
    .init { wrappedValue } set: { wrappedValue = $0 }
  }
  
  // MARK: - Init
  
  public init(wrappedValue: T? = nil, _ key: String) {
    self.key = key
    
    let keychain = KeychainStore()
    self.keychain = keychain
    
    if let data = keychain.getData(key),
       let value = try? JSONDecoder().decode(T.self, from: data) {
      _value = .init(initialValue: value)
    }
  }
  
  private func save(_ newValue: T?) {
    guard let newValue,
          let data = try? JSONEncoder().encode(newValue) else {
      return
    }
    keychain.save(data, forKey: key)
    value = newValue
  }
}

#endif

