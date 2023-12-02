--
--  File Name:         bmp_pack.vhd
--
--  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
--  Contributor(s):
--     Louis Adriaens      louisadriaens@outlook.com
--     Limor Yonatani
--
--
--  Description:
--     Bitmap logger
--
--
--
--  Revision History:
--    Date      Version    Description
--    08/2023   1.00       Initial revision
-- 

-- HOW TO USE:
   -- write_bmp_file_inst: entity work.write_bmp_file
   --  generic map (
   --      output_file     => "bmp_logs/bmp_frame_",
   --      g_num_of_frames => 20,
   --      g_picwidth      => <WIDTH>,
   --      g_picheight      => <HEIGHT>,
   --      NUM_DATA_STREAMS => 1 
   --  )
   --  port map (
   --      in_vsync   => vid_fval_out,
   --      in_hsync   => vid_lval_out,
   --      in_clk     => Clk,
   --      in_data_en => vid_dval_out,
   --      in_data(0) => vid_data_out
   --  );

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library work;
    use work.VideoBusPkg.all;
    use work.bmplibpack.all;

--------------------------------------------------------------------------------
-- Entity declaration
--------------------------------------------------------------------------------

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use std.textio.all ;
   use ieee.std_logic_textio.all ;
   
library work;
   use work.bmplibpack.all;

entity write_bmp_file is
generic(
   output_file       : string  := "results/result_";
   g_num_of_frames   : integer := 4;
   VIDEO_WIDTH        : natural := 64;
   VIDEO_HEIGHT        : natural := 64;
   NUM_DATA_STREAMS : natural := 1
   );
port(
      in_vsync   : in   std_logic;
      in_hsync   : in   std_logic;
      in_clk     : in   std_logic;
      in_data_en : in   std_logic;
      in_data  : in  VideoDataArray(0 to NUM_DATA_STREAMS-1)(23 downto 0)
   );
end write_bmp_file;

--------------------------------------------------------------------------------
-- Architecture declaration
--------------------------------------------------------------------------------
   
architecture arch_write_bmp_file of write_bmp_file is
begin
    process
        file pic_file             : T_PICFILE;
        variable file_status      : FILE_OPEN_STATUS;
        variable bmp_record       : R_bmp;
        variable pixel            : T_3BYTE;
        variable pixelCount : integer;
         variable lineCount : integer;
    begin
        -- init file now with fixed zises, but later size can come from generics
        bmp_record.picsize := (VIDEO_HEIGHT * VIDEO_WIDTH)*3; -- 3 bytes per pixel (RGB)
        bmp_record.FileSize := (VIDEO_HEIGHT * VIDEO_WIDTH)*3 + 54;  -- 54 is the offset
        bmp_record.picwidth := VIDEO_WIDTH;
        bmp_record.picheight := VIDEO_HEIGHT;
        -- start 
        for i in 0 to g_num_of_frames loop  -- number of frames to collect
            wait until rising_edge(in_vsync);
            pixelCount := 0;
            lineCount := 0;
            FILE_OPEN(file_status, pic_file, output_file & integer'image(i) & ".bmp", WRITE_MODE);
            if file_status  /= OPEN_OK then 
               report "file could not open" severity failure;
            else
               report "Opening bmp file number  " & integer'image(i)  severity note;
            end if;
            write_BmpHeader(pic_file, bmp_record);
            while (in_vsync = '1') loop
               wait until rising_edge(in_clk);
               if (in_hsync = '1') then
                  pixelCount := 0;
                  while (in_hsync = '1') loop
                     wait until rising_edge(in_clk);
                     if (in_data_en = '1') then
                        for dataStream in 0 to NUM_DATA_STREAMS-1 loop
                           pixel := in_data(dataStream);
                           PutPixel(pic_file, pixel);
                           pixelCount := pixelCount + 1;
                        end loop;
                     end if;
                  end loop;
                  -- Fill missing pixels with red color
                  for i in 1 to (VIDEO_WIDTH - pixelCount) loop 
                     pixel := 24X"FF0000";
                     PutPixel(pic_file, pixel);
                  end loop;
                  lineCount := lineCount + 1;
               end if;
            end loop;
            -- Fill missing pixels with red color
            for j in 1 to (VIDEO_HEIGHT - lineCount) loop
               for i in 1 to VIDEO_WIDTH loop
                  pixel := 24X"FF0000";
                  PutPixel(pic_file, pixel);
               end loop;   
            end loop;
            FILE_CLOSE(pic_file);
        end loop;
        wait;
    end process;

end arch_write_bmp_file;        

--------------------------------------------------------------------------------
-- End File
--------------------------------------------------------------------------------
  
