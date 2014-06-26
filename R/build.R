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


buildPage <- function(src, path=NULL, skip=TRUE) {
  use("R.utils, R.rsp, markdown")

  if (is.na(src)) throw("Unknown page source: ", src)

  # Prepend path?
  if (!is.null(path)) src <- file.path(path, src)

  # RSP files
  pathR <- "templates"
  pathnamesR <- findTemplates(path=gsub("content", pathR, path))
  pathnamesR <- file.path(pathR, pathnamesR)

  # Download?
  if (isUrl(src)) {
    url <- src
    pattern <- "^(http.?://.*)/(content/.*)$"
    if (regexpr(pattern, url) == -1) throw("Unsupported URL: ", url)
    path <- gsub(pattern, "\\1", url)
    src <- gsub(pattern, "\\2", url)
    src <- downloadFile(url, src, path=".download")

    urlsR <- file.path(path, pathnamesR, fsep="/")
    pathnamesR <- sapply(pathnamesR, FUN=function(pathnameR) {
      downloadFile(url, pathnameR, path=".download")
    })
  }

  # Input file
  pathnameS <- Arguments$getReadablePathname(src)
  mprintf("Input pathname: %s\n", pathnameS)
  mprintf("RSP templates: %s\n", hpaste(pathnamesR))
  stopifnot(length(pathnamesR) > 0L)

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



findFiles <- function(path="content", pattern=NULL, recursive=TRUE) {
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


findPages <- function(path="content") {
  findFiles(path=path, pattern="[.]md$")
}

findTemplates <- function(path="templates") {
  findFiles(path=path, pattern="[.]rsp$")
}

buildPages <- function(srcs=NULL, path=NULL) {
  use("R.utils")

  # Find pages?
  if (is.null(srcs)) {
    pages <- findPages(path)
  }

  # Build pages
  for (page in pages) {
    html <- buildPage(page, path="content")
    mprint(html)
  } # for (ii ...)

  # Copy assets
  copyDirectory("assets", "html/assets", recursive=TRUE)
} # buildPages()


path <- "content"
#path <- "https://raw.githubusercontent.com/BHGC/website/master/content"
buildPages(path=path)
