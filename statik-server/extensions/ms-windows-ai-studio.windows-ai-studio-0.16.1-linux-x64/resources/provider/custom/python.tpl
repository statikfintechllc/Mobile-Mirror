"""Run this model in Python

> pip install openai
"""
{{#hasImage}}
import base64
{{/hasImage}}
import os
{{#isAzureOpenAI}}
from openai import AzureOpenAI
{{/isAzureOpenAI}}
{{^isAzureOpenAI}}
from openai import OpenAI
{{/isAzureOpenAI}}

{{#isAzureOpenAI}}
client = AzureOpenAI(
    azure_endpoint = "{{{baseURL}}}",
    api_key = os.environ["CUSTOM_OPENAI_API_KEY"],
    api_version = "2024-12-01-preview",
)
{{/isAzureOpenAI}}
{{^isAzureOpenAI}}
client = OpenAI(
    base_url = "{{{baseURL}}}",
    api_key = os.environ["CUSTOM_OPENAI_API_KEY"],
)
{{/isAzureOpenAI}}

{{#hasImage}}
def encodeImage(path, mime_type):
    with open(path, "rb") as image:
        encoded = base64.b64encode(image.read())
    return f"data:{mime_type};base64,{encoded.decode()}"

{{/hasImage}}
{{#toolResults}}
def {{{name}}}():
    return "{{toolResult}}"

{{/toolResults}}
messages = [
{{#parameters.systemWithQuote}}
    {
        "role": "system",
        "content": {{{parameters.systemWithQuote}}},
    },
{{/parameters.systemWithQuote}}
{{#messages}}
    {
        "role": "{{role}}",
        "content": [
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
                "image_url": { "url": encodeImage({{{localPathWithQuote}}}, "{{{mimeType}}}") },
            },
{{/isImage}}
{{/content}}
        ],
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
{{#isTool}}
        "tool_call_id": "{{{tool_call_id}}}",
{{/isTool}}
    },
{{/messages}}
]

{{#tools}}
tools = {{{tools}}}

{{/tools}}
{{#response_format}}
response_format = {{{response_format}}}

{{/response_format}}
while True:
    response = client.chat.completions.create(
        messages = messages,
        model = "{{model}}",
{{#tools}}
        tools = tools,
{{/tools}}
{{#response_format}}
        response_format = response_format,
{{/response_format}}
{{#parameters.max_tokens}}
{{#o1}}
        max_completion_tokens = {{parameters.max_tokens}},
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

    if response.choices[0].message.tool_calls:
        print(response.choices[0].message.tool_calls)
        messages.append(response.choices[0].message)
        for tool_call in response.choices[0].message.tool_calls:
            messages.append({
                "role": "tool",
                "tool_call_id": tool_call.id,
                "content": [
                    {
                        "type": "text",
                        "text": locals()[tool_call.function.name](),
                    },
                ],
            })
    else:
        print(response.choices[0].message.content)
        break
