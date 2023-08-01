--
--  File Name:         TbVideoBus.vhd
--
--  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
--  Contributor(s):
--     Louis Adriaens      louisadriaens@outlook.com
--
--
--  Description:
--     Test Harness for videobus based on OSVVM Framework
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

library OSVVM; 
    context OSVVM.OsvvmContext; 
    use osvvm.ScoreboardPkg_slv.all;

library osvvm_videobus;
    context osvvm_videobus.VideoBusContext;

entity TbVideoBus is
    generic (
        VIDEO_HEIGHT     : natural := 64;  -- number of lines in a frame 
        VIDEO_WIDTH      : natural := 64;  -- number of pixels in a line
        PIXEL_DEPTH      : natural := 24; -- number of bits in a pixel (RGB = 3*8)
        NUM_DATA_STREAMS : natural := 1   -- number of data streams
    );
end entity TbVideoBus;
architecture TestHarness of TbVideoBus is
    -- signals / constants
    constant tperiod_Clk : time := 12.5 ns; -- 80Mhz
    constant tpd         : time := 2 ns;

    signal Clk         : std_logic;
    signal nReset      : std_logic;

    -------------------------------------------------------
    -- DUT
    -------------------------------------------------------

    --- VideoBus input
    signal vid_fval_in    : std_logic;
    signal vid_lval_in    : std_logic;
    signal vid_dval_in    : std_logic;
    signal vid_data_in    : std_logic_vector(PIXEL_DEPTH-1 downto 0);
    -- VideoBus output
    signal vid_fval_out   : std_logic;
    signal vid_lval_out   : std_logic;
    signal vid_dval_out   : std_logic;
    signal vid_data_out   : std_logic_vector(PIXEL_DEPTH-1 downto 0);

    -------------------------------------------------------
    -- VideoBusRx (VC)
    -------------------------------------------------------
    signal VideoBusRxTransRec : StreamRecType (
        DataToModel(PIXEL_DEPTH-1 downto 0),
        DataFromModel(PIXEL_DEPTH-1 downto 0),
        ParamToModel(7 downto 0), -- param is not used
        ParamFromModel(7 downto 0)
    );

    -------------------------------------------------------
    -- VideoBusTx (VC)
    -------------------------------------------------------
    signal VideoBusTxTransRec : StreamRecType (
        DataToModel(PIXEL_DEPTH-1 downto 0),
        DataFromModel(PIXEL_DEPTH-1 downto 0),
        ParamToModel(7 downto 0), -- param is not used
        ParamFromModel(7 downto 0)
    );

    -------------------------------------------------------
    -- TestCtrl 
    -------------------------------------------------------
    component TestCtrl is
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
    end component;
begin
    -- create Clock
    Osvvm.TbUtilPkg.CreateClock (
        Clk        => Clk,
        Period     => Tperiod_Clk
    );

    -- create nReset
    Osvvm.TbUtilPkg.CreateReset (
        Reset       => nReset,
        ResetActive => '0',
        Clk         => Clk,
        Period      => 7 * tperiod_Clk,
        tpd         => tpd
    );

    -------------------------------------------------------
    -- DUT
    -------------------------------------------------------
    passthroughdut_inst: entity work.PassthroughDUT
    generic map (
        PIXEL_DEPTH      => PIXEL_DEPTH,
        NUM_DATA_STREAMS => NUM_DATA_STREAMS
    )
    port map (
        vid_fval_in     => vid_fval_in,
        vid_lval_in     => vid_lval_in,
        vid_dval_in     => vid_dval_in,
        vid_data_in(0)  => vid_data_in,
        vid_fval_out    => vid_fval_out,
        vid_lval_out    => vid_lval_out,
        vid_dval_out    => vid_dval_out,
        vid_data_out(0) => vid_data_out
    );

    -------------------------------------------------------
    -- VideoBusRx (VC)
    -------------------------------------------------------
    VideoBusRx_1: VideoBusRx
    generic map (
        VIDEO_HEIGHT => VIDEO_HEIGHT,
        VIDEO_WIDTH => VIDEO_WIDTH,
        PIXEL_DEPTH => PIXEL_DEPTH,  -- number of bits in a pixel
        NUM_DATA_STREAMS => 1 
    )
    port map (
        -- Globals
        Clk     => Clk,

        -- VideoBus Functional Interface
        -- VideoBus Receiver: input
        vid_fval_in    =>  vid_fval_out,
        vid_lval_in    =>  vid_lval_out,
        vid_dval_in    =>  vid_dval_out,
        vid_data_in(0) =>  vid_data_out,

        -- Testbench Transaction Interface
        TransRec    => VideoBusRxTransRec
    );

    -------------------------------------------------------
    -- VideoBusTx (VC)
    -------------------------------------------------------
    VideoBusTx_1: VideoBusTx
      generic map (
        DEFAULT_DELAY    => tpd,
        VIDEO_HEIGHT     => VIDEO_HEIGHT,
        VIDEO_WIDTH      => VIDEO_WIDTH,
        PIXEL_DEPTH      => PIXEL_DEPTH,
        NUM_DATA_STREAMS => NUM_DATA_STREAMS
      )
      port map (
        Clk             => Clk,
        vid_fval_out    => vid_fval_in,
        vid_lval_out    => vid_lval_in,
        vid_dval_out    => vid_dval_in,
        vid_data_out(0) => vid_data_in,
        TransRec        => VideoBusTxTransRec
      );

    -------------------------------------------------------
    -- BMP logger
    -------------------------------------------------------
    write_bmp_file_inst: entity work.write_bmp_file
    generic map (
        output_file      => "bmp_logs/bmp_frame_",
        g_num_of_frames  => 20,
        VIDEO_WIDTH      => VIDEO_HEIGHT,
        VIDEO_HEIGHT     => VIDEO_WIDTH,
        NUM_DATA_STREAMS => 1 
    )
    port map (
        in_vsync   => vid_fval_out,
        in_hsync   => vid_lval_out,
        in_clk     => Clk,
        in_data_en => vid_dval_out,
        in_data(0) => vid_data_out
    );

    -------------------------------------------------------
    -- TestCtrl
    -------------------------------------------------------
    TestCtrl_1 : TestCtrl
    generic map (
        VIDEO_HEIGHT => VIDEO_HEIGHT,
        VIDEO_WIDTH  => VIDEO_WIDTH,
        PIXEL_DEPTH  => PIXEL_DEPTH
    )
    port map (
        nReset => nReset,
        VideoBusRxTransRec => VideoBusRxTransRec,
        VideoBusTxTransRec => VideoBusTxTransRec
    );
end architecture;