"""Connect model with mcp tools in Python
# Run this python script
> pip install openai-agents==0.*
> python <this-script-path>.py
"""
import asyncio
{{#hasImage}}
import base64
{{/hasImage}}
import json
import logging
import os
import sys
from typing import Any

from agents import Agent, AgentOutputSchemaBase, ModelSettings, OpenAIChatCompletionsModel, Runner, set_tracing_disabled
from agents.mcp import MCPServerSse, MCPServerStdio

from openai import AsyncOpenAI

{{#hasImage}}
def encodeImage(path, mime_type):
    with open(path, "rb") as image:
        encoded = base64.b64encode(image.read())
    return f"data:{mime_type};base64,{encoded.decode()}"

{{/hasImage}}
{{#response_format_json_schema}}
class CustomOutputSchema(AgentOutputSchemaBase):
    def is_plain_text(self) -> bool:
        return False

    def name(self) -> str:
        return "CustomOutputSchema"

    def json_schema(self) -> dict[str, Any]:
        return  {{{response_format_json_schema.schema}}}
    def is_strict_json_schema(self) -> bool:
        return {{{response_format_json_schema.strict}}}

    def validate_json(self, json_str: str) -> Any:
        return json.loads(json_str)

{{/response_format_json_schema}}
async def main():
    openaiClient = AsyncOpenAI(
        api_key = os.environ["OPENAI_API_KEY"],
    )

    # init MCP servers
    servers = [
{{#mcpConfigs}}
{{#isStdio}}
        MCPServerStdio(
            params = {
                "command": {{{commandWithQuote}}},
                "args": [
{{#argsWithQuote}}
                    {{{.}}},
{{/argsWithQuote}}
                ],
                "env": {
{{#env}}
                    "{{.}}": os.environ["{{.}}"],
{{/env}}
                }
            },
            name = "{{{serverName}}}",
            client_session_timeout_seconds = 30,
        ),
{{/isStdio}}
{{#isSse}}
        MCPServerSse(
            params = {
                "url": {{{urlWithQuote}}},
                "timeout": 30,
            },
            name = "{{{serverName}}}",
            client_session_timeout_seconds = 30,
        )
{{/isSse}}
{{/mcpConfigs}}
    ]

    # setup logger
    logger = logging.getLogger("openai.agents")
    logger.setLevel(logging.DEBUG)
    logHandler = logging.StreamHandler(sys.stdout)
    logHandler.setFormatter(logging.Formatter('[Agent Log]: %(message)s'))
    logger.addHandler(logHandler)
    set_tracing_disabled(True)

    agent = Agent(
        name = "agent",
{{#parameters.systemWithQuote}}
        instructions = {{{parameters.systemWithQuote}}},
{{/parameters.systemWithQuote}}
        mcp_servers = servers,
        model = OpenAIChatCompletionsModel("{{model}}", openaiClient),
        model_settings = ModelSettings(
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
{{#parameters.max_tokens}}
{{^o1}}
            max_tokens = {{parameters.max_tokens}},
{{/o1}}
{{/parameters.max_tokens}}
        ),
{{#response_format_json_schema}}
        output_type=CustomOutputSchema(),
{{/response_format_json_schema}}
    )

    try:
        for server in servers:
            await server.connect()
        result = await Runner.run(
            agent,
            [
{{#messages}}
{{#isUser}}
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
{{/isUser}}
{{#isAssistant}}
                {
                    "id": "",
                    "type": "message",
                    "role": "{{role}}",
                    "status": "completed",
                    "content": [
{{#content}}
{{#isText}}
                        {
                            "type": "output_text",
                            "text": {{{textWithQuote}}},
                            "annotations": [],
                        },
{{/isText}}
{{/content}}
                    ],
                },
{{/isAssistant}}
{{/messages}}
            ]
        )
        print("")
        print("[Agent Output]: " + str(result.final_output))
    except Exception as e:
        print(f"\nError: {str(e)}")
    finally:
        for server in servers:
            await server.cleanup()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except asyncio.exceptions.CancelledError:
        # ignore cleanup cancel error
        pass