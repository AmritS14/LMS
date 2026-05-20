import SwiftUI

struct LOApplicationDetailView: View {
    @State private var selectedTab = 0
    @State private var showSuccess = false
    @State private var showClarification = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Profile
            HStack(spacing: Spacing.m) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Jane Doe")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("App ID: #APP-991")
                        .font(.lmsCaption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Credit Score Gauge
                VStack {
                    Gauge(value: 750, in: 300...900) {
                        Text("Score")
                    } currentValueLabel: {
                        Text("750")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(.lmsSuccess)
                    
                    Text("Excellent")
                        .font(.caption2)
                        .foregroundColor(.lmsSuccess)
                }
            }
            .padding()
            .background(Color.lmsNavyBlue.opacity(0.05))
            
            // Custom Tabs
            HStack {
                TabButton(title: "Overview", index: 0, selectedIndex: $selectedTab)
                TabButton(title: "Documents", index: 1, selectedIndex: $selectedTab)
                TabButton(title: "Action", index: 2, selectedIndex: $selectedTab)
            }
            .padding(.horizontal)
            .padding(.top, Spacing.s)
            
            Divider()
            
            // Tab Content
            TabView(selection: $selectedTab) {
                OverviewTab()
                    .tag(0)
                
                DocumentsTab(showClarification: $showClarification)
                    .tag(1)
                
                ActionTab(showSuccess: $showSuccess)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Application Detail")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showSuccess) {
            LOSuccessConfirmationView()
        }
        .sheet(isPresented: $showClarification) {
            LOClarificationRequestView()
        }
    }
}

struct TabButton: View {
    let title: String
    let index: Int
    @Binding var selectedIndex: Int
    
    var body: some View {
        Button {
            withAnimation { selectedIndex = index }
        } label: {
            VStack {
                Text(title)
                    .font(.lmsHeadline)
                    .foregroundColor(selectedIndex == index ? .lmsNavyBlue : .secondary)
                
                Rectangle()
                    .fill(selectedIndex == index ? Color.lmsNavyBlue : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("Financial Summary")
                    .font(.lmsTitle2)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.m) {
                    SummaryGridItem(title: "Requested Amount", value: "$350,000")
                    SummaryGridItem(title: "Tenure", value: "30 Years")
                    SummaryGridItem(title: "Monthly Income", value: "$8,500")
                    SummaryGridItem(title: "DTI Ratio", value: "32%", isWarning: false)
                }
                .padding(.horizontal)
                
                SectionCard(title: "Loan Details") {
                    LabeledContent("Purpose", value: "Home Purchase")
                    LabeledContent("Interest Rate", value: "5.5% Fixed")
                }
                .padding()
            }
            .padding(.vertical)
        }
    }
}

struct SummaryGridItem: View {
    let title: String
    let value: String
    var isWarning: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.lmsCaption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.lmsHeadline)
                .foregroundColor(isWarning ? .lmsWarning : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                .background(Color.lmsSurface)
        )
    }
}

// MARK: - Documents Tab
struct DocumentsTab: View {
    @Binding var showClarification: Bool
    @State private var selectedDocument: String?
    
    let documents = [
        ("Identity Proof (Passport)", true),
        ("Income Statement", false),
        ("Property Details", true)
    ]
    
    var body: some View {
        VStack {
            List {
                ForEach(documents, id: \.0) { doc in
                    Button {
                        selectedDocument = doc.0
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.lmsNavyBlue)
                            Text(doc.0)
                                .foregroundColor(.primary)
                            Spacer()
                            if doc.1 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.lmsSuccess)
                            } else {
                                StatusBadge("Needs Review", tone: .warning)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            
            PrimaryButton("Request Clarifications") {
                showClarification = true
            }
            .padding()
        }
        .sheet(item: $selectedDocument) { doc in
            LODocumentReviewSheet(documentName: doc)
                .presentationDetents([.medium, .large])
        }
    }
}

extension String: Identifiable {
    public var id: String { self }
}

// MARK: - Action Tab
struct ActionTab: View {
    @Binding var showSuccess: Bool
    @State private var remarks = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                SectionCard(title: "Automated Checks") {
                    LabeledContent("Risk Level", value: "Low")
                    LabeledContent("LTV Ratio", value: "80%")
                    LabeledContent("Identity Match", value: "Verified")
                }
                
                VStack(alignment: .leading) {
                    Text("Officer Remarks (Internal)")
                        .font(.lmsHeadline)
                    TextEditor(text: $remarks)
                        .frame(minHeight: 150)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.secondary.opacity(0.3))
                        )
                }
                
                // Extra space to force deliberate scrolling for actions
                Spacer(minLength: 100)
                
                VStack(spacing: Spacing.m) {
                    PrimaryButton("Forward to Manager") {
                        showSuccess = true
                    }
                    
                    Button("Reject Application") {
                        // Handle Rejection
                    }
                    .font(.lmsHeadline)
                    .foregroundColor(.lmsDanger)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.lmsDanger, lineWidth: 1)
                    )
                }
            }
            .padding()
        }
    }
}
