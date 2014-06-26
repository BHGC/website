BHGC Website
============

This repository contains the framework for building the (future) [BHGC website].  This new website is mobile friendly.


### Contribute

In order to contribute to the content, signup for a GitHub account,
send your username to admin[at]bhgc.org and we'll give you permissions
to edit the [contents](content/).  To edit a page, just click on the
edit icon in the footer of every page on [BHGC website] to get to the
source file here on GitHub.  All editing is done in plain-text files
with [Markdown](http://www.wikipedia.org/wiki/Markdown) markup for
specifying headers, subheaders, links, images, lists etc.


### Build site on the fly

This repository is such that it is possible to build the site on the fly based on what is available in this GitHub repository.  In order to do this, just run [R](http://www.r-project.org/) (available on Windows, OSX and Linux) and call:
```s
source('http://bhgc.org/alpha/build#BHGC')
```
This will build a local copy of the site in local directory html/.  If
you clone this repository, then you can call:
```s
source('http://bhgc.org/alpha/build')
```
to build from the local files (which you can also edit).



[BHGC website]: http://bhgc.org/alpha/
