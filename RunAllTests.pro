TestSuite VideoBus
library osvvm_videobus

build ./VideoBus.pro

# make the bmp_logs directory if it does not exist
set CURR_DIR [pwd]
if {![file exists $CURR_DIR/bmp_logs]} {
    puts "Making new directory for bmp logs in [pwd]"
    file mkdir $CURR_DIR/bmp_logs
}
 
include ./testbench