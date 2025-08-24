"""Connect model with mcp tools in Python
# Run this python script
> pip install mcp cohere
> python <this-script-path>.py
"""
import asyncio
import os
from typing import Dict, Optional, Sequence
from contextlib import AsyncExitStack
import typing

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.client.sse import sse_client

from cohere import Client, ToolResult

class MCPClient:
    def __init__(self):
        # Initialize session and client objects
        self._servers = {}
        self._tool_to_server_map = {}
        self.exit_stack = AsyncExitStack()
        # To authenticate with the model you will need to generate a personal access token (PAT) in your GitHub settings.
        # Create your PAT token by following instructions here: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
        self.cohere = Client(
            base_url = "https://models.github.ai/inference",
            api_key = os.environ["GITHUB_TOKEN"],
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

    async def chatWithTools(
        self,
        messages: list[any],
        last_message: str,
        tool_results: typing.Optional[typing.Sequence[ToolResult]],
    ) -> str:
        """Chat with model and using tools
        Args:
            messages: Messages to send to the model
            last_message: Last message to send to the model
            tool_results: Results from previous tool calls
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
                    "parameters": tool.inputSchema,
                })

        while True:

            # Call model
            response = self.cohere.chat(
                model = "{{{model}}}",
{{#parameters.systemWithQuote}}
                preamble = {{{parameters.systemWithQuote}}},
{{/parameters.systemWithQuote}}
                message=last_message,
                chat_history = messages,
                tools=available_tools,
                tool_results = tool_results,
{{#parameters.max_tokens}}
                max_tokens = {{parameters.max_tokens}},
{{/parameters.max_tokens}}
{{#parameters.temperature}}
                temperature = {{.}},
{{/parameters.temperature}}
{{#parameters.top_p}}
                p = {{.}},
{{/parameters.top_p}}
{{#parameters.frequency_penalty}}
                frequency_penalty = {{.}},
{{/parameters.frequency_penalty}}
{{#parameters.presence_penalty}}
                presence_penalty = {{.}},
{{/parameters.presence_penalty}}
            )
            hasToolCall = False

            if response.tool_calls:
                tool_results = []
                for tool in response.tool_calls:
                    hasToolCall = True
                    tool_name = tool.name
                    tool_args = tool.parameters
                    messages.append({
                        "role": "chatbot",
                        "message": "",
                        "tool_calls": [{
                            "id": tool.name,
                            "type": "function",
                            "function": {
                                "name": tool.name,
                                "arguments": tool.parameters,
                            }
                        }]
                    })
                
                    # Find the appropriate server for this tool
                    if tool_name in self._tool_to_server_map:
                        server_id = self._tool_to_server_map[tool_name]
                        server_session = self._servers[server_id]["session"]
                        
                        # Execute tool call on the appropriate server
                        result = await server_session.call_tool(tool_name, tool_args)
                        print(f"[Server '{server_id}' call tool '{tool_name}' with args {tool_args}]: {result.content}")

                        last_message = ""
                        tool_results.append({
                            "call": {
                                "name": tool.name,
                                "parameters": tool.parameters,
                            },
                            "outputs": result.content,
                        })
            elif response.text:
                messages.append({
                    "role": "chatbot",
                    "message": response.text,
                })
                tool_results = None
                print(f"[Model Response]: {response.text}")
        
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
{{#isUser}}
{{#content}}
{{#isText}}
{{^isCohereMessage}}
        {
            "role": "user",
            "message": {{{textWithQuote}}},
        },
{{/isCohereMessage}}
{{/isText}}
{{/content}}
{{/isUser}}
{{#isAssistant}}
        {
            "role": "chatbot",
            "message": {{{textWithQuote}}},
{{#tool_calls}}
            "tool_calls": [
                {
                    "id": "{{{id}}}",
                    "type": "function",
                    "function": {
                        "name": "{{{function.name}}}",
                        "arguments": {{{function.arguments}}},
                    }
                },
            ],
{{/tool_calls}}
        },
{{/isAssistant}}
{{/messages}}
    ]
{{#messages}}
{{#isUser}}
{{#content}}
{{#isText}}
{{#cohereToolResult}}
    last_message = "" # Cannot specify both message and tool_results unless in single hop mode
{{/cohereToolResult}}
{{^cohereToolResult}}
{{#isCohereMessage}}
    last_message = {{{textWithQuote}}}
{{/isCohereMessage}}
{{/cohereToolResult}}
{{/isText}}
{{/content}}
{{/isUser}}
{{/messages}}
{{#cohereToolResult}}
    tool_results = {{{cohereToolResult}}}
{{/cohereToolResult}}
{{^cohereToolResult}}
    tool_results = None
{{/cohereToolResult}}
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
        await client.chatWithTools(messages, last_message, tool_results)
    except Exception as e:
        print(f"\nError: {str(e)}")
    finally:
        await client.cleanup()

if __name__ == "__main__":
    asyncio.run(main())