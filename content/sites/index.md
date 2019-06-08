# Flying Sites

<%-- ALERT (CALL FOR HELP) --%>
<div class="alert alert-warning" role="alert">
Several of the below sites lack information on for instance launch
coordinates, which in turn are used to generate the "Weather:" links.
You can help out by finding such information and reporting them back.
If you <a class="alert-link" id="edit"
href="https://github.com/join">get a GitHub account</a>, you can even
<span style="white-space: nowrap;"><a class="alert-link" id="edit"
href="https://github.com/BHGC/website/tree/master/content/sites/sites.dcf">edit</a>
<span class="glyphicon glyphicon-edit"></span></span> 
the underlying database (and all other pages) directly in the browser.
</div>


## Regional

* FAA Temporary Flight Restrictions:
  [CA](https://tfr.faa.gov/tfr_map/states.jsp?select2=CA),
  [NV](https://tfr.faa.gov/tfr_map/states.jsp?select2=NV),
  [USA](https://tfr.faa.gov/tfr_map_ims/html/index.html)
* California Red Alert Map: [Google Map](https://www.google.com/maps/d/viewer?mid=1yFb10tX5BPvSXtBWgOF1eZDVGE8&ll=38.48938213414961%2C-120.44777037662482&z=6) ([source](http://www.fire.ca.gov/communications/communications_firesafety_redflagwarning))
* California Fire Map 2019: [Google Map](https://www.google.com/maps/d/viewer?mid=1jWr_7HBs-dNjhRa1r32I5Grrk4nrd_CM) ([source](https://www.fire.ca.gov/general/firemaps.php))


<%-------------------------------------------------------------------
 SITES
 -------------------------------------------------------------------%>
<%
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
  url <- c(noaa_weather_url(gps, ...), windy_weather_url(gps, ...))
  md <- sprintf("[%s](%s)", names(url), url)
  paste(md, collapse = ",\n")
}

weather <- function(gps, ...) {
  gps <- gps[[1]]
  gps_md(gps, url_md = weather_url_md, ...)
}

windy_weather <- function(gps, ...) {
  gps <- gps[[1]]
  gps_md(gps, url_md = windy_weather_url_md, ...)
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

  gps_md(gps, url_md = aerochart_url_md, ...)
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
  gps_md(gps, url_md = gmap_url_md, ...)
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

pathname <- "content/sites/sites.dcf"
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
%>
<% for (name in rownames(data)) { %>
<% with(data[name,], {

  # Full site name
  label <- Name
  if (nzchar(Nickname)) label <- sprintf("%s (%s)", label, Nickname)
  if (nzchar(State)) label <- sprintf("%s, %s", label, State)

  seealso <- list()

  # ParaglidingEarth link
  if (nzchar(ParaglidingEarthSite)) {
    seealso$`Paragliding Earth` <- sprintf("https://www.paraglidingearth.com/pgearth/index.php?site=%s", ParaglidingEarthSite)
  }

  seealso <- sprintf("[%s](%s)", names(seealso), unlist(seealso))
  
  # "See also" text
  if (nzchar(SeeAlso)) {
    seealso <- c(SeeAlso, seealso)
  }
  
  seealso <- paste(seealso, collapse=", ")
%>
## <%=label%>

* Launch: <%= gmap(LaunchGPS) %>
* LZ: <%= gmap(LZGPS) %>
* Weather at launch: <%= weather(LaunchGPS) %>
* Live weather: <%= rstring(WeatherLive) %>
* Soundings: <%= soundings(Soundings) %>
* WindTalker: <%= paste(phone(WindTalker), collapse=", ") %>
* Aeronautical chart: <%= aerochart(LaunchGPS) %>
* Official page: <%= rstring(OfficialURL) %>
* Requirements: <%= rstring(Requirements) %>
* Sticker: <%= rstring(SiteSticker) %>
* See also: <%= rstring(seealso) %>
* Notes: <%= rstring(Notes) %>

<% }) # with(data[name,], ...) %>
<% } # for (name ...) %>


<div class="alert alert-info" role="alert" style="margin-top: 5ex;">
The "Weather:" links for each site are based on latitudinal and
longitudinal coordinates of the launch.
The National Weather Service generates forcasts for a large number of
retangular-shaped "forecast areas" place in a grid all over the US.
The size of these areas is 2.5-by-2.5 km.
</div>


<%-------------------------------------------------------------------
 REFERENCES
 -------------------------------------------------------------------%>
[WOR]: https://www.wingsofrogallo.org/
[Wings of Rogallo (WOR)]: https://www.wingsofrogallo.org/
[Sonoma Wings]: http://sonomawings.com/site-guides/
[MCHGA]: https://www.mchga.org/
[Marin County Hang Gliding Association (MCHGA)]: https://www.mchga.org/
