"""Run this model in Python

> pip install anthropic
"""
import anthropic
{{#hasImage}}
import base64
{{/hasImage}}
import os

client = anthropic.Anthropic(
    api_key = os.environ["ANTHROPIC_API_KEY"],
)

{{#hasImage}}
def encodeImage(path):
    with open(path, "rb") as image:
        encoded = base64.b64encode(image.read())
    return f"{encoded.decode()}"

{{/hasImage}}
{{#toolResults}}
def {{{name}}}():
    return "{{toolResult}}"

{{/toolResults}}
{{#tools}}
tools = {{{tools}}}

{{/tools}}
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

while True:
    message = client.messages.create(
        model = "{{model}}",
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
        messages = messages,
{{#tools}}
        tools = tools,
{{/tools}}
    )
    print(message.content)

    should_continue = False
    messages.append({
        "role": "assistant",
        "content": message.content,
    })
    content = []
    for content_block in message.content:
        if content_block.type == "tool_use":
            should_continue = True
            content.append({
                "type": "tool_result",
                "tool_use_id": content_block.id,
                "content": locals()[content_block.name](),
            })
    if should_continue:
        messages.append({
            "role": "user",
            "content": content,
        })
    else:
        break
