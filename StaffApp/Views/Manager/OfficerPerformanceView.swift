import SwiftUI

// MARK: - Officer Performance List

struct OfficerPerformanceView: View {
    @Environment(ManagerStore.self) private var store
    @State private var searchText = ""

    private var filteredOfficers: [OfficerPerformanceData] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.officerPerformance }
        return store.officerPerformance.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {


            // MARK: Officers

            Section("Loan Officers") {
                if filteredOfficers.isEmpty {
                    ContentUnavailableView("No officers found",
                                           systemImage: "person.slash",
                                           description: Text("Try a different search."))
                } else {
                    ForEach(filteredOfficers) { officer in
                        NavigationLink(value: ManagerRoute.officerDetail(officer.name)) {
                            officerRow(officer)
                           
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Officer Performance")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search officer")
    }



    // MARK: Officer Row

    private func officerRow(_ officer: OfficerPerformanceData) -> some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(initials: officer.initials, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(officer.name)
                    .font(.body)
                
                Text("\(officer.applicationsProcessed) processed • \(Formatting.percent(officer.approvalRate, fractionDigits: 0)) approval")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                
                
            }
        }
        .padding(.vertical, 4)
    }

}

#Preview {
    NavigationStack {
        OfficerPerformanceView()
    }
    .environment(ManagerStore.preview)
}
