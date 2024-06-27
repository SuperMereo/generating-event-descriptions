import pandas as pd
import json
import re

monosemy_raw_df = pd.read_csv("../outs/sense_gen_mono/output_0.7_mono_seeded.csv")

monosemy_raw_df= monosemy_raw_df.drop(columns = ['Unnamed: 0', 'llama2 output 1'])

monosemy_raw_df = monosemy_raw_df[monosemy_raw_df['llama_mono_output']!="polysemous"]

def get_substring_after(string, substring):
  sense_descr = string
  if substring in string:
      start_index = sense_descr.find(substring)
      if start_index != -1:
          start_index += len(substring)
          end_index = sense_descr.find(".", start_index)
          if end_index != -1:
              sense_descr = sense_descr[start_index:end_index].strip()
  return sense_descr

def remove_sys_strings(input_string):
    substrings_to_remove = ["</sys>", "<sys>", "<</sys>"]

    for substring in substrings_to_remove:
        input_string = input_string.replace(substring, "")

    return input_string.strip()

def extract_sense(verb, output):
  # extract text after [/INST]
  match = re.search(r'\[/INST\](.*?)</s>', output, re.DOTALL)
  if match:
      sense_descr = match.group(1).strip().lower()
  else:
    sense_descr = output.lower()

  sense_descr = remove_sys_strings(sense_descr)

  # get text before "example"
  if "example" in sense_descr or "examples" in sense_descr:
    match = re.search(r'(.*?)example|examples', sense_descr, re.DOTALL)
    sense_descr = match.group(0).strip()

  sense_descr = get_substring_after(sense_descr, "it typically means ")
  sense_descr = get_substring_after(sense_descr, "it means ")
  sense_descr = get_substring_after(sense_descr, "can mean ")
  sense_descr = get_substring_after(sense_descr, "to describe ")
  sense_descr = get_substring_after(sense_descr, "one possible sense when used in a transitive clause: 1.")
  sense_descr = get_substring_after(sense_descr, "sense: ")
  sense_descr = get_substring_after(sense_descr, "one possible sense is: 1. ")
  sense_descr = get_substring_after(sense_descr, "in the following sense: ")
  sense_descr = get_substring_after(sense_descr, "1. ")
  sense_descr = get_substring_after(sense_descr, "the most common sense is")
  sense_descr = get_substring_after(sense_descr, "in the following sense:")
  sense_descr = get_substring_after(sense_descr, "means")

  verb_string = "the most common sense of \"{}\" is".format(verb)
  sense_descr = get_substring_after(sense_descr, verb_string)

  verb_string = "sense of {} is ".format(verb)
  sense_descr = get_substring_after(sense_descr, verb_string)

  result = re.sub(r'[^a-zA-Z\s]', '', sense_descr)

  return result.strip()

monosemy_df = monosemy_raw_df.copy().reset_index(drop=True)
monosemy_df['sense_descr'] = monosemy_df.apply(lambda row: extract_sense(row['verb'], str(row['llama_mono_output'])), axis=1)

monosemy_df.to_csv("../outs/mono_sense_descr.csv")

