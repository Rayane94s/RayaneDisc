import Foundation

/// All network calls to the Tweed backend.
/// Change `baseURL` to your server's address when running on a device.
actor PlaidService {
    static let shared = PlaidService()
    private init() {}

    // When running the backend locally and testing on the Simulator, use localhost.
    // When testing on a real device, replace with your Mac's LAN IP (e.g. 192.168.1.x).
    private let baseURL = "http://localhost:3000"
    private let userId  = "default-user"

    // MARK: - Link Token

    func createLinkToken() async throws -> String {
        let url = URL(string: "\(baseURL)/api/create_link_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["userId": userId])

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode([String: String].self, from: data)
        guard let token = decoded["link_token"] else {
            throw PlaidError.missingField("link_token")
        }
        return token
    }

    // MARK: - Token Exchange

    func exchangePublicToken(_ publicToken: String) async throws {
        let url = URL(string: "\(baseURL)/api/exchange_public_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "public_token": publicToken,
            "userId": userId,
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw PlaidError.exchangeFailed
        }
    }

    // MARK: - Accounts

    func fetchAccounts() async throws -> [Account] {
        let url = URL(string: "\(baseURL)/api/accounts?userId=\(userId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(AccountsResponse.self, from: data)
        return decoded.accounts
    }

    // MARK: - Transactions

    func fetchTransactions() async throws -> [Transaction] {
        let url = URL(string: "\(baseURL)/api/transactions?userId=\(userId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(TransactionsResponse.self, from: data)
        return decoded.transactions
    }
}

enum PlaidError: Error, LocalizedError {
    case missingField(String)
    case exchangeFailed

    var errorDescription: String? {
        switch self {
        case .missingField(let f): return "Missing field: \(f)"
        case .exchangeFailed:      return "Token exchange failed"
        }
    }
}
