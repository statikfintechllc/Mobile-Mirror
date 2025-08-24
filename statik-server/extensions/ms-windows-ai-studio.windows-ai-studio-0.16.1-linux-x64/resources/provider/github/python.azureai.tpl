"""Run this model in Python

> pip install azure-ai-inference
"""
{{#hasImage}}
import base64
{{/hasImage}}
import os
from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import AssistantMessage, SystemMessage, UserMessage, ToolMessage
from azure.ai.inference.models import ImageContentItem, ImageUrl, TextContentItem
{{#response_format_json_schema}}
from azure.ai.inference.models import JsonSchemaFormat
{{/response_format_json_schema}}
from azure.core.credentials import AzureKeyCredential

# To authenticate with the model you will need to generate a personal access token (PAT) in your GitHub settings.
# Create your PAT token by following instructions here: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
client = ChatCompletionsClient(
    endpoint = "https://models.github.ai/inference",
    credential = AzureKeyCredential(os.environ["GITHUB_TOKEN"]),
{{#o1}}
    api_version = "2024-12-01-preview",
{{/o1}}
{{#api_version}}
    api_version = "{{api_version}}",
{{/api_version}}
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

{{#tools}}
tools = {{{tools}}}

{{/tools}}
{{#response_format_json_schema}}
response_format = JsonSchemaFormat(
    name = "{{response_format_json_schema.name}}",
    description = "{{response_format_json_schema.description}}",
    strict = {{response_format_json_schema.strict}},
    schema = {{{response_format_json_schema.schema}}}
)

{{/response_format_json_schema}}
{{#response_format_text}}
response_format = "text"

{{/response_format_text}}
while True:
    response = client.complete(
        messages = messages,
        model = "{{{model}}}",
{{#tools}}
        tools = tools,
{{/tools}}
{{#response_format_text}}
        response_format = response_format,
{{/response_format_text}}
{{#response_format_json_schema}}
        response_format = response_format,
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

    if response.choices[0].message.tool_calls:
        print(response.choices[0].message.tool_calls)
        messages.append(response.choices[0].message)
        for tool_call in response.choices[0].message.tool_calls:
            messages.append(ToolMessage(
                content=locals()[tool_call.function.name](),
                tool_call_id=tool_call.id,
            ))
    else:
        print(response.choices[0].message.content)
        break
