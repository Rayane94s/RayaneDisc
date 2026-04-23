import SwiftUI

struct HomeView: View {
    @State private var accounts: [Account] = []
    @State private var recentTransactions: [Transaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.displayBalance }
    }

    private var monthSpend: Double {
        recentTransactions
            .filter { $0.isDebit }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance card
                    VStack(spacing: 6) {
                        Text("Total Balance")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(totalBalance, format: .currency(code: "CAD"))
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        LinearGradient(colors: [.indigo, .purple],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // Month spend summary
                    HStack {
                        SummaryTile(title: "Spent (30d)",
                                    value: monthSpend,
                                    icon: "arrow.up.circle.fill",
                                    color: .red)
                        SummaryTile(title: "Accounts",
                                    value: Double(accounts.count),
                                    icon: "creditcard.fill",
                                    color: .indigo,
                                    isCount: true)
                    }
                    .padding(.horizontal)

                    // Recent transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.headline)
                            .padding(.horizontal)

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 80)
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.footnote)
                                .padding(.horizontal)
                        } else {
                            ForEach(recentTransactions.prefix(5)) { tx in
                                TransactionRow(transaction: tx)
                                    .padding(.horizontal)
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tweed")
            .task { await loadData() }
            .refreshable { await loadData() }
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedAccounts     = PlaidService.shared.fetchAccounts()
            async let fetchedTransactions = PlaidService.shared.fetchTransactions()
            accounts             = try await fetchedAccounts
            recentTransactions   = try await fetchedTransactions
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct SummaryTile: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    var isCount = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isCount {
                    Text("\(Int(value))")
                        .font(.title3.bold())
                } else {
                    Text(value, format: .currency(code: "CAD"))
                        .font(.title3.bold())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
