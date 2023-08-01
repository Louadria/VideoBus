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

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Library declaration
--------------------------------------------------------------------------------
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

package bmplibpack is

--------------------------------------------------------------------------------
---- Pack. Procedure &amp; Function declaration
--------------------------------------------------------------------------------

   -- subtype definition
   subtype T_BYTE  is std_logic_vector(07 downto 00);
   subtype T_WORD  is std_logic_vector(15 downto 00);
   subtype T_DWORD is std_logic_vector(31 downto 00);
   subtype T_3BYTE is std_logic_vector(23 downto 00);

   type T_PICFILE is file of character;

   subtype T_PIXEL is T_3BYTE;
   type T_PIXELSARRAY is array (natural range <>) of T_PIXEL;
   type T_picdata is access T_PIXELSARRAY;

   type R_bmp is record
      signature               : T_WORD;
      FileSize                : natural;
      rsv                     : T_DWORD;
      offset                  : T_DWORD;
      headsize                : T_DWORD;
      picwidth                : natural;
      picheight               : natural;
      picplan                 : T_WORD;
      bitcount                : T_WORD;
      comperssion             : T_DWORD;
      picsize                 : natural;
      hpix                    : T_DWORD;
      vpix                    : T_DWORD;
      color1                  : T_DWORD;
      color2                  : T_DWORD;
      picdata                 : T_picdata;
      --CurrentSamplePtr        : natural;
   end record;

   --type T_PicHandle is access R_bmp;
   
   -- constant chunck ID for PCM uncompressed files
   constant C_HEAD_SIGN      : T_WORD  := X"4d42";
   constant C_HEAD_RSV       : T_DWORD := X"00000000";
   constant C_HEAD_OFFSET    : T_DWORD := X"00000036";
   constant C_HEAD_SIZE      : T_DWORD := X"00000028";
   constant C_HEAD_PLAN      : T_WORD  := X"0001";
   constant C_BIT_COUNT      : T_WORD  := X"0018"; -- 24 bits colors
   constant C_COMPRESSION    : T_DWORD := X"00000000"; -- no compression
   constant C_BMP_WIDTH      : T_DWORD := X"00000000";


   procedure read_byte(
      file f         : T_PICFILE;
      variable Value : out T_BYTE);
   
   procedure read_word(
      file f         : T_PICFILE;
      variable Value : out T_WORD);
   
   procedure read_dword(
      file f         : T_PICFILE;
      variable Value : out T_DWORD);
   
   procedure read_pix(
      file f         : T_PICFILE;
      variable Value : out T_3BYTE);
   
   procedure write_byte(
      file f         : T_PICFILE;
      variable Value : in  T_BYTE);
   
   procedure write_word(
      file f         : T_PICFILE;
      variable Value : in  T_WORD);
   
   procedure write_dword(
      file f         : T_PICFILE;
      variable Value : in  T_DWORD);
   
   procedure write_pix(
      file f         : T_PICFILE;
      variable Value : in  T_3BYTE);
   
   procedure write_BmpHeader(
      file f : T_PICFILE;
      variable bmp_record : in R_bmp);
   
   procedure p_bmp_open(
      variable file_name  : in string;
      variable bmp_record : out R_bmp);
   
   procedure p_bmp_read(
      file f : T_PICFILE;
      variable bmp_record : out R_bmp);
   
   procedure PutPixel(
      file f : T_PICFILE;
      variable Sample : in T_3BYTE);

   type VideoDataArray is array (natural range <>) of std_logic_vector;

   component write_bmp_file
generic(
   output_file       : string  := "results/result_";
   g_num_of_frames   : integer := 4;
   g_picwidth        : natural := 64;
   g_pichight        : natural := 64;
   NUM_DATA_STREAMS : natural := 1
   );
port(
      in_vsync   : in   std_logic;
      in_hsync   : in   std_logic;
      in_clk     : in   std_logic;
      in_data_en : in   std_logic;
      in_data  : in  VideoDataArray(0 to NUM_DATA_STREAMS-1)(23 downto 0)
   );
end component;
   
end bmplibpack;

--------------------------------------------------------------------------------
---- Pack. body
--------------------------------------------------------------------------------

package body bmplibpack is

-- LOW LEVEL FILE ACCESSES ---------
   procedure read_byte(
      file f         : T_PICFILE;
      variable Value : out T_BYTE) is
      variable c1    : character;
	begin
        c1 := character'val(0);
		if endfile(f) then
           assert false report "Unexpected end of file" severity failure;
		else
         read(f,c1);
         Value := std_logic_vector(to_unsigned(natural'val(character'pos(c1)),8));
      end if;
	end read_byte;

   procedure read_word(
      file f         : T_PICFILE;
      variable Value : out T_WORD) is
      variable c1,c2 : T_BYTE;
      variable w1,w2 : T_WORD;
   begin
      read_byte(f,c1);
      read_byte(f,c2);
      w1 := std_logic_vector(resize(unsigned(c1), 16));
      w2 := std_logic_vector(resize(unsigned(c2), 16));
      Value := std_logic_vector((shift_left(unsigned(w2),8) + unsigned(w1)));
   end read_word;

   procedure read_dword(
      file f         : T_PICFILE;
      variable Value : out T_DWORD) is
      variable w1,w2 : T_WORD;
      variable d1,d2 : T_DWORD;
   begin
      read_word(f,w1);
      read_word(f,w2);
      d1 := std_logic_vector(resize(unsigned(w1), 32));
      d2 := std_logic_vector(resize(unsigned(w2), 32));
      Value := std_logic_vector((shift_left(unsigned(d2),16) + unsigned(d1)));
   end read_dword;

   procedure read_pix(  --  in the RGB scale d1 is B d2 is G d3 is R
      file f         : T_PICFILE;
      variable Value : out T_3BYTE) is
      variable w1,w2,w3 : T_BYTE;
      variable d1,d2,d3 : T_3BYTE;
   begin
      read_byte(f,w1);
      read_byte(f,w2);
      read_byte(f,w3);
      d1 := std_logic_vector(resize(unsigned(w1), 24));
      d2 := std_logic_vector(resize(unsigned(w2), 24));
      d3 := std_logic_vector(resize(unsigned(w3), 24));
      Value := std_logic_vector((shift_left(unsigned(d3),16) + shift_left(unsigned(d2),8) + unsigned(d1)));
   end read_pix;

   procedure write_byte(
      file f         : T_PICFILE;
      variable Value : in  T_BYTE) is
   begin
      write(f,character'val(to_integer(unsigned(Value))));
   end write_byte;

   procedure write_word(
      file f         : T_PICFILE;
      variable Value : in  T_WORD) is
      variable c1,c2 : T_BYTE;
   begin
      c1 := Value(07 downto 00);
      write_byte(f,c1);
      c2 := Value(15 downto 08);
      write_byte(f,c2);
   end write_word;

   procedure write_dword(
      file f         : T_PICFILE;
      variable Value : in  T_DWORD) is
      variable d1,d2 : T_WORD;
   begin
      d1 := Value(15 downto 00);
      write_word(f,d1);
      d2 := Value(31 downto 16);
      write_word(f,d2);
   end write_dword;

   procedure write_pix(
      file f         : T_PICFILE;
      variable Value : in  T_3BYTE) is
      variable c1,c2,c3 : T_BYTE;
   begin
      c1 := Value(07 downto 00);
      write_byte(f,c1);
      c2 := Value(15 downto 08);
      write_byte(f,c2);
      c3 := Value(23 downto 16);
      write_byte(f,c3);
   end write_pix;
-- /LOW LEVEL FILE ACCESSES ----------


-- HIGH LEVEL  --------------------

procedure p_bmp_read(
    file f : T_PICFILE;
    variable bmp_record : out R_bmp) is
    variable PicHandle   : R_bmp;
    variable v_tmpDW     : T_DWORD;
    variable v_tmpW      : T_WORD;
    variable v_tmpB      : T_BYTE;
    variable v_tmpP      : T_PIXEL;
    variable v_cnt       : integer;
    variable v_width     : std_logic_vector(31 downto 0);
begin
    -- Checking "RIFF"
    read_word(f,v_tmpW);
    if v_tmpW /= C_HEAD_SIGN then
       assert false report "File format is uncorrect" severity failure;
    end if;

    -- Reading file size - 8
    read_dword(f,v_tmpDW);
    PicHandle.FileSize := to_integer(unsigned(v_tmpDW));
    
    read_dword(f,v_tmpDW);-- rsv
    read_dword(f,v_tmpDW);-- offset

    -- Checking Header size
    read_dword(f,v_tmpDW);
    if v_tmpDW /= C_HEAD_SIZE then
       assert false report "Header size is not supported" severity failure;
    end if;

    -- Reading picwidth
    read_dword(f,v_tmpDW);
    PicHandle.picwidth := to_integer(unsigned(v_tmpDW));
    v_width := v_tmpDW;

    -- Reading picheight
    read_dword(f,v_tmpDW);
    PicHandle.picheight := to_integer(unsigned(v_tmpDW));

    -- Checking plan
    read_word(f,v_tmpW);
    if v_tmpW /= C_HEAD_PLAN then
       assert false report "Header plan is not supported" severity failure;
    end if;

    -- Checking bit count
    read_word(f,v_tmpW);
    if v_tmpW /= C_BIT_COUNT then
       assert false report "Header bit count is not supported" severity failure;
    end if;

    -- Checking compression
    read_dword(f,v_tmpDW);
    if v_tmpDW /= C_COMPRESSION then
       assert false report "compression is not supported" severity failure;
    end if;
    
    -- Reading pic size
    read_dword(f,v_tmpDW);
    PicHandle.picsize := to_integer(unsigned(v_tmpDW));
    
    read_dword(f,v_tmpDW);-- Reading hpix
    read_dword(f,v_tmpDW);-- Reading vpix
    read_dword(f,v_tmpDW);-- Reading color1
    read_dword(f,v_tmpDW);-- Reading color2      

    -- Now loading Data from file
    -- note that when width is not a multiplication of 4 the *.bmp add extra bytes of Zero at the end of the line!
    -- the number of bytes added = width mod 4
    v_cnt := 0;
    PicHandle.picdata := new T_PIXELSARRAY(0 to (PicHandle.picwidth * PicHandle.picheight)-1);
    for j in 0 to PicHandle.picheight - 1 loop
        -- read line
        for i in 0 to PicHandle.picwidth - 1 loop
            read_pix(f,v_tmpP);
            PicHandle.picdata(v_cnt) := v_tmpP;
            v_cnt := v_cnt + 1;
        end loop;
        -- removing the extra bytes in the bmp
        if v_width(0) = '1' then
            read_byte(f,v_tmpB);
        end if;
        if v_width(1) = '1' then
            read_byte(f,v_tmpB);
            read_byte(f,v_tmpB);
        end if;       
    end loop;
    bmp_record := PicHandle;
end p_bmp_read;

 

procedure p_bmp_open(
    variable file_name  : in string;
    variable bmp_record : out R_bmp) is
    variable PicHandle  : R_bmp;
    file pic_file       : T_PICFILE;
    variable file_status: FILE_OPEN_STATUS;
    
begin
    FILE_OPEN(file_status, pic_file, file_name, READ_MODE); 
    if file_status  /= OPEN_OK then 
        report "file could not open  " & file_name severity failure;
    else
        report "Opening source file  " & file_name  severity note;
    end if;
    p_bmp_read(pic_file,PicHandle);
    bmp_record := PicHandle;

end p_bmp_open;
  
   
procedure write_BmpHeader(
    file f : T_PICFILE;
    variable bmp_record  : in R_bmp) is
    variable v_tmpDW     : T_DWORD;
    variable v_tmpW      : T_WORD;
    variable v_tmpB      : T_BYTE;
    variable v_tmpP      : T_PIXEL;
begin
    v_tmpW := C_HEAD_SIGN;
    write_word(f, v_tmpW);                                                    -- Signature
    v_tmpDW := std_logic_vector(to_unsigned(bmp_record.FileSize, 32));
    write_dword(f, v_tmpDW);                                                  -- File size - 8
    v_tmpDW := C_HEAD_RSV;
    write_dword(f, v_tmpDW);                                                  -- rsv
    v_tmpDW := C_HEAD_OFFSET;
    write_dword(f, v_tmpDW);                                                  -- offset
    v_tmpDW := C_HEAD_SIZE;
    write_dword(f, v_tmpDW);                                                  -- header size
    v_tmpDW := std_logic_vector(to_unsigned(bmp_record.picwidth, 32));
    write_dword(f, v_tmpDW);                                                    -- width
    v_tmpDW := std_logic_vector(to_unsigned(bmp_record.picheight, 32));
    write_dword(f, v_tmpDW);                                                    -- hight
    v_tmpW := C_HEAD_PLAN;
    write_word(f, v_tmpW);                                                    -- plan
    v_tmpW := C_BIT_COUNT;
    write_word(f, v_tmpW);                                                    -- bit count
    v_tmpDW := C_COMPRESSION;
    write_dword(f, v_tmpDW);                                                    -- compression
    v_tmpDW := std_logic_vector(to_unsigned(bmp_record.picsize, 32));
    write_dword(f, v_tmpDW);                                                  -- pic size
    v_tmpDW := bmp_record.hpix;
    write_dword(f, v_tmpDW);                                                   -- hpix
    v_tmpDW := bmp_record.vpix;
    write_dword(f, v_tmpDW);                                                   -- vpix
    v_tmpDW := C_HEAD_RSV;
    write_dword(f, v_tmpDW);                                                  -- color1 not in use
    v_tmpDW := C_HEAD_RSV;
    write_dword(f, v_tmpDW);                                                  -- color2 not in use
    
end write_BmpHeader;
   

   
procedure PutPixel(
    file f : T_PICFILE;
    variable Sample : in T_3BYTE) is
begin
    write_pix(f, Sample);      
end PutPixel;
--------------------------------------------------------------------------------
-- End pack File
--------------------------------------------------------------------------------
   
end bmplibpack;

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
  
