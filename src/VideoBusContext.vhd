context VideoBusContext is
    library osvvm_common;  
    context osvvm_common.OsvvmCommonContext;

    library osvvm_videobus;
    use osvvm_videobus.bmplibpack.all;
    use osvvm_videobus.VideoBusRxPkg.all;
    use osvvm_videobus.VideoBusTxPkg.all;

end context VideoBusContext;