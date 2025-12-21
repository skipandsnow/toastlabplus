"""
Configuration settings for Toastlabplus Chat Backend.
All settings can be overridden via environment variables.
"""
import os

# GCP Settings
GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID", "toastlabplus")

# Gemini API Settings
GEMINI_MODEL_NAME = os.getenv("GEMINI_MODEL_NAME", "gemini-3-flash-preview")
GEMINI_SECRET_NAME = os.getenv("GEMINI_SECRET_NAME", "GEMINI_API_KEY")

# Server Settings
SERVER_HOST = os.getenv("SERVER_HOST", "0.0.0.0")
SERVER_PORT = int(os.getenv("SERVER_PORT", "8000"))

# CORS Settings
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")

# System Prompt for Toastmasters Assistant
SYSTEM_PROMPT = os.getenv("SYSTEM_PROMPT", """You are a helpful Toastmasters meeting assistant. 
You help with:
- Understanding meeting roles (TME, Timer, Ah-Counter, Grammarian, etc.)
- Creating and managing meeting agendas
- Providing tips for speakers and evaluators
- Answering questions about Toastmasters International
- Helping with meeting scheduling and role assignments

Always be friendly, encouraging, and supportive - just like a good Toastmaster!
Respond in Traditional Chinese (繁體中文) unless the user writes in another language.
""")
