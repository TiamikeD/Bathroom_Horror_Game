library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity renderer is
   Port ( 
      clk, reset: in std_logic;
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      background_rgb: in std_logic_vector(2 downto 0);
      player_rgb: in std_logic_vector(2 downto 0);
      level_bar_rgb: in std_logic_vector(2 downto 0);
      student_rgb: in std_logic_vector(2 downto 0);
      teacher_rgb: in std_logic_vector(2 downto 0);
      dean_rgb: in std_logic_vector(2 downto 0);
      rgb_out: out  std_logic_vector(2 downto 0)
   );
end renderer;

architecture renderer_arch of renderer is



begin

   process(background_rgb, player_rgb, level_bar_rgb)
      begin
      if (player_rgb /= "000") then
         rgb_out <= player_rgb;
      elsif (dean_rgb /= "000") then
         rgb_out <= dean_rgb;
      elsif (student_rgb /= "000") then
         rgb_out <= student_rgb;
      elsif (teacher_rgb /= "000") then
         rgb_out <= teacher_rgb;
      elsif (level_bar_rgb /= "000") then
         rgb_out <= level_bar_rgb;
      elsif (background_rgb /= "000") then
         rgb_out <= background_rgb;
      else
         rgb_out <= "000";
      end if;
   end process;

end renderer_arch;
