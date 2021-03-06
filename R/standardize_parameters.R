#' Parameters standardization
#'
#' Compute standardized model parameters (coefficients).
#'
#' @param model A statistical model.
#' @param method The method used for standardizing the parameters. Can be
#'   `"refit"` (default), `"posthoc"`, `"smart"`, `"basic"` or `"pseudo"`. See
#'   'Details'.
#' @inheritParams standardize
#' @inheritParams chisq_to_phi
#' @param ... For `standardize_parameters()`, arguments passed to
#'   [parameters::model_parameters], such as:
#' - `ci_method`, `centrality` for Bayesian models...
#' - `df_method` for Mixed models ...
#' - `exponentiate`, ...
#' - etc.
#' @param parameters Deprecated.
#'
#' @details
#' ## Methods:
#' - **refit**: This method is based on a complete model re-fit with a
#' standardized version of the data. Hence, this method is equal to
#' standardizing the variables before fitting the model. It is the "purest" and
#' the most accurate (Neter et al., 1989), but it is also the most
#' computationally costly and long (especially for heavy models such as Bayesian
#' models). This method is particularly recommended for complex models that
#' include interactions or transformations (e.g., polynomial or spline terms).
#' The `robust` (default to `FALSE`) argument enables a robust standardization
#' of data, i.e., based on the `median` and `MAD` instead of the `mean` and
#' `SD`. **See [standardize()] for more details.**
#' - **posthoc**: Post-hoc standardization of the parameters, aiming at
#' emulating the results obtained by "refit" without refitting the model. The
#' coefficients are divided by the standard deviation (or MAD if `robust`) of
#' the outcome (which becomes their expression 'unit'). Then, the coefficients
#' related to numeric variables are additionally multiplied by the standard
#' deviation (or MAD if `robust`) of the related terms, so that they correspond
#' to changes of 1 SD of the predictor (e.g., "A change in 1 SD of `x` is
#' related to a change of 0.24 of the SD of `y`). This does not apply to binary
#' variables or factors, so the coefficients are still related to changes in
#' levels. This method is not accurate and tend to give aberrant results when
#' interactions are specified.
#' - **smart** (Standardization of Model's parameters with Adjustment,
#' Reconnaissance and Transformation - *experimental*): Similar to `method =
#' "posthoc"` in that it does not involve model refitting. The difference is
#' that the SD (or MAD if `robust`) of the response is computed on the relevant
#' section of the data. For instance, if a factor with 3 levels A (the
#' intercept), B and C is entered as a predictor, the effect corresponding to B
#' vs. A will be scaled by the variance of the response at the intercept only.
#' As a results, the coefficients for effects of factors are similar to a Glass'
#' delta.
#' - **basic**: This method is similar to `method = "posthoc"`, but treats all
#' variables as continuous: it also scales the coefficient by the standard
#' deviation of model's matrix' parameter of factors levels (transformed to
#' integers) or binary predictors. Although being inappropriate for these cases,
#' this method is the one implemented by default in other software packages,
#' such as [lm.beta::lm.beta()].
#' - **pseudo** (*for 2-level (G)LMMs only*): In this (post-hoc) method, the
#' response and the predictor are standardized based on the level of prediction
#' (levels are detected with [parameters::check_heterogeneity()]): Predictors
#' are standardized based on their SD at level of prediction (see also
#' [parameters::demean()]); The outcome (in linear LMMs) is standardized based
#' on a fitted random-intercept-model, where `sqrt(random-intercept-variance)`
#' is used for level 2 predictors, and `sqrt(residual-variance)` is used for
#' level 1 predictors (Hoffman 2015, page 342). A warning is given when a
#' within-group varialbe is found to have access between-group variance.
#'
#' ## Transformed Variables
#' When the model's formula contains transformations (e.g. `y ~ exp(X)`)
#' `method = "refit"` might give different results compared to
#' `method = "basic"` (`"posthoc"` and `"smart"` do not support such
#' transformations): where `"refit"` standardizes the data prior to the
#' transformation (e.g. equivalent to `exp(scale(X))`), the `"basic"` method
#' standardizes the transformed data (e.g. equivalent to `scale(exp(X))`). See
#' [standardize()] for more details on how different transformations are dealt
#' with.
#'
#' # Generalized Linear Models
#' When standardizing coefficients of a generalized model (GLM, GLMM, etc), only
#' the predictors are standardized, maintaining the interpretability of the
#' coefficients (e.g., in a binomial model: the exponent of the standardized
#' parameter is the OR of a change of 1 SD in the predictor, etc.)
#'
#' @return A data frame with the standardized parameters (`Std_*`, depending on
#'   the model type) and their CIs (`CI_low` and `CI_high`). Where applicable,
#'   standard errors (SEs) are returned as an attribute (`attr(x,
#'   "standard_error")`).
#'
#' @family standardize
#' @family effect size indices
#' @seealso [standardize_info()]
#'
#' @examples
#' library(effectsize)
#'
#' model <- lm(len ~ supp * dose, data = ToothGrowth)
#' standardize_parameters(model, method = "refit")
#' \donttest{
#' standardize_parameters(model, method = "posthoc")
#' standardize_parameters(model, method = "smart")
#' standardize_parameters(model, method = "basic")
#'
#' # Robust and 2 SD
#' standardize_parameters(model, robust = TRUE)
#' standardize_parameters(model, two_sd = TRUE)
#'
#'
#' model <- glm(am ~ cyl * mpg, data = mtcars, family = "binomial")
#' standardize_parameters(model, method = "refit")
#' standardize_parameters(model, method = "posthoc")
#' standardize_parameters(model, method = "basic", exponentiate = TRUE)
#' }
#'
#' \donttest{
#' if (require("lme4")) {
#'   m <- lmer(mpg ~ cyl + am + vs + (1 | cyl), mtcars)
#'   standardize_parameters(m, method = "pseudo", df_method = "satterthwaite")
#' }
#'
#'
#' \dontrun{
#' if (require("rstanarm")) {
#'   model <- stan_glm(rating ~ critical + privileges, data = attitude, refresh = 0)
#'   standardize_posteriors(model, method = "refit")
#'   standardize_posteriors(model, method = "posthoc")
#'   standardize_posteriors(model, method = "smart")
#'   head(standardize_posteriors(model, method = "basic"))
#' }
#' }
#' }
#'
#' @references
#' - Hoffman, L. (2015). Longitudinal analysis: Modeling within-person fluctuation and change. Routledge.
#' - Neter, J., Wasserman, W., & Kutner, M. H. (1989). Applied linear regression models.
#' - Gelman, A. (2008). Scaling regression inputs by dividing by two standard deviations. Statistics in medicine, 27(15), 2865-2873.
#'
#' @export
standardize_parameters <- function(model, method = "refit", ci = 0.95, robust = FALSE, two_sd = FALSE, verbose = TRUE, parameters, ...) {
  if (!missing(parameters)) {
    warning(
      "'parameters' argument is deprecated, and will not be used.",
      immediate. = TRUE
    )
  }

  UseMethod("standardize_parameters")
}

#' @importFrom parameters model_parameters
#' @importFrom insight model_info
#' @export
standardize_parameters.default <- function(model, method = "refit", ci = 0.95, robust = FALSE, two_sd = FALSE, verbose = TRUE, parameters, ...) {
  object_name <- deparse(substitute(model), width.cutoff = 500)
  method <- match.arg(method, c("refit", "posthoc", "smart", "basic", "classic", "pseudo"))

  if (method == "refit") {
    model <- standardize(model, robust = robust, two_sd = two_sd, verbose = verbose)
  }
  mi <- insight::model_info(model)

  # need model_parameters to return the parameters, not the terms
  if (inherits(model, "aov")) class(model) <- class(model)[class(model) != "aov"]
  pars <- parameters::model_parameters(model, ci = ci, standardize = NULL, ...)

  # should post hoc exponentiate?
  dots <- list(...)
  exponentiate <- "exponentiate" %in% names(dots) && dots$exponentiate
  coefficient_name <- attr(pars, "coefficient_name")

  if (method %in% c("posthoc", "smart", "basic", "classic", "pseudo")) {
    pars <- .standardize_parameters_posthoc(pars, method, model, robust, two_sd, exponentiate, verbose)

    method <- attr(pars, "std_method")
    robust <- attr(pars, "robust")
  }

  ## clean cols
  if (!is.null(ci)) pars$CI <- attr(pars, "ci")
  colnm <- c("Component", "Response", "Group", "Parameter", head(.col_2_scale, -2), "CI", "CI_low", "CI_high")
  pars <- pars[, colnm[colnm %in% colnames(pars)]]

  if (!is.null(coefficient_name) && coefficient_name == "Odds Ratio") {
    colnames(pars)[colnames(pars) == "Coefficient"] <- "Odds_ratio"
  }
  if (!is.null(coefficient_name) && coefficient_name == "Risk Ratio") {
    colnames(pars)[colnames(pars) == "Coefficient"] <- "Risk_ratio"
  }
  if (!is.null(coefficient_name) && coefficient_name == "IRR") {
    colnames(pars)[colnames(pars) == "Coefficient"] <- "IRR"
  }

  i <- colnames(pars) %in% c("Coefficient", "Median", "Mean", "MAP", "Odds_ratio", "IRR")
  colnames(pars)[i] <- paste0("Std_", colnames(pars)[i])

  ## SE attribute?
  if ("SE" %in% colnames(pars)) {
    attr(pars, "standard_error") <- pars$SE
    pars$SE <- NULL
  }

  ## attributes
  attr(pars, "std_method") <- method
  attr(pars, "two_sd") <- two_sd
  attr(pars, "robust") <- robust
  attr(pars, "object_name") <- object_name
  class(pars) <- c("effectsize_std_params", "effectsize_table", "see_effectsize_table", "data.frame")
  return(pars)
}

#' @export
standardize_parameters.parameters_model <- function(model, method = "refit", ci = NULL, robust = FALSE, two_sd = FALSE, verbose = TRUE, parameters, ...) {
  if (method == "refit") {
    stop("Method 'refit' not supported for 'model_parameters()", call. = TRUE)
  }

  if (!is.null(ci)) {
    warnings("Argument 'ci' argument not supported for 'model_parameters(). It is ignored.", call. = TRUE)
  }

  pars <- model
  ci <- attr(pars, "ci")
  model <- .get_object(pars)
  if (is.null(model)) model <- attr(pars, "object")

  if (is.null(exponentiate <- attr(pars, "exponentiate"))) exponentiate <- FALSE
  pars <- .standardize_parameters_posthoc(pars, method, model, robust, two_sd, exponentiate, verbose)
  method <- attr(pars, "std_method")
  robust <- attr(pars, "robust")

  ## clean cols
  if (!is.null(ci)) pars$CI <- attr(pars, "ci")
  colnm <- c("Component", "Response", "Group", "Parameter", head(.col_2_scale, -2), "CI", "CI_low", "CI_high")
  pars <- pars[, colnm[colnm %in% colnames(pars)]]
  i <- colnames(pars) %in% c("Coefficient", "Median", "Mean", "MAP")
  colnames(pars)[i] <- paste0("Std_", colnames(pars)[i])

  ## SE attribute?
  if ("SE" %in% colnames(pars)) {
    attr(pars, "standard_error") <- pars$SE
    pars$SE <- NULL
  }

  ## attributes
  attr(pars, "std_method") <- method
  attr(pars, "two_sd") <- two_sd
  attr(pars, "robust") <- robust
  class(pars) <- c("effectsize_std_params", "effectsize_table", "see_effectsize_table", "data.frame")
  return(pars)
}

#' @keywords internal
#' @importFrom insight model_info find_random
.standardize_parameters_posthoc <- function(pars, method, model, robust, two_sd, exponentiate, verbose) {
  # Sanity Check for "pseudo"
  if (method == "pseudo" &&
    !(insight::model_info(model)$is_mixed &&
      length(insight::find_random(model)$random) == 1)) {
    warning(
      "'pseudo' method only available for 2-level (G)LMMs.\n",
      "Setting method to 'basic'.",
      call. = FALSE
    )
    method <- "basic"
  }

  if (method %in% c("smart", "posthoc") &&
    .cant_smart_or_posthoc(model, pars$Parameter)) {
    warning("Method '", method, "' does not currently support models with transformed parameters.",
      "\nReverting to 'basic' method. Concider using the 'refit' method directly.",
      call. = FALSE
    )
    method <- "basic"
  }

  if (robust && method == "pseudo") {
    warning("'robust' standardization not available for 'pseudo' method.",
      call. = FALSE
    )
    robust <- FALSE
  }


  ## Get scaling factors
  deviations <- standardize_info(model, robust = robust, include_pseudo = method == "pseudo", two_sd = two_sd)
  i_missing <- setdiff(seq_len(nrow(pars)), seq_len(nrow(deviations)))
  unstd <- pars
  if (length(i_missing)) {
    deviations[i_missing, ] <- NA
  }

  if (method == "basic") {
    col_dev_resp <- "Deviation_Response_Basic"
    col_dev_pred <- "Deviation_Basic"
  } else if (method == "posthoc") {
    col_dev_resp <- "Deviation_Response_Basic"
    col_dev_pred <- "Deviation_Smart"
  } else if (method == "smart") {
    col_dev_resp <- "Deviation_Response_Smart"
    col_dev_pred <- "Deviation_Smart"
  } else if (method == "pseudo") {
    col_dev_resp <- "Deviation_Response_Pseudo"
    col_dev_pred <- "Deviation_Pseudo"
  } else {
    stop("'method' must be one of 'basic', 'posthoc', 'smart' or 'pseudo'.")
  }

  # Sapply standardization
  pars[, colnames(pars) %in% .col_2_scale] <- lapply(
    pars[, colnames(pars) %in% .col_2_scale, drop = FALSE],
    function(x) {
      if (exponentiate) {
        x^(deviations[[col_dev_pred]] / deviations[[col_dev_resp]])
      } else {
        x * deviations[[col_dev_pred]] / deviations[[col_dev_resp]]
      }
    }
  )

  if (length(i_missing) ||
    any(to_complete <- apply(pars[, colnames(pars) %in% .col_2_scale], 1, anyNA))) {
    i_missing <- union(i_missing, which(to_complete))

    pars[i_missing, colnames(pars) %in% .col_2_scale] <-
      unstd[i_missing, colnames(pars) %in% .col_2_scale]
  }

  attr(pars, "std_method") <- method
  attr(pars, "two_sd") <- two_sd
  attr(pars, "robust") <- robust

  return(pars)
}

#' @keywords internal
.col_2_scale <- c("Coefficient", "Median", "Mean", "MAP", "SE", "CI_low", "CI_high")


# standardize_posteriors --------------------------------------------------



#' @rdname standardize_parameters
#' @export
standardize_posteriors <- function(model, method = "refit", robust = FALSE, two_sd = FALSE, verbose = TRUE, ...) {
  object_name <- deparse(substitute(model), width.cutoff = 500)

  if (method == "refit") {
    model <- standardize(model, robust = robust, two_sd = two_sd, verbose = verbose)
  }

  pars <- insight::get_parameters(model)


  if (method %in% c("posthoc", "smart", "basic", "classic", "pseudo")) {
    pars <- .standardize_posteriors_posthoc(pars, method, model, robust, two_sd, verbose)

    method <- attr(pars, "std_method")
    robust <- attr(pars, "robust")
  }

  ## attributes
  attr(pars, "std_method") <- method
  attr(pars, "two_sd") <- two_sd
  attr(pars, "robust") <- robust
  attr(pars, "object_name") <- object_name
  class(pars) <- c("effectsize_std_params", class(pars))
  return(pars)
}



#' @keywords internal
#' @importFrom insight model_info find_random
.standardize_posteriors_posthoc <- function(pars, method, model, robust, two_sd, verbose) {
  # Sanity Check for "pseudo"
  if (method == "pseudo" &&
    !(insight::model_info(model)$is_mixed &&
      length(insight::find_random(model)$random) == 1)) {
    warning(
      "'pseudo' method only available for 2-level (G)LMMs.\n",
      "Setting method to 'basic'.",
      call. = FALSE
    )
    method <- "basic"
  }

  if (method %in% c("smart", "posthoc") &&
    .cant_smart_or_posthoc(model, colnames(pars))) {
    warning("Method '", method, "' does not currently support models with transformed parameters.",
      "\nReverting to 'basic' method. Concider using the 'refit' method directly.",
      call. = FALSE
    )
    method <- "basic"
  }

  if (robust && method == "pseudo") {
    warning("'robust' standardization not available for 'pseudo' method.",
      call. = FALSE
    )
    robust <- FALSE
  }

  ## Get scaling factors
  deviations <- standardize_info(model, robust = robust, include_pseudo = method == "pseudo", two_sd = two_sd)
  i <- match(deviations$Parameter, colnames(pars))
  pars <- pars[, i]

  if (method == "basic") {
    col_dev_resp <- "Deviation_Response_Basic"
    col_dev_pred <- "Deviation_Basic"
  } else if (method == "posthoc") {
    col_dev_resp <- "Deviation_Response_Basic"
    col_dev_pred <- "Deviation_Smart"
  } else if (method == "smart") {
    col_dev_resp <- "Deviation_Response_Smart"
    col_dev_pred <- "Deviation_Smart"
  } else if (method == "pseudo") {
    col_dev_resp <- "Deviation_Response_Pseudo"
    col_dev_pred <- "Deviation_Pseudo"
  } else {
    stop("'method' must be one of 'basic', 'posthoc', 'smart' or 'pseudo'.")
  }

  # Sapply standardization
  pars <- t(t(pars) * deviations[[col_dev_pred]] / deviations[[col_dev_resp]])
  pars <- as.data.frame(pars)

  attr(pars, "std_method") <- method
  attr(pars, "two_sd") <- two_sd
  attr(pars, "robust") <- robust

  return(pars)
}



#' @keywords internal
.cant_smart_or_posthoc <- function(model, params) {
  cant_posthocsmart <- FALSE

  if (insight::model_info(model)$is_linear) {
    if (!colnames(model.frame(model))[1] == insight::find_response(model)) {
      can_posthocsmart <- TRUE
    }
  }

  # factors are allowed
  if (!cant_posthocsmart &&
    !all(params == insight::clean_names(params) |
      grepl("(as.factor|factor)\\(", params))) {
    cant_posthocsmart <- TRUE
  }

  return(cant_posthocsmart)
}
