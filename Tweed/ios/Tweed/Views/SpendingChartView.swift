import SwiftUI
import Charts

// MARK: - Supporting Types

enum SpendPeriod: String, CaseIterable, Identifiable {
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
    var id: Self { self }
}

struct SpendBucket: Identifiable {
    let date: Date
    let total: Double    // total spend for the period
    let avgDaily: Double // avg daily spend (rolling avg for daily, total/days for weekly/monthly)
    var id: Date { date }
}

// MARK: - SpendingChartView

struct SpendingChartView: View {
    @State private var transactions: [Transaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var period: SpendPeriod = .daily

    // MARK: Computed Properties

    private var buckets: [SpendBucket] {
        switch period {
        case .daily:   return makeDailyBuckets()
        case .weekly:  return makeWeeklyBuckets()
        case .monthly: return makeMonthlyBuckets()
        }
    }

    private var totalSpend: Double {
        buckets.reduce(0) { $0 + $1.total }
    }

    private var overallAvgDaily: Double {
        switch period {
        case .daily:
            let activeDays = buckets.filter { $0.total > 0 }
            return activeDays.isEmpty ? 0 : activeDays.reduce(0) { $0 + $1.total } / Double(activeDays.count)
        case .weekly, .monthly:
            guard !buckets.isEmpty else { return 0 }
            return buckets.reduce(0) { $0 + $1.avgDaily } / Double(buckets.count)
        }
    }

    private var calUnit: Calendar.Component {
        switch period {
        case .daily:   return .day
        case .weekly:  return .weekOfYear
        case .monthly: return .month
        }
    }

    private var xAxisDateFormat: Date.FormatStyle {
        switch period {
        case .daily, .weekly: return Date.FormatStyle().month(.abbreviated).day()
        case .monthly:        return Date.FormatStyle().month(.abbreviated).year(.twoDigits)
        }
    }

    private var axisTickCount: Int {
        switch period {
        case .daily:   return 5
        case .weekly:  return 6
        case .monthly: return 12
        }
    }

    private var periodTotalLabel: String {
        switch period {
        case .daily:   return "30-Day Total"
        case .weekly:  return "12-Week Total"
        case .monthly: return "12-Month Total"
        }
    }

    private var periodUnitLabel: String {
        switch period {
        case .daily:   return "Day"
        case .weekly:  return "Week"
        case .monthly: return "Month"
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Period", selection: $period) {
                        ForEach(SpendPeriod.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 4)

                    if isLoading && transactions.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = errorMessage {
                        ContentUnavailableView(
                            "Couldn't Load",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error)
                        )
                    } else {
                        HStack(spacing: 12) {
                            statTile(title: periodTotalLabel, value: totalSpend)
                            statTile(title: "Avg Daily", value: overallAvgDaily)
                        }
                        .padding(.horizontal)

                        // Histogram — spend per period
                        chartCard(title: "Spend per \(periodUnitLabel)") {
                            Chart(buckets) { bucket in
                                BarMark(
                                    x: .value("Period", bucket.date, unit: calUnit),
                                    y: .value("Spend", bucket.total)
                                )
                                .foregroundStyle(.indigo.gradient)
                                .cornerRadius(4)
                            }
                            .chartXAxis { xAxisMarks }
                            .chartYAxis { yAxisMarks }
                            .frame(height: 220)
                        }

                        // Trend line — avg daily spend
                        let trendTitle = period == .daily
                            ? "7-Day Rolling Avg Daily Spend"
                            : "Avg Daily Spend Trend"

                        chartCard(title: trendTitle) {
                            Chart(buckets) { bucket in
                                AreaMark(
                                    x: .value("Period", bucket.date, unit: calUnit),
                                    y: .value("Avg Daily", bucket.avgDaily)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.25), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Period", bucket.date, unit: calUnit),
                                    y: .value("Avg Daily", bucket.avgDaily)
                                )
                                .foregroundStyle(.purple)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Period", bucket.date, unit: calUnit),
                                    y: .value("Avg Daily", bucket.avgDaily)
                                )
                                .foregroundStyle(.purple)
                                .symbolSize(period == .daily ? 0 : 35)
                            }
                            .chartYScale(domain: 0...)
                            .chartXAxis { xAxisMarks }
                            .chartYAxis { yAxisMarks }
                            .frame(height: 200)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Charts")
            .task { await loadTransactions() }
            .refreshable { await loadTransactions() }
        }
    }

    // MARK: - Shared Axis Marks

    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: axisTickCount)) { value in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(date, format: xAxisDateFormat)
                        .font(.caption2)
                }
            }
        }
    }

    @AxisContentBuilder
    private var yAxisMarks: some AxisContent {
        AxisMarks { value in
            AxisGridLine()
            AxisValueLabel {
                if let amount = value.as(Double.self) {
                    Text(amount, format: .currency(code: "CAD").precision(.fractionLength(0)))
                        .font(.caption2)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func statTile(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "CAD"))
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Data Builders

    private func debitTransactions() -> [Transaction] {
        transactions.filter { $0.isDebit && $0.displayDate != nil }
    }

    /// Last 30 days, one bucket per day. avgDaily = 7-day rolling average.
    private func makeDailyBuckets() -> [SpendBucket] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let cutoff = cal.date(byAdding: .day, value: -29, to: today)!

        let grouped = Dictionary(
            grouping: debitTransactions().filter { $0.displayDate! >= cutoff },
            by: { cal.startOfDay(for: $0.displayDate!) }
        )

        typealias DayTotal = (date: Date, total: Double)
        var raw: [DayTotal] = []
        var cursor = cutoff
        while cursor <= today {
            let spend = (grouped[cursor] ?? []).reduce(0) { $0 + $1.amount }
            raw.append((cursor, spend))
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }

        let window = 7
        return raw.enumerated().map { i, day in
            let from = max(0, i - window + 1)
            let avg = raw[from...i].reduce(0) { $0 + $1.total } / Double(i - from + 1)
            return SpendBucket(date: day.date, total: day.total, avgDaily: avg)
        }
    }

    /// Last 12 weeks. avgDaily = weekTotal / 7.
    private func makeWeeklyBuckets() -> [SpendBucket] {
        let cal = Calendar.current
        guard
            let base = cal.date(byAdding: .weekOfYear, value: -11, to: Date()),
            let cutoffInterval = cal.dateInterval(of: .weekOfYear, for: base),
            let thisWeekInterval = cal.dateInterval(of: .weekOfYear, for: Date())
        else { return [] }

        let cutoff = cutoffInterval.start
        let grouped = Dictionary(
            grouping: debitTransactions().filter { $0.displayDate! >= cutoff },
            by: { cal.dateInterval(of: .weekOfYear, for: $0.displayDate!)!.start }
        )

        var buckets: [SpendBucket] = []
        var weekStart = cutoff
        while weekStart <= thisWeekInterval.start {
            let total = (grouped[weekStart] ?? []).reduce(0) { $0 + $1.amount }
            buckets.append(SpendBucket(date: weekStart, total: total, avgDaily: total / 7.0))
            weekStart = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }
        return buckets
    }

    /// Last 12 months. avgDaily = monthTotal / daysInMonth.
    private func makeMonthlyBuckets() -> [SpendBucket] {
        let cal = Calendar.current
        guard
            let base = cal.date(byAdding: .month, value: -11, to: Date()),
            let cutoffInterval = cal.dateInterval(of: .month, for: base),
            let thisMonthInterval = cal.dateInterval(of: .month, for: Date())
        else { return [] }

        let cutoff = cutoffInterval.start
        let grouped = Dictionary(
            grouping: debitTransactions().filter { $0.displayDate! >= cutoff },
            by: { cal.dateInterval(of: .month, for: $0.displayDate!)!.start }
        )

        var buckets: [SpendBucket] = []
        var monthStart = cutoff
        while monthStart <= thisMonthInterval.start {
            let total = (grouped[monthStart] ?? []).reduce(0) { $0 + $1.amount }
            let daysInMonth = Double(cal.range(of: .day, in: .month, for: monthStart)!.count)
            buckets.append(SpendBucket(date: monthStart, total: total, avgDaily: total / daysInMonth))
            monthStart = cal.date(byAdding: .month, value: 1, to: monthStart)!
        }
        return buckets
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
