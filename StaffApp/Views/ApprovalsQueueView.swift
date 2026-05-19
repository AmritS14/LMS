import SwiftUI
import LMSCore
import LMSDesignSystem

struct ApprovalsQueueView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Escalated #—").font(.lmsHeadline)
                            Text("Officer recommendation").font(.lmsCaption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge("Pending", tone: .warning)
                    }
                }
            }
            .navigationTitle("Approvals")
        }
    }
}
