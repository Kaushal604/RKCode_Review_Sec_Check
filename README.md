**Security Code Review and Analysis with Ollama LLM Model**

This solution automates code review and security analysis for software repositories using the Ollama LLM model. The script fetches code from a Git repository, analyzes it for security vulnerabilities, provides suggestions for code improvements, and documents the functionality using Ollama's AI model. The results are categorized into High, Moderate, or Low risk based on security severity.

The script is designed to be executed via the **HCL DevOps Deploy Tool** as part of a CI/CD pipeline.

**Prerequisites**

**HCL DevOps Deploy Tool** (to orchestrate and automate deployment)

**Ollama LLM Model API: A local Ollama API instance running at http://10.83.120.21:11434/.**

**Git: Installed on the agent running the script.**

**jq: Command-line tool for processing JSON (for parsing Ollama API responses).**
===============================================================================================

**The Code_sec_score.sh script performs the following tasks:**

**Clones the repository:** Fetches the Git repository using the specified REPO_URL.

**Fetches changed files:** Identifies files that have changed between the latest and previous commit.

**Code review:** Sends the code snippets to the Ollama model for review and improvements.

**Documentation:** Asks the model to explain what the code does and generates a summary.

**Security analysis:** Analyzes the code for potential security vulnerabilities (e.g., SQL injection, XSS, hardcoded secrets).

**Security rating:** Classifies the security risks as High, Moderate, or Low based on the severity of the vulnerabilities.

Outputs the results: Stores the review, documentation, and security analysis in separate text files.
