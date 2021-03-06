
# The main function that creates the 'lg'-object
# ----------------------------------------------

#' Create an \code{lg} object
#'
#' Create an \code{lg}-object, that can be used to estimate local Gussian
#' correlations, unconditional and conditional densities, local partial
#' correlation and for testing purposes.
#'
#' This is the main function in the package. It lets the user supply a data set
#' and set a number of options, which is then used to prepare an \code{lg}
#' object that can be supplied to other functions in the package, such as
#' \code{dlg} (density estimation), \code{clg} (conditional density estimation),
#' or other tasks in the locally Gaussian universe. The details has been laid
#' out in Otneim & Tjøstheim (2017a) and Otneim & Tjøstheim (2017b).
#'
#' The papers mentioned above deal with the estimation of multivariate density
#' functions and conditional density functions. The idea is to fit a
#' multivariate Normal locally to the unknown density function by first
#' transforming the data to marginal standard normality, and then estimate the
#' local correlations \strong{pairwise}. The local means and local standard
#' deviations are held fixed and constantly equal to 0 and 1 respectively to
#' reflect the knowledge that the marginals are approximetaly standard normal.
#' Use \code{est_method = "1par"} for this strategy, which means that we only
#' estimate one local parameter (the correlation) for each pair, and note that
#' this method requires marginally standard normal data. If \code{est_method =
#' "1par"} and \code{transform_to_marginal_normality = FALSE} the function will
#' throw a warning. It might be okay though, if you know that the data are
#' marginally standard normal already.
#'
#' The second option is \code{est_method = "5par_marginals_fixed"} which is more
#' flexible than \code{"1par"}. This method will estimate univariate local
#' Gaussian fits to each marginal, thus producing local estmates of the local
#' means: \eqn{\mu_i(x_i)} and \eqn{\sigma_i(x_i)} that will be held fixed in
#' the next step when the \strong{pairwise} local correlations are estimated.
#' This method can in many situations provide a better fit, even if the
#' marginals are standard normal. It also opens up for creating a multivariate
#' locally Gaussian fit to any density without having to transform the marginals
#' if you for some reason want to avoid that.
#'
#' The third option is \code{est_method = "5par"}, which is a full nonparametric
#' locally Gaussian fit of a bivariate density as laid out and used by Tjøstheim
#' & Hufthammer (2013) and others. This is simply a wrapper for the
#' \code{localgauss}-package by Berentsen et.al. (2014).
#'
#' @param x A matrix or data frame with data, on column per variable, one row
#'   per observation
#' @param bw_method The method used for bandwidth selection. Must be either
#'   \code{"cv"} (cross-validation, slow, but accurate) or \code{"plugin"}
#'   (fast, but crude)
#' @param est_method The estimation method, must be either "1par", "5par" or
#'   "5par_marginals_fixed" (see details)
#' @param transform_to_marginal_normality Logical true if we want to transform
#'   our data to marginal standard normality. This is assumed by method "1par",
#'   but can of course be skipped using this argument if it has been done
#'   already.
#' @param bw Bandwidth object if it has already been calculated.
#' @param plugin_constant_marginal The constant \code{c} in \code{cn^a} used for
#'   finding the plugin bandwidth for locally Gaussian marginal density
#'   estimates, which we need if estimation method is "5par_marginals_fixed".
#' @param plugin_exponent_marginal The constant \code{a} in \code{cn^a} used for
#'   finding the plugin bandwidth for locally Gaussian marginal density
#'   estimates, which we need if estimation method is "5par_marginals_fixed".
#' @param plugin_constant_joint The constant \code{c} in \code{cn^a} used for
#'   finding the plugin bandwidth for estimating the pairwise local Gaussian
#'   correlation between two variables.
#' @param plugin_exponent_joint The constant \code{a} in \code{cn^a} used for
#'   finding the plugin bandwidth for estimating the pairwise local Gaussian
#'   correlation between two variables.
#' @param tol_marginal The absolute tolerance in the optimization for finding
#'   the marginal bandwidths, passed on to the \code{optim}-function.
#' @param tol_joint The absolute tolerance in the optimization for finding the
#'   joint bandwidths. Passed on to the \code{optim}-function.
#' @param num_cores_bw_cv An integer specifying the number of cores to parallize the
#' cross validation of the bivariate bandwidths estimation when bw_method=="cv".
#' When num_cores = 1 (the default) everything is ran sequentially.
#' num_cores= 0 means using the maximum number of available logical cores.
#' Uses foreach and the doParallel backend.
#'
#' @examples
#'   x <- cbind(rnorm(100), rnorm(100), rnorm(100))
#'
#'   # Quick example
#'   lg_object1 <- lg(x, bw_method = "plugin", est_method = "1par")
#'
#'   # In the simulation experiments in Otneim & Tjøstheim (2017a),
#'   # the cross-validation bandwidth selection is used:
#'   lg_object2 <- lg(x, bw_method = "cv", est_method = "1par")
#'
#'   # If you do not wish to transform the data to standard normality,
#'   # use the five parameter fit:
#'   lg_object3 <- lg(x, est_method = "5par_marginals_fixed",
#'                   transform_to_marginal_normality = FALSE)
#'
#'   # In the bivariate case, you can use the full nonparametric fit:
#'   x_biv <- cbind(rnorm(100), rnorm(100))
#'   lg_object4 <- lg(x_biv, est_method = "5par",
#'                   transform_to_marginal_normality = FALSE)
#'
#'   # Whichever method you choose, the lg-object can now be passed on
#'   # to the dlg- or clg-functions for evaluation of the density or
#'   # conditional density estimate. Control the grid with the grid
#'   # argument.
#'   grid1 <- x[1:10,]
#'   dens_est <- dlg(lg_object1, grid = grid1)
#'
#'   # The conditional density of X1 given X2 = 1 and X2 = 0:
#'   grid2 <- matrix(-3:3, ncol = 1)
#'   c_dens_est <- clg(lg_object1, grid = grid2, condition = c(1, 0))
#'
#' @references
#'
#'   Berentsen, Geir Drage, Tore Selland Kleppe, and Dag Tjøstheim. "Introducing
#'   localgauss, an R package for estimating and visualizing local Gaussian
#'   correlation." Journal of Statistical Software 56.1 (2014): 1-18.
#'
#'   Hufthammer, Karl Ove, and Dag Tjøstheim. "Local Gaussian Likelihood and Local
#'   Gaussian Correlation" PhD Thesis of Karl Ove Hufthammer, University of
#'   Bergen, 2009.
#'
#'   Otneim, Håkon, and Dag Tjøstheim. "The locally gaussian density estimator for
#'   multivariate data." Statistics and Computing 27, no. 6 (2017a): 1595-1616.
#'
#'   Otneim, Håkon, and Dag Tjøstheim. "Conditional density estimation using
#'   the local Gaussian correlation" Statistics and Computing (2017b): 1-19.
#'
#' @export
lg <- function(x,
               bw_method = "plugin",
               est_method = "1par",
               transform_to_marginal_normality = TRUE,
               bw = NULL,
               plugin_constant_marginal = 1.75,
               plugin_constant_joint = 1.75,
               plugin_exponent_marginal = -1/5,
               plugin_exponent_joint = -1/6,
               tol_marginal = 10^(-3),
               tol_joint = 10^(-3),
               parallelize = NULL,
               num_cores_bw_cv = 1) {

    # Sanity checks
    x <- check_data(x, type = "data")
    check_est_method(est_method)
    if((est_method == "5par") & (ncol(x) != 2)) {
        stop("Data must be bivariate if estimation method is '5par'")
    }
    if((est_method == "1par") & (transform_to_marginal_normality == FALSE)) {
        warning("Estimation method '1par' assumes marginal standard normality.")
    }

    # Return a list
    ret <- list()
    ret$x <- x
    ret$bw_method <- bw_method
    ret$est_method <- est_method
    ret$transform_to_marginal_normality <- transform_to_marginal_normality

    # Transformation
    if(transform_to_marginal_normality) {
        transformed <- trans_normal(x = x)
        ret$transformed_data <- transformed$transformed_data
        ret$trans_new <- transformed$trans_new
    } else {
        ret$transformed_data <- x
        ret$trans_new <- NA
    }

    # Bandwidth selection
    if(is.null(bw)) {
        bw <- bw_select(ret$transformed_data,
                        bw_method = bw_method,
                        est_method = est_method,
                        plugin_constant_marginal = plugin_constant_marginal,
                        plugin_exponent_marginal =  plugin_exponent_marginal,
                        plugin_constant_joint = plugin_constant_joint,
                        plugin_exponent_joint = plugin_exponent_joint,
                        tol_marginal = tol_marginal,
                        tol_joint = tol_joint,
                        num_cores = num_cores_bw_cv)
    }
    ret$bw <- bw

    # Add the rest of the information to the object that we return
    ret$plugin_constant_marginal <- plugin_constant_marginal
    ret$plugin_constant_joint    <- plugin_constant_joint
    ret$plugin_exponent_marginal <- plugin_exponent_marginal
    ret$plugin_exponent_joint    <- plugin_exponent_joint
    ret$tol_marginal             <- tol_marginal
    ret$tol_joint                <- tol_joint

    class(ret) <- "lg"

    return(ret)
}
