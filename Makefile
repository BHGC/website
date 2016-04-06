#=====================================================================
# make site
#=====================================================================

#=====================================================================
# Setup
#=====================================================================
# CORE MACROS
ifeq ($(OS), Windows_NT)
CD=cd
else
CD=cd -P "$(CURDIR)"; cd   # This handles the case when CURDIR is a softlink
endif
CP=cp
MAKE=make
MV=mv
RM=rm -f
MKDIR=mkdir -p
RMDIR=$(RM) -r
ASPELL=aspell
SORT=sort
R_SCRIPT = Rscript

# Capabilities
HAS_ASPELL := $(shell $(R_SCRIPT) -e "cat(Sys.getenv('HAS_ASPELL', !is.na(utils:::aspell_find_program('aspell'))))")


#=====================================================================
# Configs
#=====================================================================


#=====================================================================
# Global
#=====================================================================
all: build


#=====================================================================
# Pages
#=====================================================================
build:
	$(R_SCRIPT) "R/build"


#=====================================================================
# Publish (=go live!)
#=====================================================================
deploy:
	rsync -avvz --perms --chmod=ugo+rx --progress html/ bhgc.org:~/public_html/bhgc.org/

publish: deploy


#=====================================================================
# Archive data bases
#=====================================================================
db_save:
	$(MKDIR) db/
	wget --no-check-certificate https://bhgc.glidelink.net/hangglider_report -O db/hangglider_report.html
	wget --no-check-certificate https://bhgc.glidelink.net/harness_report -O db/harness_report.html
	wget --no-check-certificate https://bhgc.glidelink.net/parachute_report -O db/parachute_report.html
	wget --no-check-certificate https://bhgc.glidelink.net/pilot_report -O db/pilot_report.html


#=====================================================================
# Cleanups
#=====================================================================
clean:
	$(RM) -rf html/
