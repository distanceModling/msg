#' Distance matrix smoothing
#'
#' Provides smoothing methods for multidimensional scaling-based projections 
#' of a given distance matrix.
#' 
#' Smoothing is performed using Duchon splines (see 
#' \code{\link{Duchon.spline}} for more information).
#'
#' @aliases dm smooth.construct.dm.smooth.spec
#' @S3method smooth.construct dm.smooth.spec
#' @method smooth.construct dm.smooth.spec
#' @export
#' @import mgcv
#'
#' @param object a smooth specification object, usually generated by a term 
#'    \code{s(...,bs="ds",...)}. Note that \code{xt} object is needed, see 
#'    Details.
#' @param data a list containing just the data (including any \code{by} 
#'    variable) required by this term, with names corresponding to 
#'    \code{object$term} (and \code{object$by}). The \code{by} variable is the 
#'    last element.
#' @param knots IGNORED!
#'
#' @return An object of class \code{dm.smooth}. In addition to the usual 
#'  elements of a smooth class documented under \code{\link{smooth.construct}}, 
#'    this object will contain an element named \code{msg}:
#' \tabular{ll}{
#'              \code{mds.obj} \tab result of running \code{\link{cmdscale}} on
#'                  the data\cr
#'              \code{dim} \tab dimension of the MDS projection.\cr
#'              \code{term} \tab auto-generated names of the variables in the 
#'                  MDS space (of the form "mds-i" where i indexes the data)\cr
#'              \code{data} \tab the data projected into MDS space\cr
#'              \tab Plus those extra elements as documented in 
#'                  \code{\link{Duchon.spline}}}
#'
#' @section Details: The constructor is not normally called directly, but is 
#' rather used internally by \code{\link{gam}}. To use for basis setup it is 
#' recommended to use \code{\link{smooth.construct2}}.
#'
#' When specifying the model extra arguments must be supplied by the \code{xt} 
#' argument.
#' \tabular{ll}{
#'              \code{D} \tab a distance matrix\cr
#'              \code{mds.dim} \tab dimension of the MDS projection\cr
#'              \code{grid.res} \tab grid resolution}
#'
#' MDS dimension selection may be performed by finding the projection with the 
#' lowest GCV score. BEWARE: the GCV score is not necessarily monotonic in the 
#' number of dimensions. Automated dimension selection will appear in a later 
#' version of the package.
#'
#' @references
#' Duchon, J. (1977) Splines minimizing rotation-invariant semi-norms in Solobev spaces. in W. Shemp and K. Zeller (eds) Construction theory of functions of several variables, 85-100, Springer, Berlin.
#'
#' @author David L. Miller 
#'
#' @examples
#' ### Not run
#' # test this works with the wt2 example from msg
#' library(msg)
#' data(wt2)
#' 
#' # create the sample
#' samp.ind <- sample(1:length(wt2$data$x),250)
#' wt2.samp <- list(x=wt2$data$x[samp.ind],
#'                 y=wt2$data$y[samp.ind],
#'                 z=wt2$data$z[samp.ind]+rnorm(250)*0.9)
#' mds.dim<-5
#' # get the distance matrix
#' grid.obj <- msg:::create_refgrid(wt2$bnd,120)
#'
#' D.grid <- msg:::create_distance_matrix(grid.obj$x,grid.obj$y,wt2$bnd,faster=0)
#'
#' grid.mds<-cmdscale(D.grid,eig=TRUE,k=mds.dim,x.ret=TRUE)
#' mds.data<-as.data.frame(msg:::insert.mds.generic(grid.mds,wt2.samp,grid.obj,
#'                                                  bnd=wt2$bnd))
#' D<-dist(mds.data)
#'
#' # fit the model
#' b.dm<-gam(z~s(x,y,bs="dm",k=200,xt=list(D=D,mds.dim=5)),data=wt2.samp)
#'
#'
#' # with msg
#' b.msg<-gam(z~s(x,y,bs="msg",k=200,xt=list(bnd=wt2$bnd,mds.dim=5)),data=wt2.samp)
#' @keywords models smoothing

smooth.construct.dm.smooth.spec<-function(object,data,knots){

   # this is the dm smooth.spec file
   # this does most of the work

   if(is.null(object$xt$mds.dim)){
      stop("No MDS projection dimension supplied!\n")
   }

   # extract the MDS dimension
   mds.dim<-object$xt$mds.dim

   grid.res<-object$xt$mds.grid.res
   if(is.null(grid.res)){
      # pick a grid size...

      # just pick something for now
      #grid.res<-c(40,40)
      grid.res<-120
   }

#   # if there was an old object in the extra stuff, use it
#   #old.obj<-object$xt$old.obj
#   old.obj<-NULL
#
#   if(!is.null(old.obj)){
#      # object to store all the results for later
#      new.obj<-old.obj
#
#      # pull out the grid D matrix
#      D.grid<-old.obj$D
#      my.grid<-old.obj$grid
#
#      # also the pred and sample D matrices if
#      # they are there
#      if(!is.null(old.obj$D.samp)){
#         D.samp<-old.obj$D.samp
#      }else{
#         D.samp<-NULL
#      }
#      if(!is.null(old.obj$D.pred)){
#         D.pred<-old.obj$D.pred
#      }else{
#         D.pred<-NULL
#      }
#
#      if(!is.null(old.obj$m)){
#         m<-old.obj$m
#      }
#      if(!is.null(old.obj$bs)){
#         bs<-old.obj$bs
#      }
#      if(!is.null(old.obj$k)){
#         k<-old.obj$k
#      }
#
#      if(!is.null(old.obj$mds.dim)){
#         mds.dim<-old.obj$mds.dim
#      }
#
#   }else{
#      # object to store all the results for later
#      new.obj<-list()
#   }

   new.obj<-list()

   # the data in matrix form
   #data.names<-names(data)
   mdata<-as.matrix(as.data.frame(data))

   ## separate the predictors from response
   #ind<-rep(FALSE,ncol(mdata))
   #ind[match(object$term,data.names)]<-TRUE

   ## save the response
   #response.var<-mdata[,!ind]
   #mdata<-mdata[,ind]

   new.obj$D<-object$xt$D
   D<-object$xt$D

   mds.obj<-cmdscale(D,eig=TRUE,k=mds.dim,x.ret=TRUE)
   new.obj$mds.obj<-mds.obj
   mds.data<-as.data.frame(mds.obj$points)

   object$msg<-new.obj

   # make some variable names up
   mds.names<-paste("mds-",1:dim(mds.data)[2],sep="")
   # remove any already in the data
   names(mds.data)<-mds.names

   # make sure there are the right stuff is in the object before passing
   # to Duchon, but save beforehand!
   save.dim<-object$dim
   save.term<-object$term
   save.data<-data

   object$term<-mds.names
   object$dim<-mds.dim
   data<-mds.data

   object$msg$term<-mds.names
   object$msg$dim<-mds.dim
   object$msg$data<-mds.data

   # if knots were supplied, they're going to be ignored, warn about that!
   if(length(knots)!=0){
      warning("Knots were supplied but will be ignored!\n")
      knots<-list()
   }

   # set the penalty order
   object$p.order<-c(2,mds.dim/2-1)

   # make the duchon splines object as usual
   object<-smooth.construct.ds.smooth.spec(object,data,knots)

   if(!is.null(object$xt$extra.penalty)){
      object<-extra.penalty(object)
   }

   # recover the stuff we want in the object
   object$term<-save.term
   object$dim<-save.dim
   data<-save.data

   class(object)<-"dm.smooth"
   object
}


#' Distance matrix smoothing
#'
#' Provides smoothing methods for multidimensional scaling-based projections 
#' of a given distance matrix.
#'
#' Smoothing is performed using Duchon splines (see 
#' \code{\link{Duchon.spline}} for more information).
#'
#' @aliases Predict.matrix.dm.smooth
#' @S3method Predict.matrix dm.smooth
#' @method Predict.matrix dm.smooth
#' @export
#' @import mgcv
#'
#' @param object a smooth specification object, usually generated by a term 
#'    \code{s(...,bs="ds",...)}. Note that \code{xt} object is needed, see 
#'    Details.
#' @param data a list containing just the data (including any \code{by} 
#'    variable) required by this term, with names corresponding to 
#'    \code{object$term} (and \code{object$by}). The \code{by} variable is the 
#'    last element.
Predict.matrix.dm.smooth<-function(object,data){

   save.dim<-object$dim
   save.term<-object$term

   object$term<-object$msg$term
   object$dim<-object$msg$dim

      bnd<-NULL

   mds.obj<-object$msg$mds.obj
   my.grid<-object$msg$grid
   mds.data<-as.data.frame(insert.mds(data,my.grid,mds.obj,bnd))


   # make some variable names up
   mds.names<-paste("mds-",1:dim(mds.data)[2],sep="")
   # remove any already in the data
   names(mds.data)<-mds.names

   Predict.matrix.duchon.spline(object,mds.data)
}
