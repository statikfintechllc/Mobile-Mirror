"""Connect model using Azure AI Agent (Semantic Kernel SDK) in Python
# Run this python script
> pip install semantic-kernel[azure]
> python <this-script-path>.py
"""
import asyncio
from azure.identity.aio import DefaultAzureCredential
from semantic_kernel.agents import AzureAIAgent, AzureAIAgentThread
from semantic_kernel.contents import FunctionCallContent, FunctionResultContent
from semantic_kernel.contents.chat_message_content import ChatMessageContent
{{#tools.length}}
from semantic_kernel.functions import kernel_function
{{/tools.length}}
import os

# Azure AI Agent Configuration
ENDPOINT = "{{{projectEndpoint}}}"
MODEL_DEPLOYMENT_NAME = "{{model}}"

{{#tools.length}}
class MyPlugin:
{{/tools.length}}
{{#tools}}
    @kernel_function(description="{{description}}")
    def {{name}}(*args, **kwargs):
        return "{{toolResult}}"

{{/tools}}
AGENT_NAME = "ai-agent"
{{#parameters.systemWithQuote}}
AGENT_INSTRUCTIONS = {{{parameters.systemWithQuote}}}
{{/parameters.systemWithQuote}}
{{^parameters.systemWithQuote}}
AGENT_INSTRUCTIONS = "You are a helpful AI assistant."
{{/parameters.systemWithQuote}}

# User inputs for the conversation
USER_INPUTS = [
{{#messages}}
{{#isUser}}
{{#content}}
{{#isText}}
    {{{textWithQuote}}},
{{/isText}}
{{/content}}
{{/isUser}}
{{/messages}}
{{^messages}}
    "Hello",
{{/messages}}
]

async def handle_intermediate_steps(message: ChatMessageContent) -> None:
    if message.items:
        for item in message.items:
            if isinstance(item, FunctionResultContent):
                print(f"Function Result:> {item.result} for function: {item.name}")
            elif isinstance(item, FunctionCallContent):
                print(f"Function Call:> {item.name} with arguments: {item.arguments}")
            else:
                print(f"{item}")


async def create_agent(client) -> AzureAIAgent:
    """Create and configure the Azure AI Agent"""
    print(f"Creating agent definition for '{AGENT_NAME}'...")

    # Refer to Azure AI Agent docs for adding remote actions (e.g., Code Interpreter, File Search) in Foundry:
    # https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/agent-types/azure-ai-agent?pivots=programming-language-python#advanced-features
    agent_definition = await client.agents.create_agent(
        model=MODEL_DEPLOYMENT_NAME,
        name=AGENT_NAME,
        instructions=AGENT_INSTRUCTIONS,
{{#parameters.temperature}}
        temperature={{parameters.temperature}},
{{/parameters.temperature}}
{{#parameters.top_p}}
        top_p={{parameters.top_p}},
{{/parameters.top_p}}
    )
    print(f"Agent definition created with ID: {agent_definition.id}")

    print("Creating AzureAIAgent instance...")
    agent = AzureAIAgent(
        client=client,
        definition=agent_definition,
{{#tools.length}}
        plugins=[MyPlugin()],
{{/tools.length}}
    )
    print("AzureAIAgent instance created.")
    
    return agent


async def invoke_agent(agent: AzureAIAgent) -> None:
    """Invoke the agent with user inputs"""
    print("Starting conversation with the agent...")
    
    thread: AzureAIAgentThread = None

    # Process user messages
    for user_input in USER_INPUTS:
        print(f"\n# User: '{user_input}'")
        async for response_chunk in agent.invoke(
            messages=user_input,
            thread=thread,
            on_intermediate_message=handle_intermediate_steps,
{{#parameters.max_tokens}}
            max_completion_tokens={{parameters.max_tokens}},
{{/parameters.max_tokens}}
        ):
            if response_chunk and response_chunk.content:
                print(f"# Agent: {response_chunk.content}")
            if hasattr(response_chunk, 'thread') and response_chunk.thread:
                thread = response_chunk.thread

    print("\n--- All tasks completed successfully ---")

# Main Path
async def main() -> None:
    async with (
        DefaultAzureCredential() as creds,
        AzureAIAgent.create_client(credential=creds, endpoint=ENDPOINT) as client,
    ):
        # Step 1: Create the agent
        agent = await create_agent(client)
        
        # Step 2: Invoke the agent
        await invoke_agent(agent)

def run_main():
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nProgram interrupted by user")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("Program finished.")

if __name__ == "__main__":
    run_main()
