#' cross validate huber/quantile regression
#' @param x predictors
#' @param y response
#' @param weights weights of observations
#' @param FUN use hqreg or hqreg_raw function
#' @param parallel use parallel computing or not
#' @param nfolds number of folds
#' @param fold.id id of folds
#' @param type.measure the methods to measure the distance
#' @useDynLib hqreg
#' @export 
cv.hqreg <- function(X, y, weights, ..., 
                     FUN = c("hqreg", "hqreg_raw"), 
                     parallel = F, 
                     nfolds=10, 
                     fold.id, 
                     type.measure = c("deviance", "mse", "mae"), seed) {
  FUN <- get(match.arg(FUN))
  type.measure <- match.arg(type.measure)
  n <- length(y)
  if (!missing(seed)) set.seed(seed)
  if(missing(fold.id)) fold.id <- ceiling(sample(1:n)/n*nfolds)
  
  fit <- FUN(X, y, weights, ...)
  cv.args <- list(...)
  cv.args$lambda <- fit$lambda
  cv.args$alpha <- fit$alpha
  cv.args$gamma <- fit$gamma
  cv.args$tau <- fit$tau
  measure.args <- list(method=fit$method, gamma=fit$gamma, tau=fit$tau, type.measure = type.measure)
  E <- matrix(NA, nrow=length(y), ncol=length(cv.args$lambda))
 
  if (parallel) {
    #cat("Start parallel computing for cross-validation...")
    # clusterExport(cluster, c("fold.id", "X", "y", "cv.args", "measure.args"), 
    #               envir=environment())
    # clusterCall(cluster, function() require(hqreg))
    # fold.results <- parLapply(cl = cluster, X = 1:nfolds, fun = cvf, XX = X, y = y, 
    #                           fold.id = fold.id, cv.args = cv.args, measure.args = measure.args)

    fold.results <- foreach(i=1:nfolds) %dopar% {
      cvf(i,X,y,weights,fold.id,cv.args,measure.args,FUN)
    }
  }
  
  E <- matrix(NA, nrow = n, ncol = length(cv.args$lambda))
  for (i in 1:nfolds) {
    if (parallel) {
      fit.i <- fold.results[[i]]
    } else {
      #cat("CV fold #",i,sep="","\n")
      fit.i <- cvf(i,X,y,weights,fold.id,cv.args,measure.args,FUN)
    }
    E[fold.id == i, 1:fit.i$nl] <- fit.i$pe
  }
  
  ## Eliminate saturated lambda values
  ind <- which(apply(is.finite(E), 2, all))
  E <- E[,ind]
  lambda <- cv.args$lambda[ind]
  
  ## Results
  cve <- apply(E, 2, mean)
  cvse <- apply(E, 2, sd) / sqrt(n)
  index.min <- which.min(cve)
  # adjust the selection using 1-SD method
  index.1se <- min(which(cve < cve[index.min]+cvse[index.min]))
  val <- list(cve = cve, cvse = cvse, type.measure = type.measure, lambda = lambda, fit = fit, 
              lambda.1se = lambda[index.1se], lambda.min = lambda[index.min])
  structure(val, class="cv.hqreg")
  }

#' cross validation function
#' @param i ith fold
#' @param xx predictors
#' @param y response
#' @param weights weights of observations
#' @param fold.id id of folds
#' @param cv.args cross validation args
#' @param measure.args measurement arguments
#' @param FUN function of use: hqreg or hqreg_raw
cvf <- function(i, XX, y, weights, fold.id, cv.args, measure.args, FUN) {
  cv.args$X <- XX[fold.id != i,,drop = FALSE]
  cv.args$y <- y[fold.id != i]
  cv.args$weights <- weights[fold.id !=i]
  X2 <- XX[fold.id == i,,drop = FALSE]
  y2 <- y[fold.id == i]
  weights2 <- weights[fold.id == i]
  
  fit.i <- do.call(FUN, cv.args)
  yhat <- matrix(predict(fit.i, X2), length(y2))
  
  list(pe = measure.hqreg(y2-yhat, weights2, measure.args), nl = length(fit.i$lambda))
}
