import argparse
import importlib
import math
import json
import logging
import os
import sys
import tempfile
from typing import Any
from azure.ai.evaluation import (
    evaluate,
    GroundednessEvaluator,
    RelevanceEvaluator,
    CoherenceEvaluator,
    FluencyEvaluator,
    SimilarityEvaluator,
    F1ScoreEvaluator,
    RougeScoreEvaluator,
    OpenAIModelConfiguration,
    AzureOpenAIModelConfiguration,
    GleuScoreEvaluator,
    BleuScoreEvaluator,
    MeteorScoreEvaluator,
    TaskAdherenceEvaluator,
    ToolCallAccuracyEvaluator,
    IntentResolutionEvaluator,
    RougeType
)
from promptflow._sdk._configuration import Configuration

# workaround to disable PF trace logging
Configuration.get_instance().set_config("trace.destination", "none")
logger = logging.getLogger("run_eval")

custom_evaluator_workspace = os.path.join(os.path.expanduser("~"), ".aitk", "evals", "custom_evaluators")
custom_evaluator_models = {}
if custom_evaluator_workspace not in sys.path:
    sys.path.append(custom_evaluator_workspace)

def get_model_config(judge_model):
    if judge_model == None:
        return None
    if judge_model["type"] == "openai":
        return OpenAIModelConfiguration(
            type="openai",
            model=judge_model["model"],
            base_url=judge_model["base_url"],
            api_key=judge_model["api_key"],
            organization="third-party",
        )
    elif judge_model["type"] == "azure_openai":
        return AzureOpenAIModelConfiguration(
            type="azure_openai",
            azure_deployment=judge_model["azure_deployment"],
            azure_endpoint=judge_model["azure_endpoint"],
            api_key=judge_model["api_key"]
        )

def get_evaluator(evaluator, default_model_config):
    if evaluator["type"] == "built-in":
        model_config = get_model_config(evaluator.get("judge_model"))
        model_config = model_config if model_config != None else default_model_config
        if model_config == None and evaluator["name"] in ["GroundednessEvaluator", "RelevanceEvaluator", "CoherenceEvaluator", "FluencyEvaluator", "SimilarityEvaluator"]:
            logger.error(f"No model configuration for {evaluator['name']}")
            exit(1)
        if evaluator["name"] == "GroundednessEvaluator":
            evaluator_name = "groundedness"
            evaluator_function = GroundednessEvaluator(model_config)
        elif evaluator["name"] == "RelevanceEvaluator":
            evaluator_name = "relevance"
            evaluator_function = RelevanceEvaluator(model_config)
        elif evaluator["name"] == "CoherenceEvaluator":
            evaluator_name = "coherence"
            evaluator_function = CoherenceEvaluator(model_config)
        elif evaluator["name"] == "FluencyEvaluator":
            evaluator_name = "fluency"
            evaluator_function = FluencyEvaluator(model_config)
        elif evaluator["name"] == "SimilarityEvaluator":
            evaluator_name = "similarity"
            evaluator_function = SimilarityEvaluator(model_config)
        elif evaluator["name"] == "F1ScoreEvaluator":
            evaluator_name = "f1_score"
            evaluator_function = F1ScoreEvaluator()
        elif evaluator["name"] == "RougeScoreEvaluator":
            evaluator_name = "rouge_score"
            evaluator_function = RougeScoreEvaluator(RougeType.ROUGE_1) # hardcoded to ROUGE-1
        elif evaluator["name"] == "GleuScoreEvaluator":
            evaluator_name = "gleu_score"
            evaluator_function = GleuScoreEvaluator()
        elif evaluator["name"] == "BleuScoreEvaluator":
            evaluator_name = "bleu_score"
            evaluator_function = BleuScoreEvaluator()
        elif evaluator["name"] == "MeteorScoreEvaluator":
            evaluator_name = "meteor_score"
            evaluator_function = MeteorScoreEvaluator()
        elif evaluator["name"] == "TaskAdherenceEvaluator":
            evaluator_name = "task_adherence"
            evaluator_function = TaskAdherenceEvaluator(model_config)
        elif evaluator["name"] == "ToolCallAccuracyEvaluator":
            evaluator_name = "tool_call_accuracy"
            evaluator_function = ToolCallAccuracyEvaluator(model_config)
        elif evaluator["name"] == "IntentResolutionEvaluator":
            evaluator_name = "intent_resolution"
            evaluator_function = IntentResolutionEvaluator(model_config)
        return evaluator_name, evaluator_function, evaluator.get("column_mapping")
    elif evaluator["type"] == "code-based":
        evaluator_name = evaluator["name"]
        if evaluator.get("enable_error_handling") is True:
            custom_evaluator = load_custom_evaluator(f"try_{evaluator_name}", evaluator["module_path"])
        else:
            custom_evaluator = load_custom_evaluator(evaluator_name, evaluator["module_path"])
        evaluator_function = custom_evaluator
        return evaluator_name, evaluator_function, evaluator.get("column_mapping")
    elif evaluator["type"] == "prompt-based":
        evaluator_name = evaluator["name"]
        model_config = get_model_config(evaluator.get("judge_model"))
        model_config = model_config if model_config != None else default_model_config
        if model_config == None:
            logger.error(f"No model configuration for {evaluator_name}")
            exit(1)
        custom_evaluator_models[evaluator_name] = model_config["model"] or model_config["azure_deployment"]
        custom_evaluator = load_custom_evaluator(evaluator_name, evaluator["module_path"])
        evaluator_function = custom_evaluator(model_config)
        return evaluator_name, evaluator_function, evaluator.get("column_mapping")
    return None

# validate if the evaluation result has at least one output column
def validate_evaluation_result(result):
    contains_outputs = False
    for row in result["rows"]:
        for key, value in row.items():
            if key.startswith("outputs."):
                contains_outputs = True
                if isinstance(value, float) and math.isnan(value):
                    logger.warning("Found nan value in output column")
                    # a specific exit code `102` for the case where
                    # nan value was found in the output column.
                    exit(102)

    if not contains_outputs:
        logger.warning("No output columns found in evaluation result")
        # a specific exit code `101` for the case where
        # no metrics were found from evaluation result.
        exit(101)

def run_evaluation(args):
    config = json.loads(args.config)
    run_config = config.get("run_config")
    default_model_config = get_model_config(config.get("judge_model"))
    default_column_mapping = config.get("column_mapping")
    if config.get("evaluators") == None or len(config["evaluators"]) == 0:
        logger.error("No evaluators specified in the config")
        exit(1)
    evaluators = [get_evaluator(evaluator, default_model_config) for evaluator in config["evaluators"]]
    evaluator_config = {}
    if default_column_mapping != None:
        evaluator_config["default"] = {
            "column_mapping": default_column_mapping
        }
    for evaluator in evaluators:
        if evaluator != None:
            evaluator_name, _, column_mapping = evaluator
            if column_mapping != None:
                evaluator_config[evaluator_name] = {
                    "column_mapping": column_mapping
                }
    dataset_path = config["dataset"]["path"]

    tmpname = None
    if run_config and type(run_config.get("row_numbers")) is list:
        # Since the SDK only support passing data via file, we have to filter the row and save it to a file
        row_numbers = run_config["row_numbers"]
        row_set = set(row_numbers)
        with tempfile.TemporaryFile("a", suffix=".jsonl", delete=False, encoding="utf-8") as tmp:
            dataset_path = tmp.name
            tmpname = tmp.name
            with open(config["dataset"]["path"], encoding="utf-8") as f:
                for i, line in enumerate(f):
                    if i in row_set:
                        tmp.write(line)
            if not dataset_path:
                logger.error(f"Invalid row_number '{row_numbers}'")
                exit(1)

    result = evaluate(
        evaluation_name=config["name"],
        data=dataset_path,
        evaluators=dict([(evaluator[0], evaluator[1]) for evaluator in evaluators if evaluator != None]),
        evaluator_config=evaluator_config,
    )

    if tmpname:
        os.remove(tmpname)

    return result

def load_custom_evaluator(evaluator_name, evaluator_path):
    try:
        evaluator_module = importlib.import_module(evaluator_path)
        custom_evaluator = getattr(evaluator_module, evaluator_name)
        return custom_evaluator
    except Exception as e:
        logger.error(f"Failed to load custom evaluator {evaluator_name} from {evaluator_path}")
        logger.error(e)
        exit(1)

def check_custom_evaluator_result(result):
    """
    Checks the result for errors in custom evaluator outputs and logs them if exists.

    Parameters:
    result (dict): The evaluation result.
    """
    for row in result["rows"]:
        for key, value in row.items():
            if (
                key.startswith("outputs.")
                and key.endswith(".aitk_error_code")
            ):
                evaluator_name = key.split(".")[1]
                model = custom_evaluator_models.get(evaluator_name, "Unknown model")
                error_info = {
                    "evaluator": evaluator_name,
                }
                # a specific exit code `103` for the case where
                # the response from custom evaluator is not a valid JSON.
                if (value == 103):
                    error_info["model"] = model
                    error_info["error"] = "Expect a valid JSON string or object from the response of evaluator, but an invalid JSON was received"
                    error_info["response"] = row.get(f"outputs.{evaluator_name}.aitk_actual_response", "Response Not Available")
                # a specific exit code `104` for the case where
                # the code based evaluator throws an exception .
                elif (value == 104):
                    error_info["error_message"] = row.get(f"outputs.{evaluator_name}.aitk_error_message", "Message Not Available")
                    error_info["exception"] = row.get(f"outputs.{evaluator_name}.aitk_error_exception", "Exception Not Available")
                print(f'An exception occurred while running the evaluator "{evaluator_name}":\n')
                print("=========== Evaluation Error Information ===========\n")
                print(json.dumps(error_info, indent=4))
                exit(value)

def save_evaluation_result(output_path: str, data_dict: Any):
    data_dict = replace_nan_with_string(data_dict)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data_dict, f)

    print(f'Evaluation results saved to "{output_path}".\n')

def replace_nan_with_string(data):
    if isinstance(data, dict):
        return {k: replace_nan_with_string(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [replace_nan_with_string(i) for i in data]
    elif isinstance(data, float) and math.isnan(data):
        return "NaN"
    else:
        return data

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run evaluation")
    parser.add_argument("-c", "--config", type=str, required=True, help="Json serialized evaluation config")
    parser.add_argument("-o", "--output", type=str, required=True, help="Evaluation output path")
    args = parser.parse_args()
    result = run_evaluation(args)
    check_custom_evaluator_result(result)
    save_evaluation_result(args.output, result)
    validate_evaluation_result(result)