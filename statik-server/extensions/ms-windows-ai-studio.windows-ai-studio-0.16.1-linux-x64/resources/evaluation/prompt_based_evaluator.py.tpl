import json
from promptflow.client import load_flow


class {{evaluator_name}}:
    def __init__(self, model_config):
        self._flow = load_flow(source="{{&prompty_path}}", model={"configuration": model_config})

    def __call__(self, *, {{#inputs}}{{name}}: str, {{/inputs}}**kwargs):
        llm_response = self._flow({{#inputs}}{{name}}={{name}}{{^last}}, {{/last}}{{/inputs}})
        if isinstance(llm_response, dict):
            response = llm_response
        else:
            try:
                response = json.loads(llm_response)
            except Exception as ex:
                response = {
                    "aitk_error_code": 103,
                    "aitk_actual_response": llm_response,
                }
        return response