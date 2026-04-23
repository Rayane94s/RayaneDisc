import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
            SpendingChartView()
                .tabItem {
                    Label("Charts", systemImage: "chart.bar.fill")
                }
            CategoryAnalysisView()
                .tabItem {
                    Label("Categories", systemImage: "chart.pie.fill")
                }
        }
        .tint(.indigo)
    }
}
