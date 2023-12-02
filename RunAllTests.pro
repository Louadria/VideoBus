#
#  File Name:         RunAllTests.pro
#
#  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
#  Contributor(s):
#     Louis Adriaens      louisadriaens@outlook.com
#
#
#  Description:
#  Script to build the VideoBus packages, make bmp_logs folder, and start the testbench. 
#  Based on OSVVM Framework
#
#
#
#  Revision History:
#    Date      Version    Description
#    08/2023   1.00       Initial revision


TestSuite VideoBus
library osvvm_videobus

# build ./VideoBus.pro

# make the bmp_logs directory if it does not exist
set CURR_DIR [pwd]
if {![file exists $CURR_DIR/bmp_logs]} {
    puts "Making new directory for bmp logs in [pwd]"
    file mkdir $CURR_DIR/bmp_logs
}
 
include ./testbench