"""
MCP Client for connecting to the Spring Boot MCP Server.
Uses the official MCP Python SDK with Streamable HTTP transport.
"""
import asyncio
from typing import Any, Optional
from dataclasses import dataclass

# Try to import MCP SDK - will fail gracefully if not available
try:
    from mcp import ClientSession
    from mcp.client.streamable_http import streamablehttp_client
    MCP_SDK_AVAILABLE = True
except ImportError:
    MCP_SDK_AVAILABLE = False
    print("[WARN] MCP SDK not available, install with: pip install mcp>=1.8.0")


@dataclass
class McpTool:
    """Represents an MCP tool definition."""
    name: str
    description: str
    input_schema: dict


class McpClient:
    """
    MCP Client using the official MCP Python SDK with Streamable HTTP transport.
    """
    
    def __init__(self, mcp_server_url: str):
        """
        Initialize the MCP client.
        
        Args:
            mcp_server_url: Base URL of the MCP Server (e.g., http://localhost:8080)
        """
        self.base_url = mcp_server_url.rstrip('/')
        self.mcp_endpoint = f"{self.base_url}/mcp"
        self._tools: list[McpTool] = []
        self._session: Optional[ClientSession] = None
        self._read_stream = None
        self._write_stream = None
        self._context = None
    
    async def initialize(self) -> bool:
        """
        Initialize connection to MCP Server and fetch available tools.
        
        Returns:
            True if initialization successful, False otherwise.
        """
        if not MCP_SDK_AVAILABLE:
            print("[ERR] MCP SDK not available")
            return False
            
        try:
            print(f"[CONN] Connecting to MCP Server: {self.mcp_endpoint}")
            
            # Create streamable HTTP client context
            self._context = streamablehttp_client(url=self.mcp_endpoint)
            
            # Enter the context to get read/write streams
            streams = await self._context.__aenter__()
            self._read_stream, self._write_stream, _ = streams
            
            # Create client session
            self._session = ClientSession(self._read_stream, self._write_stream)
            
            # Initialize the session
            await self._session.__aenter__()
            result = await self._session.initialize()
            
            print(f"[OK] MCP Server initialized: {result.serverInfo}")
            
            # Fetch tools list
            await self._fetch_tools()
            return True
                
        except Exception as e:
            print(f"[ERR] MCP initialization error: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    async def _fetch_tools(self):
        """Fetch available tools from MCP Server."""
        try:
            if self._session is None:
                print("[WARN] Session not initialized")
                return
                
            tools_result = await self._session.list_tools()
            
            self._tools = [
                McpTool(
                    name=t.name,
                    description=t.description or "",
                    input_schema=t.inputSchema if hasattr(t, 'inputSchema') else {}
                )
                for t in tools_result.tools
            ]
            print(f"[OK] Loaded {len(self._tools)} MCP tools: {[t.name for t in self._tools]}")
                    
        except Exception as e:
            print(f"[ERR] Failed to fetch MCP tools: {e}")
    
    def get_tools(self) -> list[McpTool]:
        """Get the list of available MCP tools."""
        return self._tools
    
    def get_gemini_function_declarations(self) -> list[dict]:
        """
        Convert MCP tools to Gemini function declarations.
        
        Returns:
            List of function declarations for Gemini API.
        """
        declarations = []
        for tool in self._tools:
            # Convert JSON Schema to Gemini format
            properties = {}
            required = []
            
            schema = tool.input_schema
            if isinstance(schema, dict) and "properties" in schema:
                for prop_name, prop_def in schema["properties"].items():
                    prop_type = prop_def.get("type", "string")
                    # Map JSON Schema types to Gemini types
                    gemini_type = {
                        "string": "STRING",
                        "integer": "INTEGER", 
                        "number": "NUMBER",
                        "boolean": "BOOLEAN",
                        "array": "ARRAY",
                        "object": "OBJECT"
                    }.get(prop_type, "STRING")
                    
                    properties[prop_name] = {
                        "type": gemini_type,
                        "description": prop_def.get("description", "")
                    }
                
                required = schema.get("required", [])
            
            declarations.append({
                "name": tool.name,
                "description": tool.description,
                "parameters": {
                    "type": "OBJECT",
                    "properties": properties,
                    "required": required
                }
            })
        
        return declarations
    
    async def call_tool(self, name: str, arguments: dict) -> dict[str, Any]:
        """
        Call an MCP tool with the given arguments.
        
        Args:
            name: The tool name to call.
            arguments: The arguments to pass to the tool.
            
        Returns:
            The tool result as a dictionary.
        """
        try:
            if self._session is None:
                return {"error": "MCP session not initialized"}
            
            result = await self._session.call_tool(name, arguments)
            
            # Extract content from result
            if result.content:
                # Parse first text content as JSON if possible
                for content in result.content:
                    if hasattr(content, 'text'):
                        try:
                            import json
                            return json.loads(content.text)
                        except:
                            return {"text": content.text}
                return {"result": str(result.content)}
            
            return {"result": "success"}
            
        except Exception as e:
            return {"error": f"MCP call error: {str(e)}"}
    
    async def close(self):
        """Close the MCP session and HTTP client."""
        try:
            if self._session:
                await self._session.__aexit__(None, None, None)
            if self._context:
                await self._context.__aexit__(None, None, None)
        except Exception as e:
            print(f"[WARN] Error closing MCP client: {e}")


# Singleton instance for the application
_mcp_client: Optional[McpClient] = None


def get_mcp_client() -> Optional[McpClient]:
    """Get the global MCP client instance."""
    return _mcp_client


async def init_mcp_client(mcp_server_url: str) -> McpClient:
    """
    Initialize the global MCP client.
    
    Args:
        mcp_server_url: Base URL of the MCP Server.
        
    Returns:
        The initialized MCP client.
    """
    global _mcp_client
    _mcp_client = McpClient(mcp_server_url)
    await _mcp_client.initialize()
    return _mcp_client
