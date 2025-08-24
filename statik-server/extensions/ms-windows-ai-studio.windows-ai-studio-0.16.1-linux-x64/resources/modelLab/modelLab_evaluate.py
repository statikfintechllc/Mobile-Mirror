import argparse
from pathlib import Path
from typing import cast
from modelLab import logger

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, help="path to input config file")
    parser.add_argument("--model_config", required=True, help="path to input model config file")
    return parser.parse_args()

def main():
    args = parse_arguments()

    p = Path(args.model_config)
    if not p.exists():
        raise FileNotFoundError(f"Model config file {p} does not exist.")

    from olive.evaluator.metric_result import MetricResult
    from olive.model.config import ModelConfig
    from olive.resource_path import create_resource_path, LocalFile
    from olive.systems.accelerator_creator import create_accelerators
    from olive.systems.olive_system import OliveSystem
    from olive.workflows.run.config import RunConfig

    logger.info("Loading model and configuration ...")

    run_config = cast(RunConfig, RunConfig.parse_file_or_obj(args.config))

    engine = run_config.engine.create_engine(
        olive_config=run_config,
        azureml_client_config=None,
        workflow_id=run_config.workflow_id,
    )
    engine.initialize()

    accelerator_specs = create_accelerators(
        engine.target_config,
        skip_supported_eps_check=True,
        is_ep_required=True,
    )

    target: OliveSystem = engine.target_config.create_system()

    model_config_file: LocalFile = cast(LocalFile, create_resource_path(p))
    model_config = cast(
        ModelConfig,
        ModelConfig.parse_file_or_obj(model_config_file.get_path()),
    )

    logger.info("Evaluating model ...")
    result: MetricResult = target.evaluate_model(
        model_config=model_config,
        evaluator_config=engine.evaluator_config,
        accelerator=accelerator_specs[0],
    )

    output_file = Path(args.config).parent / "metrics.json"
    resultStr = str(result)
    with open(output_file, 'w') as file:
        file.write(resultStr)
    logger.info("Model lab succeeded for evaluation.\n%s", resultStr)

if __name__ == "__main__":
    main()
