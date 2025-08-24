# The method signature is generated automatically, please don't change it.
# Create a new evaluator if you'd like to change the method signature, like arguments passed to the method.
def {{evaluator_name}}({{#inputs}}{{name}}, {{/inputs}}**kwargs):
    # TODO: add your evaluator logic to calculate the score.

    # return an object with score and other optional string message you'd like to display in the result.
    return {
        "score": 3,
        "reason": "This is a placeholder for evaluator's reason."
    }