"""Connect model with mcp tools in Python
# Run this python script
> pip install mcp openai
> python <this-script-path>.py
"""
import asyncio
import json
{{#hasImage}}
import base64
{{/hasImage}}
import os
from typing import Dict, Optional
from contextlib import AsyncExitStack

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.client.sse import sse_client

from openai import OpenAI

{{#hasImage}}
def encodeImage(path, mime_type):
    with open(path, "rb") as image:
        encoded = base64.b64encode(image.read())
    return f"data:{mime_type};base64,{encoded.decode()}"

{{/hasImage}}
class MCPClient:
    def __init__(self):
        # Initialize session and client objects
        self._servers = {}
        self._tool_to_server_map = {}
        self.exit_stack = AsyncExitStack()
        self.openai = OpenAI(
            api_key = os.environ["OPENAI_API_KEY"],
        )

    async def connect_stdio_server(self, server_id: str, command: str, args: list[str], env: Dict[str, str]):
        """Connect to an MCP server using STDIO transport
        
        Args:
            server_id: Unique identifier for this server connection
            command: Command to run the MCP server
            args: Arguments for the command
            env: Optional environment variables
        """
        server_params = StdioServerParameters(
            command=command,
            args=args,
            env=env
        )
        
        stdio_transport = await self.exit_stack.enter_async_context(stdio_client(server_params))
        stdio, write = stdio_transport
        session = await self.exit_stack.enter_async_context(ClientSession(stdio, write))
        await session.initialize()
        
        # Register the server
        await self._register_server(server_id, session)
    
    async def connect_sse_server(self, server_id: str, url: str, headers: Dict[str, str]):
        """Connect to an MCP server using SSE transport
        
        Args:
            server_id: Unique identifier for this server connection
            url: URL of the SSE server
            headers: Optional HTTP headers
        """
        sse_context = await self.exit_stack.enter_async_context(sse_client(url=url, headers=headers))
        read, write = sse_context
        session = await self.exit_stack.enter_async_context(ClientSession(read, write))
        await session.initialize()
        
        # Register the server
        await self._register_server(server_id, session)
    
    async def _register_server(self, server_id: str, session: ClientSession):
        """Register a server and its tools in the client
        
        Args:
            server_id: Unique identifier for this server
            session: Connected ClientSession
        """
        # List available tools
        response = await session.list_tools()
        tools = response.tools
        
        # Store server connection info
        self._servers[server_id] = {
            "session": session,
            "tools": tools
        }
        
        # Update tool-to-server mapping
        for tool in tools:
            self._tool_to_server_map[tool.name] = server_id
            
        print(f"\nConnected to server '{server_id}' with tools:", [tool.name for tool in tools])

    async def chatWithTools(self, messages: list[any]) -> str:
        """Chat with model and using tools
        Args:
            messages: Messages to send to the model
        """
        if not self._servers:
            raise ValueError("No MCP servers connected. Connect to at least one server first.")

        # Collect tools from all connected servers
        available_tools = []
        for server_id, server_info in self._servers.items():
            for tool in server_info["tools"]:
                available_tools.append({ 
                    "type": "function",
                    "name": tool.name,
                    "description": tool.description,
                    "parameters": tool.inputSchema
                })

        while True:

            # Call model
            response = self.openai.responses.create(
{{#parameters.systemWithQuote}}
                instructions = {{{parameters.systemWithQuote}}},
{{/parameters.systemWithQuote}}
                input = messages,
                model = "{{model}}",
                tools=available_tools,
{{#response_format_json_schema}}
                text = {
                    "format": {
                        "type": "json_schema",
                        "name": "{{response_format_json_schema.name}}",
                        "description": "{{response_format_json_schema.description}}",
                        "strict": {{response_format_json_schema.strict}},
                        "schema": {{{response_format_json_schema.schema}}},
                    },
                },
{{/response_format_json_schema}}
{{#parameters.max_tokens}}
                max_output_tokens = {{parameters.max_tokens}},
{{/parameters.max_tokens}}
{{#parameters.temperature}}
                temperature = {{.}},
{{/parameters.temperature}}
{{#parameters.top_p}}
                top_p = {{.}},
{{/parameters.top_p}}
            )
            hasToolCall = False

            if response.output[0].type == "function_call":
                hasToolCall = True
                tool = response.output[0]
                tool_name = tool.name
                tool_args = json.loads(tool.arguments)
                messages.append(tool)
            
                # Find the appropriate server for this tool
                if tool_name in self._tool_to_server_map:
                    server_id = self._tool_to_server_map[tool_name]
                    server_session = self._servers[server_id]["session"]
                    
                    # Execute tool call on the appropriate server
                    result = await server_session.call_tool(tool_name, tool_args)
                    print(f"[Server '{server_id}' call tool '{tool_name}' with args {tool_args}]: {result.content}")

                    messages.append({
                        "type": "function_call_output",
                        "call_id": tool.id,
                        "output": result.content[0].text,
                    })
            else:
                messages.append({
                    "role": "assistant",
                    "content": response.output_text
                })
                print(f"[Model Response]: {response.output_text}")
        
            if not hasToolCall:
                break
    
    async def cleanup(self):
        """Clean up resources"""
        await self.exit_stack.aclose()
        await asyncio.sleep(1)

async def main():
    client = MCPClient()
    messages = [
{{#messages}}
{{#isContent}}
        {
            "role": "{{role}}",
            "content": [
{{#content}}
{{#isText}}
                {
                    "type": "input_text",
                    "text": {{{textWithQuote}}},
                },
{{/isText}}
{{#isImage}}
                {
                    "type": "input_image",
                    "detail": "auto",
                    "image_url": encodeImage({{{localPathWithQuote}}}, "{{{mimeType}}}"),
                },
{{/isImage}}
{{/content}}
            ],
        },
{{/isContent}}
{{^isContent}}
        {
{{#tool_calls}}
            "type": "function_call",
            "call_id": "{{{id}}}",
            "name": "{{{function.name}}}",
            "arguments": {{{function.arguments}}},
{{/tool_calls}}
{{#isTool}}
            "type": "function_call_output",
            "call_id": "{{{tool_call_id}}}",
            "output": {{{output}}},
{{/isTool}}
        },
{{/isContent}}
{{/messages}}
    ]
    try:
{{#mcpConfigs}}
{{#isStdio}}
        await client.connect_stdio_server(
            "{{{serverName}}}", 
            {{{commandWithQuote}}}, 
            [
{{#argsWithQuote}}
                {{{.}}},
{{/argsWithQuote}}
            ],
            {
{{#env}}
                "{{.}}": os.environ["{{.}}"],
{{/env}}
            }
        )
{{/isStdio}}
{{#isSse}}
        await client.connect_sse_server(
            "{{{serverName}}}", 
            {{{urlWithQuote}}},
            {
{{#env}}
                "{{.}}": os.environ["{{.}}"],
{{/env}}
            }
        )
{{/isSse}}
{{/mcpConfigs}}
        await client.chatWithTools(messages)
    except Exception as e:
        print(f"\nError: {str(e)}")
    finally:
        await client.cleanup()

if __name__ == "__main__":
    asyncio.run(main())