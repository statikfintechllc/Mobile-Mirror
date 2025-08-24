"""Connect model with mcp tools in Python
# Run this python script
> pip install mcp azure-ai-inference
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


from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import AssistantMessage, SystemMessage, UserMessage, ToolMessage
from azure.ai.inference.models import ImageContentItem, ImageUrl, TextContentItem
{{#response_format_json_schema}}
from azure.ai.inference.models import JsonSchemaFormat
{{/response_format_json_schema}}
from azure.core.credentials import AzureKeyCredential

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
        # To authenticate with the model you will need to generate a personal access token (PAT) in your GitHub settings.
        # Create your PAT token by following instructions here: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
        self.azureai = ChatCompletionsClient(
            endpoint = "https://models.github.ai/inference",
            credential = AzureKeyCredential(os.environ["GITHUB_TOKEN"]),
{{#o1}}
            api_version = "2024-12-01-preview",
{{/o1}}
{{#api_version}}
            api_version = "{{api_version}}",
{{/api_version}}
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
                    "function": {
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": tool.inputSchema
                    },
                })

        while True:

            # Call model
            response = self.azureai.complete(
                messages = messages,
                model = "{{{model}}}",
                tools=available_tools,
{{#response_format_text}}
                response_format = "text",
{{/response_format_text}}
{{#response_format_json_schema}}
                response_format = JsonSchemaFormat(
                    name = "{{response_format_json_schema.name}}",
                    description = "{{response_format_json_schema.description}}",
                    strict = {{response_format_json_schema.strict}},
                    schema = {{{response_format_json_schema.schema}}}
                ),
{{/response_format_json_schema}}
{{#parameters.max_tokens}}
{{#o1}}
                model_extras = { "max_completion_tokens" : {{parameters.max_tokens}} },
{{/o1}}
{{^o1}}
                max_tokens = {{parameters.max_tokens}},
{{/o1}}
{{/parameters.max_tokens}}
{{#parameters.temperature}}
                temperature = {{.}},
{{/parameters.temperature}}
{{#parameters.top_p}}
                top_p = {{.}},
{{/parameters.top_p}}
{{#parameters.frequency_penalty}}
                frequency_penalty = {{.}},
{{/parameters.frequency_penalty}}
{{#parameters.presence_penalty}}
                presence_penalty = {{.}},
{{/parameters.presence_penalty}}
            )
            hasToolCall = False

            if response.choices[0].message.tool_calls:
                for tool in response.choices[0].message.tool_calls:
                    hasToolCall = True
                    tool_name = tool.function.name
                    tool_args = json.loads(tool.function.arguments)
                    messages.append(
                        AssistantMessage(
                            tool_calls = [{
                                "id": tool.id,
                                "type": "function",
                                "function": {
                                    "name": tool.function.name,
                                    "arguments": tool.function.arguments,
                                }
                            }]
                        )
                    )
                
                
                    # Find the appropriate server for this tool
                    if tool_name in self._tool_to_server_map:
                        server_id = self._tool_to_server_map[tool_name]
                        server_session = self._servers[server_id]["session"]
                        
                        # Execute tool call on the appropriate server
                        result = await server_session.call_tool(tool_name, tool_args)
                        print(f"[Server '{server_id}' call tool '{tool_name}' with args {tool_args}]: {result.content}")

                        messages.append(
                            ToolMessage(
                                tool_call_id = tool.id,
                                content = str(result.content)
                            )
                        )
            else:
                messages.append(
                    AssistantMessage(
                        content = response.choices[0].message.content
                    )
                )
                print(f"[Model Response]: {response.choices[0].message.content}")
        
            if not hasToolCall:
                break
    
    async def cleanup(self):
        """Clean up resources"""
        await self.exit_stack.aclose()
        await asyncio.sleep(1)

async def main():
    client = MCPClient()
    messages = [
{{#parameters.systemWithQuote}}
{{#o1}}
        { "role": "developer", "content": {{{parameters.systemWithQuote}}} },
{{/o1}}
{{^o1}}
        SystemMessage(content = {{{parameters.systemWithQuote}}}),
{{/o1}}
{{/parameters.systemWithQuote}}
{{#messages}}
{{#isUser}}
        UserMessage(content = [
{{#content}}
{{#isText}}
            TextContentItem(text = {{{textWithQuote}}}),
{{/isText}}
{{#isImage}}
            ImageContentItem(image_url = ImageUrl(url = encodeImage({{{localPathWithQuote}}}, "{{{mimeType}}}"))),
{{/isImage}}
{{/content}}
        ]),
{{/isUser}}
{{#isAssistant}}
        AssistantMessage(
{{^tool_calls}}
            content = {{{textWithQuote}}},
{{/tool_calls}}
{{#tool_calls}}
            tool_calls = [
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
        ),
{{/isAssistant}}
{{#isTool}}
        ToolMessage(
{{#content}}
            content= {{{textWithQuote}}},
            tool_call_id = "{{{tool_call_id}}}",
{{/content}}
        ),
{{/isTool}}
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