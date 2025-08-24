"""Run this model in Python

> pip install openai
"""
import os
from openai import OpenAI

client = OpenAI(
    base_url = "{{{baseURL}}}",
    api_key = os.environ["NVIDIA_API_KEY"],
)

response = client.chat.completions.create(
    messages = [
{{#parameters.systemWithQuote}}
        {
{{#o1}}
            "role": "developer",
{{/o1}}
{{^o1}}
            "role": "system",
{{/o1}}
            "content": {{{parameters.systemWithQuote}}},
        },
{{/parameters.systemWithQuote}}
{{#messages}}
        {
            "role": "{{role}}",
            "content": {{{content.0.textWithQuote}}},
        },
{{/messages}}
    ],
    model = "{{{model}}}",
{{#response_format}}
    response_format = {{{response_format}}},
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

print(response.choices[0].message.content)