function [predictions, log_prob_y, model] = gp_add_lo( Xtrain, ytrain, Xtest, ytest )

likfunc = @likGauss;
inference = @infExact;
[predictions, log_prob_y, model] = ...
    gp_add_general_lo( likfunc, inference, Xtrain, ytrain, Xtest, ytest );

    