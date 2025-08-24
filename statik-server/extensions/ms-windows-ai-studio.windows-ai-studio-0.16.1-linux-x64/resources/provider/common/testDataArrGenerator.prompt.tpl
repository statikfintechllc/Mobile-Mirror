<Prompt Template>
{{{inputPrompt}}}
</Prompt Template>
    
Your job is to construct {{{number}}} test case for the prompt template above. 
This template contains "variables", which are placeholders to be filled in later. In this case, the variables are:
    
<variables>
{{#variableKeys}}
{{{.}}}
{{/variableKeys}}
</variables>

{{#examples.0.0}}
Here are the existing test cases provided by the user.
<examples>
{{#examples}} 
<example>
<variables>
{{#.}}
<{{key}}>{{{value}}}</{{key}}>
{{/.}}
</variables>
</example>
{{/examples}}
</examples>
{{/examples.0.0}}

Here are the guidelines to generate test cases:
{{{planning}}}
3. Distribution of test cases
Expand the existing test cases by adding {{{number}}} new and diverse test cases. The entire test cases should follow this distribution:
- 80% typical/standard use cases that represent common scenarios. The tese cases you write should be sufficiently different from the test cases that it provides additional signal. For any classification task, ensure that your test cases include examples from all possible categories or classes.
- 20% edge cases including:
  - Irrelevant or nonexistent input data
  - Overly long input data or user input
  - [Chat use cases] Poor, harmful, or irrelevant user input
  - Ambiguous test cases which is hard to reach an assessment consensus

Output {{{number}}} test cases for this prompt template with a full, complete, value for each variable. The output format should consist of a tagged block for each variable, with the value inside the block, like the below:

<testcases>
<testcase>
{{#variableKeys}}
<{{.}}>
[a full, complete, value for the variable "{{.}}". (You do not need to repeat the variable name inside the tags.)]
</{{.}}>
{{/variableKeys}}
</testcase>
</testcases>