# multilevel modelling of in-silico series experiment
# varying intercept
# response variable: proportion of sewage in sample estimated by sourcetracker_for_qiime.py
# predictor variables: concentration group
# 
# by Jon Ahlinder

data {
  int<lower=0> L; // number of samples (L=400)
  int<lower=0> K; // number of groups (K=8)
  int<lower=1,upper=K> group[L]; // group number (i.e. a combination of water type, sewage type, concentration level) 
  real y[L]; // estimated source proportion of sewage in sample (response variable)

}
parameters {
  real a1[K]; // group level coefficients
  real mu_a1; // overall intercept
  real<lower=2, upper = 100> nu; // degrees of freedom parameter of the t-distribution
  real<lower=0.0001, upper = 100> sigma_y; // residual standard deviation
  real<lower=0.0001, upper = 100> sigma_a1; // group level standard deviation

}
transformed parameters {
  vector[L] y_hat;

  for (i in 1:L)
      y_hat[i] <- mu_a1 + a1[group[i]]; 
    
}
model {
  // prior definitions
  mu_a1 ~ normal(0, 1);
  for (i in 1:K)
    a1[i] ~ normal(0, sigma_a1); 
  nu ~ gamma(2,0.1); 
  // likelihood
  y ~ student_t(nu, y_hat, sigma_y);

}
