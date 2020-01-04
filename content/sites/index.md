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
source("R/bhgc_sites.R")
data <- read_sites(pageSource = pageSource)
%>
<% for (name in rownames(data)) { %>
<% site <- data[name, ] %>
<% with(site, {

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

* Launch: <%= gmap(gps = LaunchGPS) %>
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
