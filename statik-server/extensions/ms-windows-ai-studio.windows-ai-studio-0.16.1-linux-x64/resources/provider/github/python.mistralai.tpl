"""Run this model in Python

> pip install mistralai
"""
{{#hasImage}}
import base64
{{/hasImage}}
import os
from mistralai import Mistral, UserMessage, AssistantMessage, SystemMessage, ToolMessage

# To authenticate with the model you will need to generate a personal access token (PAT) in your GitHub settings.
# Create your PAT token by following instructions here: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
client = Mistral(
    server_url = "https://models.github.ai/inference",
    api_key = os.environ["GITHUB_TOKEN"],
)

{{#hasImage}}
def encodeImage(path, mime_type):
    with open(path, "rb") as image:
        encoded = base64.b64encode(image.read())
    return f"data:{mime_type};base64,{encoded.decode()}"

{{/hasImage}}
response = client.chat.complete(
    model = "{{{model}}}",
    messages = [
{{#parameters.systemWithQuote}}
        SystemMessage(content = {{{parameters.systemWithQuote}}}),
{{/parameters.systemWithQuote}}
{{#messages}}
{{#isUser}}
        UserMessage(content = [
{{#content}}
{{#isText}}
            {
                "type": "text",
                "text": {{{textWithQuote}}},
            },
{{/isText}}
{{#isImage}}
            {
                "type": "image_url",
                "image_url": encodeImage({{{localPathWithQuote}}}, "{{{mimeType}}}"),
            },
{{/isImage}}
{{/content}}
        ]),
{{/isUser}}
{{#isAssistant}}
        AssistantMessage(
            content = {{{textWithQuote}}},
{{#tool_calls}}
            tool_calls = [
                {
                    "id": "{{{id}}}",
                    "index": None,
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
    ],
{{#tools}}
    tools = {{{tools}}},
{{/tools}}
{{#parameters.max_tokens}}
    max_tokens = {{parameters.max_tokens}},
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

{{^tools}}
print(response.choices[0].message.content)
{{/tools}}
{{#tools}}
if response.choices[0].message.tool_calls:
    print(response.choices[0].message.tool_calls)
else:
    print(response.choices[0].message.content)
{{/tools}}