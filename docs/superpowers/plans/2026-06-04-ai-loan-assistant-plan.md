# AI Loan Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a conversational AI assistant using Gemini to recommend loans to borrowers.

**Architecture:** A stateless NestJS backend endpoint that fetches borrower and loan context, crafts a system prompt, and calls Gemini. An iOS SwiftUI modal chat interface that manages state and talks to this endpoint.

**Tech Stack:** NestJS, `@google/genai` SDK, iOS SwiftUI.

---

### Task 1: Setup Backend AI Module (NestJS)

**Files:**
- Create: `lms-backend-new-reference/src/modules/ai/ai.module.ts`
- Create: `lms-backend-new-reference/src/modules/ai/ai.service.ts`
- Create: `lms-backend-new-reference/src/modules/ai/ai.controller.ts`
- Modify: `lms-backend-new-reference/src/app.module.ts`

- [ ] **Step 1: Install GenAI SDK**

Run: `cd lms-backend-new-reference && npm install @google/genai`
Expected: Installs successfully and adds to `package.json`.

- [ ] **Step 2: Create AI Module**

Create `lms-backend-new-reference/src/modules/ai/ai.module.ts`:
```typescript
import { Module } from '@nestjs/common';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { LoansModule } from '../loans/loans.module';

@Module({
  imports: [LoansModule],
  controllers: [AiController],
  providers: [AiService],
})
export class AiModule {}
```

- [ ] **Step 3: Register in AppModule**

Modify `lms-backend-new-reference/src/app.module.ts` to import `AiModule`:
```typescript
import { Module } from '@nestjs/common';
import { AiModule } from './modules/ai/ai.module';
// Add AiModule to the imports array of the @Module decorator
```

- [ ] **Step 4: Commit**

```bash
git add lms-backend-new-reference/package.json lms-backend-new-reference/package-lock.json lms-backend-new-reference/src/modules/ai/ai.module.ts lms-backend-new-reference/src/app.module.ts
git commit -m "feat(ai): setup ai module and dependencies"
```

### Task 2: AI Controller and Service (NestJS)

**Files:**
- Modify: `lms-backend-new-reference/src/modules/ai/ai.service.ts`
- Modify: `lms-backend-new-reference/src/modules/ai/ai.controller.ts`

- [ ] **Step 1: Implement AI Service**

Create `lms-backend-new-reference/src/modules/ai/ai.service.ts`:
```typescript
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { GoogleGenAI } from '@google/genai';
import { LoansService } from '../loans/loans.service';

@Injectable()
export class AiService {
  private ai: GoogleGenAI;

  constructor(private loansService: LoansService) {
    this.ai = new GoogleGenAI({}); // Automatically picks up GOOGLE_API_KEY
  }

  async chat(borrowerId: string, chatHistory: any[]) {
    try {
      // Mock borrower profile for now, integrate actual user lookup later
      const borrowerProfile = { creditScore: 720, income: 60000 };
      
      const systemInstruction = `You are a helpful loan advisor for our LMS platform.
      The borrower's profile is: ${JSON.stringify(borrowerProfile)}.
      Available loan products are: [Personal Loan (10% APR), Auto Loan (5% APR)].
      Only recommend these products. Be concise.`;

      const contents = chatHistory.map(msg => ({
        role: msg.role,
        parts: [{ text: msg.text }]
      }));

      const response = await this.ai.models.generateContent({
        model: 'gemini-3.5-flash',
        contents: contents,
        config: { systemInstruction }
      });

      return { role: 'model', text: response.text };
    } catch (error) {
      throw new InternalServerErrorException('AI Service unavailable');
    }
  }
}
```

- [ ] **Step 2: Implement AI Controller**

Create `lms-backend-new-reference/src/modules/ai/ai.controller.ts`:
```typescript
import { Controller, Post, Body } from '@nestjs/common';
import { AiService } from './ai.service';

@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('chat')
  async chat(@Body() body: { borrowerId: string; chatHistory: any[] }) {
    return this.aiService.chat(body.borrowerId, body.chatHistory);
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lms-backend-new-reference/src/modules/ai/ai.service.ts lms-backend-new-reference/src/modules/ai/ai.controller.ts
git commit -m "feat(ai): implement gemini chat service and endpoint"
```

### Task 3: iOS LoanAssistantViewModel (SwiftUI)

**Files:**
- Create: `BorrowerApp/ViewModels/LoanAssistantViewModel.swift`

- [ ] **Step 1: Create ViewModel**

Create `BorrowerApp/ViewModels/LoanAssistantViewModel.swift`:
```swift
import Foundation

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let role: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case role, text
    }
}

class LoanAssistantViewModel: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""
    
    func sendMessage(borrowerId: String) {
        let userMessage = ChatMessage(role: "user", text: inputText)
        chatHistory.append(userMessage)
        inputText = ""
        isLoading = true
        
        let payload: [String: Any] = [
            "borrowerId": borrowerId,
            "chatHistory": chatHistory.map { ["role": $0.role, "text": $0.text] }
        ]
        
        guard let url = URL(string: "http://localhost:3000/ai/chat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data, let aiMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                    self.chatHistory.append(aiMessage)
                } else {
                    self.chatHistory.append(ChatMessage(role: "model", text: "Unable to reach the assistant right now. Please try again."))
                }
            }
        }.resume()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add BorrowerApp/ViewModels/LoanAssistantViewModel.swift
git commit -m "feat(ios): add LoanAssistantViewModel for API integration"
```

### Task 4: iOS LoanAssistantView (SwiftUI)

**Files:**
- Create: `BorrowerApp/Views/LoanAssistantView.swift`

- [ ] **Step 1: Create View**

Create `BorrowerApp/Views/LoanAssistantView.swift`:
```swift
import SwiftUI

struct LoanAssistantView: View {
    @StateObject private var viewModel = LoanAssistantViewModel()
    let borrowerId: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ForEach(viewModel.chatHistory) { message in
                        HStack {
                            if message.role == "user" { Spacer() }
                            Text(message.text)
                                .padding()
                                .background(message.role == "user" ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(message.role == "user" ? .white : .black)
                                .cornerRadius(10)
                            if message.role == "model" { Spacer() }
                        }.padding(.horizontal)
                    }
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Spacer()
                        }.padding()
                    }
                }
                
                HStack {
                    TextField("Ask about loans...", text: $viewModel.inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Send") {
                        viewModel.sendMessage(borrowerId: borrowerId)
                    }.disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                }.padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add BorrowerApp/Views/LoanAssistantView.swift
git commit -m "feat(ios): add LoanAssistantView chat interface"
```

### Task 5: Integrate Assistant in NewLoanApplicationView

**Files:**
- Modify: `BorrowerApp/Views/NewLoanApplicationView.swift`

- [ ] **Step 1: Add state and button**

Modify `BorrowerApp/Views/NewLoanApplicationView.swift`.
Add state inside the struct:
```swift
@State private var showAssistant = false
```

Find the `.toolbar` or add one to the main view body, next to the comparison view button:
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { showAssistant = true }) {
            Image(systemName: "sparkles")
        }
    }
}
.sheet(isPresented: $showAssistant) {
    LoanAssistantView(borrowerId: "current-user-id")
}
```

- [ ] **Step 2: Commit**

```bash
git add BorrowerApp/Views/NewLoanApplicationView.swift
git commit -m "feat(ios): add AI Assistant trigger to NewLoanApplicationView"
```
