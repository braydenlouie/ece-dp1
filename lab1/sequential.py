from portkey_ai import Portkey
import os


client = Portkey(
    base_url="https://ai-gateway.apps.cloud.rt.nyu.edu/v1",
    api_key=os.environ.get("PORTKEY_API_KEY"),
    timeout=30.0,
    max_retries=0,
)

prompt = '''
Design two FSMs that detect the 8-bit pattern '00010111' in a continuous 
serial bit input stream. 

The FSM has inputs, clk, reset, and X (which is the one-bit serial input) and output Z
which is the sequence-detected output. On every rising edge of clk, the FSM reads the current
value of X and if a matching pattern is detected, Z=1 is held for exactly one clock cycle. After
detection, the detector will continue to process the serial input. Note that Z=1 should happen on the
same clock cycle that the pattern is detected. 

The first of the two FSMs will be a non-overlapping sequence detector and the second will be a overlapping
sequence detector. For both, create the FSM diagram, explain what each state represents and identify any states
that differ between the two, explain when Z becomes 1 and why it remains high for one clock cycle, explain how the
FSM either prevents bits from being reused or how bits are reused depending on which FSM we're talking about, and
a complete state table. 
'''


response = client.chat.completions.create(
    model="@vertexai/anthropic.claude-opus-4-6",
    messages=[
        {"role": "user", "content": prompt}
    ]
)


print (response.choices[0].message.content)
with open("lab1/sequential_response.txt", "w", encoding="utf-8") as file:
    file.write(response.choices[0].message.content)