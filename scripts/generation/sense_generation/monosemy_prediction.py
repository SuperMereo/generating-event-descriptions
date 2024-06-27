#inputs:
lelia_path = '../../materials/all_verbs_supermereo.csv'
llama_path = '../outs'

import pandas as pd
import os
import numpy as np

lelia_df = pd.read_csv(lelia_path)
lelia_df = lelia_df.drop(columns = ["Unnamed: 0", "shared_levin_classes", "pair", "label", "freq", "total_senses", "all_sense_defs", "trans_sense_defs", "trans_levin_classes"])
lelia_df = lelia_df.rename(columns={"trans_senses": "propbank_senses"})

def process_output(llama_df, lelia_df, tune):
  llama_df['mono'] = (llama_df['mono_prob']/llama_df['poly_prob'] >= tune).astype(int)
  llama_df['poly'] = 1 - llama_df['mono']
  merged_df = llama_df.merge(lelia_df, on='verb', how='left')
  merged_df['match'] = merged_df.apply(lambda row: 1 if row['propbank_senses'] == row['mono'] else 0, axis=1)
  return merged_df

merged_df = lelia_df.copy()

for filename in os.listdir(llama_path):
    if filename.endswith('.csv') and "mono_prompting" in filename:
        file_df = pd.read_csv(llama_path + "/" + filename)
        merged_df[filename] = np.log(file_df['mono_prob']) - np.log(file_df['poly_prob'])

merged_df.dropna(subset=merged_df.columns[2:], how='all', inplace=True)

# Reset the index of the merged_df
merged_df.reset_index(drop=True, inplace=True)

# merged_df.to_csv("aaron_step0_formatting.csv")

data = merged_df.copy()

output_cols = [c for c in data.columns if "output" in c]
data[output_cols] = data[output_cols].fillna(0)

INF = 1e6
data[output_cols] = data[output_cols].clip(lower=-INF, upper=INF)

from sklearn.preprocessing import QuantileTransformer

data["monosemous"] = data.propbank_senses == 1
data.head()

X, y = data[output_cols].values, data.monosemous.values

from sklearn.svm import SVC
from sklearn.model_selection import (
  GridSearchCV,
  LeaveOneOut,
  KFold,
  cross_validate
)
from sklearn.pipeline import Pipeline

param_grid = {
  "kernel": ["linear", "rbf"],
  "C": [1e-2, 1e-1, 1., 2., 5., 10.],
}

grid_search_cv = GridSearchCV(
  estimator=SVC(),
  param_grid=param_grid,
  cv=KFold(8, shuffle=True, random_state=20309)
)

estimator = Pipeline([
  ('quantile_transformer', QuantileTransformer(n_quantiles=y.shape[0]-1)),
  ('grid_search_cv', grid_search_cv)
])

import numpy as np
from sklearn.model_selection import cross_val_score

cv = cross_val_score(
  estimator, X=X, y=y, cv=LeaveOneOut()
)

print("Cross-validated accuracy:", np.round(cv.mean(), 2))

from sklearn.metrics import precision_recall_fscore_support

model = estimator.fit(X, y)

print("            Accuracy:", np.round(model.score(X, y), 2))
print()

prf_scores = precision_recall_fscore_support(model.predict(X), y)
score_names = ["Precision", "   Recall", "       F1"]

for name, (pos_score, neg_score) in zip(score_names, prf_scores[:-1]):
  print(name, "(negative):", np.round(pos_score, 2))
  print(name, "(positive):", np.round(neg_score, 2))
  print()

result = model.predict(X)
data['prediction'] = result
data.to_csv("../outs/monosemy_prediction_seeded.csv")

