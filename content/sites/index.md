<%
country <- "USA"
%>
# Flying Sites - <%= country %>

See also:

* [Flying Sites - Bay Area](<%=pathToRoot%>sites/bayarea/index.html)
  - [Flying Sites - Mt Tamalpais](<%=pathToRoot%>sites/tam/index.html)
* [Flying Sites - Lake Tahoe-Reno Area](<%=pathToRoot%>sites/laketahoe-renoarea/index.html)
* [Flying Sites - Lakeview](<%=pathToRoot%>sites/lakeview/index.html)
* [Flying Sites - Mendocino](<%=pathToRoot%>sites/mendocino/index.html)
* [Flying Sites - Owens Valley](<%=pathToRoot%>sites/owensvalley/index.html)
* [Flying Sites - Sierra Nevada](<%=pathToRoot%>sites/sierranevada/index.html)
* [Flying Sites - Sonora Pass-Mono-Mammoth](<%=pathToRoot%>sites/sonorapass-mono-mammoth/index.html)
* [Flying Sites - Southern California](<%=pathToRoot%>sites/socal/index.html)
* [Flying Sites - Mexico](<%=pathToRoot%>sites/mexico/index.html)
* [Flying Sites - Sweden](<%=pathToRoot%>sites/sweden/index.html)
* [Flying Sites - The Alps](<%=pathToRoot%>sites/alps/index.html)


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
  
* Fire and Red Alert Maps:
   - [Cal Fire](https://www.fire.ca.gov/incidents/) - click layer to see 'Red Alert'
   - [National Wildfire Coordinating Group](https://maps.nwcg.gov/sa/#/%3F/%3F/37.9484/-123.0715/7)


<%-------------------------------------------------------------------
 SITES
 -------------------------------------------------------------------%>
<% tag <- NULL %>
<%@include file="content/sites/incl/index.md.rsp"%>
