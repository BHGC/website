<%
country <- "Austria"
tag <- tolower(country)
names(tag) <- country
%>
# Flying Sites - <%= country %>

## Regional

* [Föhn forecast in the Alps](https://www.windinfo.eu/wettervorhersage/foehndiagramme/)
* [DHV Alp Forecasts](https://www.dhv.de/2/piloteninfos/wetter/)

<%@include file="content/sites/incl/index.md.rsp"%>
