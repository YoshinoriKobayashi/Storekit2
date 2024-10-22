//
//  ContentView.swift
//  MyStorekit
//
//  Created by Swift-Beginners on 2024/10/22.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    let productIds = ["pro_monthly", "pro_yearly", "pro_lifetime"]

    @State
    private var products: [Product] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Products")
            ForEach(self.products) { product in
                Button {
                    Task {
                        do {
                            try await self.purchase(product)
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
        }.task {
            do {
                try await self.loadProducts()
            } catch {
                print(error)
            }
        }
    }

    private func loadProducts() async throws {
        // The products are not returned in the order in which the IDs are requested.
        self.products = try await Product.products(for: productIds)
    }

    // 製品に対して購入の処理を開始する
    private func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            // The purchase was successful.
            await transaction.finish()
        case let .success(.unverified(_, error)):
            // The purchase was successful, but the transaction / receipt can't be verified.
            // It could be a jailbroken phone.

            // 製品の購入処理は成功しましたが、StoreKitの検証が失敗しました。
            // この状態は脱獄したデバイス上で実行されたことが原因の可能性があります。
            // しかしStoreKitのドキュメントにこの状態についての記載はなく、詳細は不明です。
            break
        case .pending:
            // The transaction is waiting on SCA (Strong Customer Authentication) or approval from Ask to Buy.

            // 「強力な顧客認証（SCA：Strong Customer Authentication）」
            // または「承認と購入のリクエスト」のいずれかによって発生します。
            // 「強力な顧客認証」は購入処理が完了する前に
            // 金融機関が求める追加の確認や承認のプロセスです。
            // このプロセスはアプリやSMSのテキストメッセージを通じて行われます。
            // 承認された後に購入処理のトランザクションが更新されます。
            // 「承認と購入のリクエスト」は、子どもがアプリ内課金で製品を
            // 購入しようとした際に、親や保護者の承認を必要とする機能です。
            // 保護者が購入を承認または却下するまで、購入処理は保留状態になります。
            break
        case .userCancelled:
            // ユーザーが購入処理をキャンセルしました。
            // 通常はこの値をエラーとして扱う必要はありません。
            // キャンセルが発生したことを記録できるようにしておくと
            // アプリの改善に役立ちます。
            break
        @unknown default:
            // Errorがthrowされた場合の値は
            // Product.PurchaseErrorまたはStoreKitErrorです。
            // インターネットに接続できない、
            // App Storeに障害が発生している、
            // クレジットカードの支払いに問題が発生した、
            // などの原因が考えられます。
            break
        }
    }
}

#Preview {
    ContentView()
}
