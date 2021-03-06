##' @title Make a single target
##' @param target_names Vector of names of targets to build, or
##' \code{NULL} to build the default target (if specified in the
##' remakefile).
##' @param remake_file Name of the remakefile (by default
##' \code{remake.yml}).  This is passed to \code{remake()}.
##' @export
make_script <- function(target_names=NULL, remake_file="remake.yml") {
  remake_script(remake2(remake_file, load_sources=FALSE), target_names)
}


remake_script <- function(m, target_name=NULL) {
  private <- remake_private(m)
  if (is.null(target_name)) {
    target_name <- private$target_default()
  }
  pkgs <- lapply(m$store$env$packages,
                 function(x) sprintf('library("%s")', x))
  srcs <- lapply(m$store$env$find_files(),
                 function(x) sprintf('source("%s")', x))
  ## Probably best to filter by "real" here?
  plan <- private$plan(target_name)
  cmds <- lapply(plan, function(i)
    target_run_fake(m$targets[[i]], for_script=TRUE))

  src <- c(unlist(pkgs),
           unlist(srcs),
           unlist(cmds))
  class(src) <- "remake_script"
  src
}

##' @export
print.remake_script <- function(x, ...) {
  writeLines(x, ...)
}

##' Convenience function for sourcing a remake script.  This just takes
##' care of writing the character vector to a temporary file and
##' running R's \code{\link{source}} over it.  It will also source
##' other arbitrary sets of R code that are character vectors rather
##' than files.
##' @title Source a remake script
##' @param src Contents
##' @param ... Additional arguments passed to \code{\link{source}},
##' \emph{except} for the \code{file} and \code{local} arguments.
##' @param envir An environment to source into (by default the global
##' environment).
##' @return The environment into which the code is sourced,
##' invisibly.  This is primarily useful when used as
##' \code{source_remake_script(script, envir=new.env())}, as the
##' environment created in the call is returned.
##' @export
source_remake_script <- function(src, ..., envir=.GlobalEnv) {
  assert_inherits(src, c("remake_script", "character"))
  dest <- tempfile()
  writeLines(src, dest)
  on.exit(file.remove(dest))
  source(dest, envir, ...)
  invisible(envir)
}
