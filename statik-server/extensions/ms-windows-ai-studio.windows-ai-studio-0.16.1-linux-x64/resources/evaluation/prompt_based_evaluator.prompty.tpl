---
name: {{name}}
{{#description}}
description: {{description}}
{{/description}}
model:
  api: chat
  parameters:
    temperature: 0.0
    max_tokens: 4096
    top_p: 1.0
    presence_penalty: 0
    frequency_penalty: 0
    response_format:
      type: text
inputs:
{{#inputs}}
  {{.}}:
    type: string
{{/inputs}}
---
{{content}}