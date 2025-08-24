# In-Code Evaluation: How to Evaluate Your AI App

Evaluation is a critical process to measure the performance, quality, and effectiveness of AI apps. This guide will help you evaluate your AI apps with the promptflow-evals SDK and view results in AI Toolkit.

Note: Currently, this guide only applies to AI apps implemented in Python.

## Step 1: Install SDK
Install the `promptflow-evals` SDK:

```shell
pip install promptflow-evals
```

## Step 2: Prepare dataset for evaluation
Before evaluation, prepare a dataset with inputs and expected outputs (ground truth). Ensure the dataset is saved in JSONL format, as the `promptflow-evals` SDK only supports this format.

Here's a sample dataset for QA apps:

```json
//sample_qa_data.jsonl

{"question": "If it's raining, what should you carry with you?","ground_truth": "If it's raining, you should carry an umbrella, a raincoat, and waterproof shoes."}
{"question": "If you drop a glass on the floor, what will likely happen?","ground_truth": "If you drop a glass on the floor, it will likely break."}
{"question": "Can an elephant fit into a refrigerator?","ground_truth": "No, an elephant cannot fit into a refrigerator."}
{"question": "How else can you say 'It's raining cats and dogs'?","ground_truth": "It's pouring heavily."}
{"question": "If you have 10 apples and give 4 away, how many apples do you have left?","ground_truth": "If you have 10 apples and give 4 away, you have 6 apples left."}
```

## Step 3: Define evaluators
In this step, you need to define evaluators to calculate the metrics. The `promptflow-evals` SDK provides some built-in evaluators for performance & quality measurement.

* GroundednessEvaluator
* RelevanceEvaluator
* CoherenceEvaluator
* FluencyEvaluator
* SimilarityEvaluator
* F1ScoreEvaluator

Except for `F1ScoreEvaluator`, the others are AI-assisted evaluators. And when using AI-assisted evaluators, you must specify a GPT model for the calculation process. Choose a GPT model, set it as your `model_config`, and pass it to the evaluators.

Here's a sample to use SimilarityEvaluator and CoherenceEvaluator with gpt-4o model:

```python
import os
from promptflow.core import AzureOpenAIModelConfiguration
from promptflow.evals.evaluators import CoherenceEvaluator,SimilarityEvaluator

model_config = AzureOpenAIModelConfiguration(
    azure_deployment="gpt-4o",
    azure_endpoint=os.environ.get("AZURE_OPENAI_ENDPOINT"),
    api_key=os.environ.get("AZURE_OPENAI_API_KEY"),
    api_version=os.environ.get("AZURE_OPENAI_API_VERSION"),
)

similarity_evaluator = SimilarityEvaluator(model_config)
coherence_evaluator = CoherenceEvaluator(model_config)
```

The SDK allows user to define a custom evaluator for specific evaluation needs. See the advanced usage for more details.

## Step 4: Wrap your app into the evaluation target
Assuming there's already an AI app that answers user questions, it can be easily wrapped into the evaluation target by creating a new function.

Here’s the sample code snippet:

```python
# Convert the AI app to evaluation target
def target_app(question):
    answer = my_app(question)
    return { "answer": answer }

# Assuming that there’s already an existing AI app
def my_app(question: str) -> str:
    chat_completion = client.chat.completions.create(
        messages=[
            {
                "role": "system",
                "content": system_prompt,
            },
            {"role": "user", "content": question},
        ],
        model=model,
    )
return chat_completion.choices[0].message.content
```

## Step 5: Run evaluation
You can combine multiple evaluators with the `evaluate()` API on the dataset. To ensure the `evaluate()` can correctly parse the data, you must specify column mapping to map the dataset column to keywords accepted by the evaluators.

Here's a sample code snippet to evaluate the target app with dataset and built-in evaluators:

```python
# evaluate.py

from promptflow.evals.evaluate import evaluate

if __name__ == "__main__":
    # set file path to save the result
    result_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "evaluation_result.json"
)
    # run evaluation
    evaluate(
        target=target_app,
        # file path to the dataset
        data="sample_qa_data.jsonl",
        evaluators={
            "similarity": similarity_evaluator,
            "coherence": coherence_evaluator,
        },
        # column mapping
        evaluator_config={
            "default": {
                "question": "${data.question}",
                "ground_truth": "${data.ground_truth}",
                "answer": "${target.answer}",
            }
        },
        # output the evaluation result to a file
        output_path=result_path
    )
```

Run the above code snippet to save the evaluation results as a JSON file.

```bash
python evaluate.py
```

## Step 6: View result

In VS Code:
1.	`Select View` > `Command Palette` > `AI Toolkit: View Evaluations`
2.	Browse and select the evaluation results JSON file
Then the evaluation result will be visualized in AI Toolkit for further analysis.
That’s all the steps to run evaluation with the `promptflow-evals` SDK and view the result in AI Toolkit.

## Additional usage

### Built-in evaluators

Name | Required data | AI-assisted
| - | - | - |
GroundednessEvaluator| answer, context| Yes
RelevanceEvaluator | question, answer, context | Yes
CoherenceEvaluator | question, answer | Yes
FluencyEvaluator | question, answer | Yes
SimilarityEvaluator | question, answer, ground_truth | Yes
F1ScoreEvaluator | answer, ground_truth | No

Different evaluators require different data according to its algorithm to calculate the metrics:

* question: the question sent into the AI app.
* answer: the response to question generated by the AI app.
* context: the source that response is generated with respect to (that is, grounding documents)
* ground_truth: the expected response to question as the true answer.
Refer to the documentation for more details about these evaluators.

### Custom evaluator

Built-in evaluators are a great starting point for evaluating your app. However, you might want to build your own evaluator for your specific evaluation needs.

#### Code-based evaluators
Sometimes, you don't need an LLM for certain evaluation metrics. Code-based evaluators offer flexibility for defining these metrics.

Below is a sample evaluator to calculate if the answer from AI app is concise or not.

```python
def concise_evaluator(answer, ground_truth):
    score = 1 if len(answer) < 2 * len(ground_truth) else 0
return { "concise_score": score }
```

With code-based evaluators, you can import evaluators or algorithm from other packages (e.g., LangChain) to calculate the metric score.

#### Prompt-based evaluators

You can create a prompt-based custom evaluator based on a Prompty file. Prompty is a file with .prompty extension for developing prompt template. Given an example apology.prompty file that looks like the following:
```yaml
---
name: Apology Evaluator
description: Apology Evaluator for QA scenario
model:
  api: chat
  configuration:
    type: azure_openai
    connection: open_ai_connection
    azure_deployment: gpt-4
  parameters:
    temperature: 0.2
    response_format: { "type": "json_object" }
inputs:
  question:
    type: string
  answer:
    type: string
outputs:
  apology:
    type: int
---
system:
You are an AI tool that determines if, in a chat conversation, the assistant apologized, like say sorry.
Only provide a response of {"apology": 0} or {"apology": 1} so that the output is valid JSON.
Give a apology of 1 if apologized in the chat conversation.
```

Then import the prompty file as an evaluator:

```python
from promptflow.client import load_flow

# set the path of prompty file
prompty_path = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "apology.prompty"
)

# load apology evaluator from prompty file using promptflow
apology_evaluator = load_flow(source=prompty_path, model={"configuration": model_config})
```

## Reference
* [Evaluate with the prompt flow SDK](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/develop/flow-evaluate-sdk)
