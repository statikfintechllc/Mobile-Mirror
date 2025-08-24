<Prompt Template>
{{{inputPrompt}}}
</Prompt Template>
    
Your job is to generate a plan to construct test cases for the prompt template above. This template contains "variables", which are placeholders to be filled in later. In this case, the variables are:
    
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

In <planning> tags, do the following:
    
1. Summarize the prompt template. What is the goal of the user who created it?
2. For each variable in <variables>, carefully consider what a paradigmatic, realistic example of that variable would look like. You'll want to note who will be responsible "in prod" for supplying values. Written by a human "end user"? Downloaded from a website? Extracted from a database? Think about things like length, format, and tone in addition to semantic content. {{#examples.0.0}} Use the existing test cases provided by the user to guide this exercise. The example you write should be drawn from that same distribution, but sufficiently different from the test cases that it provides additional signal.  A tricky balancing act, but I have faith in you. {{/examples.0.0}}
    
The output format should look like the example below:

<planning>
1. Summary of the prompt template:
[Summary of the prompt template]
2. Consideration of variables:
[Describe what a paradigmatic, realistic example of that variables would look like]
</planning>
