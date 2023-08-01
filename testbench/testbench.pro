#
#  File Name:         testbench.pro
#
#  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
#  Contributor(s):
#     Louis Adriaens      louisadriaens@outlook.com
#
#
#  Description:
#  Script to run tests  
#  Based on OSVVM Framework
#
#
#
#  Revision History:
#    Date      Version    Description
#    08/2023   1.00       Initial revision

library osvvm_videobus

analyze  OsvvmTestCommonPkg.vhd

analyze  TestCtrl_e.vhd
analyze  TbVideoBus.vhd

RunTest  TbVideoBus_SendGet.vhd