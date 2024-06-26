% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/de_analysis.R
\name{de_analysis}
\alias{de_analysis}
\alias{de_analysis_control_default}
\title{Differential Expression Analysis using a Topic Model}
\usage{
de_analysis(
  fit,
  X,
  s = rowSums(X),
  pseudocount = 0.01,
  fit.method = c("scd", "em", "mu", "ccd", "glm"),
  shrink.method = c("ash", "none"),
  lfc.stat = "le",
  control = list(),
  verbose = TRUE,
  ...
)

de_analysis_control_default()
}
\arguments{
\item{fit}{An object of class \dQuote{poisson_nmf_fit} or
\dQuote{multinom_topic_model_fit}, or an n x k matrix of topic
proportions, where k is the number of topics. (The elements in each
row of this matrix should sum to 1.) If a Poisson NMF fit is
provided as input, the corresponding multinomial topic model fit is
automatically recovered using \code{\link{poisson2multinom}}.}

\item{X}{The n x m counts matrix. It can be a sparse matrix (class
\code{"dgCMatrix"}) or dense matrix (class \code{"matrix"}).}

\item{s}{A numeric vector of length n determining how the rates are
scaled in the Poisson models. See \dQuote{Details} for guidance on
the choice of \code{s}.}

\item{pseudocount}{Observations with this value are added to the
counts matrix to stabilize maximum-likelihood estimation.}

\item{fit.method}{Method used to fit the Poisson models. Note that
\code{fit.method = "glm"} is the slowest method, and is mainly used
for testing.}

\item{shrink.method}{Method used to stabilize the posterior mean
LFC estimates.  When \code{shrink.method = "ash"}, the "adaptive
shrinkage" method implemented in the \sQuote{ashr} package is used to
compute posterior. When \code{shrink.method = "none"}, no
stabilization is performed, and the \dQuote{raw} posterior mean LFC
estimates are returned.}

\item{lfc.stat}{The log-fold change statistics returned:
\code{lfc.stat = "vsnull"}, the log-fold change relative to the
null; \code{lfc.stat = "le"}, the \dQuote{least extreme} LFC; or a
topic name or number, in which case the LFC is defined relative to
the selected topic. See \dQuote{Details} for more detailed
explanations of these choices.}

\item{control}{A list of parameters controlling behaviour of
the optimization and Monte Carlo algorithms. See \sQuote{Details}.}

\item{verbose}{When \code{verbose = TRUE}, progress information is
printed to the console.}

\item{\dots}{When \code{shrink.method = "ash"}, these are
additional arguments passed to \code{\link[ashr]{ash}}.}
}
\value{
A list with the following elements:

\item{est}{The log-fold change maximum-likelihood estimates.}

\item{postmean}{Posterior mean LFC estimates.}

\item{lower}{Lower limits of estimated HPD intervals. Note that
  these are not updated by the shrinkage step.}

\item{upper}{Upper limits of estimated HPD intervals. Note that
  these are not updated by the shrinkage step.}

\item{z}{z-scores for posterior mean LFC estimates.}

\item{lpval}{-log10 two-tailed p-values obtained from the
  z-scores. When \code{shrink.method = "ash"}, this is \code{NA}, and
  the s-values are returned instead (see below).}

\item{svalue}{s-values returned by
  \code{\link[ashr]{ash}}. s-values are analogous to q-values, but
  based on the local false sign rate; see Stephens (2016).}

\item{lfsr}{When \code{shrink.method = "ash"} only, this output
  contains the estimated local false sign rates.}

\item{ash}{When \code{shrink.method = "ash"} only, this output
  contains the \code{\link[ashr]{ash}} return value (after removing
  the \code{"data"}, \code{"result"} and \code{"call"} list
  elements).}

\item{F}{Maximum-likelihood estimates of the Poisson model
  parameters.}

\item{f0}{Maximum-likelihood estimates of the null model
   parameters.}

\item{ar}{A vector containing the Metropolis acceptance ratios
  from each MCMC run.}
}
\description{
Implements methods for differential expression
  analysis using a topic model. These methods are motivated by gene
  expression studies, but could have other uses, such as identifying
  \dQuote{key words} for topics.
}
\details{
The methods are based on the Poisson model
\deqn{x_i ~ Poisson(\lambda_i),} in which the Poisson rates are
\deqn{\lambda_i = \sum_{j=1}^k s_i l_{ij} f_j,} the \eqn{l_{ik}}
are the topic proportions and the \eqn{f_j} are the unknowns to be
estimated. This model is applied separately to each column of
\code{X}. When \eqn{s_i} (specified by input argument \code{s}) is
equal the total count in row i (this is the default), the Poisson
model will closely approximate a binomial model of the count data,
and the unknowns \eqn{f_j} will approximate binomial
probabilities. (The Poisson approximation to the binomial is most
accurate when the total counts \code{rowSums(X)} are large and the
unknowns \eqn{f_j} are small.) Other choices for \code{s} are
possible, and implement different normalization schemes.

To allow for some flexibility, \code{de_analysis} allows for the
log-fold change to be measured in several ways.

One option is to compare against the probability under the null
model: \eqn{LFC(j) = log2(f_j/f_0)}, where \eqn{f_0} is the single
parameter in the Poisson model \eqn{x_i ~ Poisson(\lambda_i)} with
rates \eqn{\lambda_i = s_i f_0}. This LFC definition is chosen with
\code{lfc.stat = "vsnull"}.

Another option is to compare against a chosen topic, k: \eqn{LFC(j)
= log2(f_j/f_k)}. By definition, \eqn{LFC(k)} is zero, and
statistics such as z-scores and p-values for topic k are set to
\code{NA}. This LFC definition is selected by setting
\code{lfc.stat = k}.

A final option (which is the default) computes the \dQuote{least
extreme} LFC, defined as \eqn{LFC(j) = log2(f_j/f_k)} such that
\eqn{k} is the topic other than \eqn{j} that gives the ratio
\eqn{f_j/f_k} closest to 1. This option is chosen with
\code{lfc.stat = "le"}.

We recommend setting \code{shrink.method = "ash"}, which uses the
\dQuote{adaptive shrinkage} method (Stephens, 2016) to improve
accuracy of the posterior mean estimates and z-scores. We follow
the settings used in \code{lfcShrink} from the \sQuote{DESeq2}
package, with \code{type = "ashr"}.

Note that all LFC statistics are defined using the base-2 logarithm
following the conventioned used in differential expression
analysis.

The \code{control} argument is a list in which any of the
following named components will override the default optimization
algorithm settings (as they are defined by
\code{de_analysis_control_default}):

\describe{

\item{\code{numiter}}{Maximum number of iterations performed in
  fitting the Poisson models. When \code{fit.method = "glm"}, this is
  passed as argument \code{maxit} to the \code{glm} function.}

\item{\code{minval}}{A small, positive number. All topic
  proportions less than this value and greater than \code{1 - minval}
  are set to this value.}

\item{\code{tol}}{Controls the convergence tolerance for fitting
  the Poisson models. When \code{fit.method = "glm"}, this is passed
  as argument \code{epsilon} to function \code{glm}.}

\item{\code{conf.level}}{The size of the highest posterior density
  (HPD) intervals. Should be a number greater than 0 and less than 1.}

\item{\code{ns}}{Number of Monte Carlo samples simulated by
  random-walk MCMC for estimating posterior LFC quantities.}

\item{\code{rw}}{The standard deviation of the normal density used
  to propose new states in the random-walk MCMC.}

\item{\code{eps}}{A small, non-negative number added to the terms
  inside the logarithms to avoid computing logarithms of zero.}

\item{\code{nc}}{Number of threads used in the multithreaded
  computations. This controls both (a) the number of RcppParallel
  threads used to fit the factors in the Poisson models, and (b)
  the number of cores used in \code{\link[parallel]{mclapply}} for
  the MCMC simulation step. Note that mclapply relies on forking
  hence is not available on Windows; will return an error on
  Windows unless \code{nc = 1}. Also note that setting \code{nc >
  1} copies the contents of memory \code{nc} times, which can lead
  to poor performance if the total resident memory required exceeds
  available physical memory.}

\item{\code{nc.blas}}{Number of threads used in the numerical
  linear algebra library (e.g., OpenBLAS), if available. For best
  performance, we recommend setting this to 1 (i.e., no
  multithreading).}

\item{\code{nsplit}}{The number of data splits used in the
  multithreaded computations (only relevant when \code{nc > 1}). More
  splits increase the granularity of the progress bar, but can also
  slow down the mutithreaded computations by introducing more
  overhead in the call to \code{\link[pbapply]{pblapply}}.}}
}
\examples{
# Perform a differential expression (DE) analysis using the previously
# fitted multinomial topic model. Note that the de_analysis call could
# take several minutes to complete.
\donttest{
set.seed(1)
data(pbmc_facs)
de <- de_analysis(pbmc_facs$fit,pbmc_facs$counts)

# Compile the DE analysis results for topic 4 into a table, and
# rank the genes by the posterior mean log-fold change, limiting to
# DE genes identified with low lfsr ("local false sign rate").
k <- 4
dat <- data.frame(postmean = de$postmean[,k],
                  z        = de$z[,k],
                  lfsr     = de$lfsr[,k])
rownames(dat) <- with(pbmc_facs$genes,paste(symbol,ensembl,sep = "_"))
dat <- subset(dat,lfsr < 0.01)
dat <- dat[order(dat$postmean,decreasing = TRUE),]

# Genes at the top of this ranking are genes that are much more
# highly expressed in the topic compared to other topics.
head(dat,n = 10)

# The genes at the bottom of the ranking are genes that are much less
# expressed in the topic.
tail(dat,n = 10)

# Create a volcano plot from the DE results for topic 4.
volcano_plot(de,k = k,ymax = 50,labels = pbmc_facs$genes$symbol)
}

}
\references{
Stephens, M. (2016). False discovery rates: a new deal.
\emph{Biostatistics} \bold{18}(2), kxw041.
\doi{10.1093/biostatistics/kxw041}

Zhu, A., Ibrahim, J. G. and Love, M. I. (2019). Heavy-tailed prior
distributions for sequence count data: removing the noise and
preserving large differences. \emph{Bioinformatics} \bold{35}(12),
2084–2092.
}
