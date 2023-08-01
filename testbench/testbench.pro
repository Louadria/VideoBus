# Script to run tests  

library osvvm_videobus

analyze  OsvvmTestCommonPkg.vhd

analyze  TestCtrl_e.vhd
analyze  TbVideoBus.vhd

RunTest  TbVideoBus_SendGet.vhd