library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.numeric_std_unsigned.all;
    use ieee.math_real.all;

library OSVVM; 
    context OSVVM.OsvvmContext; 
    use osvvm.ScoreboardPkg_slv.all;

library osvvm_videobus;
    context osvvm_videobus.VideoBusContext;

use work.OsvvmTestCommonPkg.all;

entity TestCtrl is
    generic (
        VIDEO_HEIGHT : natural;
        VIDEO_WIDTH  : natural;
        PIXEL_DEPTH  : natural
    );
    port (
        -- Global signal Interface
        nReset : in std_logic;

        -- Transaction interface
        VideoBusRxTransRec : inout StreamRecType;
        VideoBusTxTransRec : inout StreamRecType
    );
end entity TestCtrl;