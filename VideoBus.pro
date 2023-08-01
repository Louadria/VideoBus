library osvvm_videobus
# <comp>pkg.vhd must always be in order before <comp>.vhd

analyze ./src/VideoBusRx_pkg.vhd
analyze ./src/VideoBusRx.vhd
analyze ./src/VideoBusTx_pkg.vhd
analyze ./src/VideoBusTx.vhd

analyze ./src/PassthroughDUT_pkg.vhd
analyze ./src/PassthroughDUT.vhd

analyze ./src/bmp_pack.vhd

analyze ./src/VideoBusContext.vhd