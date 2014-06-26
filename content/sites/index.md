# Flying Sites

## FAA related

Temporary Flight Restrictions:
* [CA](http://tfr.faa.gov/tfr_map/states.jsp?select2=CA),
* [NV](http://tfr.faa.gov/tfr_map/states.jsp?select2=NV),
* [USA](http://www.aopa.org/tfr/faa-tfr-map.html)


<%-------------------------------------------------------------------
 SITES
 -------------------------------------------------------------------%>
<%
gps <- function(s) {
  s <- gsub("(", "c(", s, fixed=TRUE)
  s <- sprintf("list(%s)", s)
  s <- gsub("([0-9])(ft|'|'MSL)", "\\1", s)
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
  names(url) <- c("current conditions", names(when))
  md <- sprintf("[%s](%s)", names(url), url)
  paste(md, collapse=",\n")
} # weather()


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
	md <- paste(md, collapse=", ")
    return(md)
  }
  gps <- gps[1:2]
  if (any(is.na(gps))) return("")
  url <- sprintf("http://maps.google.com/maps/preview?t=h&q=%f,%f", gps[1], gps[2])
  md <- sprintf("[(%f,%f)](%s)", gps[1], gps[2], url)
  paste(md, collapse=",\n")
} # gmap()

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
* Requirements: <%= rstring(Requirements) %>
* Weather: <%= weather(gps(LaunchGPS)[[1]]) %>
* Live weather: <%= rstring(WeatherLive) %>
* Official page: <%= rstring(OfficialURL) %>
* Sticker: <%= rstring(SiteSticker) %>
* See also: <%= rstring(seealso) %>
* Notes: <%= rstring(Notes) %>

<% }) # with(data[name,], ...) %>
<% } # for (name ...) %>

<%-------------------------------------------------------------------
 REFERENCES
 -------------------------------------------------------------------%>
[WOR]: http://www.wingsofrogallo.org/
[Wings of Rogallo (WOR)]: http://www.wingsofrogallo.org/
[Sonoma Wings]: http://sonomawings.com/site-guides/
[MCHGA]: http://www.mchga.org/
[Marin County Hang Gliding Association (MCHGA)]: http://www.mchga.org/
