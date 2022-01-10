link_split <- function(x, prefix = "") {
  y <- unlist(strsplit(x, split = ",", fixed = TRUE))
  y <- gsub("(^[ ]|[ ]$)", "", y)
  y <- gsub("^([^=]+)=([^']+)$", "\\1='\\2'", y)
  y <- gsub("^([^=']+)$", "'\\1'", y)
  y <- sprintf("c(%s)", paste(y, collapse = ", "))
  y <- eval(parse(text = y))
  names <- names(y)
  if (is.null(names)) {
    names <- y
  } else {
    names[!nzchar(names)] <- y
  }
  names <- paste0(prefix, names)
  names(y) <- names
  y
}

parse_gps <- function(s) {
  stopifnot(is.character(s))
  s <- gsub("NA", "NA_real_", s, fixed = TRUE)
  s <- gsub("(", "c(", s, fixed=TRUE)
  s <- sprintf("list(%s)", s)
#  s <- gsub("([0-9])(ft|'|'MSL)", "\\1", s)
  s <- eval(parse(text = s))
  s
} # parse_gps()

parse_webcams <- function(s) {
  stopifnot(is.character(s))
  s <- gsub("NA", "NA_real_", s, fixed = TRUE)
  s <- gsub("(", "c(", s, fixed=TRUE)
  s <- sprintf("list(%s)", s)
  s <- eval(parse(text = s))
  s
} # parse_webcams()

gps_md <- function(gps, url_md, ...) {
  stopifnot(is.list(gps) || (is.numeric(gps) && length(gps) <= 3))
  stopifnot(is.list(url_md) || is.function(url_md))
  if (length(gps) == 0) return("")
  if (!is.list(url_md)) url_md <- list(url_md)

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

  md <- lapply(url_md, FUN = function(url_md) url_md(gps, ...))
  paste(unlist(md), collapse = " ")
} ## gps_md()


noaa_weather_url <- function(gps, when = c("now" = 0, "12h" = 12, "24h" = 24, "48h" = 48, "72h" = 72), type = c("graphical", "digital")) {
  lat <- gps[1]
  long <- gps[2]
  type <- match.arg(type)

  ## Nothing todo?
  if (is.na(lat) || is.na(long)) return("")

  ## Forecast
  url <- sprintf("https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w3u=1&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&w9=snow&w10=fzg&w11=sleet&Submit=Submit&FcstType=%s&site=mtr&unit=0&dd=0&bw=0&textField1=%f&textField2=%f&AheadHour=%d", type, lat, long, when)
  
  ## Current weather
  url <- c(sprintf("https://forecast.weather.gov/MapClick.php?lat=%f&lon=%f&site=rev&unit=0&lg=en&FcstType=text", lat, long), url)
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

weather <- function(...) UseMethod("weather")

weather.bhgc_site <- function(site, ...) {
  gps <- site$LaunchGPS
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

aerochart <- function(...) UseMethod("aerochart")

aerochart.bhgc_site <- function(site, ...) {
  gps <- site$LaunchGPS
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


#  Source: https://www.opentopomap.org/
opentopo_url_md <- function(gps, digits = 5L, zoom = 16, ...) {
  lat <- round(gps[1], digits = digits)
  long <- round(gps[2], digits = digits)
  if (is.na(lat) || is.na(long)) return("")
  url <- sprintf("https://www.opentopomap.org/#marker=%s/%s/%s", zoom, lat, long)
  md <- sprintf("[topo](%s)", url)
  md
}


launch_map <- function(...) UseMethod("launch_map")

launch_map.bhgc_site <- function(site, ...) {
  gps <- site$LaunchGPS
  gps_md(gps = gps, url_md = list(gmap_url_md, opentopo_url_md), ...)
}

lz_map <- function(...) UseMethod("lz_map")

lz_map.bhgc_site <- function(site, ...) {
  gps <- site$LZGPS
  gps_md(gps = gps, url_md = list(gmap_url_md, opentopo_url_md), ...)
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

wind_talker <- function(...) UseMethod("wind_talker")

wind_talker.bhgc_site <- function(site, ...) {
   paste(phone(site$WindTalker), collapse=", ")
}
 
soundings <- function(...) UseMethod("soundings")

soundings.bhgc_site <- function(site, ...) {
  airport <- site$Soundings
  if (nchar(airport) == 0) return("")
  sprintf("[%s](https://www.topaflyers.com/weather/soundings/%s.png)",
          airport, tolower(airport))
}


live_weather <- function(...) UseMethod("live_weather")

live_weather.bhgc_site <- function(site, ...) {
  with(site, {
    liveweather <- list()

    # WindAlert
    if (nzchar(WindAlertSite)) {
      values <- link_split(WindAlertSite, prefix = "WA:")
      liveweather[names(values)] <- sprintf("https://www.windalert.com/spot/%s", values)
    }
  
    # Weather Underground Weather Station ID link
    if (nzchar(WeatherUndergroundStationID)) {
      values <- link_split(WeatherUndergroundStationID, prefix = "WU:")
      liveweather[names(values)] <- sprintf("https://www.wunderground.com/dashboard/pws/%s", values)
    }

    liveweather <- sprintf("[%s](%s)", names(liveweather), unlist(liveweather))
  
    # "Live weather" text
    if (nzchar(WeatherLive)) {
      liveweather <- c(WeatherLive, liveweather)
    }
    
    rstring(liveweather)
  }) ## with()
}

official_page <- function(...) UseMethod("official_page")

official_page.bhgc_site <- function(site, ...) {
 rstring(site$OfficialURL)
} 

requirements <- function(...) UseMethod("requirements")

requirements.bhgc_site <- function(site, ...) {
 rstring(site$Requirements)
} 

see_also <- function(...) UseMethod("see_also")

see_also.bhgc_site <- function(site, ...) {
  with(site, {
    seealso <- list()
    
    # ParaglidingEarth link
    if (nzchar(ParaglidingEarthSite)) {
      values <- link_split(ParaglidingEarthSite, prefix = "PGE:")
      seealso[names(values)] <- sprintf("https://www.paraglidingearth.com/pgearth/index.php?site=%s", values)
    }

    seealso <- sprintf("[%s](%s)", names(seealso), unlist(seealso))

    # "See also" text
    if (nzchar(SeeAlso)) {
      seealso <- c(SeeAlso, seealso)
    }
    
    rstring(seealso)
  })
} 

sticker <- function(...) UseMethod("sticker")

sticker.bhgc_site <- function(site, ...) {
 rstring(site$SiteSticker)
} 


notes <- function(...) UseMethod("notes")

notes.bhgc_site <- function(site, ...) {
 rstring(site$Notes)
} 


webcams <- function(...) UseMethod("webcams")

webcams.bhgc_site <- function(site, ...) {
 urls <- unlist(site$Webcams)
 md <- sprintf("[%s](%s)", names(urls), urls)
 md <- paste(md, collapse = ", ")
 md
} 


#' @importFrom R.utils isUrl
read_sites <- function(pathname = "content/sites/sites.dcf", pageSource = ".", tags = NULL) {
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
  data[["Webcams"]] <- lapply(data[["Webcams"]], FUN = parse_webcams)

  sites <- lapply(seq_len(nrow(data)), FUN = function(row) {
    site <- as.list(data[row,])
    site$Tags <- unlist(strsplit(site$Tags, split="[, ]"), use.names=FALSE)
    site$Tags <- site$Tags[nzchar(site$Tags)]
    structure(site, class = "bhgc_site")
  })
  names(sites) <- rownames(data)

  if (!is.null(tags)) {
    keep <- vapply(sites, FUN = function(site) {
      all(tags %in% site$Tags)
    }, FUN.VALUE = FALSE)
    sites <- sites[keep]
  }

  sites
}
