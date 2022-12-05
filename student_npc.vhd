library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity student_npc is
   Port (
      clk, reset: in std_logic;
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      SUMMON_STUDENT: in std_logic;
      teacher_cant_hear: out std_logic;
      graph_rgb: out std_logic_vector(2 downto 0)
   );
end student_npc;

architecture student of student_npc is
   signal refr_tick: std_logic;
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer := 640;
   constant MAX_Y: integer := 480;
   
   constant student_width: integer := 30;
   constant student_height: integer := 30;
   constant student_origin_x: integer := 0;
   constant student_origin_y: integer := 15;
   
   signal student_x_reg, student_x_next: unsigned(9 downto 0);
   signal student_y_reg, student_y_next: unsigned(9 downto 0);
   signal using_sink_reg, using_sink_next: std_logic;
   signal student_rgb: std_logic_vector(2 downto 0);
   signal student_on, student_on_en: std_logic;
   signal clk_divider_reg, clk_divider_next: unsigned(9 downto 0);
   type state_type is (idle, walk_in, wash_hands, walk_out);
   signal state_reg, state_next: state_type;
   
   constant student_velocity: integer := 4;
begin
   process(clk, reset)
      begin
      if (reset = '1') then
         state_reg <= idle;
         student_x_reg <= (others => '0');
         student_y_reg <= (others => '0');
         using_sink_reg <= '0';
         clk_divider_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
         state_reg <= state_next;
         student_x_reg <= student_x_next;
         student_y_reg <= student_y_next;
         using_sink_reg <= using_sink_next;
         clk_divider_reg <= clk_divider_next;
      end if;
   end process;
   
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   student_rgb <= "001";
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';
   student_on <= '1' when (pix_x >= student_x_reg) and (pix_x <= student_x_reg + student_width) and
                          (pix_y >= student_y_reg) and (pix_y <= student_y_reg + student_height) and
                          (student_on_en = '1') else '0'; -- Only render the student when it's not in the idle state
   teacher_cant_hear <= using_sink_reg;
   
   process(student_on, video_on, student_x_reg, student_y_reg, refr_tick,clk_divider_reg)
      begin
      clk_divider_next <= clk_divider_reg;
      student_x_next <= student_x_reg;
      student_y_next <= student_y_reg;
      using_sink_next <= using_sink_reg;
      state_next <= state_reg;
      
      if (video_on = '0') then
         graph_rgb <= "000";
      else
         if (student_on ='1') then
            graph_rgb <= student_rgb;
         else
            graph_rgb <= "000";
         end if;
      end if;
      
      case state_reg is
         when idle => -- Waiting to be summoned
            student_on_en <= '0';
            using_sink_next <= '0';
            student_x_next <= to_unsigned(student_origin_x, student_x_next'length);
            student_y_next <= to_unsigned(student_origin_y, student_y_next'length);
            if (SUMMON_STUDENT = '1') then
               state_next <= walk_in;
            end if;
            
         when walk_in => --Walk to the sink animation
            student_on_en <= '1';
            using_sink_next <= '0';
            if (refr_tick = '1') then
               if (student_x_reg <= 472) then
                  student_x_next <= student_x_reg + student_velocity;
               elsif (student_y_reg <= 310) then
                  student_y_next <= student_y_reg + student_velocity;
               else
                  state_next <= wash_hands;
               end if;
            end if;
            
         when wash_hands => -- Wait at the sink
            student_on_en <= '1';
            using_sink_next <= '1';
            if (refr_tick = '1') then
               clk_divider_next <= clk_divider_reg + 1;
               if (clk_divider_reg = "0010010110") then
                  clk_divider_next <= (others => '0');
                  state_next <= walk_out;
               end if;
            end if;
            
         when walk_out => -- Walk out of the bathroom animation, return to idle
            student_on_en <= '1';
            using_sink_next <= '0';
            if (refr_tick = '1') then
               if (student_y_reg >= student_origin_y) then
                  student_y_next <= student_y_reg - student_velocity;
               elsif (student_x_reg >= 6) then
                  student_x_next <= student_x_reg - student_velocity;
               else
                  state_next <= idle;
               end if;
            end if;
      end case;
   end process;
   
end student;
