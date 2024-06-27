import numpy as np
import pandas as pd

pb_counts = pd.read_csv("../../materials/all_verbs_supermereo.csv", index_col=0).reset_index(drop=True)
pb_counts = pb_counts[["verb", "trans_senses"]]

prompt_counts = pd.read_csv("../outs/output_mine_sense_poly/sense_gen_poly.csv", index_col=0).drop(["mean", "harmonic_mean"])

prompt_counts = pd.melt(
    prompt_counts,
    var_name="verb",
    value_name="prompt_count",
    ignore_index=False
).reset_index().rename(columns={"index": "prompt"})

data = pd.merge(pb_counts, prompt_counts, on="verb")

data["abserr"] = (data.trans_senses - data.prompt_count).abs()

mae_ranked = data.groupby(["prompt"])[["abserr"]].mean().reset_index().sort_values("abserr").reset_index(drop=True)

best_prompt = mae_ranked.prompt[0]

np.random.seed(403924)

def bootstrap_mean_ci(x, alpha=0.05, niter=1000):
  return np.quantile(
    [np.random.choice(a=x, size=x.shape[0]).mean() for _ in range(niter)],
    q=np.array([alpha/2, 0.5, 1-alpha/2])
  )


bootstrap_mean_ci(data.abserr, alpha=0.01)

data_best = data[data.prompt == best_prompt]
data_best = data_best.sort_values("verb")

bootstrapped_mae_diff = []

for idx, r in mae_ranked.iterrows():
  if not idx:
    continue

  data_sub = data[data.prompt == r.prompt]
  data_sub = data_sub.sort_values("verb")

  ci = bootstrap_mean_ci(
    data_best["abserr"].values - data_sub["abserr"].values,
    alpha=0.05/idx
  )

  bootstrapped_mae_diff.append([r.prompt] + list(ci))

bootstrapped_mae_diff = pd.DataFrame(
  bootstrapped_mae_diff,
  columns=["prompt", "lower", "mean", "upper"]
)

bootstrapped_mae_diff["keep"] = bootstrapped_mae_diff.upper > 0

best_prompts = list(bootstrapped_mae_diff[bootstrapped_mae_diff.keep].prompt.values)

best_prompts = [best_prompt] + best_prompts

print(best_prompts)
