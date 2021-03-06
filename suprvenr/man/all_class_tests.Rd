% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/class_test.R
\name{all_class_tests}
\alias{all_class_tests}
\title{Conduct class tests for several features}
\usage{
all_class_tests(encoding, test_classes, class_test_fn)
}
\arguments{
\item{encoding}{an \code{\link{encoding}} object}

\item{test_classes}{a data frame specifying the classes: it contains a column
\code{fname} giving the feature  a column \code{label} giving the label of the element,
and a column \code{value} giving the classification label}

\item{class_test_fn}{a function performing a classification test for a single binary
feature, returning a data frame of information about the class separation, containing
(at least) a column called \code{avg_loo}, giving the average of the 0-1 classification
scores for all points under leave-one-out}
}
\value{
a \code{\link{dplyr::tbl}} containing the results of applying \code{class_test_fn}
for all the unique feature names in \code{test_classes$fname}; the \code{tbl} will
have the following columns (at least):
\itemize{
 \itemize{"fname"}{feature name}
 \itemize{"avg_loo"}{Average leave-one-out classification score}
}
}
\description{
Conducts class separation tests independently on the features defined in
\code{test_classes}
}

