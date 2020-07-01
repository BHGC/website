# Flying Sites - Bay Area

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
sites <- read_sites(pageSource = pageSource, tags = c("BayArea"))
R.utils::cstr(sites)
%>
<% for (kk in seq_along(sites)) { %>
<% site <- sites[[kk]] %>
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

  # WindAlert
  if (nzchar(WindAlertSite)) {
    seealso$`WindAlert Station` <- sprintf("https://www.windalert.com/spot/%s", WindAlertSite)
  }

  # Weather Underground Weather Station ID link
  if (nzchar(WeatherUndergroundStationID)) {
    seealso$`Weather Underground Station` <- sprintf("https://www.wunderground.com/dashboard/pws/%s", WeatherUndergroundStationID)
  }

  seealso <- sprintf("[%s](%s)", names(seealso), unlist(seealso))
  
  # "See also" text
  if (nzchar(SeeAlso)) {
    seealso <- c(SeeAlso, seealso)
  }
  
  seealso <- paste(seealso, collapse=", ")
%>	  
## <%=label%>

* Launch: <%= launch_map(site) %>
* LZ: <%= lz_map(site) %>
* Weather at launch: <%= weather(site) %>
* Live weather: <%= live_weather(site) %>
* Soundings: <%= soundings(site) %>
* WindTalker: <%= wind_talker(site) %>
* Aeronautical chart: <%= aerochart(site) %>
* Official page: <%= official_page(site) %>
* Requirements: <%= requirements(site) %>
* Sticker: <%= sticker(site) %>
* See also: <%= rstring(seealso) %>
* Notes: <%= notes(site) %>

<% }) # with(site, ...) %>
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