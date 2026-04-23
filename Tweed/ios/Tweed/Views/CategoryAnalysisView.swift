import SwiftUI
import Charts

// MARK: - Supporting Types

enum CategoryPeriod: String, CaseIterable, Identifiable {
    case month   = "30 Days"
    case quarter = "3 Months"
    case year    = "12 Months"
    var id: Self { self }

    var lookbackDays: Int {
        switch self {
        case .month:   return 30
        case .quarter: return 90
        case .year:    return 365
        }
    }
}

struct CategorySlice: Identifiable {
    let name: String
    let total: Double
    let color: Color
    var id: String { name }
}

// MARK: - CategoryAnalysisView

struct CategoryAnalysisView: View {
    @State private var transactions: [Transaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var period: CategoryPeriod = .month
    @State private var selectedCategory: String?

    private static let palette: [Color] = [
        .indigo, .orange, .teal, .pink, .purple,
        .blue, .mint, .red, .yellow, .cyan
    ]

    // MARK: - Computed

    private var cutoff: Date {
        Calendar.current.date(byAdding: .day, value: -period.lookbackDays, to: Date())!
    }

    private var slices: [CategorySlice] {
        let debits = transactions.filter {
            $0.isDebit && ($0.displayDate ?? .distantPast) >= cutoff
        }
        var totals: [String: Double] = [:]
        for tx in debits {
            totals[tx.primaryCategory, default: 0] += tx.amount
        }
        return totals
            .sorted { $0.value > $1.value }
            .enumerated()
            .map { i, pair in
                CategorySlice(
                    name: pair.key,
                    total: pair.value,
                    color: Self.palette[i % Self.palette.count]
                )
            }
    }

    private var grandTotal: Double {
        slices.reduce(0) { $0 + $1.total }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Period", selection: $period) {
                        ForEach(CategoryPeriod.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .onChange(of: period) { selectedCategory = nil }

                    if isLoading && transactions.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = errorMessage {
                        ContentUnavailableView(
                            "Couldn't Load",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error)
                        )
                    } else if slices.isEmpty {
                        ContentUnavailableView(
                            "No Spending Data",
                            systemImage: "chart.pie",
                            description: Text("No transactions found for the selected period.")
                        )
                    } else {
                        donutCard
                        breakdownList
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Categories")
            .task { await loadTransactions() }
            .refreshable { await loadTransactions() }
        }
    }

    // MARK: - Donut Card

    @ViewBuilder
    private var donutCard: some View {
        VStack(spacing: 4) {
            ZStack {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Spend", slice.total),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.color)
                    .opacity(selectedCategory == nil || selectedCategory == slice.name ? 1 : 0.25)
                    .cornerRadius(4)
                }
                .frame(height: 240)

                // Center label
                VStack(spacing: 2) {
                    if let sel = selectedCategory,
                       let slice = slices.first(where: { $0.name == sel }) {
                        Text(sel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 100)
                        Text(slice.total, format: .currency(code: "CAD").precision(.fractionLength(0)))
                            .font(.title3.bold())
                        Text(pct(slice.total))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Total")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(grandTotal, format: .currency(code: "CAD").precision(.fractionLength(0)))
                            .font(.title3.bold())
                        Text(period.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Breakdown List

    @ViewBuilder
    private var breakdownList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breakdown")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(slices) { slice in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = selectedCategory == slice.name ? nil : slice.name
                        }
                    } label: {
                        categoryRow(slice: slice)
                    }
                    .buttonStyle(.plain)

                    if slice.id != slices.last?.id {
                        Divider().padding(.leading, 46)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func categoryRow(slice: CategorySlice) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(slice.color)
                .frame(width: 12, height: 12)
                .padding(.leading, 16)

            Text(slice.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(slice.color.opacity(0.15))
                    Capsule()
                        .fill(slice.color.opacity(0.5))
                        .frame(width: geo.size.width * (grandTotal > 0 ? slice.total / grandTotal : 0))
                }
            }
            .frame(width: 60, height: 6)

            VStack(alignment: .trailing, spacing: 2) {
                Text(slice.total, format: .currency(code: "CAD").precision(.fractionLength(0)))
                    .font(.subheadline.weight(.semibold))
                Text(pct(slice.total))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 72, alignment: .trailing)
            .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
        .background(
            selectedCategory == slice.name
                ? slice.color.opacity(0.08)
                : Color.clear
        )
    }

    // MARK: - Helpers

    private func pct(_ value: Double) -> String {
        guard grandTotal > 0 else { return "0%" }
        return (value / grandTotal).formatted(.percent.precision(.fractionLength(1)))
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
}
