from portkey_ai import Portkey
import os


client = Portkey(
    base_url="https://ai-gateway.apps.cloud.rt.nyu.edu/v1",
    api_key=os.environ.get("PORTKEY_API_KEY"),
    timeout=30.0,
    max_retries=0,
)

prompt = '''
A function is defined as F(A, B, C, D) with minterms of 0, 2, 5, 7, 8, 10, 
13, 14, 15 with A being the MSB and D being the LSB. 

Create a 16-row truth table for A, B, C, D, and F, a canonical SOP expression, a 
K-map with the rows being AB and the columns being CD, K-map groupings based on the
created K-map, and a simplified SOP from the K-map. 

From there create a logic circuit based on the simplified SOP expression using only
NOT, AND, and OR gates as well as a verification that the simplified expression produces
F = 1 for the minterms and F = 0 for the remaining input combinations. 

Lastly, create a verilog implementation and an associated testbench that applies all 
16 possible input combinations. 
'''


response = client.chat.completions.create(
    model="@vertexai/anthropic.claude-opus-4-6",
    messages=[
        {"role": "user", "content": prompt}
    ]
)


print (response.choices[0].message.content)
with open("lab1/combinational_response.txt", "w", encoding="utf-8") as file:
    file.write(response.choices[0].message.content)