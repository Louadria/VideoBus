--
--  File Name:         VideoBusRx_pkg.vhd
--
--  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
--  Contributor(s):
--     Louis Adriaens      louisadriaens@outlook.com
--
--
--  Description:
--  Package for VideoBus receiver Verification Component
--  Based on OSVVM Framework
--
--
--
--  Revision History:
--    Date      Version    Description
--    08/2023   1.00       Initial revision
-- 

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.numeric_std_unsigned.all;
    use ieee.math_real.all;

library osvvm;
    context osvvm.OsvvmContext;
    use osvvm.ScoreboardPkg_slv.all;

library osvvm_common;
    context osvvm_common.OsvvmCommonContext;

package VideoBusRxPkg is

    type VideoDataArray is array (natural range <>) of std_logic_vector;

    ----------------------------------------
    component VideoBusRx is
    ----------------------------------------
    
        generic (
            MODEL_ID_NAME    : string := "";
            VIDEO_HEIGHT     : natural := 64;  -- number of lines in a frame
            VIDEO_WIDTH      : natural := 64;  -- number of pixels in a line
            PIXEL_DEPTH      : natural := 24;  -- number of bits in a pixel
            NUM_DATA_STREAMS : natural := 1    -- number of pixel data streams
        );
        port (
            -- Globals
            Clk     : in std_logic;

            -- VideoBus Functional Interface
            -- VideoBus Receiver: input
            vid_fval_in    : in  std_logic;
            vid_lval_in    : in  std_logic;
            vid_dval_in    : in  std_logic;
            vid_data_in    : in  VideoDataArray(0 to NUM_DATA_STREAMS-1)(PIXEL_DEPTH-1 downto 0);
            
            -- Testbench Transaction Interface
            TransRec    : InOut StreamRecType
        );
    end component VideoBusRx;

end VideoBusRxPkg;