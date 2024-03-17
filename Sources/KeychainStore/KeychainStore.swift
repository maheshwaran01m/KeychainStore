// KeychainStore.swift

// Copyright © 2024 MAHESHWARAN

#if canImport(Foundation) && canImport(Security)

import Foundation
import Security

open class KeychainStore {
  
  open var synchronizable: Bool
  
  open var accessGroup: String?
  
  open var resultCode: OSStatus = noErr
  
  // MARK: -  Internal Property
  
  private let lock = NSLock()
  
  private var key: String
  
  private var queryParameter: [String: Any]?
  
  // MARK: - Init
  
  public init() {
    key = ""
    synchronizable = false
  }
  
  public init(_ key: String, synchronizable: Bool = false) {
    self.key = key
    self.synchronizable = synchronizable
  }
  
  // MARK: - Save
  
  @discardableResult
  open func save(_ value: String, forKey key: String, withAccess access: KeychainStoreOption? = nil) -> Bool {
    
    guard let value = value.data(using: .utf8) else { return false }
    return save(value, forKey: key, withAccess: access)
  }
  
  @discardableResult
  open func save(_ value: Data, forKey key: String, withAccess access: KeychainStoreOption? = nil) -> Bool {
    
    lock.lock()
    
    defer { lock.unlock() }
    
    deleteWithOutLock(key)
    
    var query: [String: Any] = [
      kSecClass.stringValue: kSecClassGenericPassword,
      kSecAttrAccount.stringValue: keyWithPrefix(key),
      kSecValueData.stringValue: value,
      kSecAttrAccessible.stringValue: access?.value ?? KeychainStoreOption.none
    ]
    query = addAccessGroupWhenPresent(query)
    query = addSynchronizableIfRequired(query, addingItems: true)
    queryParameter = query
    
    resultCode = SecItemAdd(query as CFDictionary, nil)
    
    return resultCode == noErr
  }
  
  // MARK: - Get
  
  open func get(_ key: String) -> String? {
    
    guard let data = getData(key, reference: false) else { return nil }
    
    guard let newData = String(data: data, encoding: .utf8) else {
      resultCode = -67853
      return nil
    }
    return newData
  }
  
  open func getData(_ key: String, reference: Bool = false) -> Data? {
    
    lock.lock()
    
    defer { lock.unlock() }
    
    var query: [String: Any] = [
      kSecClass.stringValue: kSecClassGenericPassword,
      kSecAttrAccount.stringValue: keyWithPrefix(key),
      kSecMatchLimit.stringValue: kSecMatchLimitOne
    ]
    
    if reference {
      query[kSecReturnPersistentRef.stringValue] = kCFBooleanTrue
    } else {
      query[kSecReturnData.stringValue] = kCFBooleanTrue
    }
    
    query = addAccessGroupWhenPresent(query)
    query = addSynchronizableIfRequired(query)
    queryParameter = query
    
    var result: AnyObject?
    
    resultCode = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }
    
    guard resultCode == noErr else { return nil }
    
    return result as? Data
  }
  
  // MARK: - Delete
  
  @discardableResult
  open func delete(_ key: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    
    return deleteWithOutLock(key)
  }
  
  @discardableResult
  private func deleteWithOutLock(_ key: String) -> Bool {
    
    var query: [String: Any] = [
      kSecClass.stringValue: kSecClassGenericPassword,
      kSecAttrAccount.stringValue: keyWithPrefix(key),
    ]
    query = addAccessGroupWhenPresent(query)
    query = addSynchronizableIfRequired(query)
    queryParameter = query
    resultCode = SecItemDelete(query as CFDictionary)
    
    return resultCode == noErr
  }
  
  // MARK: - Clear
  
  @discardableResult
  open func clear() -> Bool {
    
    lock.lock()
    defer { lock.unlock() }
    
    var query: [String: Any] = [kSecClass.stringValue: kSecClassGenericPassword]
    query = addAccessGroupWhenPresent(query)
    query = addSynchronizableIfRequired(query)
    
    queryParameter = query
    resultCode = SecItemDelete(query as CFDictionary)
    
    return resultCode == noErr
  }
  
  // MARK: - Internal Methods
  
  public var allKeys: [String] {
    
    var query: [String: Any] = [
      kSecClass.stringValue: kSecClassGenericPassword,
      kSecReturnData.stringValue: true,
      kSecReturnAttributes.stringValue: true,
      kSecReturnPersistentRef.stringValue: true,
      kSecMatchLimit.stringValue: kSecMatchLimitAll.stringValue
    ]
    query = addAccessGroupWhenPresent(query)
    query = addSynchronizableIfRequired(query)
    
    var result: AnyObject?
    
    let resultCode = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }
    
    guard resultCode == noErr else { return [] }
    
    guard let result = (result as? [[String: Any]]) else { return [] }
    
    return result.compactMap { ($0[kSecAttrAccount.stringValue] as? String) }
  }
  
  private func keyWithPrefix(_ newKey: String) -> String {
    "\(key)\(newKey)"
  }
  
  private func addAccessGroupWhenPresent(_ items: [String: Any]) -> [String: Any] {
    guard let accessGroup = accessGroup else { return items }
    
    var result = items
    result[kSecAttrAccessGroup.stringValue] = accessGroup
    return result
  }
  
  private func addSynchronizableIfRequired(_ items: [String: Any], addingItems: Bool = false) -> [String: Any] {
    guard synchronizable else { return items }
    
    var result = items
    result[kSecAttrSynchronizable.stringValue] = addingItems == true ? true : kSecAttrSynchronizableAny
    
    return result
  }
}

// MARK: - SubScript

public extension KeychainStore {
  
  subscript(key: String) -> String? {
    get { get(key) }
    set {
      guard let newValue else { return }
      save(newValue, forKey: key)
    }
  }
  
  subscript(key: String) -> Data? {
    get { getData(key) }
    set {
      guard let newValue else { return }
      save(newValue, forKey: key)
    }
  }
}

#endif
