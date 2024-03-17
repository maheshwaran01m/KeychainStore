# KeychainStore

**URL:** 

```
https://github.com/maheshwaran01m/KeychainStore
```

## UIKit

```
import UIKit
import KeychainStore

class ExampleVC: UIViewController {
  
  private var records = [User]()
  
  let keychain = KeychainStore()
  
  init() {
    super.init(nibName: nil, bundle: nil)
    getKeychainValues()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  struct User: Codable {
    let userName: String
  }
  
  private func saveToKeychain() {
    let value = User(userName: UUID().uuidString)
    
    if let data = try? JSONEncoder().encode(value) {
      keychain.save(data, forKey: "KeyValue")
      records.append(value)
    }
  }
  
  private func getKeychainValues() {
    if let data = keychain.getData("KeyValue"),
       let user = try? JSONDecoder().decode(User.self, from: data) {
      records.append(user)
    }
  }
}

```


## SwiftUI

```
import SwiftUI
import KeychainStore

struct ExampleView: View {
  
  var body: some View {
    VStack {
      keychainEnvironmentView
      
      keychainStorageView
    }
  }
  
  // MARK: - Environment
  
  struct User: Codable {
    let userName: String
  }
  
  @Environment(\.keychain) private var keychain
  
  @State private var user = User(userName: "")
  
  private var keychainEnvironmentView: some View {
    Button(user.userName.isEmpty ? "No" : user.userName) {
      let value = User(userName: UUID().uuidString)
      if let data = try? JSONEncoder().encode(value) {
        
        keychain.save(data, forKey: "KeyValue")
        user = value
      }
    }
    .buttonStyle(.borderedProminent)
    .onAppear {
      if let data = keychain.getData("KeyValue"),
         let user = try? JSONDecoder().decode(User.self, from: data) {
        self.user = user
      }
    }
  }
  
  // MARK: - State
  
  @KeychainStorage("UserPassword") private var userPassword: String?
  
  private var keychainStorageView: some View {
    
    Button(!(userPassword?.isEmpty ?? false) ? userPassword ?? "No" : "No Password") {
      userPassword = UUID().uuidString
    }
    .buttonStyle(.borderedProminent)
  }
}
```
