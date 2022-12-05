library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dean_npc is
   Port ( 
      clk, reset: in std_logic;
      on_brd_btn: in std_logic_vector(3 downto 0);
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      SUMMON_DEAN: in std_logic;
      graph_rgb: out std_logic_vector(2 downto 0);
      blocked_door: in std_logic;
      dean_danger_normal: out std_logic;
      doing_assignment: in std_logic;
      dean_game_over: out std_logic
   );
end dean_npc;

architecture dean of dean_npc is
   signal refr_tick: std_logic;
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer := 640;
   constant MAX_Y: integer := 480;
   
   constant dean_width: integer := 30;
   constant dean_height: integer := 30;
   constant dean_origin_x: integer := 600;
   constant dean_origin_y: integer := 15;
   
   signal dean_x_reg, dean_x_next: unsigned(9 downto 0);
   signal dean_y_reg, dean_y_next: unsigned(9 downto 0);
   signal dean_game_over_reg, dean_game_over_next: std_logic;
   signal dean_rgb: std_logic_vector(2 downto 0);
   signal dean_on, dean_on_en: std_logic;
   signal clk_divider_reg, clk_divider_next: unsigned(9 downto 0);
   type state_type is (idle, walk_in, watch_stall, walk_out, breach_stall);
   signal state_reg, state_next: state_type;
   signal caught_doing_assignment_reg, caught_doing_assignment_next: std_logic;
   
   constant dean_velocity: integer := 4;
   constant dean_breach_velocity: integer := 10;
begin
   process(clk, reset)
      begin
      if (reset = '1') then
         state_reg <= idle;
         dean_x_reg <= (others => '0');
         dean_y_reg <= (others => '0');
         clk_divider_reg <= (others => '0');
         dean_game_over_reg <= '0';
         caught_doing_assignment_reg <= '0';
      elsif (clk'event and clk = '1') then
         state_reg <= state_next;
         dean_x_reg <= dean_x_next;
         dean_y_reg <= dean_y_next;
         clk_divider_reg <= clk_divider_next;
         dean_game_over_reg <= dean_game_over_next;
         caught_doing_assignment_reg <= caught_doing_assignment_next;
      end if;
   end process;
   
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   dean_rgb <= "100";
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';
   dean_on <= '1' when (pix_x >= dean_x_reg) and (pix_x <= dean_x_reg + dean_width) and
                       (pix_y >= dean_y_reg) and (pix_y <= dean_y_reg + dean_height) and
                       (dean_on_en = '1') else '0';
   dean_game_over <= dean_game_over_reg;

   process(dean_on, video_on, dean_x_reg, dean_y_reg, refr_tick, clk_divider_reg, caught_doing_assignment_reg)
      begin
      clk_divider_next <= clk_divider_reg;
      dean_x_next <= dean_x_reg;
      dean_y_next <= dean_y_reg;
      state_next <= state_reg;
      dean_game_over_next <= dean_game_over_reg;
      caught_doing_assignment_next <= caught_doing_assignment_reg;
      
      if (video_on = '0') then
         graph_rgb <= "000";
      else
         if (dean_on ='1') then
            graph_rgb <= dean_rgb;
         else
            graph_rgb <= "000";
         end if;
      end if;
      
      case state_reg is
         when idle => -- wait to be summoned
            dean_game_over_next <= '0';
            dean_on_en <= '0';
            --caught_doing_assignment_next <= '0';
            dean_x_next <= to_unsigned(dean_origin_x, dean_x_next'length);
            dean_y_next <= to_unsigned(dean_origin_y, dean_y_next'length);
            dean_danger_normal <= '0';
            if (SUMMON_DEAN = '1') then
               state_next <= walk_in;
            end if;
            
         when walk_in => -- walk into the bathroom animation
            dean_game_over_next <= '0';
            dean_on_en <= '1';
            if (dean_y_reg > 60) then
               dean_danger_normal <= '1';
               if (doing_assignment = '1') then
                  caught_doing_assignment_next <= '1'; -- Enhanced hearing: When in the bathroom, check if student is doing the assignment
               end if;
            end if;
            if (refr_tick = '1') then
               if (dean_x_reg >= 472) and (dean_y_reg < 70) then
                  dean_x_next <= dean_x_reg - dean_velocity;
               elsif (dean_y_reg <= 75) and (dean_x_reg >= 470)  then
                  dean_y_next <= dean_y_reg + dean_velocity;
               elsif (dean_x_reg >= 214) or (dean_y_reg <= 170) then
                  dean_x_next <= dean_x_reg - dean_velocity;
                  if (dean_y_reg <= 170) then
                     dean_y_next <= dean_y_reg + dean_velocity;
                  end if;
               else
                  if (caught_doing_assignment_reg = '1') then
                     state_next <= breach_stall;
                  else
                     state_next <= watch_stall;
                  end if;
               end if;
            end if;
            
         when watch_stall => -- Stand outside player stall
            dean_danger_normal <= '1';
            if (caught_doing_assignment_reg = '1') and (blocked_door = '0') then
               if (on_brd_btn(1) = '0') then
                  state_next <= breach_stall; -- If the player was doing assignment while the dean is in the bathroom, breach the stall
               end if;
            elsif (doing_assignment = '1') then
               state_next <= breach_stall;
            end if;
            dean_game_over_next <= '0';
            dean_on_en <= '1';
            if (refr_tick = '1') then
               clk_divider_next <= clk_divider_reg + 1;
               if (clk_divider_reg = "0010010110") then -- Wait for x screen refreshes before walking out
                  clk_divider_next <= (others => '0');
                  state_next <= walk_out;
               end if;
            end if;
         
         when breach_stall => -- Breach the stall animation
            dean_on_en <= '1';
            if (refr_tick = '1') then
               if (dean_y_reg <= 310) then
                  dean_y_next <= dean_y_reg + dean_breach_velocity;
               else
                  dean_game_over_next <= '1'; -- Raise flag to end the game
               end if;
            end if;
            
         when walk_out => -- If the student wasn't caught, leave the bathroom animation
         dean_danger_normal <= '0';
         dean_game_over_next <= '0';
            dean_on_en <= '1';
            if (refr_tick = '1') then
               if (dean_y_reg >= 75) and (dean_x_reg <= 230) then
                  dean_y_next <= dean_y_reg - dean_velocity;
               elsif (dean_x_reg <= 472) and (dean_y_reg > 60) then
                  dean_x_next <= dean_x_reg + dean_velocity;
               elsif (dean_y_reg >= dean_origin_y) then
                  dean_y_next <= dean_y_reg - dean_velocity;
               elsif (dean_x_reg >= 6) then
                  dean_x_next <= dean_x_reg - dean_velocity;
               else
                  state_next <= idle;
               end if;
            end if;
      end case;
   end process;
end dean;
