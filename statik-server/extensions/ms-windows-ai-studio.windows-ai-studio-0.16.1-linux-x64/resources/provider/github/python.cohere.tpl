"""Run this model in Python

> pip install cohere
"""
import os
from cohere import Client

# To authenticate with the model you will need to generate a personal access token (PAT) in your GitHub settings.
# Create your PAT token by following instructions here: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
client = Client(
    base_url = "https://models.github.ai/inference",
    api_key = os.environ["GITHUB_TOKEN"],
)

response = client.chat(
    model = "{{{model}}}",
{{#parameters.systemWithQuote}}
    preamble = {{{parameters.systemWithQuote}}},
{{/parameters.systemWithQuote}}
{{#messages}}
{{#isUser}}
{{#content}}
{{#isText}}
{{#cohereToolResult}}
    message = "", # Cannot specify both message and tool_results unless in single hop mode
{{/cohereToolResult}}
{{^cohereToolResult}}
{{#isCohereMessage}}
    message = {{{textWithQuote}}},
{{/isCohereMessage}}
{{/cohereToolResult}}
{{/isText}}
{{/content}}
{{/isUser}}
{{/messages}}
    chat_history = [
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
    ],
{{#cohereTools}}
    tools = {{{cohereTools}}},
{{/cohereTools}}
{{#cohereToolResult}}
    tool_results = {{{cohereToolResult}}},
{{/cohereToolResult}}
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

{{^cohereTools}}
print(response.text)
{{/cohereTools}}
{{#cohereTools}}
if response.tool_calls:
    print(response.tool_calls)
else:
    print(response.text)
{{/cohereTools}}