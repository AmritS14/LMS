import SwiftUI
import LMSCore
import LMSDesignSystem

struct AuditTrailView: View {
    var body: some View {
        NavigationStack {
            List {
                // TODO: AdminService.auditTrail
                ForEach(0..<5, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Action — Entity").font(.lmsHeadline)
                        Text("by user · timestamp").font(.lmsCaption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Audit Trail")
        }
    }
}
