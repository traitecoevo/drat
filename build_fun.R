main <- function() {
  dir.create("packages", FALSE)
  pkgs <- read_packages()
  update_package_sources(pkgs)
  build_packages(pkgs)
  update_drat(pkgs)
}

read_packages <- function() {
  packages <- readLines("packages.txt")
  packages <- sub("\\s*#.*$", "", packages)
  packages[!grepl("^\\s*$", packages)]
}

update_package_sources <- function(packages) {
  ret <- setNames(logical(length(packages)), packages)
  for (p in packages) {
    log("update", p)
    dp <- package_dir(p)
    if (file.exists(dp)) {
      sha0 <- package_sha(p)
      git2r::pull(git2r::repository(dp))
      ret[p] <- package_sha(p) == sha0
    } else {
      prefix <- "git@github.com:"
      prefix <- "https://github.com/"
      url <- paste0(prefix, p, ".git")
      git2r::clone(url, dp)
      ret[p] <- TRUE
    }
  }
  invisible(ret)
}

## should only build if we have a different version to last time.
build_packages <- function(packages) {
  for (p in packages) {
    dp <- package_dir(p)
    sha <- package_sha(p)
    sha_file <- package_built_sha(p)
    dest <- package_zip(p)
    if (file.exists(dest) &&
        file.exists(sha_file) &&
        readLines(sha_file) == sha) {
      next
    }
    log("build", p)
    devtools::build(dp, quiet=TRUE)
    writeLines(sha, sha_file)
  }
}

clean_packages <- function(packages) {
  for (p in packages) {
    z <- package_zip(p)
    if (file.exists(z)) {
      log("clean", p)
      file.remove(z)
    }
  }
}

## Optionally work on a branch here to make the work easy to roll back?
update_drat <- function(packages, commit=TRUE) {
  repo <- git2r::repository(".")
  if (git_nstaged(repo) > 0L) {
    stop("Must have no staged files")
  }
  for (p in packages) {
    log("drat", p)
    z <- package_zip(p)
    drat::insertPackage(z, ".")
    git2r::add(repo, file.path("src/contrib", basename(z)))
    if (commit) {
      if (git_nstaged(repo) > 0L) {
        log("commit", p)
        git2r::add(repo, "src/contrib/PACKAGES")
        git2r::add(repo, "src/contrib/PACKAGES.gz")
        msg <- paste(basename(p),
                     package_version(p),
                     substr(package_sha(p), 1, 7),
                     package_url(p))
        git2r::commit(repo, msg)
      }
    }
  }
}

commit_drat <- function() {
  repo <- git2r::repository(".")
  st <- git2r::status(repo, verbose=FALSE, unstaged=FALSE, untracked=FALSE)
  if (length(st$staged) > 0L) {

  }
}

log <- function(action, package) {
  message(sprintf("*** [%s] %s",
                  crayon::yellow(action), crayon::blue(package)))
}

package_dir <- function(p) {
  file.path("packages", basename(p))
}

package_zip <- function(p) {
  paste0(package_dir(p), "_", package_version(p), ".tar.gz")
}

package_version <- function(p) {
  devtools::as.package(package_dir(p))$version
}

package_sha <- function(p) {
  git_sha(package_dir(p))
}

package_built_sha <- function(p) {
  paste0(package_dir(p), "_built_sha")
}

package_url <- function(p) {
  git2r::remote_url(git2r::repository(package_dir(p)), "origin")
}

git_sha <- function(path) {
  git2r::branch_target(head(git2r::repository(path)))
}

git_nstaged <- function(repo) {
  st <- git2r::status(repo, verbose=FALSE, unstaged=FALSE, untracked=FALSE)
  length(st$staged)
}
