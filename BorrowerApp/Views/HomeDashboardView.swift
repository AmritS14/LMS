import SwiftUI

struct HomeDashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    SectionCard(title: "Quick Actions") {
                        NavigationLink("Apply for Loan") { NewLoanApplicationView() }
                        NavigationLink("EMI Calculator") { EMICalculatorView() }
                        NavigationLink("Complete KYC") { KYCView() }
                    }
                    SectionCard(title: "My Applications") {
                        NavigationLink("View All") { ApplicationTrackingView() }
                    }
                }
                .padding(Spacing.m)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview { HomeDashboardView() }
