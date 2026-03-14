# CoreBrain — Local AI Second Brain

> **Your private, offline AI assistant.** CoreBrain lives entirely on your device—no internet, no cloud, no data leaks.

---

## 1. Vision & Purpose

**CoreBrain** is a mobile application designed to function as an external digital cortex. Unlike cloud-based AI, CoreBrain lives entirely on the user's hardware. It indexes notes, files, and voice memos to provide semantic retrieval and executes local system actions (calendar, reminders, file management) without ever sending data to the internet.

---

## 2. The Core Architecture

The app follows a **Local-First AI Architecture** consisting of three layers:

### A. The Perception Layer (MediaPipe Tasks)
- **Text Inference:** MediaPipe LLM Inference API running **Llama 3.2 (1B)** or **Gemma 2 (2B)**.
- **Vision:** MediaPipe Object Detector & OCR (Text Recognizer) for scanning physical documents.
- **Audio:** MediaPipe Audio Classifier + Local Whisper.tflite for voice-to-text journaling.

### B. The Memory Layer (Local RAG)
- **Embeddings:** Text is converted into vectors using a lightweight local model (e.g., `sentence-transformers`).
- **Vector Database:** **sqlite-vec** (SQLite extension) or **ObjectBox** stored on the phone's internal storage.
- **Indexing:** Every note or PDF added is automatically chunked, embedded, and indexed for semantic search.

### C. The Action Layer (Native Bridge)
- **Function Calling:** The LLM is prompted to output structured JSON.
- **Method Channels:** Flutter communicates with Android (Kotlin) and iOS (Swift) APIs to trigger system-level events.

---

## 3. Key Features

### 🧠 Semantic Recall (The "Brain" Part)
- **Natural Language Query:** Ask in plain language; the RAG pipeline retrieves semantically related notes and answers using the local LLM.
- **Automatic Linking:** The app detects overlaps between new notes and old documents, suggesting "Related Thoughts" in a side panel.

### ⚡ Agentic Actions (The "Action" Part)
- **Auto-Tasking:** Write *"Need to follow up with Sarah tomorrow at 10 AM"* and the LLM offers a "Create Calendar Event" button.
- **Smart Filing:** Photograph a receipt; AI reads it, categorises it as "Expenses", and saves extracted data to a local CSV/Database.

### 🎙️ Contextual Voice Journaling
- Record offline voice notes. The app transcribes them via Whisper.tflite and summarises them into bullet points.

---

## 4. Technical Stack

| Component | Technology | Detail |
|:---|:---|:---|
| **UI Framework** | Flutter | Cross-platform high-performance UI |
| **AI Logic** | MediaPipe LLM Inference API | On-device GPU model execution |
| **Model** | Llama 3.2 1B (4-bit quantised) | ~1.2 GB RAM footprint |
| **Local Storage** | SQLite + FTS5 | Text search & metadata |
| **Vector Search** | ObjectBox Vector DB | High-speed local vector storage |
| **File Handling** | Markdown (.md) | Portable, exportable notes |
| **Encryption** | SQLCipher | On-device database encryption |

---

## 5. Development Roadmap

### Phase 1 — The "Quiet" Brain (Foundations)
1. Integrate MediaPipe LLM Inference into Flutter.
2. Implement a local chat interface.
3. Benchmark performance (tokens/sec) on Pixel 7 and iPhone 13.

### Phase 2 — The "Total Recall" (Memory)
1. Background worker that scans a "Documents" folder.
2. Integrate ObjectBox for vector embeddings.
3. RAG pipeline: `User Query → Vector Search → LLM Context → Answer`.

### Phase 3 — The "Active" Brain (Agents)
1. Design the system prompt for Tool Use.
2. Flutter Method Channels for `WRITE_CALENDAR` and `RECEIVE_BOOT_COMPLETED`.
3. UI "Confirmation Toast" before the AI performs any action.

### Phase 4 — Multi-Modal (Vision/Audio)
1. MediaPipe OCR for image-to-note conversion.
2. Whisper.tflite for offline voice transcription.

---

## 6. Privacy & Security

- **Zero-Internet Policy:** `AndroidManifest.xml` and `Info.plist` do not request INTERNET permission.
- **On-Device Encryption:** SQLCipher encrypts the database so stolen devices cannot read the "Brain".
- **Model Integrity:** LLM weights are downloaded once during setup and verified via SHA-256 hash.

---

## 7. Hardware Requirements

| Platform | Minimum | Recommended |
|:---|:---|:---|
| **Android** | 6 GB RAM, Android 11+, Snapdragon 8 Gen 1 | 8 GB RAM |
| **iOS** | iPhone 13 Pro | iPhone 15 Pro |
| **Storage** | 2 GB (app + model weights) + user data | 4 GB+ |

---

## 8. Getting Started

```bash
# Clone the repository
git clone https://github.com/Badal3850/Catalyst.git
cd Catalyst

# Install Flutter dependencies
flutter pub get

# Run on a connected device (Android/iOS)
flutter run

# Run tests
flutter test
```

> **Model Setup:** On first launch CoreBrain will prompt you to download the quantised Llama 3.2 1B model (~800 MB). The model is stored in the app's private storage directory and verified by SHA-256 hash before use.

---

## 9. Project Structure

```
lib/
├── main.dart                  # App entry point
├── app.dart                   # MaterialApp + routing
├── core/
│   ├── constants.dart         # App-wide constants & config
│   └── theme.dart             # Light/dark theme definitions
├── features/
│   ├── chat/                  # AI chat interface
│   ├── notes/                 # Note-taking & semantic search
│   └── voice/                 # Voice journaling & transcription
├── services/
│   ├── ai/                    # LLM, embedding & RAG pipeline
│   ├── storage/               # SQLite + vector store
│   └── actions/               # Calendar & file-system bridge
└── widgets/                   # Shared UI components
```

---

## 10. Contributing

Contributions are welcome! Please open an issue first to discuss what you would like to change. All AI processing must remain fully on-device; PRs that introduce remote API calls will not be merged.

---

*CoreBrain — Think privately.*