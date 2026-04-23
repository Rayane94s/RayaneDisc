import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var categoryIcon: String {
        let cat = transaction.primaryCategory.lowercased()
        if cat.contains("food") || cat.contains("restaurant") { return "fork.knife" }
        if cat.contains("transport") || cat.contains("travel")  { return "car.fill" }
        if cat.contains("shop") || cat.contains("merchand")     { return "cart.fill" }
        if cat.contains("health") || cat.contains("medical")    { return "heart.fill" }
        if cat.contains("entertainment")                        { return "film.fill" }
        if cat.contains("transfer")                             { return "arrow.left.arrow.right" }
        return "creditcard.fill"
    }

    private var iconColor: Color {
        let cat = transaction.primaryCategory.lowercased()
        if cat.contains("food") || cat.contains("restaurant") { return .orange }
        if cat.contains("transport") || cat.contains("travel")  { return .blue }
        if cat.contains("shop") || cat.contains("merchand")     { return .purple }
        if cat.contains("health") || cat.contains("medical")    { return .red }
        if cat.contains("entertainment")                        { return .pink }
        return .indigo
    }

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            Image(systemName: categoryIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())

            // Name + date
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant_name ?? transaction.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(transaction.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(abs(transaction.amount), format: .currency(code: "CAD"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(transaction.isDebit ? .primary : .green)
                if transaction.pending {
                    Text("Pending")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
