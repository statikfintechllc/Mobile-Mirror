"""Run this model in Python

> pip install openai
"""
{{#hasImage}}
import base64
{{/hasImage}}
from openai import OpenAI

client = OpenAI(
    base_url = "{{{baseURL}}}",
    api_key = "unused", # required for the API but not used
)

{{#hasImage}}
def encodeImage(path, mime_type):
    with open(path, "rb") as image:
        encoded = base64.b64encode(image.read())
    return f"data:{mime_type};base64,{encoded.decode()}"

{{/hasImage}}
response = client.chat.completions.create(
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
        },
{{/messages}}
    ],
    model = "{{model}}",
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

print(response.choices[0].message.content)