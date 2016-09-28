# multilevel modelling of dillution series experiment
# varying intercept
# response variable: detection of sewage in sample (binary response)
# predictor variables: concentration of sewage (factor), sewage treatment plant (Enköping/Rosenlund)
# 
# by Jon Ahlinder

data {
  int<lower=0> L; // number of samples (L=51)
  int<lower=0> K; // number of groups (K=9)
  int<lower=-1,upper=1> sewage[L]; // sewage treatment plant
  int<lower=1,upper=K> group[L]; // group number (i.e. a combination of water type, sewage type, concentration level) 
  int<lower=0,upper=1> y[L]; // detection of sewage in sample (response variable)

}
parameters {
  real a1[K]; // group level coefficients
  real<lower=0.00001,upper=50> sigma; // group level standard deviation
  real mu_a1; // overall intercept
  real bsew0; // sewage type coefficient

}
transformed parameters {
  vector[L] y_hat;
  vector[2] bsew;

  bsew[1]<-bsew0; // center sewage type effect around zero
  bsew[2]<--bsew0;

  for (i in 1:L)
      y_hat[i] <- mu_a1 + a1[group[i]] + bsew0 * sewage[i]; 
 
}
model {
  // prior definitions
  mu_a1 ~ normal(0, 10);
  sigma ~ cauchy(0,3);
  for (i in 1:K)
    a1[i] ~ normal (0, sigma); 
  bsew0 ~ normal(0,100);
  // likelihood
  y ~ bernoulli_logit(y_hat); 
  
}
