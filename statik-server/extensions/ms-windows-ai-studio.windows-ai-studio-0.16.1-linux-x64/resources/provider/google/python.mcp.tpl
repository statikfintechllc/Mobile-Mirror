"""Connect model with mcp tools in Python
# Run this python script
> pip install mcp google-generativeai
> python <this-script-path>.py
"""

import asyncio
import os
{{#files.0}}
import time
{{/files.0}}
from typing import Dict, Optional
from contextlib import AsyncExitStack

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.client.sse import sse_client

import google.generativeai as genai

genai.configure(api_key=os.environ["GEMINI_API_KEY"])

generation_config = {
{{#parameters.temperature}}
  "temperature": {{.}},
{{/parameters.temperature}}
{{#parameters.top_p}}
  "top_p": {{.}},
{{/parameters.top_p}}
{{#parameters.max_tokens}}
  "max_output_tokens": {{.}},
{{/parameters.max_tokens}}
{{#parameters.presence_penalty}}
  "presence_penalty": {{.}},
{{/parameters.presence_penalty}}
{{#parameters.frequency_penalty}}
  "frequency_penalty": {{.}},
{{/parameters.frequency_penalty}}
  "response_mime_type": "{{{parameters.response_mime_type}}}",
{{#parameters.response_schema}}
  "response_schema": {{{.}}},
{{/parameters.response_schema}}
}

def transform_schema(schema):
  """Transform the schema by removing unsupported keys and values.
  Args:
    schema: The schema to transform.
  """
  if not isinstance(schema, dict):
      raise ValueError("Schema must be a dictionary")
  transformed_schema = {}
  supported_keys = [
      "type",
      "properties",
      "items",
      "required",
      "enum",
      "description",
      "max_items",
      "min_items",
      "nullable",
  ]

  for key, value in schema.items():
      if key not in supported_keys:
          continue
      
      if key == "properties":
         transformed_schema[key] = {}
         for prop_key, prop_value in value.items():
            transformed_schema[key][prop_key] = transform_schema(prop_value)
      elif key == "items":
          transformed_schema[key] = transform_schema(value)
      else:
          transformed_schema[key] = value
          
  return transformed_schema

{{#files.0}}
def upload_to_gemini(path, mime_type=None):
  """Uploads the given file to Gemini.

  See https://ai.google.dev/gemini-api/docs/prompting_with_media
  """
  file = genai.upload_file(path, mime_type=mime_type)
  print(f"Uploaded file '{file.display_name}' as: {file.uri}")
  return file

def wait_for_files_active(files):
  """Waits for the given files to be active.

  Some files uploaded to the Gemini API need to be processed before they can be
  used as prompt inputs. The status can be seen by querying the file's "state"
  field.

  This implementation uses a simple blocking polling loop. Production code
  should probably employ a more sophisticated approach.
  """
  print("Waiting for file processing...")
  for name in (file.name for file in files):
    file = genai.get_file(name)
    while file.state.name == "PROCESSING":
      print(".", end="", flush=True)
      time.sleep(10)
      file = genai.get_file(name)
    if file.state.name != "ACTIVE":
      raise Exception(f"File {file.name} failed to process")
  print("...all files ready")
  print()

# TODO Make these files available on the local file system
# You may need to update the file paths
files = [
{{#files}}
  upload_to_gemini({{{localPath}}}, mime_type={{{mimeType}}}),
{{/files}}
]

# Some files have a processing delay. Wait for them to be ready.
wait_for_files_active(files)

{{/files.0}}
class MCPClient:
  def __init__(self):
    # Initialize session and client objects
    self._servers = {}
    self._tool_to_server_map = {}
    self.exit_stack = AsyncExitStack()
    self.gemini = genai.GenerativeModel(
      model_name={{{model}}},
      generation_config=generation_config,
{{#parameters.system_prompt}}
      system_instruction={{{.}}},
{{/parameters.system_prompt}}
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
          "name": tool.name,
          "description": tool.description,
          "parameters": transform_schema(tool.inputSchema),
        })
    
    while True:

      # Call model
      response = self.gemini.generate_content(
        contents=messages,
        tools=[{
          "function_declarations": available_tools
        }],
      )
      hasToolCall = False

      for part in response.candidates[0].content.parts:
        messages.append({"role": "model", "parts": [part]})
        if part.text:
          print(f"[Model Response]: {part.text}")
        elif part.function_call:
          hasToolCall = True
          tool_name = part.function_call.name
          tool_args = part.function_call.args
                
          # Find the appropriate server for this tool
          if tool_name in self._tool_to_server_map:
            server_id = self._tool_to_server_map[tool_name]
            server_session = self._servers[server_id]["session"]
            
            # Execute tool call on the appropriate server
            result = await server_session.call_tool(tool_name, tool_args)
            print(f"[Server '{server_id}' call tool '{tool_name}' with args {tool_args}]: {result.content}")

            messages.append({"role": "user", "parts": [
              {
                "function_response": {
                  "name": part.function_call.name,
                  "response": {"result": result.content[0].text},
                }
              }
            ]})

      if not hasToolCall:
        break

  async def cleanup(self):
    """Clean up resources"""
    await self.exit_stack.aclose()
    await asyncio.sleep(1)

async def main():
  client = MCPClient()
  messages = [
{{#allMessages}}
    {
      "role": {{{role}}},
      "parts": [
{{#content}}
{{#isFile}}
        files[{{{fileIndex}}}],
{{/isFile}}
{{#isText}}
        {{{textWithQuote}}},
{{/isText}}
{{#isToolUse}}
        {
          "function_call": {
            "name": "{{{functionCall.name}}}",
            "args": {{{functionCall.args}}},
          },
        },
{{/isToolUse}}
{{#isToolResult}}
        {
          "function_response": {
            "name": "{{{functionResponse.name}}}",
            "response": {{{functionResponse.response}}},
          },
        },
{{/isToolResult}}
{{/content}}
      ],
    },
{{/allMessages}}
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
