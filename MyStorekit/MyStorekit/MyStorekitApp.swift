//
//  MyStorekitApp.swift
//  MyStorekit
//
//  Created by Swift-Beginners on 2024/10/22.
//

import SwiftUI

@main
struct MyStorekitApp: App {

    // PurchaseManagerはAppで作成されて、
    // EnvironmentObjectとしてContentViewに渡されます。
    // この方法では他にSwiftUIのビューが増えても、
    // 同じPurchaseManagerオブジェクトに簡単にアクセスできます。

    @StateObject
    private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .task {
                    // アプリの起動時にupdatePurchasedProducts()を実行
                    // purchasedProductIDsを起動時のcurrentEntitlementsの状態で初期化
                    await purchaseManager.updatePurchasedProducts()
                }
        }
    }
}
