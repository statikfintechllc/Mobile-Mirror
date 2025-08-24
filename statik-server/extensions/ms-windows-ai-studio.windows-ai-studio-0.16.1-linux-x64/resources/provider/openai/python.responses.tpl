"""Run this model in Python

> pip install openai
"""
{{#hasImage}}
import base64
{{/hasImage}}
import os
from openai import OpenAI

client = OpenAI(
    api_key = os.environ["OPENAI_API_KEY"],
)

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
input = [
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

{{#tools}}
tools = {{{tools}}}

{{/tools}}
{{#response_format}}
text = {{{response_format}}}

{{/response_format}}
while True:
    response = client.responses.create(
    {{#parameters.systemWithQuote}}
        instructions = {{{parameters.systemWithQuote}}},
    {{/parameters.systemWithQuote}}
        input = input,
        model = "{{model}}",
    {{#tools}}
        tools = tools,
    {{/tools}}
    {{#response_format}}
        text = text,
    {{/response_format}}
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
    print(response.output)
    
    should_continue = False
    input.extend(response.output)
    for item in response.output:
        if item.type == "function_call":
            should_continue = True
            input.append({
                "type": "function_call_output",
                "call_id": item.call_id,
                "output": locals()[item.name]()
            })
    if not should_continue:
        break