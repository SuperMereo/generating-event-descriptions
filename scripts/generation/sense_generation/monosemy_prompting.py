# This script uses constrained decoding to differentiate between affirmative and dissenting answers to whether or not a verb is monosemous.

#inputs:
prompts_path = '../../materials/step0_prompts.csv'
verbs_path = '../../materials/verb_list.csv'

import torch
import random
import numpy as np
import tensorflow as tf
# print(torch.__version__) # should be 2.0.1
# !python --version # should be python 3.11.5

if torch.cuda.is_available():
    device = torch.device("cuda")
else:
    device = torch.device("cpu")

import os

os.environ["CUDA_DEVICE_ORDER"]="PCI_BUS_ID"
os.environ["CUDA_VISIBLE_DEVICES"] = "0,1"

from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import pandas as pd
model_name_or_path = "TheBloke/Llama-2-13B-chat-GPTQ"
# To use a different branch, change revision; For example: revision="gptq-4bit-32g-actorder_True"
model = AutoModelForCausalLM.from_pretrained(model_name_or_path,
                                             torch_dtype=torch.float16,
                                             device_map="auto",
                                             revision="gptq-8bit-128g-actorder_True")

tokenizer = AutoTokenizer.from_pretrained(model_name_or_path, use_fast=True)

def llama_talk(prompt, sys_prompt, temperature, verb, mono_list, poly_list):
    # Generic sys instructions
    sys_instructions = '''
    You are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.
    Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content.
    Please ensure that your responses are socially unbiased and positive in nature.
    If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct.
    If you don't know the answer to a question, please don't share false information.
    '''

    seed = 42
    torch.manual_seed(seed)
    random.seed(seed)
    np.random.seed(seed)
    torch.cuda.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    np.random.permutation(seed)
    tf.random.set_seed(seed)
    
    prompt = prompt.format(verb)
    
    prompt_template = f'''
    [INST] <<SYS>>
    {sys_prompt}
    <</SYS>>
    {prompt}[/INST]
    '''

    print("\n\n*** Generating:")

    inputs = tokenizer(prompt_template, return_tensors='pt').input_ids.to(model.device)

    outputs = model.generate(
        inputs,
        temperature=temperature,
        do_sample=True,
        max_length=1,
        return_dict_in_generate=True,
        output_scores=True
    )

    # Get prob distribution 
    logits = outputs.scores[0]
    probabilities = tuple(torch.softmax(logit, dim=-1) for logit in logits)
    token_probabilities = [(token_id, prob) for token_id, prob in enumerate(probabilities[0])]
    sorted_token_probabilities = sorted(token_probabilities, key=lambda x: x[1], reverse=True)
    generated_token_ids = outputs.sequences.tolist()
        
    prob_dict = {}
    for token_id, prob in sorted_token_probabilities:
        token_str = tokenizer.decode(token_id)
        prob_dict[token_str] = prob
    
    mono_total, poly_total = 0, 0
    for tok in prob_dict.keys():
        if tok in mono_list:
            mono_total += prob_dict[tok].item()
        elif tok in poly_list:
            poly_total += prob_dict[tok].item()
        
    return mono_total, poly_total

prompts_df = pd.read_csv(prompts_path)
prompts_df.rename(columns={'Unnamed: 0': 'prompt_id'}, inplace=True)
prompt_dict = prompts_df.set_index('prompts')['prompt_id'].to_dict()
prompts_dict = prompts_df.set_index('prompt_id').to_dict(orient='index')

verbs_df = pd.read_csv(verbs_path)
verbs_list = verbs_df['verb'].tolist()

#actual prompting:
linguist = "You are a professional linguist and you act as a consultant. Give a concise and clear answer. There is no need for introductions or formalities before answering the question."
standard = "You are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information."
empty = ""

all_sys_prompts = {"linguist": linguist, "standard": standard, "empty": empty}

for sys_prompt in all_sys_prompts.keys():
    for prompt_id in prompts_dict.keys():
        prompt = prompts_dict[prompt_id]["prompts"]
        # print("current prompt = " + prompt)
        for temp in [0.7, 0.8, 0.9]:
            print("temp = " + str(temp) + "; prompt = " + prompt)
            verbs_df = pd.read_csv(verbs_path)
            verbs_df = verbs_df.drop(columns=["sense"])
            verbs_df = verbs_df.rename(columns={"alpaca output": "mono_prob", 'sentence': 'poly_prob'})
            sys_prompt_sent = all_sys_prompts[sys_prompt]
            try:
                def apply_llama_talk(row):
                    try:
                        return llama_talk(prompt, sys_prompt_sent, temp, row['verb'], prompts_dict[prompt_id]["monosemous"], prompts_dict[prompt_id]["polysemous"])
                    except:
                        return None
                    
                verbs_df['mono_prob'], verbs_df['poly_prob'] = zip(*verbs_df.apply(apply_llama_talk, axis=1))
            except:
                print("error!")
    
            temp_name = '../outs/' + "mono_prompting_output_" + str(temp) + "_" + str(prompt_dict[prompt]) + "_" + str(sys_prompt) + ".csv"
            verbs_df.to_csv(temp_name)
