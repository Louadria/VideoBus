library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

use work.PassthroughDUTPkg.all;

entity PassthroughDUT is
    generic (
        PIXEL_DEPTH      : natural := 24; -- number of bits in a pixel
        NUM_DATA_STREAMS : natural := 1
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
end entity;

architecture SimplePassthrough of PassthroughDUT is
begin
    vid_fval_out <= vid_fval_in;
    vid_lval_out <= vid_lval_in;
    vid_dval_out <= vid_dval_in;
    vid_data_out <= vid_data_in;
end architecture;
