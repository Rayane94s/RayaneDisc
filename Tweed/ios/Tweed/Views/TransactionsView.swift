import SwiftUI

struct TransactionsView: View {
    @State private var transactions: [Transaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""

    private var filtered: [Transaction] {
        guard !searchText.isEmpty else { return transactions }
        let q = searchText.lowercased()
        return transactions.filter {
            ($0.merchant_name ?? $0.name).lowercased().contains(q) ||
            $0.primaryCategory.lowercased().contains(q)
        }
    }

    // Group by date string "YYYY-MM-DD"
    private var grouped: [(date: String, items: [Transaction])] {
        let dict = Dictionary(grouping: filtered, by: \.date)
        return dict
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, items: $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && transactions.isEmpty {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Couldn't Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.date) { group in
                            Section(header: Text(formatSectionDate(group.date))) {
                                ForEach(group.items) { tx in
                                    TransactionRow(transaction: tx)
                                        .listRowSeparator(.hidden)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search merchants or categories")
            .task { await loadTransactions() }
            .refreshable { await loadTransactions() }
        }
    }

    private func loadTransactions() async {
        isLoading = true
        errorMessage = nil
        do {
            transactions = try await PlaidService.shared.fetchTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func formatSectionDate(_ dateStr: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: dateStr) else { return dateStr }
        let display = DateFormatter()
        display.dateStyle = .medium
        return display.string(from: date)
    }
}
