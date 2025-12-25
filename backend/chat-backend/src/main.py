import os
import asyncio
import subprocess
import json
import traceback
from typing import Optional
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from dotenv import load_dotenv
from google import genai
from google.genai import types as genai_types

# ADK imports
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types as genai_types

# Load environment variables
load_dotenv()

# Import configuration
from src.config import (
    GCP_PROJECT_ID,
    GEMINI_MODEL_NAME,
    GEMINI_SECRET_NAME,
    CORS_ORIGINS,
    SYSTEM_PROMPT,
    MCP_SERVER_URL,
)

# Import ADK Agent
from src.agent import create_agent

# Import MCP client (keep for backward compatibility)
from src.mcp_client import McpClient, get_mcp_client, init_mcp_client


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
            print(f"[OK] Fetched {secret_id} using gcloud CLI")
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
        print(f"[OK] Fetched {secret_id} using Secret Manager SDK")
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        print(f"Secret Manager SDK method failed: {e}")
    
    # Method 3: Fallback to environment variable
    env_value = os.getenv(secret_id, "")
    if env_value:
        print(f"[OK] Using {secret_id} from environment variable")
        return env_value
    
    print(f"[WARN] Failed to fetch {secret_id} from any source")
    return ""


# Configure Gemini SDK Client
GEMINI_API_KEY = get_secret_from_gcp(GEMINI_SECRET_NAME)
genai_client = None
if GEMINI_API_KEY:
    os.environ["GOOGLE_API_KEY"] = GEMINI_API_KEY
    # Initialize the modern Gemini Client
    genai_client = genai.Client(api_key=GEMINI_API_KEY)
    
    masked_key = GEMINI_API_KEY[:10] + "..." + GEMINI_API_KEY[-4:] if len(GEMINI_API_KEY) > 14 else "***"
    print(f"[OK] Gemini API configured with key: {masked_key}")
    print(f"[MODEL] Using model: {GEMINI_MODEL_NAME}")
else:
    print("[WARN] No Gemini API key found")


# Global MCP client instance
mcp_client: Optional[McpClient] = None

# Global ADK Runner and Session Service
adk_runner: Optional[Runner] = None
session_service: Optional[InMemorySessionService] = None
TOOL_DISPLAY_MAP: dict[str, str] = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan - initialize ADK Runner on startup."""
    global mcp_client, adk_runner, session_service
    
    # Initialize MCP client (for backward compatibility / health check)
    print(f"[CONN] Connecting to MCP Server: {MCP_SERVER_URL}")
    try:
        mcp_client = await init_mcp_client(MCP_SERVER_URL)
        tools = mcp_client.get_tools()
        print(f"[OK] MCP Client connected with {len(tools)} tools")
        
        # Populate display map from descriptions
        for tool in tools:
            # Expected format: "[Friendly Name] Description..."
            desc = tool.description or ""
            if desc.startswith("[") and "]" in desc:
                end_idx = desc.find("]")
                friendly_name = desc[1:end_idx]
                TOOL_DISPLAY_MAP[tool.name] = friendly_name
                print(f"[TOOL] Map {tool.name} -> {friendly_name}")
            else:
                TOOL_DISPLAY_MAP[tool.name] = tool.name
    except Exception as e:
        print(f"[WARN] MCP Client initialization failed: {e}")
        mcp_client = None
    
    # Initialize ADK Runner
    try:
        print("[ADK] Initializing ADK Agent and Runner...")
        agent = create_agent()
        session_service = InMemorySessionService()
        adk_runner = Runner(
            agent=agent,
            app_name="toastlabplus",
            session_service=session_service
        )
        print("[OK] ADK Runner initialized successfully")
    except Exception as e:
        print(f"[WARN] ADK Runner initialization failed: {e}")
        import traceback
        traceback.print_exc()
        adk_runner = None
    
    yield
    
    # Cleanup
    if mcp_client:
        await mcp_client.close()


app = FastAPI(
    title="Toastlabplus Chat Backend",
    description="Chat Backend with Gemini AI + MCP integration for Toastmasters meeting assistance",
    version="0.2.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ActionButton(BaseModel):
    """Interactive action button for chat responses."""
    id: str
    label: str
    action_type: str  # "signup_role", "view_meeting", etc.
    payload: dict


class ChatRequest(BaseModel):
    message: str
    conversation_history: Optional[list] = None
    user_email: Optional[str] = None  # For signup actions
    user_name: Optional[str] = None


class StepDetail(BaseModel):
    step_type: str  # "tool_call", "tool_result", "thought"
    content: str    # Detailed content or JSON string


class ChatResponse(BaseModel):
    response: str
    model: str
    actions: Optional[list[ActionButton]] = None
    thought_process: Optional[list[StepDetail]] = None


@app.get("/")
async def root():
    return {"message": "Toastlabplus Chat Backend", "status": "running"}


@app.get("/health")
async def health():
    mcp_tools_count = len(mcp_client.get_tools()) if mcp_client else 0
    return {
        "status": "healthy",
        "gemini_configured": bool(GEMINI_API_KEY),
        "model": GEMINI_MODEL_NAME,
        "gcp_project": GCP_PROJECT_ID,
        "mcp_server": MCP_SERVER_URL,
        "mcp_connected": mcp_client is not None,
        "mcp_tools_count": mcp_tools_count,
        "adk_runner": adk_runner is not None
    }


@app.post("/chat")
async def chat(request: ChatRequest):
    """
    Chat endpoint using ADK Runner with Streaming Response (NDJSON).
    """
    if not adk_runner:
        raise HTTPException(status_code=503, detail="ADK Runner not initialized")
    
    # User Context from Request
    user_email = request.user_email or "unknown_user"
    user_id = user_email
    session_id = f"session_{user_id}"
    
    # 確保 session 存在
    try:
        session = await session_service.get_session(
            app_name="toastlabplus",
            user_id=user_id,
            session_id=session_id
        )
        if not session:
            await session_service.create_session(
                app_name="toastlabplus",
                user_id=user_id,
                session_id=session_id
            )
    except Exception as e:
        print(f"[WARN] Session check failed: {e}")

    # Process message history (optional: ADK handles history in session usually)
    # But for a stateless REST API view, we usually just pass the new message
    user_name = request.user_name or "Unknown"
    message_content = genai_types.Content(parts=[
        genai_types.Part(text=f"User: {request.message}\nUser Email: {user_email}\nUser Name: {user_name}")
    ])
    
    async def event_generator():
        print(f"[ADK] Streaming agent for user: {user_id}")
        
        # Keep track of actions to send at the end
        accumulated_actions = []
        
        try:
            async for event in adk_runner.run_async(
                user_id=user_id,
                session_id=session_id,
                new_message=message_content
            ):
                if event.content and event.content.parts:
                    for part in event.content.parts:
                        # 1. Text Content
                        if hasattr(part, 'text') and part.text:
                            yield json.dumps({
                                "type": "text", 
                                "content": part.text
                            }, ensure_ascii=False) + "\n"
                        
                        # 2. Tool Calls
                        if hasattr(part, 'function_call') and part.function_call:
                            fc = part.function_call
                            
                            # Look up display label
                            tool_label = TOOL_DISPLAY_MAP.get(fc.name, fc.name)
                            
                            yield json.dumps({
                                "type": "thought_start",
                                "tool": fc.name,
                                "tool_label": tool_label,
                                "args": dict(fc.args) if fc.args else {}
                            }, ensure_ascii=False) + "\n"
                        
                        # 3. Tool Results
                        if hasattr(part, 'function_response') and part.function_response:
                            fr = part.function_response
                            
                            # Truncate long results for frontend display
                            result_str = str(fr.response)
                            if len(result_str) > 100:
                                result_str = result_str[:100] + "..."
                            
                            yield json.dumps({
                                "type": "thought_end",
                                "tool": fr.name,
                                "result": result_str
                            }, ensure_ascii=False) + "\n"
                            
                            # Special logic for generating buttons
                            if fr.name == "get_role_slots":
                                try:
                                    result = fr.response
                                    slots = json.loads(result) if isinstance(result, str) else result
                                    if isinstance(slots, list):
                                        available_slots = [s for s in slots if not s.get("isAssigned")]
                                        for slot in available_slots[:5]:
                                            accumulated_actions.append({
                                                "id": f"signup_{slot['id']}",
                                                "label": f"報名 {slot['displayName']}",
                                                "action_type": "signup_role",
                                                "payload": {
                                                    "meetingId": slot.get("meetingId"),
                                                    "roleSlotId": slot["id"],
                                                    "roleName": slot["displayName"]
                                                }
                                            })
                                except Exception as e:
                                    print(f"[WARN] Error parsing buttons: {e}")

            # End of stream, send actions if any
            if accumulated_actions:
                yield json.dumps({
                    "type": "actions",
                    "data": accumulated_actions
                }, ensure_ascii=False) + "\n"
                
        except Exception as e:
            print(f"[ERROR] Stream error: {e}")
            yield json.dumps({"type": "error", "content": str(e)}) + "\n"

    return StreamingResponse(event_generator(), media_type="application/x-ndjson")


@app.get("/chat/stream")
async def chat_stream(message: str = Query(..., description="The message to send")):
    """
    Stream a response from Gemini AI using Server-Sent Events (SSE).
    """
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured")

    async def generate():
        try:
            # Use the global genai_client
            if not genai_client:
                yield "data: Error: Client not initialized\n\n"
                return

            response = genai_client.models.generate_content_stream(
                model=GEMINI_MODEL_NAME,
                contents=message,
                config=genai_types.GenerateContentConfig(
                    system_instruction=SYSTEM_PROMPT
                )
            )

            for chunk in response:
                if chunk.text:
                    yield f"data: {chunk.text}\n\n"
                    # await asyncio.sleep(0.01) # Usually not needed with this SDK

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
        # Use the global genai_client
        if not genai_client:
            raise HTTPException(status_code=500, detail="Gemini Client not initialized")

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

        response = genai_client.models.generate_content(
            model=GEMINI_MODEL_NAME,
            contents=prompt,
            config=genai_types.GenerateContentConfig(
                system_instruction="You are a Toastmasters meeting agenda generator. Generate structured meeting agendas in JSON format."
            )
        )

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
        # Use the global genai_client
        if not genai_client:
            raise HTTPException(status_code=500, detail="Gemini Client not initialized")

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

        response = genai_client.models.generate_content(
            model=GEMINI_MODEL_NAME,
            contents=prompt,
            config=genai_types.GenerateContentConfig(
                system_instruction="""You are a Toastmasters meeting agenda template parser.
Your job is to analyze Excel template content with coordinates and identify:
1. Where each role's name should be filled (row and column)
2. Role slots and their positions
3. Variables like date, theme, meeting number

The Excel content is in format: [R行,C列] Content
You must identify which cells contain ROLE LABELS and which adjacent cells should contain the PERSON NAME.

Always respond in valid JSON format."""
            )
        )
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

