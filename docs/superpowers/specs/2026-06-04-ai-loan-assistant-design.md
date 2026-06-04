# AI Loan Assistant Feature Specification

## Overview
A conversational AI assistant within the Borrower App that helps users find the most suitable loan product. The assistant acts as a read-only advisor, analyzing the borrower's profile and available loan products to provide personalized recommendations through a chat interface.

## Architecture & Integration

### Backend (NestJS)
1.  **Endpoint**:
    *   `POST /ai/chat`
    *   **Payload**: `borrowerId` (UUID) and `chatHistory` (array of `{ role: "user" | "model", text: string }`).
2.  **Context Gathering**:
    *   Fetch borrower profile data (income, employment status, credit score).
    *   Fetch all active loan products (interest rates, terms, limits).
3.  **Gemini API Integration**:
    *   Uses `@google/genai` SDK with the `gemini-3.5-flash` model.
    *   Constructs a **System Prompt** dynamically injecting the borrower profile and loan products.
    *   Instructs the model to act as a financial advisor, strictly recommending from the provided list.
    *   Initializes the client using the `GOOGLE_API_KEY` (Express Mode) environment variable.

### Frontend (iOS SwiftUI - BorrowerApp)
1.  **Entry Point**:
    *   Located in `NewLoanApplicationView.swift`.
    *   A navigation bar button (e.g., a sparkle icon) placed at the top right, next to the Product Comparison view button.
    *   Tapping the button presents the assistant in a modal bottom sheet (`.sheet(isPresented:)`).
2.  **Chat Interface (`LoanAssistantView.swift`)**:
    *   A scrollable view of chat message bubbles (distinct styles for user vs. assistant).
    *   A bottom text input area with a send button.
    *   A typing/loading indicator when waiting for the backend response.
3.  **State Management (`LoanAssistantViewModel.swift`)**:
    *   Maintains the `chatHistory` state array.
    *   Handles the network call to `POST /ai/chat`.
    *   Updates the UI state during loading and upon receiving the response.

## Error Handling
*   **Backend**: Returns a standard HTTP error response if the Gemini API fails or if database fetching fails.
*   **Frontend**: Displays a graceful "Unable to reach the assistant right now. Please try again." message bubble in the chat UI if the API request fails, keeping the user in the flow without blocking them.
