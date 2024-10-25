//
//  PurchaseManager.swift
//  MyStorekit
//
//  Created by Swift-Beginners on 2024/10/23.
//

import Foundation
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    // PurchaseManagerはObservableObjectなので、
    // プロパティが変更されるとSwiftUIのビューは自動的に再描画されます。

    private let productIds = ["pro_monthly", "pro_yearly", "pro_monthly"]

    @Published
    private(set) var products: [Product] = []
    @Published
    private(set) var purchasedProductIDs = Set<String>()

    private var productLoaded = false
    private var updates: Task<Void, Never>? = nil

    init() {
        self.updates = observeTransactionUpdates()
    }

    deinit {
        self.updates?.cancel()
    }

    var hasUnlockedPro: Bool {
        return !self.purchasedProductIDs.isEmpty
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                // Using verificationResult directly would be better,
                // but this approach works for the purpose of this tutorial.
                await self.updatePurchasedProducts()
            }
        }
    }

    func loadProducts() async throws {
        guard !self.productLoaded else { return }
        self.products = try await Product.products(for: productIds)
        self.productLoaded = true
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            // The purchase was successful.
            await transaction.finish()
        case let .success(.verified(transaction)):
            // The purchase was successful, but the transaction / receipt can't be verified.
            // It could be a jailbroken phone.

            // 製品の購入処理は成功しましたが、StoreKitの検証が失敗しました。
            // この状態は脱獄したデバイス上で実行されたことが原因の可能性があります。
            // しかしStoreKitのドキュメントにこの状態についての記載はなく、詳細は不明です。

            await transaction.finish()
            // 新しく購入した製品でpurchasedProductIDsを更新
            await self.updatePurchasedProducts()
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

    // アプリの起動時、購入後、およびトランザクションが更新されたときに呼び出し
    func updatePurchasedProducts() async {

        // Transaction.currentEntitlementsは、非同期シーケンスを返すプロパティで、
        // ユーザーの現在の購入情報（エンタイトルメント）を非同期に提供します。
        // これを処理するには、for awaitを使って各エンタイトルメントが
        // 非同期に提供されるのを待ちながら順次処理する必要があります。

        // Transaction.currentEntitlementsによる購入済み製品の取得は、
        // オンラインでもオフラインでも同じように動作します。

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
                // この後で有効であることが確認できた製品IDに
                // 対応する有料の機能やコンテンツを解放します。
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
}
