"""
ToastLabPlus AI Agent using Google ADK with MCP Tools integration.
"""
import os
from google.adk.agents import Agent
from google.adk.tools.mcp_tool.mcp_toolset import McpToolset, StreamableHTTPConnectionParams

from .config import MCP_SERVER_URL, SYSTEM_PROMPT, GEMINI_MODEL_NAME

def create_agent() -> Agent:
    """Create and return the ADK Agent with MCP tools."""
    
    # MCP Server 連接參數
    mcp_connection_params = StreamableHTTPConnectionParams(
        url=f"{MCP_SERVER_URL}/mcp"
    )
    
    # 建立 MCP Toolset
    mcp_tools = McpToolset(
        connection_params=mcp_connection_params
    )
    
    # 定義 Agent
    agent = Agent(
        name="toastlabplus_assistant",
        model=GEMINI_MODEL_NAME,
        description="ToastLabPlus AI 助理 - 幫助 Toastmasters 會員查詢分會、會議資訊並報名角色",
        instruction=SYSTEM_PROMPT,
        tools=[mcp_tools]
    )
    
    return agent

# 預設 root_agent 供 ADK CLI 使用
root_agent = None  # Will be lazily initialized

