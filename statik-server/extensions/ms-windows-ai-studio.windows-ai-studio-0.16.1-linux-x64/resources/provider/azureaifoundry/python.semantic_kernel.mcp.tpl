"""Connect model with mcp tools using Azure AI Agent (Semantic Kernel SDK) in Python
# Run this python script
> pip install semantic-kernel[mcp,azure]
> python <this-script-path>.py
"""
import asyncio
from contextlib import AsyncExitStack
from azure.identity.aio import DefaultAzureCredential
from semantic_kernel.agents import AzureAIAgent, AzureAIAgentThread
from semantic_kernel.contents import FunctionCallContent, FunctionResultContent
from semantic_kernel.contents.chat_message_content import ChatMessageContent
from semantic_kernel.connectors.mcp import MCPStdioPlugin, MCPSsePlugin
import os

# Azure AI Agent Configuration
ENDPOINT = "{{{projectEndpoint}}}"
MODEL_DEPLOYMENT_NAME = "{{model}}"

AGENT_NAME = "mcp-agent"
{{#parameters.systemWithQuote}}
AGENT_INSTRUCTIONS = {{{parameters.systemWithQuote}}}
{{/parameters.systemWithQuote}}
{{^parameters.systemWithQuote}}
AGENT_INSTRUCTIONS = "Use the provided tools to answer questions. You have access to MCP tools for various functionalities."
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

def create_mcp_plugins() -> list:
    return [
{{#mcpConfigs}}
{{#isStdio}}
        MCPStdioPlugin(
            name="{{{serverName}}}".replace("-", "_"),
            description="MCP server for {{{serverName}}}",
            command={{{commandWithQuote}}},
            args=[
{{#argsWithQuote}}
                {{{.}}},
{{/argsWithQuote}}
            ]{{#env}},
            env={
{{#env}}
                "{{.}}": os.environ.get("{{.}}", ""),
{{/env}}
            }{{/env}}
        ),
{{/isStdio}}
{{#isSse}}
        MCPSsePlugin(
            name="{{{serverName}}}".replace("-", "_"),
            description="MCP server for {{{serverName}}}",
            url={{{urlWithQuote}}}
        ),
{{/isSse}}
{{/mcpConfigs}}
    ]

async def connect_mcp_plugins(stack: AsyncExitStack) -> list:
    """Connect to MCP servers and return connected plugins"""
    mcp_plugins = create_mcp_plugins()
    print(f"Created {len(mcp_plugins)} MCP plugins")
    print("Connecting to MCP servers...")
    connected_plugins = []
    for i, plugin in enumerate(mcp_plugins):
        print(f"Connecting to {plugin.name}...")
        connected_plugin = await stack.enter_async_context(plugin)
        connected_plugins.append(connected_plugin)
        print(f"{plugin.name} connected successfully.")

    print(f"All {len(connected_plugins)} MCP servers connected!")
    return connected_plugins

async def handle_intermediate_steps(message: ChatMessageContent) -> None:
    if message.items:
        for item in message.items:
            if isinstance(item, FunctionResultContent):
                print(f"Function Result:> {item.result} for function: {item.name}")
            elif isinstance(item, FunctionCallContent):
                print(f"Function Call:> {item.name} with arguments: {item.arguments}")
            else:
                print(f"{item}")


async def create_agent(client, connected_plugins: list) -> AzureAIAgent:
    """Create and configure the Azure AI Agent with MCP plugins"""
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
        plugins=connected_plugins,
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
    async with AsyncExitStack() as stack:
        # Step 1: Connect to MCP plugins
        connected_plugins = await connect_mcp_plugins(stack)

        async with (
            DefaultAzureCredential() as creds,
            AzureAIAgent.create_client(credential=creds, endpoint=ENDPOINT) as client,
        ):
            # Step 2: Create the agent
            agent = await create_agent(client, connected_plugins)
            
            # Step 3: Invoke the agent
            await invoke_agent(agent)

    # Give a moment for cleanup to complete
    await asyncio.sleep(0.5)

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
