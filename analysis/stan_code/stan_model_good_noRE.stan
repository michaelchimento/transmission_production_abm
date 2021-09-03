data {
    int K;              // num behaviors
    int N;              // num observations in dataset
    int J;              // num individuals
    int tech[N];        // techique chosen
    real y[N,K];    // observed personal yields of techs (1/0)
    real s[N,K];        // observed number of times observing behaviors
    int bout[N];        // processing bout per individual
    int id[N];          // individual id
    int N_effects;      // number of learning parameters to estimate
}

parameters {
    vector[N_effects] mu;                     //population means
}


model {
    vector[K] AC;       // attraction scores
    real logPrA;        // asocial learning Pr
    real PrS;           // social learning Pr
    vector[K] s_temp;   // social learning temp
    real phi;           // sensitivity to recent experience
    real lambda;        // sensitivity to attraction scores
    real gamma;         // social weight vs personal
    real fc;            // conformity exponent

   //priors
    mu[1] ~ normal(0,3);
    mu[2] ~ normal(0,3);
    mu[3] ~ normal(0,0.5);
    mu[4] ~ normal(0,0.5);

    //liklihood loop
    for ( i in 1:N ) {
        //update attractions
        for ( j in 1:K ) {
            if ( bout[i] > 1 ) {
                AC[j] = (1-phi)*AC[j] + phi*y[i-1,j];
            } else {
                AC[j] = 0;
            }
        }//j

        if ( bout[i]==1 ) {
            //IMPORTANT: uncomment this line to account for starting knowledge state of individuals in diffusion sims
            //AC[1] <- 1
            // calculate new individual's parameter values
            phi= inv_logit(mu[1]);
            gamma = inv_logit(mu[2]);
            fc = exp(mu[3]);
            lambda = exp(mu[4]);
        }

        logPrA = lambda*AC[tech[i]] - log_sum_exp( lambda*AC );

        //conformity aspect below
        if ( bout[i] > 1 ) {
            if (sum( s[i] ) > 0 ) {
                // compute frequency cue
                for ( j in 1:K ) s_temp[j] = pow(s[i,j],fc);
                PrS = s_temp[tech[i]]/sum(s_temp);
                target += log( (1-gamma)*exp(logPrA) + gamma*PrS ) ;
            } else {
                target += logPrA;
            }
        } else {
            target += logPrA;
         }
     }//i

}//end of model

generated quantities{
    vector[N] log_lik;
    vector[K] AC;       // attraction scores
    real logPrA;        // individual learning temp
    real PrS;        // social learning temp
    vector[K] s_temp;
    real lambda;           // stickiness parameter
    real phi;           // stickiness parameter
    real gamma;         // social weight
    real fc;     // conform exponent
    matrix[N,K] PrPreds;


    for ( i in 1:N ) {
        //update attractions
        for ( j in 1:K ) {
            if ( bout[i] > 1 ) {
                AC[j] = (1-phi)*AC[j] + phi*y[i-1,j];
            } else {
                AC[j] = 0;
            }
        }//j

        if ( bout[i]==1 ) {
            phi= inv_logit(  mu[1]);
            gamma = inv_logit(mu[2]);
            fc = exp(mu[3]);
            lambda = exp( mu[4]) ;
        }

        logPrA = lambda*AC[tech[i]] - log_sum_exp( lambda*AC );

        //conformity aspect below
        if ( bout[i] > 1 ) {
            if (sum( s[i] ) > 0 ) { //only socially learn when there is social information
                // compute frequency cue
                for ( j in 1:K ) s_temp[j] = pow(s[i,j],fc);
                PrS = s_temp[tech[i]]/sum(s_temp);
                log_lik[i] =  log( (1-gamma)*exp(logPrA) + gamma*PrS )  ;
                for(j in 1:K){
                PrPreds[i,j] = (1-gamma)*exp( lambda*AC[j] - log_sum_exp( lambda*AC) ) + gamma*(s_temp[j]/sum(s_temp)) ;
                }
            } else {
                 log_lik[i] = (logPrA);
                 for(j in 1:K){
                    PrPreds[i,j] = exp( lambda*AC[j] - log_sum_exp( lambda*AC) );
                 }
            }
        } else {
                 log_lik[i] = (logPrA);
                 for(j in 1:K){
                    PrPreds[i,j] = exp( lambda*AC[j] - log_sum_exp( lambda*AC) );
                }
            }
     }//i

}//end of model
