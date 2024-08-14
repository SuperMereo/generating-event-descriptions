functions {
  real unit_clip(real x) {
    real zero = 1e-6;
    real clipped_low = fmax(x, zero);
    real clipped = fmin(clipped_low, 1.0-zero);
    return clipped;
  }  
}

data {
  int<lower=1> N_resp;                           // number of responses
  int<lower=1> N_subj;                           // number of subjects
  int<lower=1> N_verb;                           // number of verbs
  int<lower=1> N_sense;                          // number of senses
  int<lower=1> N_item;                           // number of items
  int<lower=1> N_fixed;                          // number of fixed predictors
  int<lower=1> N_by_subj;                        // number of random by-subject predictors
  int<lower=1> N_by_verb;                        // number of random by-verb predictors
  int<lower=1> N_by_sense;                       // number of random by-sense predictors
  int<lower=1> N_by_item;                        // number of random by-item predictors
  matrix[N_resp,N_fixed] fixed_predictors;       // predictors including intercept
  matrix[N_resp,N_by_subj] by_subj_predictors;   // by-subject predictors including intercept
  matrix[N_resp,N_by_verb] by_verb_predictors;   // by-verb predictors including intercept
  matrix[N_resp,N_by_sense] by_sense_predictors; // by-sense predictors including intercept
  matrix[N_resp,N_by_item] by_item_predictors;   // by-item predictors including intercept
  int<lower=1,upper=N_subj> subj[N_resp];        // subject who gave response n
  int<lower=1,upper=N_verb> verb[N_resp];        // verb corresponding to response n
  int<lower=1,upper=N_sense> sense[N_resp];      // sense corresponding to response n
  int<lower=1,upper=N_item> item[N_resp];        // item corresponding to response n
  int<lower=1,upper=3> resp_bin[N_resp];         // whether a response is 0=1, (0, 1)=2, or 1=2
  real<lower=0,upper=1> resp[N_resp];            // [0, 1] responses                                    
}

parameters {
  vector[N_fixed] fixed_coefs;                   // fixed coefficients (including intercept)
  corr_matrix[N_by_subj] subj_corr;              // prior by-subject coefficients correlations
  vector<lower=0>[N_by_subj] subj_scale_inv;     // prior by-subject coefficients inverse scale
  corr_matrix[N_by_verb] verb_corr;              // prior by-verb coefficients correlations
  vector<lower=0>[N_by_verb] verb_scale_inv;     // prior by-verb coefficients inverse scale
  corr_matrix[N_by_sense] sense_corr;            // prior by-sense coefficients correlations
  vector<lower=0>[N_by_sense] sense_scale_inv;   // prior by-sense coefficients inverse scale
  corr_matrix[N_by_item] item_corr;              // prior by-item coefficients correlations
  vector<lower=0>[N_by_item] item_scale_inv;     // prior by-item coefficients inverse scale
  vector[N_by_subj] by_subj_coefs[N_subj];       // by-subject coefficients (including intercept)
  vector[N_by_verb] by_verb_coefs[N_verb];       // by-verb coefficients (including intercept)
  vector[N_by_sense] by_sense_coefs[N_sense];    // by-sense coefficients (including intercept)        
  vector[N_by_item] by_item_coefs[N_item];       // by-item coefficients (including intercept)
  real<upper=0> cutpoint0;                       // the cutpoint for 0 v. (0, 1]
  real interval_size_logmean;                    // the interval size mean across subjects in log-space
  real sample_size_logmean;                      // the sample size mean across subjects in log-space
  real<lower=0> interval_size_logstd;            // the interval size standard deviation across subjects in log-space
  real<lower=0> sample_size_logstd;              // the sample size standard deviation across subjects in log-space    
  vector[N_subj] interval_size_shift_z;          // the z-score of the interval size shift for each subject in log-space
  vector[N_subj] sample_size_shift_z;            // the z-score of the sample size shift for each subject in log-space
}

transformed parameters {
  vector[N_by_subj] subj_scale = 1 / subj_scale_inv;
  vector[N_by_verb] verb_scale = 1 / verb_scale_inv;
  vector[N_by_sense] sense_scale = 1 / sense_scale_inv;
  vector[N_by_item] item_scale = 1 / item_scale_inv;

  matrix[N_by_subj,N_by_subj] subj_cov = quad_form_diag(
    subj_corr, subj_scale
  );
  matrix[N_by_verb,N_by_verb] verb_cov = quad_form_diag(
    verb_corr, verb_scale
  );
  matrix[N_by_sense,N_by_sense] sense_cov = quad_form_diag(
    sense_corr, sense_scale
  );
  matrix[N_by_item,N_by_item] item_cov = quad_form_diag(
    item_corr, item_scale
  );

  vector[N_subj] interval_size = exp(
    interval_size_logstd * interval_size_shift_z + interval_size_logmean
  );
  vector[N_subj] sample_size = exp(
    sample_size_logstd * sample_size_shift_z + sample_size_logmean
  );

  // compute the predictions
  real prediction[N_resp];
  real interval_mean[N_resp];
  matrix[N_resp,2] cutpoints;

  for (n in 1:N_resp) {
    prediction[n] = fixed_predictors[n] * fixed_coefs + 
                    by_subj_predictors[n] * by_subj_coefs[subj[n]] +
                    by_verb_predictors[n] * by_verb_coefs[verb[n]] +
                    by_sense_predictors[n] * by_sense_coefs[sense[n]] +
                    by_item_predictors[n] * by_item_coefs[item[n]];

    // ordinal component
    cutpoints[n,1] = cutpoint0;
    cutpoints[n,2] = cutpoint0 + interval_size[subj[n]];

    // beta component
    interval_mean[n] = unit_clip(
      inv_logit(prediction[n])
    );
  }
}

model { 
  // sample the general parameters
  cutpoint0 ~ std_normal() T[,0];

  // sample the subject-specific parameters
  interval_size_logmean ~ std_normal();
  sample_size_logmean ~ std_normal();
  
  interval_size_logstd ~ std_normal() T[0,];
  sample_size_logstd ~ std_normal() T[0,];

  interval_size_shift_z ~ std_normal();
  sample_size_shift_z ~ std_normal();

  subj_scale_inv ~ std_normal() T[0,];
  subj_corr ~ lkj_corr(2);

  vector[N_by_subj] subj_mean = rep_vector(0.0, N_by_subj);

  // sample the subject coefficients
  for (s in 1:N_subj)
    by_subj_coefs[s] ~ multi_normal(
      subj_mean, subj_cov
    );

  // sample the verb-specific parameters
  verb_scale_inv ~ std_normal() T[0,];
  verb_corr ~ lkj_corr(2);

  vector[N_by_verb] verb_mean = rep_vector(0.0, N_by_verb);

  // sample the by-verb coefficients
  for (v in 1:N_verb)
    by_verb_coefs[v] ~ multi_normal(
      verb_mean, verb_cov
    );

  // sample the sense-specific parameters
  sense_scale_inv ~ std_normal() T[0,];
  sense_corr ~ lkj_corr(2);

  vector[N_by_sense] sense_mean = rep_vector(0.0, N_by_sense);

  // sample the by-sense coefficients
  for (s in 1:N_sense)
    by_sense_coefs[s] ~ multi_normal(
      sense_mean, sense_cov
    );

  // sample the item-specific parameters
  item_scale_inv ~ std_normal() T[0,];
  item_corr ~ lkj_corr(2);

  vector[N_by_item] item_mean = rep_vector(0.0, N_by_item);

  // sample the by-item coefficients
  for (i in 1:N_item)
    by_item_coefs[i] ~ multi_normal(
      item_mean, item_cov
    );

  for (n in 1:N_resp) {
    // sample the response bins
    resp_bin[n] ~ ordered_logistic(
      prediction[n], 
      cutpoints[n]'
    );

    // sample the (0, 1) responses
    if (resp_bin[n] == 2) {
      resp[n] ~ beta_proportion(
        interval_mean[n], 
        sample_size[subj[n]]
      );
    } 
  }
}