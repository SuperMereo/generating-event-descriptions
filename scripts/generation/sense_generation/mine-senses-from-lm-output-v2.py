import argparse
import json
import logging
from pathlib import Path
import re

from bs4 import BeautifulSoup
import pandas as pd
from statistics import harmonic_mean


INLINE_ENUMERATION_PATTERN = r'(\(?(\d\d?)(\)|\.|\:|\>))'
ENUMERATION_PATTERN = r'^((-+|•|\*)|(\(|\<|)(\d\d?)(\)|\.|\:|\>))'


def get_senses_from_fp(fp, verb_senses, col_name):
    df = pd.read_csv(fp, index_col=0)
    # Retain only target column
    df = df[['verb', col_name]]
    # Strip out <s> tags from whole output
    df.loc[df[col_name].str.startswith('<s>'), col_name] = df[col_name].str[3:].str.lstrip()
    df.loc[df[col_name].str.endswith('</s>'), col_name] = df[col_name].str[:-4].str.rstrip()
    # Split after final instruction tag & strip response
    df[['instruction', 'response']] = df[col_name].str.split('\[/INST\]', expand=True)
    df['response'] = df['response'].str.lstrip()
    # Ensure everything is maximally stripped
    for col in df.columns:
        df[col] = df[col].str.strip()
    
    for _, row in df.iterrows():

        verb = row['verb']

        if verb_senses.get(verb):
            if verb_senses[verb].get(str(fp)):
                logging.warning("'{}' already exists; overwriting data from '{}' with current file '{}'.".format(verb, verb_senses[verb]['fp'], fp))
            else:
                verb_senses[verb][str(fp)] = {}
        else:
            verb_senses[verb] = {str(fp): {}}
        
        if row[col_name] == 'monosemous':
            verb_senses[verb][str(fp)][1] = 'monosemous'
            continue

        text = re.sub(INLINE_ENUMERATION_PATTERN, r'\n\1', row['response'])
        
        ctr = 0
        first_pattern_encountered = None
        for line in text.split('\n'):
            line = line.strip()
            if not line:
                continue
            match = re.match(ENUMERATION_PATTERN, line)
            if not match:
                
                continue
            
            # print(match.group(), match.group(0), match.group(1), match.group(2), match.group(3), match.group(4))
            if match.group(4):
                assert match.group(4).isdigit()
                if not first_pattern_encountered:
                    first_pattern_encountered = 'digit'
                if first_pattern_encountered != 'digit':
                    continue
                
                ctr += 1
                if ctr != int(match.group(4)):
                    #logging.warning("Second occurrence of a list present. {} {} {} {}".format(verb, str(ctr), match.group(2), fp))
                    continue
            else:
                assert match.group(1) in ['*', '•'] or match.group(1) in '---------------'
                if not first_pattern_encountered:
                    first_pattern_encountered = 'dash'
                if first_pattern_encountered != 'dash':
                    continue
                ctr += 1
                
            sense = line[len(match.group()):].lstrip().split(':')[0]
            verb_senses[verb][str(fp)][ctr] = sense
        
        if len(verb_senses[verb][str(fp)]) < 1:
            # If no matches, see if text is an XML output
            soup = BeautifulSoup(text, 'lxml')
            # If there's a findable tag, then it's XML-like
            if soup.find():
                for sense in soup.find_all('sense'):
                    ctr += 1
                    verb_senses[verb][str(fp)][ctr] = sense.find().text
                if len(verb_senses[verb][str(fp)]) < 1:
                    logging.warning("No enumerated senses found; XML-like tags found, but none labelled 'sense'. Leaving senses list empty. Manually investigate '{verb}' ({fp})")
                else:
                    logging.warning(f"No enumerated senses found; senses found in XML. Manually investigate '{verb}' ({fp})")
            else:
                logging.warning("No enumerated senses found; no XML-like tags found. Manually investigate '{verb}' ({fp})")
    
    return verb_senses
        

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-d', '--directory-path', help='a directory path')
    parser.add_argument('-f', '--filepath', help='a filename')
    parser.add_argument('-n', '--colname', default='llama_poly_output', help='column name')
    parser.add_argument('-o', '--output-path', default='verb_senses', help='a filename')
    ARGS = parser.parse_args()
    
    print('===\nMining senses...')   
    verb_senses = {}
    if ARGS.directory_path:
        for fp in Path(ARGS.directory_path).iterdir():
            if not fp.is_file():
                continue
            verb_senses = get_senses_from_fp(fp, verb_senses, ARGS.colname)
    elif ARGS.filepath:
        verb_senses = get_senses_from_fp(Path(ARGS.filepath), verb_senses, ARGS.colname)
    else:
        raise ValueError('No valid file or directory path supplied.')
    
    fp = Path(ARGS.directory_path) if ARGS.directory_path else Path(ARGS.filepath)
    with open(Path(f'{ARGS.output_path}{fp.stem}.json'), 'w', encoding='utf-8') as outf:
        json.dump(verb_senses, outf, indent=4)
    print(f"===\nSenses mined. Output in '{ARGS.output_path}{fp.stem}.json'.")

    # infp = Path.cwd() / f'output/{ARGS.output_path}{fp.stem}.json'
    # outfp = Path.cwd() / f'output/{ARGS.output_path}{fp.stem}.csv'
    infp = f'{ARGS.output_path}{fp.stem}.json'
    outfp = f'{ARGS.output_path}{fp.stem}.csv'
    df = pd.read_json(infp)
    df = df.applymap(lambda x: len(x))
    df.loc['mean'] = df.mean().round()
    df.loc['harmonic_mean'] = df.apply(lambda x: harmonic_mean(x)).round()
    df.to_csv(outfp)
    print(f"Senses counted. Output in '{ARGS.output_path}{fp.stem}.csv'.")
