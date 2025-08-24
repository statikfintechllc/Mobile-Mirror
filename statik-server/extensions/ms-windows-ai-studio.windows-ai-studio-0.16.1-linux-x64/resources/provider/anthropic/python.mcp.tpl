"""Connect model with mcp tools in Python
# Run this python script
> pip install mcp anthropic
> python <this-script-path>.py
"""
import asyncio
{{#hasImage}}
import base64
{{/hasImage}}
import os
from typing import Dict, Optional
from contextlib import AsyncExitStack

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.client.sse import sse_client

from anthropic import Anthropic

{{#hasImage}}
def encodeImage(path):
    with open(path, "rb") as image:
        encoded = base64.b64encode(image.read())
    return f"{encoded.decode()}"

{{/hasImage}}
class MCPClient:
    def __init__(self):
        # Initialize session and client objects
        self._servers = {}
        self._tool_to_server_map = {}
        self.exit_stack = AsyncExitStack()
        self.anthropic = Anthropic(
            api_key = os.environ["ANTHROPIC_API_KEY"],
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
            messages: List of messages for the chat
        """
        if not self._servers:
            raise ValueError("No MCP servers connected. Connect to at least one server first.")

        # Collect tools from all connected servers
        available_tools = []
        for server_id, server_info in self._servers.items():
            for tool in server_info["tools"]:
                available_tools.append({ 
                    "name": tool.name,
                    "description": tool.description,
                    "input_schema": tool.inputSchema
                })


        while True:

            # Call model
            response = self.anthropic.messages.create(
                model="{{model}}",
{{#parameters.max_tokens}}
                max_tokens = {{.}},
{{/parameters.max_tokens}}
{{#parameters.temperature}}
                temperature = {{.}},
{{/parameters.temperature}}
{{#parameters.top_p}}
                top_p = {{.}},
{{/parameters.top_p}}
{{#parameters.systemWithQuote}}
                system = {{{.}}},
{{/parameters.systemWithQuote}}
{{#parameters.think_mode}}
                thinking = {
                    "type": "enabled",
                    "budget_tokens": {{parameters.budget_tokens}}
                },
{{/parameters.think_mode}}
                messages=messages,
                tools=available_tools,
            )
            hasToolCall = False

            for content in response.content:
                if content.type == 'text':
                    messages.append({
                        "role": "assistant",
                        "content": content.text
                    })
                    print(f"[Model Response]: {content.text}")
                elif content.type == 'tool_use':
                    hasToolCall = True
                    tool_name = content.name
                    tool_args = content.input
                    messages.append({
                        "role": "assistant",
                        "content": [
                            {
                                "type": "tool_use",
                                "id": content.id,
                                "name": tool_name,
                                "input": tool_args,
                            }
                        ]
                    })
                
                    # Find the appropriate server for this tool
                    if tool_name in self._tool_to_server_map:
                        server_id = self._tool_to_server_map[tool_name]
                        server_session = self._servers[server_id]["session"]
                        
                        # Execute tool call on the appropriate server
                        result = await server_session.call_tool(tool_name, tool_args)
                        print(f"[Server '{server_id}' call tool '{tool_name}' with args {tool_args}]: {result.content}")

                        # Add tool results back to messages
                        if hasattr(content, 'text') and content.text:
                            messages.append({
                                "role": "assistant",
                                "content": content.text
                            })

                        content_list = []
                        for item in result.content:
                            if item.type == "image":
                                content_list.append({
                                    "type": "image",
                                    "source": {
                                        "type": "base64",
                                        "media_type": item.mimeType,
                                        "data": item.data,
                                    }
                                })
                            elif item.type == "text":
                                content_list.append({
                                    "type": "text", 
                                    "text": item.text
                                })
                                
                        messages.append({
                            "role": "user", 
                            "content": [
                                {
                                    "type": "tool_result",
                                    "tool_use_id": content.id,
                                    "content": content_list,
                                }
                            ]
                        })
        
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
        {
            "role": "{{role}}",
            "content": [
{{#content}}
                {
{{#isText}}
                    "type": "text",
                    "text": {{{textWithQuote}}},
{{/isText}}
{{#isImage}}
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": "{{{mimeType}}}",
                        "data": encodeImage({{{localPathWithQuote}}}),
                    },
{{/isImage}}
{{#isToolUse}}
                    "type": "tool_use",
                    "id": "{{{toolUseId}}}",
                    "name": "{{{toolUseName}}}",
                    "input": {{{toolUseInput}}},
{{/isToolUse}}
{{#isToolResult}}
                    "type": "tool_result",
                    "tool_use_id": "{{{toolUseId}}}",
                    "content": {{{toolResultContentWithQuote}}},
{{/isToolResult}}
{{#isThinking}}
                    "type": "thinking",
                    "thinking": {{{thinkingWithQuote}}},
                    "signature": "{{{signature}}}",
{{/isThinking}}
{{#isRedactedThinking}}
                    "type": "redacted_thinking",
                    "data": "{{{redactedThinking}}}",
{{/isRedactedThinking}}
                },
{{/content}}
            ],
        },
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