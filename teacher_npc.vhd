library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity teacher_npc is
   Port ( 
      clk, reset: in std_logic;
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      SUMMON_TEACHER: in std_logic;
      doing_assignment: in std_logic;
      blocked_stall: in std_logic;
      teacher_cant_hear: in std_logic;
      graph_rgb: out std_logic_vector(2 downto 0);
      teacher_game_over: out std_logic
   );
end teacher_npc;

architecture teacher of teacher_npc is
   signal refr_tick: std_logic;
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer := 640;
   constant MAX_Y: integer := 480;
   
   constant teacher_width: integer := 30;
   constant teacher_height: integer := 30;
   constant teacher_origin_x: integer := 0;
   constant teacher_origin_y: integer := 15;
   
   signal teacher_x_reg, teacher_x_next: unsigned(9 downto 0);
   signal teacher_y_reg, teacher_y_next: unsigned(9 downto 0);
   signal teacher_game_over_reg, teacher_game_over_next: std_logic;
   signal teacher_rgb: std_logic_vector(2 downto 0);
   signal teacher_on, teacher_on_en: std_logic;
   signal clk_divider_reg, clk_divider_next: unsigned(9 downto 0);
   type state_type is (idle, walk_in, use_stall, walk_out, breach_stall);
   signal state_reg, state_next: state_type;
   
   constant teacher_velocity: integer := 3;
begin
   process(clk, reset)
      begin
      if (reset = '1') then
         state_reg <= idle;
         teacher_x_reg <= (others => '0');
         teacher_y_reg <= (others => '0');
         teacher_game_over_reg <= '0';
         clk_divider_reg <= (others => '0');
      elsif (clk'event and clk = '1') then
         state_reg <= state_next;
         teacher_x_reg <= teacher_x_next;
         teacher_y_reg <= teacher_y_next;
         teacher_game_over_reg <= teacher_game_over_next;
         clk_divider_reg <= clk_divider_next;
      end if;
   end process;
   
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   teacher_rgb <= "010";
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';
   teacher_on <= '1' when (pix_x >= teacher_x_reg) and (pix_x <= teacher_x_reg + teacher_width) and --Make the teacher 30x30 pixels
                          (pix_y >= teacher_y_reg) and (pix_y <= teacher_y_reg + teacher_height) and
                          (teacher_on_en = '1') else '0'; -- Only render the teacher when not in the idle state
   teacher_game_over <= teacher_game_over_reg;
   process(teacher_on, video_on, teacher_x_reg, teacher_y_reg, refr_tick,clk_divider_reg)
      begin
      clk_divider_next <= clk_divider_reg;
      teacher_x_next <= teacher_x_reg;
      teacher_y_next <= teacher_y_reg;
      teacher_game_over_next <= teacher_game_over_reg;
      state_next <= state_reg;
      
      if (video_on = '0') then
         graph_rgb <= "000";
      else
         if (teacher_on ='1') then
            graph_rgb <= teacher_rgb;
         else
            graph_rgb <= "000";
         end if;
      end if;
      
      case state_reg is
         when idle => -- Wait to be summoned
            teacher_on_en <= '0';
            teacher_x_next <= to_unsigned(teacher_origin_x, teacher_x_next'length);
            teacher_y_next <= to_unsigned(teacher_origin_y, teacher_y_next'length);
            teacher_game_over_next <= '0';
            if (SUMMON_TEACHER = '1') then
               state_next <= walk_in;
            end if;
            
         when walk_in => -- Walk into bathroom stall animation
            teacher_on_en <= '1';
            teacher_game_over_next <= '0';
            if (refr_tick = '1') then
               if (teacher_x_reg <= 472) and (teacher_y_reg < 70) then
                  teacher_x_next <= teacher_x_reg + teacher_velocity;
               elsif (teacher_y_reg <= 75) and (teacher_x_reg >= 470)  then
                  teacher_y_next <= teacher_y_reg + teacher_velocity;
               elsif (teacher_x_reg >= 90) then
                  teacher_x_next <= teacher_x_reg - teacher_velocity;
               elsif (teacher_y_reg <= 310) then
                  teacher_y_next <= teacher_y_reg + teacher_velocity;
               else
                  state_next <= use_stall;
               end if;
            end if;
            
         when use_stall => -- Wait in the stall
            teacher_on_en <= '1';
            teacher_game_over_next <= '0';
            if (doing_assignment = '1') and (blocked_stall = '0') and (teacher_cant_hear = '0') then
               state_next <= breach_stall;
            end if;
            if (refr_tick = '1') then
               clk_divider_next <= clk_divider_reg + 1;
               if (clk_divider_reg = "0010010110") then
                  clk_divider_next <= (others => '0');
                  state_next <= walk_out;
               end if;
            end if;
         
         when breach_stall =>
            if (refr_tick = '1') then
               if (teacher_x_reg <= 214) then
                  teacher_x_next <= teacher_x_reg + 5;
               else
                  teacher_game_over_next <= '1';
               end if;
            end if;
            
         when walk_out => -- walk out of the bathroom animation
            teacher_on_en <= '1';
            teacher_game_over_next <= '0';
            if (refr_tick = '1') then
               if (teacher_y_reg >= 75) and (teacher_x_reg <= 95) then
                  teacher_y_next <= teacher_y_reg - teacher_velocity;
               elsif (teacher_x_reg <= 472) and (teacher_y_reg > 60) then
                  teacher_x_next <= teacher_x_reg + teacher_velocity;
               elsif (teacher_y_reg >= teacher_origin_y) then
                  teacher_y_next <= teacher_y_reg - teacher_velocity;
               elsif (teacher_x_reg >= 6) then
                  teacher_x_next <= teacher_x_reg - teacher_velocity;
               else
                  state_next <= idle;
               end if;
            end if;
      end case;
   end process;

end teacher;
