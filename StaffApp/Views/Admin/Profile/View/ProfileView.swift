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
        List {
            // Header: Avatar, Name, Role
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
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .padding(.bottom, 16)
            
            // MARK: Account Section
            Section("ACCOUNT") {
                profileRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: "Personal Information"
                )
                profileRow(
                    icon: "checkmark.shield.fill",
                    iconColor: .green,
                    title: "KYC Status",
                    value: "Verified"
                )
            }
            
            // MARK: Security Section
            Section("SECURITY") {
                profileRow(
                    icon: "lock.fill",
                    iconColor: .gray,
                    title: "Change Password"
                )
                
                HStack(spacing: 12) {
                    iconView(icon: "key.fill", color: .orange)
                    Toggle("Two-Factor\nAuthentication", isOn: $isTwoFactorEnabled)
                        .tint(.green)
                }
                
                HStack(spacing: 12) {
                    iconView(icon: "faceid", color: .indigo)
                    Toggle("Biometric Login", isOn: $isBiometricEnabled)
                        .tint(.green)
                }
            }
            
            // MARK: Preferences Section
            Section("PREFERENCES") {
                profileRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Notification Settings"
                )
                profileRow(
                    icon: "globe",
                    iconColor: .teal,
                    title: "Language",
                    value: "English"
                )
            }
            
            // MARK: Footer Section
            Section {
                profileRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .gray,
                    title: "Support"
                )
                
                HStack(spacing: 12) {
                    iconView(icon: "rectangle.portrait.and.arrow.right.fill", color: .red.opacity(0.2), foregroundColor: .red)
                    Text("Sign Out")
                        .foregroundStyle(.red)
                    Spacer()
                }
            } footer: {
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
        .listStyle(.insetGrouped)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
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
