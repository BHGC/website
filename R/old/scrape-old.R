R.utils::use("R.utils")

download <- function() {
  root <- "http://bhgc.org"
  dirs=c(".", "flyingSites", "tam", "forums", "join", "members", "db", "miscellaneous", "miscellaneous/recipe-goat", "about")

  for (dir in dirs) {
    path <- file.path("md", dir)
    mkdirs(path)
    prefix <- file.path(path, "index")
    file <- sprintf("%s.md", prefix)
    if (!file_test("-f", file)) {
      url <- file.path(root, dir)
      printf("Downloading: %s -> %s\n", url, file)
      system2("pandoc", args=c("-s", url, "-o", file))
    }
  } # for (dir ...)
} # download()

clean <- function() {
  # All downloaded files
  files <- list.files("md", pattern="[.]md$", recursive=TRUE)

  for (file in files) {
    fileD <- file.path("md,trimmed", file)
    if (!file_test("-f", fileD)) {
      mkdirs(dirname(fileD))
      printf("Trimming: %s -> %s\n", file, fileD)

      # Read
      bfr <- readLines(file.path("md", file), warn=FALSE)

      # Trim
      start <- grep("/user/password", bfr, fixed=TRUE) + 4L
      end <- grep("[![Powered by Drupal", bfr, fixed=TRUE) - 1L
      bfr <- bfr[start:end]

      # Trim empty lines at the top
      idx <- which(nzchar(bfr))[1L]
      bfr <- bfr[idx:length(bfr)]

      # Trim empty lines at the bottom
      bfr <- rev(bfr)
      idx <- which(nzchar(bfr))[1L]
      bfr <- bfr[idx:length(bfr)]
      bfr <- rev(bfr)

      # Trim HTML/CSS markup
      bfr <- gsub("[{]style=[^}]*[}]", "", bfr)
      bfr <- trim(bfr)

      # Trim odd characters
      bfr <- gsub(" ", "", bfr)

      # Markdown translation
      bfr <- gsub("[\\]$", "  ", bfr)

      # Write
      writeLines(bfr, con=fileD)
    }
  } # for (file ...)
} # clean()

torsp <- function() {
  # All downloaded files
  pathS <- "md,trimmed"
  files <- list.files(pathS, pattern="[.]md$", recursive=TRUE)

  pathD <- "md,trimmed,rsp"
  for (file in files) {
    path <- dirname(file)
    fileD <- file.path(pathD, path, "index.md.rsp")
    if (!file_test("-f", fileD)) {
      mkdirs(dirname(fileD))
      fileS <- file.path("md,trimmed", file)
      printf("Copying: %s -> %s\n", fileS, fileD)
      file.copy(fileS, fileD)
    }
  } # for (file ...)
} # torsp()

tohtml <- function(force=FALSE) {
  use("R.rsp")

  # All downloaded files
  pathS <- "md,trimmed,rsp"
  files <- list.files(pathS, pattern="[.]rsp$", recursive=TRUE)

  for (file in files) {
    path <- dirname(file)
    fileS <- file.path(pathS, file)
    pathD <- file.path("md,trimmed,html", path)
    fileD <- file.path(pathD, gsub(".md.rsp", ".html", basename(fileS)))
    if (force || !file_test("-f", fileD)) {
      printf("Compiling: %s -> %s\n", fileS, fileD)

      # Find page title
      bfr <- readLines(fileS)
      idx <- which(nzchar(bfr))[1L]
      page <- trim(bfr[idx])

      # Find depth
      if (path == ".") {
        pathToRoot <- ""
      } else {
        depth <- length(unlist(strsplit(path, split="/")))
        pathToRoot <- paste(c(rep("..", times=depth), ""), collapse="/")
      }

      options(markdown.HTML.options="fragment_only")
      args <- list()
      args$pathToRoot <- pathToRoot
      html <- rfile(fileS, args=args, workdir=pathD)
      print(html)
    }
  } # for (file ...)
} # tohtml()


build <- function(force=FALSE) {
  use("R.rsp")

  # All downloaded files
  pathS <- "md,trimmed,html"
  files <- list.files(pathS, pattern="[.]html$", recursive=TRUE)

  for (file in files) {
    path <- dirname(file)
    fileS <- file.path(pathS, file)
    pathD <- file.path("html", path)
    fileD <- file.path(pathD, gsub(".md.rsp", ".html", basename(fileS)))
    if (force || !file_test("-f", fileD)) {
      printf("Compiling: %s -> %s\n", fileS, fileD)

      # Find page title
      bfr <- readLines(fileS)
      bfr <- grep("<h2>", bfr, value=TRUE)[1L]
      bfr <- gsub("(<h2>|</h2>)", "", bfr)
      page <- trim(bfr)
      if (is.na(page)) page <- ""

      # Find depth
      if (path == ".") {
        pathToRoot <- ""
      } else {
        depth <- length(unlist(strsplit(path, split="/")))
        pathToRoot <- paste(c(rep("..", times=depth), ""), collapse="/")
      }

      options(markdown.HTML.options="fragment_only")
      args <- list()
      args$pathToRoot <- pathToRoot
      args$body <- file.path("..", fileS)
      args$page <- page
      html <- rfile("includes/index.html.rsp", args=args, workdir=pathD)
      print(html)
    }
  } # for (file ...)
} # build()

download(); clean(); torsp(); tohtml();
build()
