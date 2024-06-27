#inputs:
prompts_path = '../../materials/step1_no_prompts.csv'
verbs_path = '../../materials/verb_list.csv'
monosemy_path = '../outs/monosemy_prediction_seeded.csv'

import os

os.environ["CUDA_DEVICE_ORDER"]="PCI_BUS_ID"
os.environ["CUDA_VISIBLE_DEVICES"] = "1,2"

from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline

import torch
import random
import numpy as np
import tensorflow as tf

import pandas as pd

model_name_or_path = "TheBloke/Llama-2-13B-chat-GPTQ"
# To use a different branch, change revision; For example: revision="gptq-4bit-32g-actorder_True"
model = AutoModelForCausalLM.from_pretrained(model_name_or_path,
                                             torch_dtype=torch.float16,
                                             device_map="auto",
                                             revision="gptq-8bit-128g-actorder_True")

tokenizer = AutoTokenizer.from_pretrained(model_name_or_path, use_fast=True)

def llama_talk(prompt, sys_prompt, temperature, verb):

    seed = 42
    
    torch.manual_seed(seed)
    random.seed(seed)
    np.random.seed(seed)
    torch.cuda.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    np.random.permutation(seed)
    tf.random.set_seed(seed)
    
    prompt = prompt.format(verb)
    
    prompt_template=f'''[INST] <<SYS>>
    {sys_prompt}
    <</SYS>>
    {prompt}[/INST]
    '''

    print("\n\n*** Generating:")

    input_ids = tokenizer(prompt_template, return_tensors='pt').input_ids.cuda()
    output = model.generate(inputs=input_ids, temperature=temperature, do_sample=True, max_new_tokens=512)
    output_string = tokenizer.decode(output[0])
    return output_string

# prompts_path = 'step1_no_prompts.csv'
prompts_df = pd.read_csv(prompts_path)
prompts_df.rename(columns={'Unnamed: 0': 'prompt_id'}, inplace=True)

prompt_dict = prompts_df.set_index('prompts')['prompt_id'].to_dict()
prompt_list = prompts_df['prompts'].tolist()

# prompt_dict

# verbs_path = 'verb_list.csv'
verbs_df = pd.read_csv(verbs_path)
verbs_list = verbs_df['verb'].tolist()
# verbs_df

# monosemy_path = 'monosemy_prediction_seeded.csv'
monosemy_df = pd.read_csv(monosemy_path)
monosemy_df = monosemy_df.drop(columns = ["Unnamed: 0"])
# monosemy_df

monosemy_dict = monosemy_df.set_index('verb')['prediction'].to_dict()

# monosemous generation
for temp in [0.7, 0.8, 0.9]:
    print("temp = " + str(temp))
    
    verbs_df = pd.read_csv(verbs_path)
    verbs_df = verbs_df.drop(columns=["sense", "sentence"])
    verbs_df = verbs_df.rename(columns={'alpaca output': 'llama2 output 1'})
    sys_prompt = ""
    
    # Create an empty list to store the results
    llama2_output = []

    for index, row in verbs_df.iterrows():
        # False means that the prediction is that it is polysemous
        print(row['verb'])
        if monosemy_dict[row['verb']] == True:
            prompt1 = "Please describe the one possible sense of the verb {} when it is used in a transitive clause."
            result = llama_talk(prompt1, sys_prompt, temp, row['verb'])
            llama2_output.append(result)
        else:
            result = "polysemous"
            llama2_output.append(result)

    verbs_df['llama_mono_output'] = llama2_output

    print(verbs_df)
    temp_name = '../outs/sense_gen_mono/' + "output_" + str(temp) + "_mono_seeded" + ".csv"
    verbs_df.to_csv(temp_name)
    print("saved " + temp_name)

# polysemous generation
for prompt in prompt_dict.keys():
    print(prompt_dict[prompt])
    for temp in [0.7, 0.8, 0.9]:
        print("temp = " + str(temp))
        
        verbs_df = pd.read_csv(verbs_path)
        verbs_df = verbs_df.drop(columns=["sense", "sentence"])
        verbs_df = verbs_df.rename(columns={'alpaca output': 'llama2 output 1'})
        sys_prompt = ""
        
        llama2_output = []
    
        for index, row in verbs_df.iterrows():
            # False means that the prediction is that it is polysemous
            print(row['verb'])
            if monosemy_dict[row['verb']] == False:
                result = llama_talk(prompt, sys_prompt, temp, row['verb'])
                llama2_output.append(result)
            else:
                result = "monosemous"
                llama2_output.append(result)
    
        verbs_df['llama_poly_output'] = llama2_output
    
        print(verbs_df)
        temp_name = '../outs/sense_gen_poly/' + "output_" + str(temp) + "prompt" + str(prompt_dict[prompt]) + "_poly_seeded" + ".csv"
        verbs_df.to_csv(temp_name)
        print("saved " + temp_name)