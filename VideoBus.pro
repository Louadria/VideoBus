#
#  File Name:         VideoBus.pro
#
#  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
#  Contributor(s):
#     Louis Adriaens      louisadriaens@outlook.com
#
#
#  Description:
#  Script to build the VideoBus packages. 
#  Based on OSVVM Framework
#
#
#
#  Revision History:
#    Date      Version    Description
#    08/2023   1.00       Initial revision

library osvvm_videobus
# <comp>pkg.vhd must always be in order before <comp>.vhd

analyze ./src/VideoBusRx_pkg.vhd
analyze ./src/VideoBusRx.vhd
analyze ./src/VideoBusTx_pkg.vhd
analyze ./src/VideoBusTx.vhd
analyze ./src/VideoBusPkg.vhd

analyze ./src/PassthroughDUT_pkg.vhd
analyze ./src/PassthroughDUT.vhd

analyze ./src/bmp_pack_pkg.vhd
analyze ./src/bmp_pack.vhd

analyze ./src/VideoBusContext.vhd