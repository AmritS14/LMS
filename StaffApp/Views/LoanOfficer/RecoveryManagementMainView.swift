//
//  RecoveryManagementMainView.swift
//  loan officer
//
//  Created by Aadya Tiwari on 21/05/26.
//


import SwiftUI

struct RecoveryManagementMainView: View {

    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {

        ScrollView(.vertical, showsIndicators: false) {

            VStack(spacing: 20) {

                // MARK: Header

                VStack(alignment: .leading, spacing: 4) {

                    Text("Recovery Management")
                        .font(
                            .system(
                                size: 28,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text("Track overdue & pending recoveries")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // MARK: Recovery Cards

                VStack(spacing: 14) {

                    ForEach(viewModel.filteredApplications) { application in

                        if application.status == .pending
                            || application.riskLevel == .critical {

                            VStack(alignment: .leading, spacing: 14) {

                                HStack(spacing: 12) {

                                    AvatarView(
                                        initials: application.borrowerInitials,
                                        size: 44,
                                        colors: [
                                            .orange,
                                            .red
                                        ]
                                    )

                                    VStack(alignment: .leading, spacing: 4) {

                                        Text(application.borrowerName)
                                            .font(
                                                .system(
                                                    size: 16,
                                                    weight: .semibold
                                                )
                                            )

                                        Text(application.loanType)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {

                                        Text(
                                            AppFormatters.formatCurrency(
                                                application.emiAmount
                                            )
                                        )
                                        .font(
                                            .system(
                                                size: 15,
                                                weight: .bold
                                            )
                                        )

                                        Text("Pending EMI")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                HStack(spacing: 8) {

                                    StatusBadge(
                                        text: application.status.rawValue,
                                        color: application.status.color,
                                        icon: application.status.icon,
                                        size: .small
                                    )

                                    StatusBadge(
                                        text: application.riskLevel.rawValue,
                                        color: application.riskLevel.color,
                                        icon: application.riskLevel.icon,
                                        size: .small
                                    )

                                    Spacer()
                                }

                                Divider()

                                HStack(spacing: 12) {

                                    Button {

                                        if let conversation =
                                            viewModel.conversations.first(where: {
                                                $0.borrowerName == application.borrowerName
                                            }) {

                                            viewModel.selectedConversation = conversation

                                            viewModel.navigationPath.append(
                                                AppDestination.communications
                                            )
                                        }

                                    } label: {

                                        HStack(spacing: 6) {

                                            Image(systemName: "message.fill")

                                            Text("Message")
                                        }
                                        .font(
                                            .system(
                                                size: 13,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundStyle(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(
                                                    Color.blue.opacity(0.1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    Button {

                                        viewModel.selectedApplication =
                                            application

                                        viewModel.navigationPath.append(
                                            AppDestination.recovery
                                        )

                                    } label: {

                                        HStack(spacing: 6) {

                                            Image(
                                                systemName: "arrow.right.circle.fill"
                                            )

                                            Text("View Details")
                                        }
                                        .font(
                                            .system(
                                                size: 13,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.orange)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        Color(
                                            .secondarySystemGroupedBackground
                                        )
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recovery")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {

    NavigationStack {

        RecoveryManagementMainView()
            .environmentObject(AppViewModel())
    }
}
