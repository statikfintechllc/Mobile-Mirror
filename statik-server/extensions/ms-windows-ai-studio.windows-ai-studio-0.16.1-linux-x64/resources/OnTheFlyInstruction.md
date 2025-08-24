# Model Conversion

## Overview

The AI Toolkit for Visual Studio Code supports various models from catalogs like Azure AI Foundry and Hugging Face. These models need to be in the ONNX ([Open Neural Network Exchange](https://onnx.ai)) format before they could be run on AI Toolkit. ONNX is an open standard for representing machine learning models, which defines a common set of operators and a file format that enables models to be used across different hardware platforms. This tutorial will help you to migrate your models to ONNX format.

## Onnxruntime Environment Setup

Model conversion depends on the [model builder tool](https://onnxruntime.ai/docs/genai/howto/build-model.html) from onnxruntime_genai package for the conversion. Here is the setup guide:

1. Install Anaconda or Miniconda should your Python environment is not fully setup.

1. Create a dedicated conda environment for model builder, and install all necessary dependencies (onnx, torch, onnxruntime_genai, transformers):

    ```powershell
    conda create -n model_builder python==3.11 -y
    conda activate model_builder
    pip install onnx torch onnxruntime_genai==0.6.0 transformers
    ```

* For some latest models such as Phi-4-mini, you may need to install transformers from the Git development branch with all essential components for conversion:
   ```powershell
    pip install git+https://github.com/huggingface/transformers
   ```

## HuggingFace Guide

There are multiple ways to access hugging face model. For a beginner, command line interface for huggingface_hub provides a easy way to manage model repository. Commands below are based on well set-up Python environment.

1. A good approach to model repo is to get started with [cli installation](https://huggingface.co/docs/huggingface_hub/main/en/guides/cli#getting-started).

1. After completed setup, you could [download model repository](https://huggingface.co/docs/huggingface_hub/main/en/guides/cli#download-an-entire-repository), all files in the repo are used in conversion. 

## Create the Directory Structure

The AI Toolkit (AITK) will load ONNX format models from the AITK working directory, which are: `$HOME\.aitk\models` for Windows or `%USERPROFILE%/.aitk/models` for unix-like systems.
 
To ensure your models are correctly loaded by AITK, you need to manually create the necessary 4-layer directories within AITK working directory. For example:
   ```powershell
    mkdir C:\Users\Administrator\.aitk\models\microsoft\Phi-3.5-vision-instruct-onnx\cpu\phi3.5-cpu-int4-rtn-block-32
   ```
In this example, the 4-layer directory structure is `microsoft\Phi-3.5-vision-instruct-onnx\cpu\phi3.5-cpu-int4-rtn-block-32`.
 
**Tip: The name of 4-layer directory structure matters. Name of each layer of directory would be used as different system parameter when processing. The structure would be identified as `$publisherName`\\`$modelName`\\`$runtime`\\`$displayName`. The `$displayName` would be the name shown in local model tree view on the top-left side of the extension, so please follow the directory structure and try to use different displayName for different models to avoid obfuscation.**

## Migrate models to ONNX format

Based on ONNX runtime, onnxruntime_genai plugin would convert your model with the command below:

```powershell
python -m onnxruntime_genai.models.builder -m $modelPath -p $precision -e $executionProvider -o $outputModelPath -c $cachePath --extra_options include_prompt_templates=1
```
Typical pair of precision and execution provider are: `FP32 CPU`, `FP32 CUDA`, `FP16 CUDA`, `FP16 DML`, `INT4 CPU`, `INT4 CUDA`, `INT4 DML`.

**Example**
```powershell
python -m onnxruntime_genai.models.builder -m C:\hfmodel\phi3 -p fp16 -e cpu -o C:\Users\Administrator\.aitk\models\microsoft\Phi-3-mini-4k-instruct\cpu\phi3-cpu-int4-rtn-block-32-acc-level-4 -c C:\temp --extra_options include_prompt_templates=1
```

**Tutorial**

[Basic tutorial of precision](https://huggingface.co/docs/optimum/en/concept_guides/quantization)  
[Basic knowledge of executionProvider](https://onnxruntime.ai/docs/execution-providers)  

## Load models in AITK

After conversion, move your ONNX model file into the newly created directory, and your ONNX format model will be auto-loaded by the AI Toolkit at startup/model refresh process. Simply double click on your model name in `MY MODELS` view, or open `Playground` in `TOOLS` view on left side of AI Toolkit extension, and start chatting with your own model.

**Note: You must manage the model yourself as AI toolkit delete operation on your model is not supported. To delete the model, you could simply remove the model directory.**

## Supported Models

| Support Matrix | Supported now | Under development | On the roadmap |
| :------: | :---: | :---: | :---: |
| Model architectures | `DeepSeek`, `Gemma`, `Llama`, `Mistral`, `Phi(Language + Vision)`, `Qwen`, `Nemotron`, `Granite`, `AMD OLMo` | `Whisper` | `Stable diffusion` |