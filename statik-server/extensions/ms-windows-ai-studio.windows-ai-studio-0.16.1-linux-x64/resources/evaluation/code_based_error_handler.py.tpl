import traceback
from . import {{evaluator_name}}

def try_{{evaluator_name}}({{#inputs}}{{name}}, {{/inputs}}**kwargs):
    try:
        return {{evaluator_name}}.{{evaluator_name}}({{#inputs}}{{name}}, {{/inputs}}**kwargs)
    except Exception as e:
        return {
            "aitk_error_code": 104,
            "aitk_error_message": str(e),
            "aitk_error_exception": traceback.format_exc()
        }