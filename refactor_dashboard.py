import re

with open("StaffApp/Views/Manager/ManagerPortfolioView.swift", "r") as f:
    content = f.read()

# Replace ScrollView + VStack with List
content = content.replace("ScrollView(showsIndicators: false) {", "List {")
content = content.replace(".padding(.vertical, Spacing.m)", ".listStyle(.insetGrouped)")
content = content.replace(".background(Color.lmsBackground)", "")

# Fix the body VStack issue we introduced earlier (missing opening brace/VStack)
# The current body is:
#     var body: some View {
#         ScrollView(showsIndicators: false) {
#                 greetingSection
# ...
#             .padding(.vertical, Spacing.m)
#         }

# Remove SectionCard usages and replace with Section
content = re.sub(r'SectionCard\(title:\s*"([^"]+)"\)\s*\{', r'Section("\1") {', content)
content = re.sub(r'\}\s*\.padding\(\.horizontal,\s*Spacing\.m\)', '}', content)

# Officer Performance refactor
officer_perf_regex = r'VStack\(alignment:\s*\.leading,\s*spacing:\s*Spacing\.s\)\s*\{\s*SectionHeader\(title:\s*"Officer Performance",[^}]*\}\s*\.padding\(\.horizontal,\s*Spacing\.m\)'
content = re.sub(officer_perf_regex, 'Section("Officer Performance") {', content)

# Remove the custom background from officer list (it was previously just an inline padding thing)
content = re.sub(r'\.background\(Color\.lmsSurface.*?CornerRadius\.card.*?\)', '', content)
content = re.sub(r'if officer\.id !=\s*.*?Divider\(\).*?\}', '', content, flags=re.DOTALL)

# Branch performance refactor
branch_perf_regex = r'VStack\(alignment:\s*\.leading,\s*spacing:\s*Spacing\.s\)\s*\{\s*SectionHeader\(title:\s*"Branch Performance",[^}]*\}\s*\.padding\(\.horizontal,\s*Spacing\.m\)'
content = re.sub(branch_perf_regex, 'Section("Branch Performance") {', content)

with open("StaffApp/Views/Manager/ManagerPortfolioView.swift", "w") as f:
    f.write(content)
