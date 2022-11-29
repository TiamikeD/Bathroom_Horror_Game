library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity level_timer_bar is
   Port ( 
      clk, reset: in std_logic;
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      graph_rgb: out std_logic_vector(2 downto 0);
      level_over: out std_logic
   );
end level_timer_bar;

architecture Class_Bar of level_timer_bar is
   signal refr_tick: std_logic;
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant Progress_Bar_Width: integer := 75;
   constant Progress_Bar_Height: integer := 15;
   constant Progress_Bar_y_Pos: integer := 400;
   constant Progress_Bar_x_Pos: integer := 30;
   
   signal bar_on: std_logic;
   signal bar_rgb: std_logic_vector(2 downto 0);
   signal level_progress_reg, level_progress_next: unsigned(6 downto 0); --7 bits. Will be reset when equal to 76: "1001100"
   signal clk_divider_reg, clk_divider_next: unsigned(5 downto 0); --6 bits. will be reset when equal to 60: "111100"
   signal local_reset: std_logic;
   
begin

   process(clk, local_reset)
      begin
      if (local_reset = '1') then
         level_progress_reg <= (others => '0');
         clk_divider_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
         level_progress_reg <= level_progress_next;
         clk_divider_reg <= clk_divider_next;
      end if;
   end process;

   process (pix_x, pix_y, level_progress_reg, refr_tick)
      begin
      level_progress_next <= level_progress_reg;
      clk_divider_next <= clk_divider_reg;
      
      if (pix_x >= Progress_Bar_x_Pos) and (pix_x <= Progress_Bar_x_Pos + Progress_Bar_Width) and (pix_y = Progress_Bar_y_Pos) then -- Top bar of progress bar
         bar_on <= '1';
      elsif (pix_x >= Progress_Bar_x_Pos) and (pix_x <= Progress_Bar_x_Pos + Progress_Bar_Width) and (pix_y = Progress_Bar_y_Pos + Progress_Bar_Height) then -- Bottom bar of progress bar
         bar_on <= '1';
      elsif (pix_x <= Progress_Bar_x_Pos + level_progress_reg) and (pix_x >= Progress_Bar_x_Pos) and (pix_y >= Progress_Bar_y_Pos) and (pix_y <= Progress_Bar_y_Pos + Progress_Bar_Height) then -- Left bar of progress bar - gets longer as more time passes
         bar_on <= '1';
      elsif (pix_x = Progress_Bar_x_Pos + Progress_Bar_Width) and (pix_y >= Progress_Bar_y_Pos) and (pix_y <= Progress_Bar_y_Pos + Progress_Bar_Height) then -- Right bar of progress bar
         bar_on <= '1';
      else
         bar_on <= '0';
      end if;
      
      if (refr_tick = '1') then
         clk_divider_next <= clk_divider_reg + 1;
      end if;
      
      if (clk_divider_reg = "111100") then
         clk_divider_next <= (others => '0');
         level_progress_next <= level_progress_reg + 1; -- Can be simplified - currently uses two clock dividers, but can use one like the NPCs.
                                                        -- This simplification may fix the bug where the bar doesnt reset to zero
      end if;
      
      if (level_progress_next = "1001100") then
         level_over <= '1'; -- Raise a flag to indicate the level is over
         local_reset <= '1'; -- Bar uses a local reset to reset itself to zero
      else
         level_over <= '0';
         local_reset <= reset; -- The local reset is tied to global reset whenever the bar isnt full.
      end if;
      
      
   end process;
   
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   
   --60 Hz clock to drive the pixel count
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';
   --clk_divider_next <= clk_divider_reg + 1 when refr_tick = '1' else clk_divider_reg;
   --level_progress_next <= level_progress_reg + 1 when clk_divider_next = "111100" else level_progress_reg;
   
   bar_rgb <= "101";
   process(bar_rgb)
      begin
         if (bar_on = '1') then
            graph_rgb <= bar_rgb;
         else
            graph_rgb <= "000"; -- bkgnd
         end if;
   end process;

end Class_Bar;
