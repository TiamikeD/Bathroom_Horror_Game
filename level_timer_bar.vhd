library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity level_timer_bar is
   Port ( 
      clk, reset: in std_logic;
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      graph_rgb: out std_logic_vector(2 downto 0)
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
   
begin

   process (clk, reset)
      begin
      if (reset = '1') then

      elsif (clk'event and clk = '1') then

      end if;
   end process;
   
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   
   --60 Hz clock to drive the pixel count
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';
   
   bar_rgb <= "101";
   bar_on <= '1' when (pix_x = Progress_Bar_x_pos) else '0';
   process(bar_rgb)
      begin
         if (bar_on = '1') then
            graph_rgb <= bar_rgb;
         else
            graph_rgb <= "000"; -- bkgnd
         end if;
   end process;

end Class_Bar;
