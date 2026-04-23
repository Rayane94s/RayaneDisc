import Foundation

struct Account: Codable, Identifiable {
    let account_id: String
    let name: String
    let official_name: String?
    let type: String
    let subtype: String?
    let balances: Balances

    var id: String { account_id }

    struct Balances: Codable {
        let available: Double?
        let current: Double?
        let iso_currency_code: String?
    }

    var displayBalance: Double {
        balances.current ?? balances.available ?? 0
    }

    var currencyCode: String {
        balances.iso_currency_code ?? "CAD"
    }
}

struct AccountsResponse: Codable {
    let accounts: [Account]
}
