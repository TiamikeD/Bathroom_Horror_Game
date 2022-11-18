-- ======================================================================================================
-- ======================================================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Background is
   port(
      clk, reset: in std_logic;
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      graph_rgb: out std_logic_vector(2 downto 0)
   );
end Background;

-- ======================================================================================================
-- ======================================================================================================

architecture bathroom of Background is

-- Signal used to control speed of ball and how often pushbuttons are checked for paddle movement.
   signal refr_tick: std_logic;

-- x, y coordinates (0,0 to (639, 479)
   signal pix_x, pix_y: unsigned(9 downto 0);

-- Screen dimensions
   constant MAX_X: integer := 640;
   constant MAX_Y: integer := 480;

-- Wall left, right, top, and bottom boundary of wall
   constant BathroomWall_Top: integer := 60; --Horizontal bar at top of screen
   constant BathroomWall_Bottom: integer := 380; --Hotizontal bar at bottom of screen
   constant BathroomWall_Left: integer := 30;
   constant BathroomWall_Right: integer := 550;
   constant LongStallWall:  integer := BathroomWall_Left + 150;
   constant PlayerStallWall: integer := LongStallWall + 100;
   constant ShortStallWall: integer := PlayerStallWall + 100;
   constant HorizStallWall: integer := BathroomWall_top + 150;

-- object output signals -- new signal to indicate if scan coord is within ball
   signal wall_on, rd_sink_on, sq_sink_on, rd_toilet_1_on, sq_toilet_1_on, rd_toilet_2_on, sq_toilet_2_on, rd_toilet_3_on, sq_toilet_3_on: std_logic;
   signal wall_rgb, sink_rgb, toilet_rgb: std_logic_vector(2 downto 0);
   
   type rom_type is array(0 to 31) of std_logic_vector(0 to 31);
   constant SINK_ROM: rom_type := ( -- SINK ROM IMAGE
      "00000111111111111111111111100000",
      "00011111111111111111111111111000",
      "00111110000000000000000001111100",
      "01111000000000000000000000011110",
      "01110000000000000000000000001110",
      "11100000000000000000000000000111",
      "11100000000000000000000000000111",
      "11000000000000000000000000000011",
      "11000000000000000000000000000011",
      "11000000000000000000000000000011",
      "11000000000001111100000000000011",
      "11000000000010000010000000000011",
      "11000000000100000001000000000011",
      "11000000001001100000100000000011",
      "11000000001000001100100000000011",
      "11000000001001100000100000000011",
      "11000000001000000110100000000011",
      "11000000001000110000100000000011",
      "11000000000100000001000000000011",
      "11000000000010000010000000000011",
      "11000000000001111100000000000011",
      "11000000000000000000000000000011",
      "11000000000000000000000000000011",
      "11000000000000000000000000000011",
      "11000000000000010000000000000011",
      "11100000000000111000000000000111",
      "11100000010000111000010000000111",
      "01110000111000111000111000001110",
      "01111000010000111000010000011110",
      "00111110010000111000010001111100",
      "00011111111111111111111111111000",
      "00000111111111111111111111100000");
   signal sink_addr, sink_col: unsigned(9 downto 0); -- ROM map row and column
   signal sink_data: std_logic_vector(31 downto 0); -- Contain one row of the ROM map
   signal sink_bit: std_logic; -- Is a bit in the ROM map 1 or 0
   constant SINK_POS_X: integer := BathroomWall_Right - 75; -- Left side of sink is x pixels from right wall
   constant SINK_POS_Y: integer := BathroomWall_Bottom - 32; --top of sink is 32 pixels above the bottom wall
   
   constant TOILET_ROM: rom_type := ( -- TOILET ROM IMAGE
      "00000000000000000000000000000000",
      "00000000000111111111100000000000",
      "00000000111111111111111100000000",
      "00000011111111000011111111000000",
      "00000111110000000000001111100000",
      "00001111100000000000000111110000",
      "00011110000000000000000001111000",
      "00111100000000000000000000111100",
      "00111100000000000000000000111100",
      "01111000000000000000000000011110",
      "01110000000000000000000000001110",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11110000000000000000000000001111",
      "11111111111111111111111111111111",
      "11111111111111111111111111111111",
      "11111111111111111111111111111111",
      "11111111111111111111111111111111");
   signal toilet_1_addr, toilet_2_addr, toilet_3_addr, toilet_1_col, toilet_2_col, toilet_3_col: unsigned(9 downto 0); -- ROM map row and column
   signal toilet_1_data, toilet_2_data, toilet_3_data : std_logic_vector(31 downto 0); -- Contain one row of the ROM map
   signal toilet_1_bit, toilet_2_bit, toilet_3_bit : std_logic; -- Is a bit in the ROM map 1 or 0
   constant TOILET_1_POS_X: integer := BathroomWall_Left + 59; -- Left side of toilet 1 is x pixels from left wall
   constant TOILET_1_POS_Y: integer := BathroomWall_Bottom - 32; --top of toilet 1 is 32 pixels above the bottom wall
   constant TOILET_2_POS_X: integer := LongStallWall + 34; -- Left side of toilet 2 is y pixels from long wall
   constant TOILET_2_POS_Y: integer := BathroomWall_Bottom - 32; --top of toilet 2 is 32 pixels above the bottom wall
   constant TOILET_3_POS_X: integer := PlayerStallWall + 34; -- Left side of toilet 3 is z pixels from player's short wall (middle wall)
   constant TOILET_3_POS_Y: integer := BathroomWall_Bottom - 32; --top of toilet 3 is 32 pixels above the bottom wall

-- ======================================================================================================
   begin
   sink_rgb <= "111";-- WHITE
   wall_rgb <= "111"; -- WHITE
   toilet_rgb <= "111"; -- WHITE

-- ======================================================================================================
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);

-- Refr_tick: 1-clock tick asserted at start of v_sync, e.g., when the screen is refreshed -- speed is 60 Hz
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';

-- Render Sink
   sink_addr <= pix_y - SINK_POS_Y;-- when (pix_y >= SINK_POS_Y) and (pix_y <= SINK_POS_Y + 16);
   sink_data <= SINK_ROM(to_integer(sink_addr));
   sink_col <= pix_x - SINK_POS_X;
   sink_bit <= sink_data(to_integer(sink_col));
   sq_sink_on <= '1' when (pix_x >= SINK_POS_X) and (pix_x <= SINK_POS_X + 31) and (pix_y >= SINK_POS_Y) and (pix_y <= SINK_POS_Y + 32) else '0';
   rd_sink_on <= '1' when (sq_sink_on = '1') and (sink_bit = '1') else '0';

-- Render Toilets
   toilet_1_addr <= pix_y - TOILET_1_POS_Y;
   toilet_1_data <= TOILET_ROM(to_integer(toilet_1_addr)); -- Assign the row being rendered by pix_y
   toilet_1_col <= pix_x - TOILET_1_POS_X; -- Assign the single bit in the row being rendered by pix_x
   toilet_1_bit <= toilet_1_data(to_integer(toilet_1_col)); -- Assign if the bit is 1 or zero
   sq_toilet_1_on <= '1' when (pix_x >= TOILET_1_POS_X) and (pix_x <= TOILET_1_POS_X + 31) and (pix_y >= TOILET_1_POS_Y) and (pix_y <= TOILET_1_POS_Y + 32) else '0'; --Render in the space where the toilet belongs
   rd_toilet_1_on <= '1' when (sq_toilet_1_on = '1') and (toilet_1_bit = '1') else '0'; --Turn on the pixel if pix_x and pix_y are in the range and the bit is 1
   
   toilet_2_addr <= pix_y - TOILET_2_POS_Y;
   toilet_2_data <= TOILET_ROM(to_integer(toilet_2_addr));
   toilet_2_col <= pix_x - TOILET_2_POS_X;
   toilet_2_bit <= toilet_2_data(to_integer(toilet_2_col));
   sq_toilet_2_on <= '1' when (pix_x >= TOILET_2_POS_X) and (pix_x <= TOILET_2_POS_X + 31) and (pix_y >= TOILET_2_POS_Y) and (pix_y <= TOILET_2_POS_Y + 32) else '0';
   rd_toilet_2_on <= '1' when (sq_toilet_2_on = '1') and (toilet_2_bit = '1') else '0';
   
   toilet_3_addr <= pix_y - TOILET_3_POS_Y;
   toilet_3_data <= TOILET_ROM(to_integer(toilet_3_addr));
   toilet_3_col <= pix_x - TOILET_3_POS_X;
   toilet_3_bit <= toilet_1_data(to_integer(toilet_3_col));
   sq_toilet_3_on <= '1' when (pix_x >= TOILET_3_POS_X) and (pix_x <= TOILET_3_POS_X + 31) and (pix_y >= TOILET_3_POS_Y) and (pix_y <= TOILET_3_POS_Y + 32) else '0';
   rd_toilet_3_on <= '1' when (sq_toilet_3_on = '1') and (toilet_3_bit = '1') else '0';
   
   process(refr_tick, pix_x, pix_y)
      begin
      --Build walls
      if (pix_y >= BathroomWall_Top) and (pix_y <=  BathroomWall_Top + 5) then --Make Hallway wall 5 pixels tall
         wall_on <= '1';
      elsif (pix_y >= BathroomWall_Bottom) and (pix_y <= BathroomWall_Bottom + 4) and (pix_x >= BathroomWall_Left) and (pix_x <= BathroomWall_Right + 4) then -- Make bathroom walls 4 pixels thick
         wall_on <= '1';
      elsif (pix_x >= BathroomWall_Right) and (pix_x <= BathroomWall_Right + 4) and (pix_y <= BathroomWall_Bottom) and (pix_y >= BathroomWall_Top) then
         wall_on <= '1';
      elsif (pix_x >= BathroomWall_Left) and (pix_x <= BathroomWall_Left + 4) and (pix_y <= BathroomWall_Bottom) and (pix_y >= BathroomWall_Top) then
         wall_on <= '1';
      elsif (LongStallWall = pix_x) and (pix_y <= BathroomWall_Bottom) and (pix_y >= BathroomWall_Top) then -- put the long stall wall between the top and bottom bathroom walls
         wall_on <= '1';
      elsif (PlayerStallWall = pix_x) and (pix_y <= BathroomWall_Bottom) and (pix_y >= HorizStallWall) then -- put the player stall wall between the horizontal wall and the bottom
         wall_on <= '1';
      elsif (HorizStallWall = pix_y) and (pix_x >= LongStallWall) and (pix_x <= ShortStallWall) then -- put the horizontal stall wall between the long wall and the unoccpied wall
         wall_on <= '1';
      elsif (ShortStallWall = pix_x) and (pix_y <= BathroomWall_Bottom) and (pix_y >= HorizStallWall) then -- put the unoccupied stall wall between the horizontal wall and the bottom
         wall_on <= '1';
      else
         wall_on <= '0';
      end if;

   end process;

-- ======================================================================================================
-- turn on the appropriate color depending on the current pixel position.
   process (video_on, wall_on, sink_rgb, wall_rgb, rd_sink_on, rd_toilet_1_on, toilet_rgb, rd_toilet_2_on, rd_toilet_3_on)
      begin
      if (video_on = '0') then
         graph_rgb <= "000"; -- blank
      else 
         if (wall_on = '1') then
            graph_rgb <= wall_rgb;
         elsif (rd_sink_on = '1') then
            graph_rgb <= sink_rgb;
         elsif (rd_toilet_1_on = '1') then
            graph_rgb <= toilet_rgb;
         elsif (rd_toilet_2_on = '1') then
            graph_rgb <= toilet_rgb;
         elsif (rd_toilet_3_on = '1') then
            graph_rgb <= toilet_rgb;
         else
            graph_rgb <= "000"; -- bkgnd
         end if;
      end if;
   end process;

end bathroom;