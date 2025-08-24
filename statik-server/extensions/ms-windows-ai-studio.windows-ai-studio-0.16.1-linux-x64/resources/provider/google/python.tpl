"""Run this model in Python

> pip install google-generativeai
"""
import os
{{#files.0}}
import time
{{/files.0}}
import google.generativeai as genai

{{#toolResults}}
def {{{name}}}():
    return "{{toolResult}}"

{{/toolResults}}
genai.configure(api_key=os.environ["GEMINI_API_KEY"])

{{#files.0}}
def upload_to_gemini(path, mime_type=None):
  """Uploads the given file to Gemini.

  See https://ai.google.dev/gemini-api/docs/prompting_with_media
  """
  file = genai.upload_file(path, mime_type=mime_type)
  print(f"Uploaded file '{file.display_name}' as: {file.uri}")
  return file

def wait_for_files_active(files):
  """Waits for the given files to be active.

  Some files uploaded to the Gemini API need to be processed before they can be
  used as prompt inputs. The status can be seen by querying the file's "state"
  field.

  This implementation uses a simple blocking polling loop. Production code
  should probably employ a more sophisticated approach.
  """
  print("Waiting for file processing...")
  for name in (file.name for file in files):
    file = genai.get_file(name)
    while file.state.name == "PROCESSING":
      print(".", end="", flush=True)
      time.sleep(10)
      file = genai.get_file(name)
    if file.state.name != "ACTIVE":
      raise Exception(f"File {file.name} failed to process")
  print("...all files ready")
  print()

{{/files.0}}
# Create the model
generation_config = {
{{#parameters.temperature}}
  "temperature": {{.}},
{{/parameters.temperature}}
{{#parameters.top_p}}
  "top_p": {{.}},
{{/parameters.top_p}}
{{#parameters.max_tokens}}
  "max_output_tokens": {{.}},
{{/parameters.max_tokens}}
{{#parameters.presence_penalty}}
  "presence_penalty": {{.}},
{{/parameters.presence_penalty}}
{{#parameters.frequency_penalty}}
  "frequency_penalty": {{.}},
{{/parameters.frequency_penalty}}
  "response_mime_type": "{{{parameters.response_mime_type}}}",
{{#parameters.response_schema}}
  "response_schema": {{{.}}},
{{/parameters.response_schema}}
}

model = genai.GenerativeModel(
  model_name={{{model}}},
  generation_config=generation_config,
{{#tools}}
  tools = {{{tools}}},
{{/tools}}
{{#parameters.system_prompt}}
  system_instruction={{{.}}},
{{/parameters.system_prompt}}
)

{{#files.0}}
# TODO Make these files available on the local file system
# You may need to update the file paths
files = [
{{#files}}
  upload_to_gemini({{{localPath}}}, mime_type={{{mimeType}}}),
{{/files}}
]

# Some files have a processing delay. Wait for them to be ready.
wait_for_files_active(files)

{{/files.0}}
contents = [
{{#historyMessages}}
  {
    "role": {{{role}}},
    "parts": [
{{#content}}
{{#isFile}}
      files[{{{fileIndex}}}],
{{/isFile}}
{{#isText}}
      {{{textWithQuote}}},
{{/isText}}
{{#isToolUse}}
      {
        "function_call": {
          "name": "{{{functionCall.name}}}",
          "args": {{{functionCall.args}}},
        },
      },
{{/isToolUse}}
{{#isToolResult}}
      {
        "function_response": {
          "name": "{{{functionResponse.name}}}",
          "response": {{{functionResponse.response}}},
        },
      },
{{/isToolResult}}
{{/content}}
    ],
  },
{{/historyMessages}}
  {
    "role": "user",
    "parts": [
      {
        "text": {{{messageWithQuote}}},
      },
    ],
  },
]

while True:
  response = model.generate_content(contents=contents)
  print(response.candidates[0].content.parts)
  
  should_continue = False
  contents.append(response.candidates[0].content)
  for part in response.candidates[0].content.parts:
    if part.function_call:
      should_continue = True
      contents.append({
        "role": "user",
        "parts": [
          {
            "function_response": {
              "name": part.function_call.name,
              "response": {
                "result": locals()[part.function_call.name](),
              }
            }
          }
        ]
      })
  if not should_continue:
    break