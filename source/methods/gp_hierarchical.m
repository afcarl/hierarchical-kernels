function [predictions, log_prob_y, model] = gp_hierarchical(  Xtrain, ytrain, Xtest, ytest, hyp )

% Implements a multivariate hierarchical kernel.
%
%
% David Duvenaud, Jasoer Snoek, Frank Hutter, Mike Osborne, Kevin Swersky
% Oct 2013

% A mask to indicate which variables cannot be missing.
dims_always_there = [ 1 1 1 1 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 ];
num_dims_always_there = sum(dims_always_there);
num_dims_sometimes_there = sum(dims_always_there == 0);

assert( none(none(isnan(Xtrain(:, dims_always_there)))))

hhp = common_gp_parameters();     % Use a common set of hyper-hyper-priors.
[N,D] = size(Xtrain);


% Easy part of model set up:
meanfunc = {'meanConst'};
inference = @infExact;
likfunc = @likGauss;
hyp.mean = 0;
hyp.lik = ones(1,eval(likfunc())).*log(hhp.noise_scale);    


% Randomly draw hyperparameters for se_ard part of kernel..
log_lengthscales = log(hhp.length_scale.*gamrnd(hhp.gamma_a, hhp.gamma_b,1,num_dims_always_there));
log_variance = log(hhp.sd_scale);
iso_cov_hypers = [ log_lengthscales, log_variance ];

% Set up hypers for the rest of the dimensions.
omega = 1;  rho = 0.1;  sf2 = 1;
covcond_hypers = repmat( [log(omega);log(rho);log(sf2)], num_dims_sometimes_there, 1);

% Now construct the kernel.  It will be a product of a se_ard for the
% dimensions that are always there, and a product of covCond for the
% dimensions that could be missing.
cov_iso = { 'covMask', {dims_always_there, 'covSEard' }};
list_of_covconds = cell(1, num_dims_sometimes_there);
for i = 1:num_dims_sometimes_there
    list_of_covconds{i} = 'covCond';
end
covcond_nomask = { 'covProd', list_of_covconds };
covcond_mask = { 'covMask', {~dims_always_there, 'covcond_nomask' }};
cov = { 'covProd', {cov_iso, covcond_mask }};


max_iters = hhp.max_iterations;

% Save intialize hyperparameters.
model.init_hypers = hyp;        

% Fit the model.
[cur_hyp, nlZ] = minimize(hyp, @gp, -max_iters, ...
               inference, meanfunc, covfunc, likfunc, Xtrain, ytrain);

model.hypers = cur_hyp;
model.hhp = hhp;
model.marginal_log_likelihood_train = -nlZ(end);
model.marginal_log_likelihood_test = ...
    -gp(model.hypers, inference, meanfunc, covfunc, likfunc, Xtest, ytest);


% Make predictions.
[ymu, ys2, predictions, fs2, log_prob_y] = ...
    gp(model.hypers, inference, meanfunc, covfunc, likfunc, Xtrain, ytrain, Xtest, ytest);
