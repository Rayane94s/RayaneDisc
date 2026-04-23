import Foundation

struct Transaction: Codable, Identifiable {
    let transaction_id: String
    let account_id: String
    let name: String
    let merchant_name: String?
    let amount: Double
    let date: String         // "YYYY-MM-DD"
    let category: [String]?
    let pending: Bool

    var id: String { transaction_id }

    /// Plaid amounts are positive for debits (money out). Flip for display.
    var displayAmount: Double { -amount }

    var isDebit: Bool { amount > 0 }

    var primaryCategory: String {
        category?.first ?? "Other"
    }

    var displayDate: Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: date)
    }
}

struct TransactionsResponse: Codable {
    let transactions: [Transaction]
    let total_transactions: Int
}
