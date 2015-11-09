# Flying Sites

<%-- ALERT (CALL FOR HELP) --%>
<div class="alert alert-warning" role="alert">
Several of the below sites lack information on for instance launch
coordinates, which in turn are used to generate the weather links.
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
  [CA](http://tfr.faa.gov/tfr_map/states.jsp?select2=CA),
  [NV](http://tfr.faa.gov/tfr_map/states.jsp?select2=NV),
  [USA](http://tfr.faa.gov/tfr_map_ims/html/index.html)
* California Fire Maps:
  [CAL file](https://www.google.com/maps/d/u/0/viewer?mid=zp8nK_5H0MFQ.kzTmU5
  ([source](http://www.fire.ca.gov/general/firemaps.php)XK-qJQ))


<%-------------------------------------------------------------------
 SITES
 -------------------------------------------------------------------%>
<%
gps <- function(s) {
  s <- gsub("(", "c(", s, fixed=TRUE)
  s <- sprintf("list(%s)", s)
#  s <- gsub("([0-9])(ft|'|'MSL)", "\\1", s)
  s <- eval(parse(text=s))
  s
} # gps()


weather <- function(gps, when=c("now"=0, "12h"=12,"24h"=24, "48h"=48, "72h"=72)) {
  gps <- gps[1:2]
  if (any(is.na(gps))) return()
  url <-
  sprintf("http://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w3u=1&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&w9=snow&w10=fzg&w11=sleet&Submit=Submit&FcstType=digital&site=mtr&unit=0&dd=0&bw=0&textField1=%f&textField2=%f&AheadHour=%d",
  gps[1], gps[2], when)
  url <-
  c(sprintf("http://forecast.weather.gov/MapClick.php?lat=%f&lon=%f&site=rev&unit=0&lg=en&FcstType=text",
  gps[1], gps[2]), url)
  names(url) <- c("current conditions + 5-day forecast", names(when))
  md <- sprintf("[%s](%s)", names(url), url)
  paste(md, collapse=",\n")
} # weather()


aerochart <- function(gps, chart=301, zoom=3) {
  gps <- gps[1:2]
  if (any(is.na(gps))) return()
  url <- sprintf("http://skyvector.com/?ll=%f,%f&chart=%d&zoom=%d",
                 gps[1], gps[2], chart, zoom)
  names(url) <- c("SkyVector")
  md <- sprintf("[%s](%s)", names(url), url)
  paste(md, collapse=",\n")
} # aerochart()


# "This is current accepted way to link to a specific lat lon
#  (rather than search for the nearest object).
#  http://maps.google.com/maps?z=12&t=m&q=loc:38.9419+-78.3020
#  - z is the zoom level (1-20)
#  - t is the map type ("m" map, "k" satellite, "h" hybrid,
#      "p" terrain, "e" GoogleEarth)
#  - q is the search query, if it is prefixed by loc:
#      then google assumes it is a lat lon separated by a +"
#  Source: http://goo.gl/2DD2yP
gmap <- function(gps) {
  if (length(gps) == 0) return("")
  if (is.character(gps)) gps <- gps(gps)
  if (is.list(gps)) {
    md <- sapply(gps, FUN=gmap)
	if (!is.null(names(gps))) {
      md <- sprintf("%s: %s", names(gps), md);
	}
    if (length(md) > 1L) {
      md <- sprintf("  - %s", md);
      md <- paste(c("", md), collapse="\n")
    }
    return(md)
  }
  msl <- gps[3]
  gps <- gps[1:2]
  if (any(is.na(gps))) return("")
  url <- sprintf("http://maps.google.com/maps/preview?t=h&q=%f,%f", gps[1], gps[2])
  md <- sprintf("[(%f,%f)](%s)", gps[1], gps[2], url)
  if (!is.na(msl)) {
    md <- sprintf("%s @ %d' MSL", md, msl);
  }
  if (length(md) > 1L) {
    md <- sprintf("  - %s", md);
    md <- paste(md, collapse="\n")
  }
  md 
} # gmap()

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

pathname <- "content/sites/sites.dcf"
if (isUrl(pageSource)) {
  url <- file.path(pageSource, pathname)
  message("Downloading: ", url)
  pathname <- downloadFile(url, pathname, path=".download", overwrite=TRUE)
  message("Downloaded: ", pathname)
}
data <- read.dcf(pathname)
data[is.na(data)] <- ""
data <- as.data.frame(data, stringsAsFactors=FALSE)
data <- data[order(data$Name),]
rownames(data) <- data$Name
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
    seealso$`Paragliding Earth` <- sprintf("http://www.paraglidingearth.com/pgearth/index.php?site=%s", ParaglidingEarthSite)
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
* Aeronautical charts: <%= aerochart(gps(LaunchGPS)[[1]]) %>
* Weather: <%= weather(gps(LaunchGPS)[[1]]) %>
* Live weather: <%= rstring(WeatherLive) %>
* WindTalker: <%= paste(phone(WindTalker), collapse=", ") %>
* Official page: <%= rstring(OfficialURL) %>
* Requirements: <%= rstring(Requirements) %>
* Sticker: <%= rstring(SiteSticker) %>
* See also: <%= rstring(seealso) %>
* Notes: <%= rstring(Notes) %>

<% }) # with(data[name,], ...) %>
<% } # for (name ...) %>



<div class="alert alert-info" role="alert" style="margin-top: 5ex;">
The weather links for each site are based on the location of the
launch (based on the longitudinal and latitudinal coordinates of the
first launch per site).
</div>


<%-------------------------------------------------------------------
 REFERENCES
 -------------------------------------------------------------------%>
[WOR]: http://www.wingsofrogallo.org/
[Wings of Rogallo (WOR)]: http://www.wingsofrogallo.org/
[Sonoma Wings]: http://sonomawings.com/site-guides/
[MCHGA]: http://www.mchga.org/
[Marin County Hang Gliding Association (MCHGA)]: http://www.mchga.org/
