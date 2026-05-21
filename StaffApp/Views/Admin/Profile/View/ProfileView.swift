//
//  ProfileView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Profile View

/// A native iOS Profile view matching the requested layout.
struct ProfileView: View {
    @State private var isTwoFactorEnabled = true
    @State private var isBiometricEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: AdminSpacing.sectionGap) {
                // Header: Avatar, Name, Role
                headerView
                
                // Account Section
                accountSection
                
                // Security Section
                securitySection
                
                // Preferences Section
                preferencesSection
                
                // Support & Sign Out Section
                footerSection
            }
            .padding(.horizontal, AdminSpacing.cardRowHorizontalInset)
            .padding(.top, AdminSpacing.cardRowVerticalInset)
            .padding(.bottom, Spacing.xl)
        }
        .background(AdminColor.background)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections

    private var headerView: some View {
        VStack(spacing: 12) {
            Text("SA")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(Color.indigo)
                .clipShape(Circle())

            VStack(spacing: 4) {
                Text("Sarah Jenkins")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("SYSTEM ADMIN")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.indigo.opacity(0.15), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Account", systemImage: "person.circle")
            
            VStack(spacing: Spacing.s) {
                profileRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: "Personal Information"
                )
                
                Divider()
                
                profileRow(
                    icon: "checkmark.shield.fill",
                    iconColor: .green,
                    title: "KYC Status",
                    value: "Verified"
                )
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Security", systemImage: "lock.shield")
            
            VStack(spacing: Spacing.s) {
                profileRow(
                    icon: "lock.fill",
                    iconColor: .gray,
                    title: "Change Password"
                )
                
                Divider()
                
                HStack(spacing: 12) {
                    iconView(icon: "key.fill", color: .orange)
                    Toggle("Two-Factor Authentication", isOn: $isTwoFactorEnabled)
                        .tint(.green)
                }
                
                Divider()
                
                HStack(spacing: 12) {
                    iconView(icon: "faceid", color: .indigo)
                    Toggle("Biometric Login", isOn: $isBiometricEnabled)
                        .tint(.green)
                }
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            SectionHeaderView(title: "Preferences", systemImage: "slider.horizontal.3")
            
            VStack(spacing: Spacing.s) {
                profileRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Notification Settings"
                )
                
                Divider()
                
                profileRow(
                    icon: "globe",
                    iconColor: .teal,
                    title: "Language",
                    value: "English"
                )
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: AdminSpacing.headerToCardGap) {
            VStack(spacing: Spacing.s) {
                profileRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .gray,
                    title: "Support"
                )
                
                Divider()
                
                Button {
                    // Sign out action
                } label: {
                    HStack(spacing: 12) {
                        iconView(icon: "rectangle.portrait.and.arrow.right.fill", color: .red.opacity(0.2), foregroundColor: .red)
                        Text("Sign Out")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(AdminSpacing.cardPadding)
            .background(
                AdminColor.cardBackground,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 4) {
                Text("Version v2.4.0")
                Text("Last login: Today, 10:42 AM")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Subviews
    
    private func profileRow(icon: String, iconColor: Color, title: String, value: String? = nil) -> some View {
        HStack(spacing: 12) {
            iconView(icon: icon, color: iconColor)
            
            Text(title)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
    
    private func iconView(icon: String, color: Color, foregroundColor: Color = .white) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .frame(width: 32, height: 32)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
