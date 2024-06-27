python monosemy_prompting.py

python monosemy_prediction.py

python sense_gen.py

python mine-senses-from-lm-output-v2.py \
    -d "../outs/sense_gen_poly/" -o "../outs/output_mine_sense_poly/" -n "llama_poly_output"

python prompt_selection.py

python monosemous_senses_from_outputs.py