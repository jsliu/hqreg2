% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hqreg.R
\name{hqreg}
\alias{hqreg}
\title{high dimensional quantile regression}
\usage{
hqreg(X, y, method = c("huber", "quantile", "ls"), gamma = IQR(y)/10,
  tau = 0.5, alpha = 1, nlambda = 100, lambda.min = 0.05, lambda,
  preprocess = c("standardize", "rescale"), screen = c("ASR", "SR",
  "none"), max.iter = 10000, eps = 1e-07, dfmax = ncol(X) + 1,
  penalty.factor = rep(1, ncol(X)), message = FALSE)
}
\arguments{
\item{y}{response}

\item{method}{type of loss function}

\item{gamma}{gamma used for huber loss}

\item{tau}{tau used for quantile regression}

\item{alpha}{mixing parameter of elastic net}

\item{preprocess}{the way to preprocess data: standardize or rescale}

\item{penalty.factor}{numbers to penalise each predictor}

\item{x}{predictors}
}
\description{
high dimensional quantile regression
}
