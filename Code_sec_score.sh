#!/bin/bash
#!/bin/bash
# ------------------------------------------------------------------------------
# Script: Code_sec_score.sh
# Author& Owner : Rajesh Kaushal
# Description: This script automates the process of code review, documentation,
#              and security analysis for changed files in a Git repository.
#              It uses the Ollama LLM model for generating insights and ratings.
# ------------------------------------------------------------------------------
set -e

REPO_URL="https://github.com/Kaushal604/jpetstore-64.git"
REPO_DIR="jpetstore-64"
OLLAMA_API="http://10.83.120.21:11434/api/generate" 
MODEL="codellama"
REVIEW_OUTPUT="ai_review_results.txt"
DOCS_OUTPUT="ai_docs_results.txt"
SECURITY_OUTPUT="ai_security_results.txt" 

# Cleanup
rm -rf "$REPO_DIR" "$REVIEW_OUTPUT" "$DOCS_OUTPUT" "$SECURITY_OUTPUT" changed_files.txt

echo "[+] Cloning repo..."
git clone "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR"

if git rev-parse HEAD~1 >/dev/null 2>&1; then
  PREV_COMMIT="HEAD~1"
else
  PREV_COMMIT="HEAD"
fi

echo "[+] Getting changed files between $PREV_COMMIT and HEAD..."
git diff --name-only "$PREV_COMMIT" HEAD > ../changed_files.txt
cd ..

# Security rating function
get_security_rating() {
    local security_analysis="$1"
    if echo "$security_analysis" | grep -iqE 'SQL injection|remote code execution|buffer overflow'; then
        echo "High"
    elif echo "$security_analysis" | grep -iqE 'XSS|CSRF|Insecure deserialization'; then
        echo "Moderate"
    else
        echo "Low"
    fi
}

# Process files
while read -r file; do
  FILEPATH="$REPO_DIR/$file"
  if [ -f "$FILEPATH" ]; then
    echo "[+] Processing: $file"

    CODE_SNIPPET=$(sed ':a;N;$!ba;s/"/\\"/g' "$FILEPATH")

    # === CODE REVIEW ===
    REVIEW_PROMPT="Review this code and provide suggestions for improvement (bugs, clarity, formatting, etc.):\n$CODE_SNIPPET"
    REVIEW_PAYLOAD=$(jq -n \
      --arg model "$MODEL" \
      --arg prompt "$REVIEW_PROMPT" \
      '{model: $model, prompt: $prompt, stream: false}')

    REVIEW_RESPONSE=$(curl -s -X POST "$OLLAMA_API" \
      -H "Content-Type: application/json" \
      -d "$REVIEW_PAYLOAD")

    echo "[DEBUG] Review response:"
    echo "$REVIEW_RESPONSE"

    REVIEW_TEXT=$(echo "$REVIEW_RESPONSE" | jq -r '.response // empty')

    if [ -n "$REVIEW_TEXT" ]; then
      echo "===== Review for $file =====" >> "$REVIEW_OUTPUT"
      echo "$REVIEW_TEXT" >> "$REVIEW_OUTPUT"
      echo -e "\n-------------------------------\n" >> "$REVIEW_OUTPUT"
    else
      echo "[WARN] No review text returned for $file"
    fi

    # =================================== CODE DOCS ==================================================
    DOC_PROMPT="Summarize this code and explain what it does (inputs, outputs, logic):\n$CODE_SNIPPET"
    DOC_PAYLOAD=$(jq -n \
      --arg model "$MODEL" \
      --arg prompt "$DOC_PROMPT" \
      '{model: $model, prompt: $prompt, stream: false}')

    DOC_RESPONSE=$(curl -s -X POST "$OLLAMA_API" \
      -H "Content-Type: application/json" \
      -d "$DOC_PAYLOAD")

    echo "[DEBUG] Doc response:"
    echo "$DOC_RESPONSE"

    DOC_TEXT=$(echo "$DOC_RESPONSE" | jq -r '.response // empty')

    if [ -n "$DOC_TEXT" ]; then
      echo "===== Documentation for $file =====" >> "$DOCS_OUTPUT"
      echo "$DOC_TEXT" >> "$DOCS_OUTPUT"
      echo -e "\n-------------------------------\n" >> "$DOCS_OUTPUT"
    else
      echo "[WARN] No documentation returned for $file"
    fi

    # === SECURITY ANALYSIS ===
    SECURITY_PROMPT="Analyze this code for potential security vulnerabilities, such as SQL injections, XSS, hardcoded secrets, or other unsafe practices:\n$CODE_SNIPPET"
    SECURITY_PAYLOAD=$(jq -n \
      --arg model "$MODEL" \
      --arg prompt "$SECURITY_PROMPT" \
      '{model: $model, prompt: $prompt, stream: false}')

    SECURITY_RESPONSE=$(curl -s -X POST "$OLLAMA_API" \
      -H "Content-Type: application/json" \
      -d "$SECURITY_PAYLOAD")

    echo "[DEBUG] Security response:"
    echo "$SECURITY_RESPONSE"

    SECURITY_TEXT=$(echo "$SECURITY_RESPONSE" | jq -r '.response // empty')

    if [ -n "$SECURITY_TEXT" ]; then
      # Get the security rating based on the analysis
      SECURITY_RATING=$(get_security_rating "$SECURITY_TEXT")

      echo "===== Security Analysis for $file =====" >> "$SECURITY_OUTPUT"
      echo "Security Rating: $SECURITY_RATING" >> "$SECURITY_OUTPUT"
      echo "$SECURITY_TEXT" >> "$SECURITY_OUTPUT"
      echo -e "\n-------------------------------\n" >> "$SECURITY_OUTPUT"
    else
      echo "[WARN] No security analysis returned for $file"
    fi
  else
    echo "[!] File not found: $file"
  fi
done < changed_files.txt

echo "Review results: $REVIEW_OUTPUT"
echo "Docs results:   $DOCS_OUTPUT"
echo "Security results: $SECURITY_OUTPUT"
