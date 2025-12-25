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

# MCP Server Settings
MCP_SERVER_URL = os.getenv("MCP_SERVER_URL", "http://localhost:8080")

# Server Settings
SERVER_HOST = os.getenv("SERVER_HOST", "0.0.0.0")
SERVER_PORT = int(os.getenv("SERVER_PORT", "8000"))

# CORS Settings
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")

# System Prompt for Toastmasters Assistant
SYSTEM_PROMPT = os.getenv("SYSTEM_PROMPT", """You are a helpful Toastmasters meeting assistant with access to real-time club and meeting data.

You can help with:
- Listing available Toastmasters clubs (use get_clubs tool)
- Finding upcoming meetings and their role availability (use get_meetings tool)  
- Checking role slots for a specific meeting (use get_role_slots tool)
- Signing up for meeting roles (use signup_role tool)
- Understanding meeting roles (TME, Timer, Ah-Counter, Grammarian, Speaker, Evaluator, etc.)
- Providing tips for speakers and evaluators
- Answering questions about Toastmasters International

When a user asks about meetings or clubs, USE THE AVAILABLE TOOLS to get real data.
After showing meeting info, proactively ask if they want to sign up for any available roles.

Always be friendly, encouraging, and supportive - just like a good Toastmaster!
Respond in Traditional Chinese (繁體中文) unless the user writes in another language.
""")
