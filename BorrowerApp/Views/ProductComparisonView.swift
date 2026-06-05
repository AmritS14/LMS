import SwiftUI

struct ProductComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    
    /// List of available loan products to compare
    let products: [LoanProduct]
    
    /// The currently selected product in the main application view (optional, for visual state)
    let selectedProductID: UUID?
    
    /// Callback triggered when the borrower selects a product
    let onSelect: (LoanProduct) -> Void
    
    // Benchmark configuration for normalized comparisons
    private let benchmarkPrincipal: Decimal = 100_000
    private let benchmarkTenureMonths = 12

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Banner
                headerBanner
                
                if products.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: Spacing.m) {
                            explanationCard
                            
                            // Comparison Grid Area
                            HStack(alignment: .top, spacing: 0) {
                                // Fixed Left Column for Row Labels
                                criteriaLabelColumn
                                    .padding(.top, 130) // Offset to align with product rows (under the headers)
                                
                                Divider()
                                    .padding(.vertical, Spacing.s)
                                
                                // Scrollable Columns for Products
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Spacing.m) {
                                        ForEach(products) { product in
                                            productColumn(product: product)
                                                .frame(width: 170)
                                        }
                                    }
                                    .padding(.horizontal, Spacing.m)
                                }
                            }
                            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
                            .padding(.horizontal, Spacing.m)
                        }
                        .padding(.vertical, Spacing.m)
                    }
                }
            }
            .background(Color.lmsBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Compare Products")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subviews
    
    private var headerBanner: some View {
        VStack(spacing: Spacing.xs) {
            Text("Find Your Perfect Fit")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Compare rates, limits, tenures, and normalized EMIs side-by-side.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Color.lmsSurface)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView(
            "No Products to Compare",
            systemImage: "square.grid.3x1.folder.badge.plus",
            description: Text("Could not load any loan products for comparison.")
        )
        .frame(maxHeight: .infinity)
    }
    
    private var explanationCard: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Benchmark EMI Comparison")
                    .font(.caption.weight(.semibold))
                Text("Benchmark EMIs are estimated based on a standardized amount of ₹1,00,000 for 12 months using the product's midpoint interest rate.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.m)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.m)
    }
    
    // MARK: - Row Title / Criteria Column (Fixed Left)
    private var criteriaLabelColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            criteriaRowLabel("Interest Rate", height: 60)
            Divider()
            criteriaRowLabel("Amount Limit", height: 60)
            Divider()
            criteriaRowLabel("Tenure Range", height: 60)
            Divider()
            criteriaRowLabel("Benchmark EMI", height: 80)
            Divider()
            criteriaRowLabel("Best For", height: 110)
            Divider()
            criteriaRowLabel("Action", height: 60)
        }
        .frame(width: 105)
    }
    
    private func criteriaRowLabel(_ text: String, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text(text)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(height: height, alignment: .leading)
        .padding(.leading, Spacing.sm)
    }
    
    // MARK: - Product Column (Scrollable Right)
    @ViewBuilder
    private func productColumn(product: LoanProduct) -> some View {
        let isCurrent = selectedProductID == product.id
        let emiResult = EMICalculator.calculate(
            principal: benchmarkPrincipal,
            annualInterestRate: product.displayRate,
            tenureMonths: benchmarkTenureMonths
        )
        
        VStack(spacing: 0) {
            // Product Header Cell (Height: 130)
            productHeaderCell(product: product, isCurrent: isCurrent)
                .frame(height: 130)
            
            // Criteria Cells
            
            // 1. Interest Rate Range (Height: 60)
            VStack(spacing: Spacing.xxs) {
                Spacer()
                Text(String(format: "%.1f%% – %.1f%%", product.minimumInterestRate, product.maximumInterestRate))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Reducing p.a.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(height: 60)
            
            Divider()
            
            // 2. Amount Range (Height: 60)
            VStack(spacing: Spacing.xxs) {
                Spacer()
                Text("\(shortAmount(NSDecimalNumber(decimal: product.minimumAmount).doubleValue)) – \(shortAmount(NSDecimalNumber(decimal: product.maximumAmount).doubleValue))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Sanction Limit")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(height: 60)
            
            Divider()
            
            // 3. Tenure Range (Height: 60)
            VStack(spacing: Spacing.xxs) {
                Spacer()
                Text("\(product.minimumTenureMonths) mo – \(product.maximumTenureMonths) mo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(formatTenureYears(product.minimumTenureMonths)) – \(formatTenureYears(product.maximumTenureMonths)) approx.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(height: 60)
            
            Divider()
            
            // 4. Benchmark EMI (Height: 80)
            VStack(spacing: Spacing.xxs) {
                Spacer()
                Text(Formatting.currency(emiResult.monthlyInstallment))
                    .font(.body.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                Text("₹1L for 12mo")
                    .font(.system(size: 9).weight(.medium))
                    .foregroundStyle(.secondary)
                Text("@ \(String(format: "%.1f%%", product.displayRate)) avg rate")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(height: 80)
            
            Divider()
            
            // 5. Best For / Description (Height: 110)
            VStack(spacing: Spacing.xxs) {
                Spacer()
                Text(getBestForText(for: product.loanType))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, Spacing.xs)
                Spacer()
            }
            .frame(height: 110)
            
            Divider()
            
            // 6. Action Button (Height: 60)
            VStack(spacing: 0) {
                Spacer()
                if isCurrent {
                    Text("Selected")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.sm)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                } else {
                    Button {
                        onSelect(product)
                        dismiss()
                    } label: {
                        Text("Apply")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, Spacing.xs + 2)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(height: 60)
        }
    }
    
    @ViewBuilder
    private func productHeaderCell(product: LoanProduct, isCurrent: Bool) -> some View {
        VStack(spacing: Spacing.s) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.accentColor : Color.lmsFill)
                    .frame(width: 44, height: 44)
                Image(systemName: product.icon)
                    .font(.body)
                    .foregroundStyle(isCurrent ? .white : .secondary)
            }
            
            VStack(spacing: 2) {
                Text(product.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                if isCurrent {
                    Text("Current choice")
                        .font(.system(size: 9).weight(.bold))
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text("Sanctionable")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.xs)
        .background(isCurrent ? Color.accentColor.opacity(0.04) : Color.clear)
    }

    // MARK: - Helpers
    
    private func shortAmount(_ value: Double) -> String {
        if value >= 10_000_000 {
            return String(format: "₹%.1fCr", value / 10_000_000)
        } else if value >= 100_000 {
            let lakhs = value / 100_000
            return lakhs.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "₹%.0fL", lakhs)
                : String(format: "₹%.1fL", lakhs)
        } else if value >= 1_000 {
            return String(format: "₹%.0fK", value / 1_000)
        }
        return "₹\(Int(value))"
    }
    
    private func formatTenureYears(_ months: Int) -> String {
        let years = Double(months) / 12.0
        if years == years.rounded() {
            return "\(Int(years)) yr"
        } else {
            return String(format: "%.1f yr", years)
        }
    }
    
    private func getBestForText(for type: LoanType) -> String {
        switch type {
        case .home:
            return "Buying apartments, villas, builder floors, constructing houses or buying residential plots."
        case .personal:
            return "Medical emergencies, home improvements, vacations, weddings, or any urgent personal needs."
        case .vehicle:
            return "Buying new or pre-owned cars, SUVs, sedans, or standard premium two-wheelers."
        case .education:
            return "Financing higher education in India or abroad, tuition fees, and university charges."
        case .business:
            return "Expanding operational capital, purchasing inventory, machinery, or general enterprise growth."
        }
    }
}

#Preview {
    ProductComparisonView(
        products: [
            LoanProduct(name: "Home Loan", minimumAmount: 500_000, maximumAmount: 50_000_000, minimumTenureMonths: 60, maximumTenureMonths: 360, minimumInterestRate: 6, maximumInterestRate: 12),
            LoanProduct(name: "Personal Loan", minimumAmount: 10_000, maximumAmount: 1_000_000, minimumTenureMonths: 6, maximumTenureMonths: 60, minimumInterestRate: 10, maximumInterestRate: 24),
            LoanProduct(name: "Vehicle Loan", minimumAmount: 50_000, maximumAmount: 5_000_000, minimumTenureMonths: 12, maximumTenureMonths: 84, minimumInterestRate: 7, maximumInterestRate: 15)
        ],
        selectedProductID: nil,
        onSelect: { _ in }
    )
}
