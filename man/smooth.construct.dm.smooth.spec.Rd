\name{smooth.construct.dm.smooth.spec}
\alias{dm}
\alias{smooth.construct.dm.smooth.spec}
\title{Distance matrix smoothing}
\usage{
  \method{smooth.construct}{dm.smooth.spec} (object, data,
    knots)
}
\arguments{
  \item{object}{a smooth specification object, usually
  generated by a term \code{s(...,bs="ds",...)}. Note that
  \code{xt} object is needed, see Details.}

  \item{data}{a list containing just the data (including
  any \code{by} variable) required by this term, with names
  corresponding to \code{object$term} (and
  \code{object$by}). The \code{by} variable is the last
  element.}

  \item{knots}{IGNORED!}
}
\value{
  An object of class \code{dm.smooth}. In addition to the
  usual elements of a smooth class documented under
  \code{\link{smooth.construct}}, this object will contain
  an element named \code{msg}: \tabular{ll}{ \code{mds.obj}
  \tab result of running \code{\link{cmdscale}} on the
  data\cr \code{dim} \tab dimension of the MDS
  projection.\cr \code{term} \tab auto-generated names of
  the variables in the MDS space (of the form "mds-i" where
  i indexes the data)\cr \code{data} \tab the data
  projected into MDS space\cr \tab Plus those extra
  elements as documented in \code{\link{Duchon.spline}}}
}
\description{
  Provides smoothing methods for multidimensional
  scaling-based projections of a given distance matrix.
}
\details{
  Smoothing is performed using Duchon splines (see
  \code{\link{Duchon.spline}} for more information).
}
\section{Details}{
  The constructor is not normally called directly, but is
  rather used internally by \code{\link{gam}}. To use for
  basis setup it is recommended to use
  \code{\link{smooth.construct2}}.

  When specifying the model extra arguments must be
  supplied by the \code{xt} argument. \tabular{ll}{
  \code{D} \tab a distance matrix\cr \code{mds.dim} \tab
  dimension of the MDS projection\cr \code{grid.res} \tab
  grid resolution}

  MDS dimension selection may be performed by finding the
  projection with the lowest GCV score. BEWARE: the GCV
  score is not necessarily monotonic in the number of
  dimensions. Automated dimension selection will appear in
  a later version of the package.
}
\examples{
### Not run
# test this works with the wt2 example from msg
library(msg)
data(wt2)

# create the sample
samp.ind <- sample(1:length(wt2$data$x),250)
wt2.samp <- list(x=wt2$data$x[samp.ind],
                y=wt2$data$y[samp.ind],
                z=wt2$data$z[samp.ind]+rnorm(250)*0.9)
mds.dim<-5
# get the distance matrix
grid.obj <- msg:::create_refgrid(wt2$bnd,120)

D.grid <- msg:::create_distance_matrix(grid.obj$x,grid.obj$y,wt2$bnd,faster=0)

grid.mds<-cmdscale(D.grid,eig=TRUE,k=mds.dim,x.ret=TRUE)
mds.data<-as.data.frame(msg:::insert.mds.generic(grid.mds,wt2.samp,grid.obj,
                                                 bnd=wt2$bnd))
D<-dist(mds.data)

# fit the model
b.dm<-gam(z~s(x,y,bs="dm",k=200,xt=list(D=D,mds.dim=5)),data=wt2.samp)


# with msg
b.msg<-gam(z~s(x,y,bs="msg",k=200,xt=list(bnd=wt2$bnd,mds.dim=5)),data=wt2.samp)
}
\author{
  David L. Miller
}
\references{
  Duchon, J. (1977) Splines minimizing rotation-invariant
  semi-norms in Solobev spaces. in W. Shemp and K. Zeller
  (eds) Construction theory of functions of several
  variables, 85-100, Springer, Berlin.
}
\keyword{models}
\keyword{smoothing}

