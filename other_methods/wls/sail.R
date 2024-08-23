# R codes below are forked from GitHub repo
# https://github.com/ZeyuBian/pdwols.
# Please see repo instruction for more information.
require(foreach) |> suppressMessages()

cv.sail <- function(x, y, e, ...,
                    weights,
                    lambda = NULL,
                    type.measure = c("mse", "deviance", "class", "auc", "mae"),
                    nfolds = 10, foldid, grouped = TRUE, keep = FALSE, parallel = FALSE) {
  
  
  if (!requireNamespace("foreach", quietly = TRUE)) {
    stop("Package \"foreach\" needed for this function to work in parallel. Please install it.",
         call. = FALSE
    )
  }
  
  if (missing(type.measure)) type.measure <- "default" else type.measure <- match.arg(type.measure)
  if (!is.null(lambda) && length(lambda) < 2) {
    stop("Need more than one value of lambda for cv.sail")
  }
  N <- nrow(x)
  if (missing(weights)) {
    weights <- rep(1, N)
  } else {
    weights <- as.double(weights)
  }
  y <- drop(y)
  sail.call <- match.call(expand.dots = TRUE)
  which <- match(c(
    "type.measure", "nfolds", "foldid", "grouped",
    "keep"
  ), names(sail.call), F)
  if (any(which)) {
    sail.call <- sail.call[-which]
  }
  sail.call[[1]] <- as.name("sail")
  sail.object <- sail::sail(
    x = x, y = y, e = e, ...,
    weights = weights, lambda = lambda
  )
  
  sail.object$call <- sail.call
  
  ### Next line is commented out so each call generates its own lambda sequence
  # lambda <- sail.object$lambda
  
  # nz = sapply(predict(sail.object, type = "nonzero"), length)
  nz <- sapply(sail.object$active, length)
  # if (missing(foldid)) foldid <- sample(rep(seq(nfolds), length = N)) else nfolds <- max(foldid)
  if (missing(foldid)) foldid <- createfolds(y = y, k = nfolds) else nfolds <- max(foldid)
  if (nfolds < 2) {
    stop("nfolds must be bigger than 2; nfolds=10 recommended")
  }
  outlist <- as.list(seq(nfolds))
  if (parallel) {
    outlist <- foreach::foreach(i = seq(nfolds), .packages = c("sail")) %dopar% {
      which <- foldid == i
      
      if (length(dim(y)) > 1) {
        y_sub <- y[!which, ]
      } else {
        y_sub <- y[!which]
      }
      
      if (length(dim(e)) > 1) {
        e_sub <- e[!which, ]
      } else {
        e_sub <- e[!which]
      }
      
      sail::sail(
        x = x[!which, , drop = FALSE], y = y_sub, e = e_sub, ...,
        lambda = lambda, weights = weights[!which]
      )
    }
  } else {
    for (i in seq(nfolds)) {
      which <- foldid == i
      
      if (is.matrix(y)) {
        y_sub <- y[!which, ]
      } else {
        y_sub <- y[!which]
      }
      
      if (length(dim(e)) > 1) {
        e_sub <- e[!which, ]
      } else {
        e_sub <- e[!which]
      }
      
      outlist[[i]] <- sail::sail(
        x = x[!which, , drop = FALSE], y = y_sub, e = e_sub, ...,
        lambda = lambda, weights = weights[!which]
      )
    }
  }
  
  fun <- paste("cv", class(sail.object)[[1]], sep = ".")
  lambda <- sail.object$lambda
  cvstuff <- do.call(fun, list(
    outlist, lambda, x, y, e, weights,
    foldid, type.measure, grouped, keep
  ))
  cvm <- cvstuff$cvm
  cvsd <- cvstuff$cvsd
  nas <- is.na(cvsd)
  if (any(nas)) {
    lambda <- lambda[!nas]
    cvm <- cvm[!nas]
    cvsd <- cvsd[!nas]
    nz <- nz[!nas]
  }
  cvname <- cvstuff$name
  out <- list(
    lambda = lambda, cvm = cvm, cvsd = cvsd, cvup = cvm +
      cvsd, cvlo = cvm - cvsd, nzero = nz, name = cvname,
    sail.fit = sail.object
  )
  if (keep) {
    out <- c(out, list(fit.preval = cvstuff$fit.preval, foldid = foldid))
  }
  lamin <- if (cvname == "AUC") {
    getmin(lambda, -cvm, cvsd)
  } else {
    getmin(lambda, cvm, cvsd)
  }
  obj <- c(out, as.list(lamin))
  class(obj) <- "cv.sail"
  obj
}

createfolds <- function(y, k = 10, list = FALSE, returnTrain = FALSE) {
  if (class(y)[1] == "Surv") {
    y <- y[, "time"]
  }
  if (is.numeric(y)) {
    cuts <- floor(length(y) / k)
    if (cuts < 2) {
      cuts <- 2
    }
    if (cuts > 5) {
      cuts <- 5
    }
    breaks <- unique(stats::quantile(y, probs = seq(0, 1, length = cuts)))
    y <- cut(y, breaks, include.lowest = TRUE)
  }
  if (k < length(y)) {
    y <- factor(as.character(y))
    numInClass <- table(y)
    foldVector <- vector(mode = "integer", length(y))
    for (i in 1:length(numInClass)) {
      min_reps <- numInClass[i] %/% k
      if (min_reps > 0) {
        spares <- numInClass[i] %% k
        seqVector <- rep(1:k, min_reps)
        if (spares > 0) {
          seqVector <- c(seqVector, sample(1:k, spares))
        }
        foldVector[which(y == names(numInClass)[i])] <- sample(seqVector)
      }
      else {
        foldVector[which(y == names(numInClass)[i])] <- sample(1:k,
                                                               size = numInClass[i]
        )
      }
    }
  }
  else {
    foldVector <- seq(along = y)
  }
  if (list) {
    out <- split(seq(along = y), foldVector)
    names(out) <- paste("Fold", gsub(" ", "0", format(seq(along = out))),
                        sep = ""
    )
    if (returnTrain) {
      out <- lapply(out, function(data, y) y[-data], y = seq(along = y))
    }
  }
  else {
    out <- foldVector
  }
  out
}

cv.lspath <- function(outlist, lambda, x, y, e, weights,
                      foldid, type.measure, grouped, keep = FALSE) {
  
  typenames <- c(
    deviance = "Mean-Squared Error", mse = "Mean-Squared Error",
    mae = "Mean Absolute Error"
  )
  if (type.measure == "default") {
    type.measure <- "mse"
  }
  if (!match(type.measure, c("mse", "mae", "deviance"), FALSE)) {
    warning("Only 'mse', 'deviance' or 'mae'  available for Gaussian models; 'mse' used")
    type.measure <- "mse"
  }
  
  mlami <- max(sapply(outlist, function(obj) min(obj$lambda)))
  which_lam <- lambda >= mlami
  predmat <- matrix(NA, length(y), length(lambda))
  nfolds <- max(foldid)
  nlams <- double(nfolds)
  for (i in seq(nfolds)) {
    which <- foldid == i
    fitobj <- outlist[[i]]
    # fitobj$offset = FALSE
    preds <- predict(fitobj, newx = x[which, , drop = FALSE], newweights=weights[which],
                     newe = e[which], s = lambda[which_lam])
    nlami <- sum(which_lam)
    predmat[which, seq(nlami)] <- preds
    nlams[i] <- nlami
    
    
  }
  N <- length(y) - apply(is.na(predmat), 2, sum)
  cvraw <- switch(type.measure, mse = (y - predmat)^2, deviance = (y - predmat)^2, mae = abs(y - predmat))
  if ((length(y) / nfolds < 3) && grouped) {
    warning("Option grouped=FALSE enforced in cv.sail, since < 3 observations per fold",
            call. = FALSE
    )
    grouped <- FALSE
  }
  if (grouped) {
    cvob <- cvcompute(cvraw, weights, foldid, nlams)
    cvraw <- cvob$cvraw
    weights <- cvob$weights
    N <- cvob$N
  }
  cvm <- apply(cvraw, 2, stats::weighted.mean, w = weights, na.rm = TRUE)
  
  cvsd <- sqrt(apply(scale(cvraw, cvm, FALSE)^2, 2, stats::weighted.mean,
                     w = weights, na.rm = TRUE
  ) / (N - 1))
  out <- list(cvm = cvm, cvsd = cvsd, name = typenames[type.measure])
  if (keep) {
    out$fit.preval <- predmat
  }
  out
}

cvcompute <- function(mat, weights, foldid, nlams) {
  ### Computes the weighted mean and SD within folds, and hence the se of the mean
  wisum <- tapply(weights, foldid, sum)
  nfolds <- max(foldid)
  outmat <- matrix(NA, nfolds, ncol(mat))
  good <- matrix(0, nfolds, ncol(mat))
  mat[is.infinite(mat)] <- NA # just in case some infinities crept in
  for (i in seq(nfolds)) {
    mati <- mat[foldid == i, , drop = FALSE]
    wi <- weights[foldid == i]
    outmat[i, ] <- apply(mati, 2, stats::weighted.mean, w = wi, na.rm = TRUE)
    good[i, seq(nlams[i])] <- 1
  }
  N <- apply(good, 2, sum)
  list(cvraw = outmat, weights = wisum, N = N)
}

## 1se: gives the most regularized model
#such that error is within one standard error of the minimum

getmin <- function(lambda, cvm, cvsd) {
  cvmin <- min(cvm, na.rm = TRUE)
  idmin <- cvm <= cvmin
  lambda.min <- max(lambda[idmin], na.rm = TRUE)
  idmin <- match(lambda.min, lambda)
  semin <- (cvm +0.25*cvsd)[idmin]
  idmin <- cvm <= semin
  lambda.1se <- max(lambda[idmin], na.rm = TRUE)
  list(lambda.min = lambda.min, lambda.1se = lambda.1se)
}

lambda.interp <- function(lambda, s) {
  ### lambda is the index sequence that is produced by the model
  ### s is the new vector at which evaluations are required.
  ### the value is a vector of left and right indices, and a vector of fractions.
  ### the new values are interpolated bewteen the two using the fraction
  ### Note: lambda decreases. you take:
  ### sfrac*left+(1-sfrac*right)
  
  if (length(lambda) == 1) { # degenerate case of only one lambda
    nums <- length(s)
    left <- rep(1, nums)
    right <- left
    sfrac <- rep(1, nums)
  }
  else {
    s[s > max(lambda)] <- max(lambda)
    s[s < min(lambda)] <- min(lambda)
    k <- length(lambda)
    sfrac <- (lambda[1] - s) / (lambda[1] - lambda[k])
    lambda <- (lambda[1] - lambda) / (lambda[1] - lambda[k])
    coord <- approx(lambda, seq(lambda), sfrac)$y
    left <- floor(coord)
    right <- ceiling(coord)
    sfrac <- (sfrac - lambda[right]) / (lambda[left] - lambda[right])
    sfrac[left == right] <- 1
    sfrac[abs(lambda[left] - lambda[right]) < .Machine$double.eps] <- 1
  }
  list(left = left, right = right, frac = sfrac)
}