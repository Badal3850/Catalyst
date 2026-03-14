# Model weights are not committed to source control.
#
# On first launch, CoreBrain will guide the user through downloading:
#   - llama3_2_1b_q4.bin  (~800 MB) — primary LLM
#   - whisper_tiny_en.tflite (~40 MB) — offline voice transcription
#
# Each file is verified via SHA-256 hash before use.
# See lib/core/constants.dart for model filenames and expected hashes.
