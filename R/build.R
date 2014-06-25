R.utils::use("R.utils")
use("R.rsp")
use("markdown")

pathD <- "html"
pathD <- Arguments$getWritablePath(pathD)

pathS <- "content"
pages <- list.files(pathS, pattern="[.]md$", recursive=TRUE)
for (ii in seq_along(pages)) {
  page <- pages[ii]

  # Markdown content
  content <- readLines(file.path(pathS, page))

  # Find page title
  idx <- which(nzchar(content))[1L]
  title <- trim(content[idx])
  message(sprintf("Page title: %s", title))

  # Output directory
  dir <- dirname(page)

  # Find depth
  if (dir == ".") {
    pathToRoot <- ""
  } else {
    depth <- length(unlist(strsplit(dir, split="/")))
    pathToRoot <- paste(c(rep("..", times=depth), ""), collapse="/")
  }

  # Setup RSP arguments
  args <- list()
  args$pathToRoot <- pathToRoot
  args$content <- content
  args$page <- title

  workdir <- file.path(pathD, dir)

  # Compile RSP Markdown to Markdown
  content <- rstring(content, type="application/x-rsp", args=args, workdir=workdir)

  # Compile Markdown to HTML
  content <- markdownToHTML(text=content, options="fragment_only")

  # Compile RSP HTML with content
  args$content <- content
  html <- rfile("templates/index.html.rsp", args=args, workdir=workdir)
  print(html)
} # for (ii ...)

# Copy assets
pathS <- "assets"
copyDirectory(pathS, file.path(pathD, pathS), recursive=TRUE)

