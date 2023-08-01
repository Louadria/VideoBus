--
--  File Name:         VideoBusContext.vhd
--
--  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
--  Contributor(s):
--     Louis Adriaens      louisadriaens@outlook.com
--
--
--  Description:
--     Context definition for videobus based on OSVVM Framework
--
--
--
--  Revision History:
--    Date      Version    Description
--    08/2023   1.00       Initial revision
-- 

context VideoBusContext is
    library osvvm_common;  
    context osvvm_common.OsvvmCommonContext;

    library osvvm_videobus;
    use osvvm_videobus.bmplibpack.all;
    use osvvm_videobus.VideoBusRxPkg.all;
    use osvvm_videobus.VideoBusTxPkg.all;

end context VideoBusContext;