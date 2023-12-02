--
--  File Name:         VideoBusTx_pkg.vhd
--
--  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
--  Contributor(s):
--     Louis Adriaens      louisadriaens@outlook.com
--
--
--  Description:
--  Package for VideoBus transmitter Verification Component
--  Based on OSVVM Framework
--
--
--
--  Revision History:
--    Date      Version    Description
--    08/2023   1.00       Initial revision


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

library work;
    use work.VideoBusPkg.all;

package VideoBusTxPkg is

    type VideoBusOptionsType is (
        -- VideoBus Model Options
        FVAL_GUARD_CYCLES,   -- number of cycles between fval low  -> fval high
        LVAL_GUARD_CYCLES,   -- number of cycles between fval high -> lval high / lval low -> fval low
        DVAL_GUARD_CYCLES,   -- number of cycles between lval high -> dval high / dval low -> lval low

        -- Marker
        OPTIONS_MARKER
    );


    procedure GetVideoBusParameter(variable Params : inout ModelParametersPType; Operation : in VideoBusOptionsType; OutValue : out integer);

    ----------------------------------------
    component VideoBusTx is
    ----------------------------------------
    
        generic (
            MODEL_ID_NAME    : string := "";
            DEFAULT_DELAY    : time := 1 ns;   -- used for tpd (Total Propagation Delay)
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
            vid_fval_out    : out  std_logic;
            vid_lval_out    : out  std_logic;
            vid_dval_out    : out  std_logic;
            vid_data_out    : out  VideoDataArray(0 to NUM_DATA_STREAMS-1)(PIXEL_DEPTH-1 downto 0);

            -- Testbench Transaction Interface
            TransRec    : InOut StreamRecType
        );
    end component VideoBusTx;

end VideoBusTxPkg;

package body VideoBusTxPkg is

    procedure GetVideoBusParameter(variable Params : inout ModelParametersPType; Operation : in VideoBusOptionsType; OutValue : out integer) is
    begin
        OutValue := Params.Get(VideoBusOptionsType'pos(Operation));
    end procedure;

end package body;