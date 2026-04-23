import SwiftUI
import LinkKit   // Plaid Link iOS SDK

struct LinkBankView: View {
    @EnvironmentObject private var appState: AppState
    @State private var linkToken: String?
    @State private var isPresenting = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "banknote")
                .font(.system(size: 72))
                .foregroundStyle(.indigo)

            VStack(spacing: 8) {
                Text("Welcome to Tweed")
                    .font(.largeTitle.bold())
                Text("Connect your Scotiabank account\nto get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task { await connectBank() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    Text("Connect Scotiabank")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        // Present Plaid Link sheet once we have a link_token
        .sheet(isPresented: $isPresenting) {
            if let token = linkToken {
                PlaidLinkView(linkToken: token) { publicToken in
                    Task { await handleSuccess(publicToken: publicToken) }
                } onExit: { error in
                    isPresenting = false
                    if let e = error { errorMessage = e.localizedDescription }
                }
            }
        }
    }

    private func connectBank() async {
        isLoading = true
        errorMessage = nil
        do {
            linkToken = try await PlaidService.shared.createLinkToken()
            isPresenting = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func handleSuccess(publicToken: String) async {
        isPresenting = false
        isLoading = true
        do {
            try await PlaidService.shared.exchangePublicToken(publicToken)
            KeychainService.shared.markLinked()
            await MainActor.run { appState.markLinked() }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
