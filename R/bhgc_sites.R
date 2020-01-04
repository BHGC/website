parse_gps <- function(s) {
  stopifnot(is.character(s))
  s <- gsub("NA", "NA_real_", s, fixed = TRUE)
  s <- gsub("(", "c(", s, fixed=TRUE)
  s <- sprintf("list(%s)", s)
#  s <- gsub("([0-9])(ft|'|'MSL)", "\\1", s)
  s <- eval(parse(text = s))
  s
} # parse_gps()

gps_md <- function(gps, url_md, ...) {
  stopifnot(is.list(gps) || (is.numeric(gps) && length(gps) <= 3))
  stopifnot(is.function(url_md))
  if (length(gps) == 0) return("")

  ## A list?
  if (is.list(gps)) {
    n <- length(gps)
    md <- character(length = n)
    for (kk in seq_len(n)) {
	  md[[kk]] <- Recall(gps[[kk]], url_md = url_md, ...)
    }
	if (!is.null(names(gps))) {
      md <- sprintf("%s: %s", names(gps), md);
	}
	  
	## Turn into a Markdown sublist?
    if (n > 1L) {
      md <- sprintf("  - %s", md);
      md <- paste(c("", md), collapse = "\n")
    }
	  
    return(md)
  }

  url_md(gps, ...)
} ## gps_md()


noaa_weather_url <- function(gps, when = c("now" = 0, "12h" = 12, "24h" = 24, "48h" = 48, "72h" = 72)) {
  lat <- gps[1]
  long <- gps[2]
  if (is.na(lat) || is.na(long)) return("")
  url <- sprintf("https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w3u=1&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&w9=snow&w10=fzg&w11=sleet&Submit=Submit&FcstType=digital&site=mtr&unit=0&dd=0&bw=0&textField1=%f&textField2=%f&AheadHour=%d", lat, long, when)
  url <- c(sprintf("https://forecast.weather.gov/MapClick.php?lat=%f&lon=%f&site=rev&unit=0&lg=en&FcstType=text", lat, long), url)
#  url <- c(url, sprintf("https://forecast.weather.gov/MapClick.php?lat=%s&lon=%s", lat, long))
  names(url) <- c("current conditions + 5-day forecast, forecast area", names(when))
  url
}

windy_weather_url <- function(gps, zoom=11L) {
  lat <- gps[1]
  long <- gps[2]
  if (is.na(lat) || is.na(long)) return("")
  url <- sprintf("https://www.windy.com/%f/%f?%f,%f,%d", lat, long, lat, long, zoom)
  names(url) <- "Windy"
  url
}

weather_url_md <- function(gps, ...) {
  url <- c(noaa_weather_url(gps = gps, ...), windy_weather_url(gps = gps, ...))
  md <- sprintf("[%s](%s)", names(url), url)
  paste(md, collapse = ",\n")
}

weather <- function(gps, ...) {
  gps <- gps[[1]]
  gps_md(gps = gps, url_md = weather_url_md, ...)
}

windy_weather <- function(gps, ...) {
  gps <- gps[[1]]
  gps_md(gps = gps, url_md = windy_weather_url_md, ...)
}


aerochart_url_md <- function(gps, chart = 301, zoom = 3) {
  lat <- gps[1]
  long <- gps[2]
  if (is.na(lat) || is.na(long)) return("")
  
  url <- sprintf("https://skyvector.com/?ll=%f,%f&chart=%d&zoom=%d",
                 lat, long, chart, zoom)
  names(url) <- c("SkyVector")
  md <- sprintf("[%s](%s)", names(url), url)
  paste(md, collapse = ",\n")
}
  
aerochart <- function(gps, ...) {
  gps <- gps[[1]]

  ## First launch site only
  gps <- gps[[1]]

  gps_md(gps = gps, url_md = aerochart_url_md, ...)
}


# "This is current accepted way to link to a specific lat lon
#  (rather than search for the nearest object).
#  https://maps.google.com/maps?z=12&t=m&q=loc:38.9419+-78.3020
#  - z is the zoom level (1-20)
#  - t is the map type ("m" map, "k" satellite, "h" hybrid,
#      "p" terrain, "e" GoogleEarth)
#  - q is the search query, if it is prefixed by loc:
#      then google assumes it is a lat lon separated by a +"
#  Source: https://goo.gl/2DD2yP
gmap_url_md <- function(gps, digits = 4L, ...) {
  lat <- round(gps[1], digits = digits)
  long <- round(gps[2], digits = digits)
  msl <- gps[3]
  if (is.na(lat) || is.na(long)) return("")
  url <- sprintf("https://maps.google.com/maps/preview?t=h&q=%s,%s", lat, long)
  md <- sprintf("[(%s,%s)](%s)", lat, long, url)
  if (!is.na(msl)) {
    md <- sprintf("%s @ %d' MSL", md, msl);
  }
  md
}

gmap <- function(gps, ...) {
  gps_md(gps = gps, url_md = gmap_url_md, ...)
}

phone <- function(numbers) {
  if (length(numbers) == 0) return(NULL)
  if (any(is.na(numbers))) return(NULL)
  numbers <- unlist(strsplit(numbers, split=",", fixed=TRUE))
  if (length(numbers) == 0) return(NULL)
  links <- sapply(numbers, FUN=function(s) {
    s <- unlist(strsplit(s, split="=", fixed=TRUE))
	s <- trim(s)
    number <- s[length(s)]
	label <- gsub("^[+]1[-]?", "", number)
    link <- sprintf('<a href="tel:%s">%s</a>', number, label)
    name <- s[-length(s)]
    if (length(name) == 1L) {
	  link <- sprintf('%s: %s', name, link)
	}
	link
  })
  links
} # phone()

soundings <- function(airport) {
  if (nchar(airport) == 0) return("")
  sprintf("[%s](https://www.topaflyers.com/weather/soundings/%s.png)",
          airport, tolower(airport))
} # soundings()


#' @importFrom R.utils isUrl
read_sites <- function(pathname = "content/sites/sites.dcf", pageSource = ".") {
  isUrl <- R.utils::isUrl
  if (isUrl(pageSource)) {
    url <- file.path(pageSource, pathname)
    message("Downloading: ", url)
    pathname <- downloadFile(url, pathname, path=".download", overwrite=TRUE)
    message("Downloaded: ", pathname)
  }
  bfr <- readLines(pathname)
  bfr <- grep("^#.*", bfr, value=TRUE, invert=TRUE)
  data <- local({
    con <- textConnection(bfr, open="r")
    on.exit(close(con))
    read.dcf(con)
  })
  
  ## If an entry has an extra newline by mistake, it'll show up here
  if (anyNA(data[, "Name"])) {
    names <- data[, "Name"]
    nas <- which(is.na(names)) - 1L
    stop("It looks like one of the following entries may have been split up (extra newline?): ", paste(sQuote(names[nas]), collapse = ", "))
  }
  
  data[is.na(data)] <- ""
  data <- as.data.frame(data, stringsAsFactors=FALSE)
  stopifnot(!anyNA(data$Name))
  
  data <- data[order(data$Name),]
  rownames(data) <- data$Name
  stopifnot(all(nzchar(rownames(data))))
  data[["LaunchGPS"]] <- lapply(data[["LaunchGPS"]], FUN = parse_gps)
  data[["LZGPS"]] <- lapply(data[["LZGPS"]], FUN = parse_gps)

  sites <- lapply(seq_len(nrow(data)), FUN = function(row) {
    as.list(data[row,])
  })
  names(sites) <- rownames(data)

  sites
}