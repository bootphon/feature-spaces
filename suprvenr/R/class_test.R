#' @importFrom dplyr %>%
#' @importFrom foreach %dopar%
#' @importFrom foreach foreach
NULL

loo_parallel <- function(d, fnames, fit_and_predict_fn) {
  doParallel::registerDoParallel()
  pred <- foreach(i=1:nrow(d), .combine=c) %dopar%
    (function(j) {
      x_tr <- d[-j,names(d) %in% fnames]
      y_tr <- d[-j,]$y
      x_te <- d[j,names(d) %in% fnames]
      return(fit_and_predict_fn(x_tr, y_tr, x_te))
    })(i)  
  return(pred)
}

loo_serial <- function(d, fnames, fit_and_predict_fn) {
  pred <- rep("", nrow(d))
  for (i in 1:nrow(d)) {
    x_tr <- d[-i,names(d) %in% fnames]
    y_tr <- d[-i,]$y
    x_te <- d[i,names(d) %in% fnames]
    pred[i] <- fit_and_predict_fn(x_tr, y_tr, x_te)
  } 
}


#' Conduct a class test
#' @description Conducts a class separation test on a single feature as defined in
#' \code{test_classes_f} 
#' @param encoding an \code{\link{encoding}} object
#' @param test_classes_f a data frame specifying the two classes: it contains a column
#' column \code{label} giving the label of the element,
#' and a column \code{value} giving the classification label
#' @param fit_and_predict_fn a function of three arguments: \code{x_tr}
#' (an N by d array of training vectors), \code{y_tr} (a vector of training labels),
#' \code{x_te} (an array containing a point to classify), returning a
#' predicted label.
#' @return a \code{\link{dplyr::tbl}} containing classification scores,
#' having at least one column,  \code{avg_loo}, giving the average
#' leave-one-out classification score
#' @export
generic_test <- function(encoding, test_classes_f, fit_and_predict_fn,
                         parallel=T) {
  d <- dplyr::inner_join(dplyr::as.tbl(encoding), test_classes_f, by="label")
  if (!identical(sort(unique(test_classes_f$label)),
                 sort(unique(d$label)))) {
    warning("Missing labels in encoding: unexpected errors may occur\n")
  }
  d$y <- factor(d$value)
  if (parallel) {
    pred <- loo_parallel(d, encoding$fnames, fit_and_predict_fn)
  } else {
    pred <- loo_serial(d, encoding$fnames, fit_and_predict_fn)
  }
  correct <- pred == as.character(d$y)
  result <- dplyr::data_frame(avg_loo=mean(correct),
                       predictions=list(dplyr::data_frame(label=d$label,
                                                   y=d$y,
                                                   pred=pred,
                                                   correct=correct)))
  return(result)
}

#' Conduct class tests for several features
#' @description Conducts class separation tests independently on the features defined in
#' \code{test_classes} 
#' @param encoding an \code{\link{encoding}} object
#' @param test_classes a data frame specifying the classes: it contains a column
#' \code{fname} giving the feature  a column \code{label} giving the label of the element,
#' and a column \code{value} giving the classification label
#' @param class_test_fn a function performing a classification test for a single binary
#' feature, returning a data frame of information about the class separation, containing
#' (at least) a column called \code{avg_loo}, giving the average of the 0-1 classification
#' scores for all points under leave-one-out
#' @return a \code{\link{dplyr::tbl}} containing the results of applying \code{class_test_fn}
#' for all the unique feature names in \code{test_classes$fname}; the \code{tbl} will
#' have the following columns (at least):
#' \itemize{
#'  \itemize{"fname"}{feature name}
#'  \itemize{"avg_loo"}{Average leave-one-out classification score}
#' }
#' @export
all_class_tests <- function(encoding, test_classes, class_test_fn) {
  test_classes %>%
    dplyr::group_by(fname) %>%
    dplyr::do(class_test=class_test_fn(encoding, .)) %>%
    dplyr::ungroup() %>%
    tidyr::unnest(class_test)
}
