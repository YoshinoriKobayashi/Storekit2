//
//  ContentView.swift
//  MyStorekit
//
//  Created by Swift-Beginners on 2024/10/22.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject
    private var purchaseManager: PurchaseManager

    var body: some View {
        VStack(spacing: 20) {
            if purchaseManager.hasUnlockedPro {
                Text("Thank you for purchasing pro!")
            } else {
                Text("Products")
                ForEach(purchaseManager.products) { product in
                    Button {
                        Task {
                            do {
                                try await purchaseManager.purchase(product)
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        Text("\(product.displayPrice) - \(product.displayName)")
                            .foregroundColor(.white)
                            .padding()
                            .background(.blue)
                            .clipShape(Capsule())
                    }
                }
                Button {
                    Task {
                        do {
                            try await AppStore.sync()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Restore Purchases")
                }
            }
        }.task {
            do {
                try await purchaseManager.loadProducts()
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
