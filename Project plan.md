# Project Documentation: CoreBrain (Local AI Second Brain)

## 1. Vision & Purpose
**CoreBrain** is a mobile application designed to function as an external digital cortex. Unlike cloud-based AI, CoreBrain lives entirely on the user’s hardware. It indexes notes, files, and voice memos to provide semantic retrieval and executes local system actions (calendar, reminders, file management) without ever sending data to the internet.

---

## 2. The Core Architecture
The app follows a **Local-First AI Architecture** consisting of three layers:

### A. The Perception Layer (MediaPipe Tasks)
*   **Text Inference:** MediaPipe LLM Inference API running **Llama 3.2 (1B)** or **Gemma 2 (2B)**.
*   **Vision:** MediaPipe Object Detector & OCR (Text Recognizer) for scanning physical documents.
*   **Audio:** MediaPipe Audio Classifier + Local Whisper.tflite for voice-to-text journaling.

### B. The Memory Layer (Local RAG)
*   **Embeddings:** Text is converted into vectors using a lightweight local model (e.g., `sentence-transformers`).
*   **Vector Database:** **sqlite-vec** (SQLite extension) or **ObjectBox** stored on the phone’s internal storage.
*   **Indexing:** Every note or PDF added is automatically chunked, embedded, and indexed for semantic search.

### C. The Action Layer (Native Bridge)
*   **Function Calling:** The LLM is prompted to output structured JSON.
*   **Method Channels:** Flutter communicates with Android (Kotlin) and iOS (Swift) APIs to trigger system-level events.

---

## 3. Key Productive Features

### 🧠 Semantic Recall (The "Brain" Part)
*   **Natural Language Query:** Instead of searching for keywords, ask: *"What was that idea I had about the marketing plan while I was at the cafe?"*
*   **Automatic Linking:** The app detects overlaps between new notes and old documents, suggesting "Related Thoughts" in a side panel.

### ⚡ Agentic Actions (The "Action" Part)
*   **Auto-Tasking:** If you write *"Need to follow up with Sarah tomorrow at 10 AM,"* the LLM extracts the intent and offers a "Create Calendar Event" button.
*   **Smart Filing:** Capture a photo of a receipt; the AI reads it, categorizes it as "Expenses," and saves the extracted data to a local CSV/Database.

### 🎙️ Contextual Voice Journaling
*   Record high-fidelity voice notes offline. The app transcribes them and summarizes them into bullet points immediately.

---

## 4. Technical Stack Detail

| Component | Technology | Implementation Detail |
| :--- | :--- | :--- |
| **UI Framework** | **Flutter** | For cross-platform high-performance UI. |
| **AI Logic** | **MediaPipe LLM Inference API** | Handles the `.bin` or `.tflite` model execution on GPU. |
| **Model** | **Llama 3.2 1B (Quantized)** | 4-bit quantization to fit within ~1.2GB RAM. |
| **Local Storage** | **SQLite + FTS5** | For traditional text search and metadata. |
| **Vector Search** | **ObjectBox Vector DB** | High-speed local vector storage for Flutter. |
| **File Handling** | **Markdown (.md)** | All notes are saved as local files so users can export them. |

---

## 5. Development Roadmap

### Phase 1: The "Quiet" Brain (Foundations)
1.  Integrate **MediaPipe LLM Inference** into a Flutter project.
2.  Implement a local chat interface.
3.  Benchmark performance (Tokens per second) on target devices (e.g., Pixel 7, iPhone 13).

### Phase 2: The "Total Recall" (Memory)
1.  Implement a background worker that scans a "Documents" folder.
2.  Integrate **ObjectBox** for vector embeddings.
3.  Create the RAG pipeline: User Query -> Vector Search -> LLM Context -> Answer.

### Phase 3: The "Active" Brain (Agents)
1.  Develop the **System Prompt** for Tool Use.
2.  Build Flutter Method Channels for:
    *   `android.permission.WRITE_CALENDAR`
    *   `android.permission.RECEIVE_BOOT_COMPLETED` (for reminders)
3.  Implement a UI "Confirmation Toast" before the AI performs any action.

### Phase 4: Multi-Modal (Vision/Audio)
1.  Integrate MediaPipe OCR for image-to-note conversion.
2.  Integrate Whisper.tflite for offline voice transcription.

---

## 6. Privacy & Security Protocol
*   **Zero-Internet Policy:** The app’s `AndroidManifest` and `Info.plist` will not request INTERNET permissions unless strictly required for (optional) cloud backup.
*   **On-Device Encryption:** Use **SQLCipher** to encrypt the local database so even if the phone is stolen, the "Brain" remains locked.
*   **Model Weights:** The LLM models are downloaded once during setup and verified via hash.

---

## 7. Hardware Requirements
*   **Android:** Minimum 6GB RAM (8GB recommended), Android 11+, Snapdragon 8 Gen 1 or better.
*   **iOS:** iPhone 13 Pro or newer (due to RAM requirements of LLMs).
*   **Storage:** ~2GB for the app and model weights + storage for user notes.

---
