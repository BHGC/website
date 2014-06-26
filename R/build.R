############################################################################
# Usage:
#  source('http://bhgc.org/alpha/R/build')
############################################################################

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Debug
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mout <- function(..., sep="", collapse="\n", appendLF=FALSE) {
  msg <- paste(..., sep=sep, collapse=collapse)
  message(msg, appendLF=appendLF)
}

mprintf <- function(...) {
  mout(sprintf(...))
}

mcat <- function(...) {
  mout(capture.output(cat(...)), appendLF=TRUE)
}

mprint <- function(...) {
  mout(capture.output(print(...)), appendLF=TRUE)
}

mstr <- function(...) {
  mout(capture.output(str(...)), appendLF=TRUE)
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Handle source() via URL
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copied from the R.utils package
findSourceTraceback <- function(...) {
  # Identify the environment/frame of interest by making sure
  # it at least contains all the arguments of source().
  argsToFind <- names(formals(base::source));

  # Scan the call frames/environments backwards...
  srcfileList <- list();
  for (ff in sys.nframe():0) {
    env <- sys.frame(ff);

    # Does the environment look like a source() environment?
    exist <- sapply(argsToFind, FUN=exists, envir=env, inherits=FALSE);
    if (!all(exist)) {
      # Nope, then skip to the next one
      next;
    }
    # Identify the source file
    srcfile <- get("srcfile", envir=env, inherits=FALSE);
    if (!is.null(srcfile)) {
      if (!is.function(srcfile)) {
        srcfileList <- c(srcfileList, list(srcfile));
      }
    }
  } # for (ff ...)

  # Extract the pathnames to the files called
  pathnames <- sapply(srcfileList, FUN=function(srcfile) {
    if (inherits(srcfile, "srcfile")) {
      pathname <- srcfile$filename;
    } else if (is.environment(srcfile)) {
      pathname <- srcfile$filename;
    } else if (is.character(srcfile)) {
      # Occurs with source(..., keep.source=FALSE)
      pathname <- srcfile;
    } else {
      pathname <- NA_character_;
      warning("Unknown class of 'srcfile': ", class(srcfile)[1L]);
    }
    pathname;
  });
  names(srcfileList) <- pathnames;

  srcfileList;
} # findSourceTraceback()


findURIs <- function(url=NULL) {
  trim <- function(x) gsub("(^[ ]|[ ]$)", "", x)

  if (is.null(url)) {
    urls <- names(findSourceTraceback())
    pattern <- ".*/build#"
    urls <- grep(pattern, urls, value=TRUE)
    urls <- gsub(pattern, "", urls)
    url <- urls[1]
  }
  if (is.na(url)) {
    # Local testing?
    url <- getOption("build#")
    if (is.null(url)) return(data.frame(name=character(0L), flags=c()))
    print(url)
  }

  url <- URLdecode(url)

  uris <- unlist(strsplit(url, split=",", fixed=TRUE))

  # Translater gist:// URIs
  uris <- sapply(uris, FUN=gist_to_url)

  uris
} # findURIs()


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Local functions
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
use <- function(...) {
  isInstalled <- function(pkgs) {
    unlist(sapply(pkgs, FUN=function(pkg) {
      nzchar(suppressWarnings(system.file(package=pkg)))
    }))
  } # isInstalled()

  if (!isInstalled("R.utils")) install.packages("R.utils")
  R.utils::use(...)
} # use()


buildPage <- function(src, path=".", skip=TRUE) {
  use("R.utils, R.rsp, markdown")

  if (is.na(src)) throw("Unknown page source: ", src)

  # Prepend path?
  if (is.null(path)) path <- "."

  # Page files
  src <- file.path(path, "content", src)
  stopifnot(length(src) > 0L)

  # RSP files
  pathnamesR <- findTemplates(path=path)
  pathnamesR <- file.path("templates", pathnamesR)
  stopifnot(length(pathnamesR) > 0L)

  # Download?
  if (isUrl(src)) {
    url <- src
    pattern <- "^(http.?://.*)/(content/.*)$"
    if (regexpr(pattern, url) == -1) throw("Unsupported URL: ", url)
    path <- gsub(pattern, "\\1", url)
    src <- gsub(pattern, "\\2", url)
    src <- downloadFile(url, src, path=".download")

    pathnamesR <- sapply(pathnamesR, FUN=function(pathnameR) {
      url <- file.path(path, pathnameR, fsep="/")
      downloadFile(url, pathnameR, path=".download")
    })
  }

  # Input file
  pathnameS <- Arguments$getReadablePathname(src)
  mprintf("Input pathname: %s\n", pathnameS)
  mprintf("RSP templates: %s\n", hpaste(pathnamesR))

  # Output file
  pathD <- dirname(pathnameS)
  pathD <- strsplit(pathD, split="/", fixed=TRUE)[[1]]
  pathD <- pathD[which(pathD == "content"):length(pathD)]
  pathD[1] <- "html"
  depth <- length(pathD) - 1
  pathD <- do.call(file.path, as.list(pathD))
  pathnameD <- file.path(pathD, "index.html")
  mprintf("Output pathname: %s\n", pathnameD)

  # Already done?
  if (skip && isFile(pathnameD)) {
    # Time stamp for *all* source files
    pathnamesS <- c(pathnameS, pathnamesR)
    mtimeS <- file.info(pathnamesS)$mtime
    mtimeD <- file.info(pathnameD)$mtime
    if (all(mtimeD > mtimeS)) {
      mcat("Already processed. Skipping.")
      html <- RspFileProduct(pathnameD)
      return(html)
    }
  }

  # Read RSP Markdown content
  body <- readLines(pathnameS)

  # Extract page title
  idx <- which(nzchar(body))[1L]
  title <- trim(body[idx])
  mprintf("Page title: %s\n", title)

  # Relative path to root/home page
  pathToRoot <- paste(c(rep("..", times=depth), ""), collapse="/")

  # Setup RSP arguments
  args <- list()
  args$page <- title
  args$depth <- depth
  mcat("RSP arguments:\n")
  mstr(args)

  # Compile RSP Markdown to Markdown
  mcat("RSP Markdown -> Markdown...\n")
  body <- rstring(body, type="application/x-rsp", args=args, workdir=pathD)
  mcat("RSP Markdown -> Markdown...done\n")

  # Compile Markdown to HTML
  mcat("Markdown -> HTML...\n")
  body <- markdownToHTML(text=body, options="fragment_only")
  mcat("Markdown -> HTML...done\n")

  # Compile RSP HTML with content
  mcat("HTML + template -> HTML...\n")
  pathnameR <- grep("index.html.rsp$", pathnamesR, value=TRUE)
  stopifnot(length(pathnameR) == 1L)
  args$body <- body
  mcat("RSP arguments:\n")
  mstr(args)
  html <- rfile(pathnameR, args=args, workdir=pathD)
  mcat("HTML + template -> HTML...done\n")

  html
} # buildPage()



findFiles <- function(path, pattern=NULL, recursive=TRUE) {
  use("R.utils")

  # Download list of files?
  if (isUrl(path)) {
    url <- file.path(path, ".files")
    pathname <- file.path(basename(path), basename(url))
    pathname <- downloadFile(url, pathname, path=".download")
    files <- readLines(pathname, warn=FALSE)
    files <- trim(files)
    files <- files[nzchar(files)]
    files <- unique(files)
  } else {
    # Scan for files?
    path <- Arguments$getReadablePath(path)
    files <- list.files(path, pattern=pattern, recursive=recursive)
    # Update content/.files file
    writeLines(files, con=file.path(path, ".files"))
  }
  files
} # findFiles()


findPages <- function(path=".") {
  findFiles(path=file.path(path, "content"), pattern="[.]md$")
}

findTemplates <- function(path=".") {
  findFiles(path=file.path(path, "templates"), pattern="[.]rsp$")
}

findAssets <- function(path=".") {
  findFiles(path=file.path(path, "assets"), pattern="[^~]$")
}

buildAssets <- function(path=".") {
  use("R.utils, R.rsp, markdown")

  # List of assets
  pathnamesA <- file.path("assets", findAssets(path))

  # Nothing todo?
  if (length(pathnamesA) == 0) return()

  # Download?
  if (isUrl(path)) {
    pathnamesA <- sapply(pathnamesA, FUN=function(pathnameA) {
      url <- file.path(path, pathnameA)
      downloadFile(url, pathnameA, path="html")
    })
  } else {
    pathnamesA <- sapply(pathnamesA, FUN=function(pathnameA) {
      pathnameD <- file.path("html", pathnameA)
      file.copy(pathnameA, pathnameD, overwrite=TRUE, copy.date=TRUE)
    })
  }
} # buildAssets()

buildPages <- function(srcs=NULL, path=".") {
  use("R.utils")

  # Build assets
  buildAssets(path)

  # Find pages?
  if (is.null(srcs)) {
    pages <- findPages(path)
  }

  # Build pages
  for (page in pages) {
    html <- buildPage(page, path=path)
    mprint(html)
  } # for (ii ...)
} # buildPages()


path <- "."
path <- "https://raw.githubusercontent.com/BHGC/website/master"
buildPages(path=path)
