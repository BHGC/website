Flying Sites
------------

### FAA related

Temporary Flight Restrictions:
* [CA](http://tfr.faa.gov/tfr_map/states.jsp?select2=CA),
* [NV](http://tfr.faa.gov/tfr_map/states.jsp?select2=NV),
* [USA](http://www.aopa.org/tfr/faa-tfr-map.html)


<%-------------------------------------------------------------------
 SITES
 -------------------------------------------------------------------%>
<%
data <- read.dcf("content/flyingSites/sites.dcf")
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

  # GPS coordinates
  gps <- gsub("(", "c(", LaunchGPS, fixed=TRUE)
  gps <- sprintf("list(%s)", gps)
  gps <- gsub("ft", "", gps, fixed=TRUE)
  gps <- eval(parse(text=gps))

  seealso <- list()
  # ParaglidingEarth link
  if (nzchar(ParaglidingEarthSite)) {
    seealso$`Paragliding Earth` <- sprintf("http://www.paraglidingearth.com/pgearth/index.php?site=%s", ParaglidingEarthSite)
  }

  seealso <- sprintf("[%s](%s)", names(seealso), unlist(seealso))
  seealso <- paste(seealso, collapse=", ")
%>
### <%=label%>

* Requirements: <%= Requirements %>
* Weather: <%= weather(gps[[1]]) %>
* Live weather: <%= WeatherLive %>
* Site page: <%= SiteURL %>
* Sticker: <%= SiteSticker %>
* See also: <%= seealso %>
* Notes: <%= Notes %>

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
