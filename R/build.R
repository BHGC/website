############################################################################
# Usage:
#  source('https://bhgc.org/build#BHGC')
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

#' @importFrom utils capture.output str
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


#' @importFrom R.oo trim
#' @importFrom utils URLdecode
findURIs <- function(url=NULL) {
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
    if (is.null(url)) return(character(0L))
    mprintf("URL: %s\n", url)
  }

  url <- URLdecode(url)
  uris <- unlist(strsplit(url, split=",", fixed=TRUE))

  uris
} # findURIs()


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Local functions
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#' @importFrom R.oo throw
#' @importFrom R.utils hpaste isFile isUrl downloadFile Arguments
#' @importFrom R.rsp rstring rfile RspFileProduct
#' @importFrom markdown markdownToHTML
buildPage <- function(src, path=".", skip=TRUE) {
  if (is.na(src)) throw("Unknown page source: ", src)

  # Prepend path?
  if (is.null(path)) path <- "."

  # Page file
  src0 <- src
  src <- file.path(path, "content", src)
  stopifnot(length(src) == 1L)

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
    src <- downloadFile(url, src, path=".download", overwrite=TRUE)

    pathnamesR <- sapply(pathnamesR, FUN=function(pathname) {
      url <- file.path(path, pathname, fsep="/")
      downloadFile(url, pathname, path=".", overwrite=TRUE)
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
  title <- grep("^#[ ]*", body, value=TRUE)[1L]
  title <- trim(gsub("^#[ ]*", "", title))
  title <- trim(gsub("<[^>]*>", "", title))
  if (is.na(title)) title <- ""
  mprintf("Page title: %s\n", title)

  # Relative path to root/home page
  pathToRoot <- paste(c(rep("..", times=depth), ""), collapse="/")

  # Edit source
  editsrc <- src0
  if (editsrc == "sites/index.md") editsrc <- "sites/sites.dcf"

  # Setup RSP arguments
  args <- list()
  args$page <- title
  args$depth <- depth
  args$pageSource <- path
  args$editURL <- file.path("https://github.com/BHGC/website/tree/master/content", editsrc, fsep="/")
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



#' @importFrom R.oo trim
#' @importFrom R.utils isUrl downloadFile Arguments
findFiles <- function(path, pattern=NULL, recursive=TRUE) {
  # Download list of files?
  if (isUrl(path)) {
    url <- file.path(path, ".files")
    pathname <- file.path(basename(path), basename(url))
    pathname <- downloadFile(url, pathname, path=".download", overwrite=TRUE)
    files <- readLines(pathname, warn=FALSE)
    files <- trim(files)
    files <- files[nzchar(files)]
    files <- unique(files)
  } else {
    # Scan for files?
    path <- Arguments$getReadablePath(path)
    files <- list.files(path, pattern=pattern, all.files=FALSE, recursive=recursive)
    # Update content/.files file
    writeLines(files, con=file.path(path, ".files"))
  }
  files
} # findFiles()


findPages <- function(path=".") {
  findFiles(path=file.path(path, "content"), pattern="[.]md$")
}

findContent <- function(path=".") {
  findFiles(path=file.path(path, "content"), pattern="[^~]$")
}

findTemplates <- function(path=".") {
  findFiles(path=file.path(path, "templates"), pattern="[.]rsp$")
}

findAssets <- function(path=".") {
  findFiles(path=file.path(path, "assets"), pattern="[^~]$")
}

#' @importFrom R.utils mkdirs
buildAssets <- function(path=".") {
  # List of assets
  pathnamesA <- file.path("assets", findAssets(path))

  # Nothing todo?
  if (length(pathnamesA) == 0) return()

  # Download?
  if (isUrl(path)) {
    pathnamesA <- sapply(pathnamesA, FUN=function(pathnameA) {
      url <- file.path(path, pathnameA)
      downloadFile(url, pathnameA, path="html", overwrite=TRUE)
    })
  } else {
    pathnamesA <- sapply(pathnamesA, FUN=function(pathnameA) {
      pathnameD <- file.path("html", pathnameA)
      mkdirs(dirname(pathnameD))
      file.copy(pathnameA, pathnameD, overwrite=TRUE, copy.date=TRUE)
    })
  }
} # buildAssets()

buildPages <- function(srcs=NULL, path=".") {
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


#' Build the BHGC Website
#'
#' @importFrom R.oo throw
#' @export
build <- function() {
  mcat("BHGC.org compiler v1.0 by Henrik Bengtsson\n\n")
  
  uris <- findURIs()
  nuris <- length(uris)
  if (nuris == 0L) {
    path <- "."
  } else if (nuris == 1L) {
    path <- sprintf("https://raw.githubusercontent.com/%s/website/master", uris)
  } else {
    throw("To many URIs: ", hpaste(uris))
  }
  
  mprintf("Source: %s\n", path)
  buildPages(path=path)
}

