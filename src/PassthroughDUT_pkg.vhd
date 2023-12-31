--
--  File Name:         PassthroughDUT_pkg.vhd
--
--  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
--  Contributor(s):
--     Louis Adriaens      louisadriaens@outlook.com
--
--
--  Description:
--     Package for the passthrough DUT
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

package PassthroughDUTPkg is

    type VideoDataArray is array (natural range <>) of std_logic_vector;

    ----------------------------------------
    component PassthroughDUT is
    ----------------------------------------
    
        generic (
            PIXEL_DEPTH      : natural := 24; -- number of bits in a pixel
            NUM_DATA_STREAMS : natural := 1   -- number of pixel data streams
        );
        port (
            -- VideoBus input
            vid_fval_in    : in  std_logic;
            vid_lval_in    : in  std_logic;
            vid_dval_in    : in  std_logic;
            vid_data_in    : in  VideoDataArray(0 to NUM_DATA_STREAMS-1)(PIXEL_DEPTH-1 downto 0);
            -- VideoBus output
            vid_fval_out   : out std_logic;
            vid_lval_out   : out std_logic;
            vid_dval_out   : out std_logic;
            vid_data_out   : out VideoDataArray(0 to NUM_DATA_STREAMS-1)(PIXEL_DEPTH-1 downto 0)
        );
    end component PassthroughDUT;

end PassthroughDUTPkg;