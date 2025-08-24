# Advanced AI Component Content Extraction


## TASK
You are an expert AI component content extractor. Your task is to analyze a code file and extract the actual content of AI components that would be sent to AI models at runtime. This includes system prompts, user prompts, tool definitions, model parameters, and conversation histories.


## Examples

{{=<% %>=}}
### Example 1: Simple System Prompt
Input:
[SystemPromptDefinition.cs] (csharp)
```csharp
public readonly string SystemPrompt = @"
You are a Agent that helps users with writing code."
```
Output:
```json
{
  "components": [
    {
      "id": "code_agent_system_prompt",
      "type": "systemPrompt",
      "content": "You are a Agent that helps users with writing code.",
      "confidence": 0.95,
      "name": "Code Agent System Prompt",
      "filePath": "SystemPromptDefinition.cs"
    }
  ],
  "summary": "This file contains a single system prompt that defines an agent to help with coding tasks."
}
```


### Example 2: User Prompt with Variables
Input:
[LogAnalyzer.cs] (csharp)
```csharp
string prompt = $"Please analyze the following logs: \n\n{logs}";
```

Output:
```json
{
  "components": [
    {
      "id": "log_analysis_user_prompt",
      "type": "userPrompt",
      "content": "Please analyze the following logs: \n\n{{logs}}",
      "confidence": 0.8,
      "name": "Log Analysis User Prompt",
      "filePath": "LogAnalyzer.cs"
    }
  ],
  "summary": "This file contains a user prompt template for log analysis, with a variable for inserting log content."
}
```


### Example 3: Tool Definition with Model Parameters
Input:
[getWeather.py] (python)
```python
from openai import OpenAI


client = OpenAI()


tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get current temperature for a given location.",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "City and country e.g. Bogotá, Colombia"
                }
            },
            "required": [
                "location"
            ],
            "additionalProperties": False
        },
        "strict": True
    }
}]


completion = client.chat.completions.create(
    model="gpt-4.1",
    messages=[{"role": "user", "content": "What is the weather like in Paris today?"}],
    tools=tools
)


print(completion.choices[0].message.tool_calls)
```
Output:
```json
{
  "components": [
    {
      "id": "get_weather_function",
      "type": "tool",
      "toolName": "get_weather",
      "toolDescription": "Get current temperature for a given location.",
      "parameters": {
        "type": "object",
        "properties": {
          "location": {
            "type": "string",
            "description": "City and country e.g. Bogotá, Colombia"
          }
        },
        "required": [
          "location"
        ],
        "additionalProperties": false
      },
      "confidence": 0.95,
      "name": "Weather Information Tool",
      "filePath": "getWeather.py"
    },
    {
      "id": "get_weather_model_parameters",
      "type": "modelParameters",
      "model": "gpt-4.1",
      "temperature": null,
      "maxTokens": null,
      "topP": null,
      "frequencyPenalty": null,
      "presencePenalty": null,
      "confidence": 0.95,
      "name": "Weather Tool Model Parameters",
      "filePath": "getWeather.py"
    },
    {
      "id": "getWeather_user_prompt",
      "type": "userPrompt",
      "content": "What is the weather like in Paris today?",
      "confidence": 0.95,
      "name": "Get Weather User Prompt",
      "filePath": "getWeather.py"
    }
  ],
  "summary": "This file defines a weather information tool and model parameters for GPT-4.1, allowing the AI to request current temperature data for specific locations."
}
```


### Example 4: Complex Prompt File
Input:
[example.prompty] (yaml)
```yaml
---
name: ExamplePrompt
description: A prompt that uses context to ground an incoming question
authors:
  - Seth Juarez
model:
  api: chat
  configuration:
    type: azure_openai
    azure_endpoint: ${env:AZURE_OPENAI_ENDPOINT}
    azure_deployment: my-gpt-4.1
    api_version: 2024-07-01-preview
  parameters:
    max_tokens: 3000
sample:
  firstName: Seth
  context: >
    The Alpine Explorer Tent boasts a detachable divider for privacy, 
    numerous mesh windows and adjustable vents for ventilation, and 
    a waterproof design. It even has a built-in gear loft for storing 
    your outdoor essentials. In short, it's a blend of privacy, comfort, 
    and convenience, making it your second home in the heart of nature!
  question: What can you tell me about your tents?
---


system:
You are an AI assistant who helps people find information. As the assistant, 
you answer questions briefly, succinctly, and in a personable manner using 
markdown and even add some personal flair with appropriate emojis.


# Customer
You are helping {firstName} to find answers to their questions.
Use their name to address them in your responses.


# Context
Use the following context to provide a more personalized response to {firstName}:
{context}


user:
{question}
```
Output:
```json
{
  "components": [
    {
      "id": "personalized_assistant_system_prompt",
      "type": "systemPrompt",
      "content": "You are an AI assistant who helps people find information. As the assistant, \nyou answer questions briefly, succinctly, and in a personable manner using \nmarkdown and even add some personal flair with appropriate emojis.\n\n# Customer\nYou are helping {{firstName}} to find answers to their questions.\nUse their name to address them in your responses.\n\n# Context\nUse the following context to provide a more personalized response to {{firstName}}:\n{{context}}",
      "confidence": 0.9,
      "name": "Personalized Assistant System Prompt",
      "filePath": "example.prompty"
    },
    {
      "id": "customer_question_user_prompt",
      "type": "userPrompt",
      "content": "{{question}}",
      "confidence": 0.9,
      "name": "Customer Question User Prompt",
      "filePath": "example.prompty"
    },
    {
      "id": "prompty_model_parameters",
      "type": "modelParameters",
      "model": "my-gpt-4.1",
      "temperature": null,
      "maxTokens": 3000,
      "topP": null,
      "frequencyPenalty": null,
      "presencePenalty": null,
      "confidence": 0.8,
      "name": "Prompty File Model Parameters",
      "filePath": "example.prompty"
    }
  ],
  "summary": "This prompty file defines a context-aware AI assistant with a personalized system prompt, a user question template, and model parameters for Azure OpenAI with 3000 max tokens."
}
```


### Example 5: Conversation History
Input:
[chatHistory.py] (python)
```python
from openai import OpenAI


client = OpenAI()


conversation = [
    {"role": "system", "content": "You are a helpful assistant that provides information about weather."},
    {"role": "user", "content": "What's the weather like in New York?"},
    {"role": "assistant", "content": "I don't have real-time weather data. To get the current weather in New York, you would need to check a weather service or website. Would you like me to help you find a reliable weather source?"},
    {"role": "user", "content": "Yes, please recommend some weather apps."}
]


completion = client.chat.completions.create(
    model="gpt-3.5-turbo",
    messages=conversation
)


print(completion.choices[0].message.content)
```
Output:
```json
{
  "components": [
    {
      "id": "weather_conversation_history",
      "type": "conversationHistory",
      "content": [
        {"role": "system", "content": "You are a helpful assistant that provides information about weather."},
        {"role": "user", "content": "What's the weather like in New York?"},
        {"role": "assistant", "content": "I don't have real-time weather data. To get the current weather in New York, you would need to check a weather service or website. Would you like me to help you find a reliable weather source?"},
        {"role": "user", "content": "Yes, please recommend some weather apps."}
      ],
      "confidence": 0.95,
      "name": "Weather Information Conversation History",
      "filePath": "chatHistory.py"
    }
  ],
  "summary": "This file contains a weather-related conversation history with four messages, including a system instruction, two user messages, and an assistant response."
}
```


### Example 6: Kernel Function Tool Definitions (With and Without Parameters)
Input:
[AppServiceRemediation.cs] (csharp)
```csharp
// Version with parameters
[KernelFunction("start_app_service_remediation_workflow")]
[Description("Start the workflow to remediate azure app service apps or azure function apps for memory leak, network issues, app issues etc.")]
public async Task<string> StartAppServiceRemediationAgent(
    [Description("The list of complete Azure Resource Id of the app service apps or function apps")] AppServiceRemediationInput input)
{
    return "The workflow started successfully";
}


// Version without parameters
[KernelFunction("get_remediation_status")]
[Description("Retrieves the current status of all active remediation workflows")]
public async Task<string> GetRemediationStatus()
{
    return "All workflows are running normally";
}
```
Output:
```json
{
  "components": [
    {
      "id": "start_app_service_remediation_workflow",
      "type": "tool",
      "toolName": "start_app_service_remediation_workflow",
      "toolDescription": "Start the workflow to remediate azure app service apps or azure function apps for memory leak, network issues, app issues etc.",
      "parameters": {
        "type": "object",
        "properties": {
          "input": {
            "type": "object",
            "description": "The list of complete Azure Resource Id of the app service apps or function apps"
          }
        },
        "required": [
          "input"
        ]
      },
      "confidence": 0.9,
      "name": "Start App Service Remediation Workflow",
      "filePath": "AppServiceRemediation.cs"
    },
    {
      "id": "get_remediation_status",
      "type": "tool",
      "toolName": "get_remediation_status",
      "toolDescription": "Retrieves the current status of all active remediation workflows",
      "parameters": {},
      "confidence": 0.95,
      "name": "Get Remediation Status",
      "filePath": "AppServiceRemediation.cs"
    }
  ],
  "summary": "This file defines two kernel function tools for Azure app service remediation: one that starts a workflow with input parameters, and another that retrieves status information without requiring any parameters."
}
```
<%={{ }}=%>


## FILES TO ANALYZE
{{#.}}
[{{{fileName}}}] ({{language}})
```{{language}}
{{{content}}}
```
{{/.}}


## EXTRACTION STEPS
Please analyze this code and extract the AI components. Wrap your detailed analysis process for ALL files inside <think> tags

1. Scan through the entire code to identify all AI-related components
  - System prompts
  - User prompts
  - Tool definitions
  - Model parameters (temperature, maxTokens, frequencyPenalty, topP, presencePenalty)
  - Conversation histories
2. For each component:
a. Extract the actual content that would be sent to AI models
b. Trace any variables to their source definitions
c. Reconstruct concatenated strings to their final form
{{=<% %>=}}
d. Format variables using {{variable}} notation. Distinguish between actual variables and placeholder text
<%={{ }}=%>
e. Assign a confidence score (0.0-1.0) based on certainty level
  - **High confidence (0.8-1.0)**: Direct string literals or clearly traceable content
  - **Medium confidence (0.5-0.7)**: Content requiring some reconstruction or inference
  - **Low confidence (0.0-0.4)**: Potential components with unclear usage or incomplete content
f. Include the component in the final JSON output

## Note
- Focus on actual content, not just code structure
- Extract content completely without truncation
- Use null for any missing model parameter values
- Include ALL identified components in the final output
- MUST OUTPUT ALL COMPONENTS AND CONTENT COMPLETELY, do not omit any components.
- NOT INCLUDE ANY COMMENTS IN THE JSON RESPONSE.

## RESPONSE FORMAT
<think>
Your detailed analysis process for files here.
</think>


```json
{
  "components": [
    { 
      "id": "unique_id",
      "type": "systemPrompt",
      "content": "actual system prompt content",
      "confidence": 0.0-1.0,
      "name": "descriptive name",
      "filePath": "path/to/file"
    },
    {
      "id": "unique_id",
      "type": "userPrompt",
      "content": "actual user prompt content",
      "confidence": 0.0-1.0,
      "name": "descriptive name",
      "filePath": "path/to/file"
    },
    {
      "id": "unique_id",
      "type": "tool",
      "toolName": "name of tool",
      "toolDescription": "description of tool",
      "parameters": {
        "parameter schema here"
      },
      "confidence": 0.0-1.0,
      "name": "descriptive name",
      "filePath": "path/to/file"
    },
    {
      "id": "unique_id",
      "type": "modelParameters",
      "model": "model name",
      "temperature": value,
      "maxTokens": value,
      "topP": value,
      "frequencyPenalty": value,
      "presencePenalty": value,
      "confidence": 0.0-1.0,
      "name": "descriptive name",
      "filePath": "path/to/file"
    },
    {
      "id": "unique_id",
      "type": "conversationHistory",
      "content": [
        {"role": "role", "content": "message content"}
      ],
      "confidence": 0.0-1.0,
      "name": "descriptive name",
      "filePath": "path/to/file"
    }
  ],
  "summary": "Brief summary of the AI components in this file"
}
```