import os
import asyncio
import subprocess
from typing import Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from dotenv import load_dotenv
import google.generativeai as genai

# Load environment variables
load_dotenv()

# Import configuration
from src.config import (
    GCP_PROJECT_ID,
    GEMINI_MODEL_NAME,
    GEMINI_SECRET_NAME,
    CORS_ORIGINS,
    SYSTEM_PROMPT,
)


def get_secret_from_gcp(secret_id: str) -> str:
    """Fetch secret from Google Cloud Secret Manager using multiple methods."""
    
    # Method 1: Try using gcloud CLI (works in local development)
    try:
        result = subprocess.run(
            f'gcloud secrets versions access latest --secret={secret_id}',
            capture_output=True,
            text=True,
            timeout=30,
            shell=True
        )
        if result.returncode == 0 and result.stdout.strip():
            print(f"✅ Fetched {secret_id} using gcloud CLI")
            return result.stdout.strip()
        else:
            print(f"gcloud CLI returned: {result.stderr}")
    except Exception as e:
        print(f"gcloud CLI method failed: {e}")
    
    # Method 2: Try using Secret Manager SDK (works in Cloud Run)
    try:
        from google.cloud import secretmanager
        
        client = secretmanager.SecretManagerServiceClient()
        name = f"projects/{GCP_PROJECT_ID}/secrets/{secret_id}/versions/latest"
        response = client.access_secret_version(request={"name": name})
        print(f"✅ Fetched {secret_id} using Secret Manager SDK")
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        print(f"Secret Manager SDK method failed: {e}")
    
    # Method 3: Fallback to environment variable
    env_value = os.getenv(secret_id, "")
    if env_value:
        print(f"✅ Using {secret_id} from environment variable")
        return env_value
    
    print(f"⚠️ Failed to fetch {secret_id} from any source")
    return ""


# Configure Gemini API
GEMINI_API_KEY = get_secret_from_gcp(GEMINI_SECRET_NAME)
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    masked_key = GEMINI_API_KEY[:10] + "..." + GEMINI_API_KEY[-4:] if len(GEMINI_API_KEY) > 14 else "***"
    print(f"✅ Gemini API configured with key: {masked_key}")
    print(f"📦 Using model: {GEMINI_MODEL_NAME}")
else:
    print("⚠️ No Gemini API key found")


app = FastAPI(
    title="Toastlabplus Chat Backend",
    description="Chat Backend with Gemini AI integration for Toastmasters meeting assistance",
    version="0.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str
    conversation_history: Optional[list] = None


class ChatResponse(BaseModel):
    response: str
    model: str


@app.get("/")
async def root():
    return {"message": "Toastlabplus Chat Backend", "status": "running"}


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "gemini_configured": bool(GEMINI_API_KEY),
        "model": GEMINI_MODEL_NAME,
        "gcp_project": GCP_PROJECT_ID
    }


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Send a message to Gemini AI and get a response.
    """
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured")

    try:
        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL_NAME,
            system_instruction=SYSTEM_PROMPT
        )

        # Build conversation history if provided
        history = []
        if request.conversation_history:
            for msg in request.conversation_history:
                history.append({
                    "role": msg.get("role", "user"),
                    "parts": [msg.get("content", "")]
                })

        chat_session = model.start_chat(history=history)
        response = chat_session.send_message(request.message)

        return ChatResponse(
            response=response.text,
            model=GEMINI_MODEL_NAME
        )

    except Exception as e:
        import traceback
        error_detail = f"{type(e).__name__}: {str(e)}"
        print(f"Error in chat: {error_detail}")
        raise HTTPException(status_code=500, detail=error_detail)


@app.get("/chat/stream")
async def chat_stream(message: str = Query(..., description="The message to send")):
    """
    Stream a response from Gemini AI using Server-Sent Events (SSE).
    """
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured")

    async def generate():
        try:
            model = genai.GenerativeModel(
                model_name=GEMINI_MODEL_NAME,
                system_instruction=SYSTEM_PROMPT
            )

            response = model.generate_content(
                message,
                stream=True
            )

            for chunk in response:
                if chunk.text:
                    yield f"data: {chunk.text}\n\n"
                    await asyncio.sleep(0.01)

            yield "data: [DONE]\n\n"

        except Exception as e:
            yield f"data: Error: {str(e)}\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        }
    )


@app.post("/tools/generate-agenda")
async def generate_agenda(
    meeting_theme: str = Query("General Meeting", description="Theme of the meeting"),
    duration_minutes: int = Query(60, description="Meeting duration in minutes")
):
    """
    Use Gemini AI to generate a meeting agenda.
    """
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured")

    try:
        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL_NAME,
            system_instruction="You are a Toastmasters meeting agenda generator. Generate structured meeting agendas in JSON format."
        )

        prompt = f"""Generate a Toastmasters meeting agenda with the following parameters:
- Theme: {meeting_theme}
- Total Duration: {duration_minutes} minutes

Return the agenda in JSON format with the following structure:
{{
    "theme": "meeting theme",
    "total_duration": duration in minutes,
    "items": [
        {{
            "order": 1,
            "title": "item title",
            "duration_min": duration,
            "role": "who leads this",
            "description": "brief description"
        }}
    ]
}}

Include typical Toastmasters segments: Opening, Word of the Day, Table Topics, Prepared Speeches, Evaluations, Reports, and Closing."""

        response = model.generate_content(prompt)

        return {
            "agenda": response.text,
            "theme": meeting_theme,
            "duration": duration_minutes
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class ParseTemplateRequest(BaseModel):
    template_content: str
    filename: Optional[str] = None


class ParseTemplateResponse(BaseModel):
    variables: list
    role_slots: list
    dynamic_blocks: list
    variable_mappings: list  # New: mappings with coordinates
    raw_analysis: str


@app.post("/parse-template", response_model=ParseTemplateResponse)
async def parse_template(request: ParseTemplateRequest):
    """
    Use Gemini AI to parse a Toastmasters meeting agenda template.
    Identifies variables, role slots, and returns coordinate mappings for filling.
    """
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured")

    try:
        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL_NAME,
            system_instruction="""You are a Toastmasters meeting agenda template parser.
Your job is to analyze Excel template content with coordinates and identify:
1. Where each role's name should be filled (row and column)
2. Role slots and their positions
3. Variables like date, theme, meeting number

The Excel content is in format: [R行,C列] Content
You must identify which cells contain ROLE LABELS and which adjacent cells should contain the PERSON NAME.

Always respond in valid JSON format."""
        )

        prompt = f"""分析這個 Toastmasters 會議 Agenda Excel 模板。
模板內容有座標格式：[R行,C列] 內容

模板內容:
{request.template_content}

請找出：
1. 每個角色標籤（如 TME、Timer、GE、LE 等）的位置
2. 該角色對應的「人名」應該填在哪個儲存格（通常在標籤的右邊或同一行的其他欄）

回傳 JSON 格式：
{{
    "variable_mappings": [
        {{
            "role": "TME",
            "label_position": {{"row": 10, "col": 3}},
            "value_position": {{"row": 10, "col": 4}},
            "description": "總主持人名字"
        }},
        {{
            "role": "TIMER",
            "label_position": {{"row": 15, "col": 1}},
            "value_position": {{"row": 15, "col": 2}},
            "description": "計時員名字"
        }},
        {{
            "role": "SPEAKER_1",
            "label_position": {{"row": 20, "col": 1}},
            "value_position": {{"row": 20, "col": 2}},
            "description": "第一位講者名字"
        }},
        {{
            "role": "MEETING_DATE",
            "label_position": null,
            "value_position": {{"row": 3, "col": 2}},
            "description": "會議日期"
        }},
        {{
            "role": "THEME",
            "label_position": null,
            "value_position": {{"row": 4, "col": 2}},
            "description": "會議主題"
        }}
    ],
    "variables": [
        {{"name": "MEETING_DATE", "type": "basic", "description": "會議日期"}},
        {{"name": "TME_NAME", "type": "role", "description": "總主持人"}}
    ],
    "role_slots": [
        {{"role": "SPEAKER", "slot_count": 3, "has_evaluator": true}},
        {{"role": "TME", "slot_count": 1, "has_evaluator": false}}
    ],
    "dynamic_blocks": []
}}

重點：
- variable_mappings 必須包含精確的 row 和 col 數字（從內容的 [R行,C列] 格式讀取）
- 仔細找出「每個角色標籤」以及「對應的值應該填在哪裡」
- 如果標籤右邊的儲存格是空的或只有佔位符文字，那就是 value_position
- 支援的角色包括：TME, TIMER, AH_COUNTER, GRAMMARIAN, GE, LE, PHOTOGRAPHER, SAA, SPEAKER_1/2/3, EVALUATOR_1/2/3 等

請只回傳 JSON，不要其他文字。"""

        response = model.generate_content(prompt)
        raw_text = response.text.strip()

        # Try to parse the JSON response
        import json
        import re

        # Extract JSON from response (handle markdown code blocks)
        json_match = re.search(r'```json\s*(.*?)\s*```', raw_text, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        else:
            json_str = raw_text

        try:
            parsed = json.loads(json_str)
            return ParseTemplateResponse(
                variables=parsed.get("variables", []),
                role_slots=parsed.get("role_slots", []),
                dynamic_blocks=parsed.get("dynamic_blocks", []),
                variable_mappings=parsed.get("variable_mappings", []),
                raw_analysis=raw_text
            )
        except json.JSONDecodeError:
            # Return raw response if JSON parsing fails
            return ParseTemplateResponse(
                variables=[],
                role_slots=[],
                dynamic_blocks=[],
                variable_mappings=[],
                raw_analysis=raw_text
            )

    except Exception as e:
        import traceback
        error_detail = f"{type(e).__name__}: {str(e)}"
        print(f"Error in parse_template: {error_detail}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=error_detail)


if __name__ == "__main__":
    import uvicorn
    from src.config import SERVER_HOST, SERVER_PORT
    uvicorn.run(app, host=SERVER_HOST, port=SERVER_PORT)

