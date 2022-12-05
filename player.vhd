library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity player is
   Port ( 
      clk, reset: in std_logic;
      on_brd_btn: in std_logic_vector(3 downto 0);
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      graph_rgb: out std_logic_vector(2 downto 0);
      doing_assignment: out std_logic;
      holding_breath: out std_logic;
      blocking_view: out std_logic;
      blocking_door: out std_logic;
      dean_danger_normal: in std_logic;
      dean_game_over: in std_logic
   );
end player;

architecture player_1 of player is
   type player_face is array(0 to 30) of std_logic_vector(0 to 30); -- Face is 31x31 pixels.
   constant HAPPY_ROM: player_face := (
      "0000000000001111111000000000000",
      "0000000001110000000111000000000",
      "0000000110000000000000110000000",
      "0000001000000000000000001000000",
      "0000010000000000000000000100000",
      "0000100000000000000000000010000",
      "0001000000000000000000000001000",
      "0010000001110000001110000000100",
      "0010000001110000001110000000100",
      "0100000001110000001110000000010",
      "0100000000000000000000000000010",
      "0100000000000000000000000000010",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "0100000001000000000001000000010",
      "0100000000100000000010000000010",
      "0100000000010000000100000000010",
      "0010000000001000001000000000100",
      "0010000000000111110000000000100",
      "0001000000000000000000000001000",
      "0000100000000000000000000010000",
      "0000010000000000000000000100000",
      "0000001000000000000000001000000",
      "0000000110000000000000110000000",
      "0000000001110000000111000000000",
      "0000000000001111111000000000000"
      );
   constant LOSE_ROM: player_face := (
      "0000000000001111111000000000000",
      "0000000001110000000111000000000",
      "0000000110000000000000110000000",
      "0000001000000000000000001000000",
      "0000010000000000000000000100000",
      "0000100000000000000000000010000",
      "0001000000000000000000000001000",
      "0010000001110000001110000000100",
      "0010000001110000001110000000100",
      "0100000001110000001110000000010",
      "0100000000000000000000000000010",
      "0100000000000000000000000000010",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "1000000000000011100000000000001",
      "1000000000000100010000000000001",
      "1000000000001000001000000000001",
      "1000000000010000000100000000001",
      "0100000000010000000100000000010",
      "0100000000010000000100000000010",
      "0100000000010000000100000000010",
      "0010000000001000001000000000100",
      "0010000000000100010000000000100",
      "0001000000000011100000000001000",
      "0000100000000000000000000010000",
      "0000010000000000000000000100000",
      "0000001000000000000000001000000",
      "0000000110000000000000110000000",
      "0000000001110000000111000000000",
      "0000000000001111111000000000000"
      );
   constant SCARED_ROM: player_face := (
      "0000000000001111111000000000000",
      "0000000001110000000111000000000",
      "0000000110000000000000110000000",
      "0000001000000000000000001000000",
      "0000010000000000000000000100000",
      "0000100000000000000000000010000",
      "0001000000000000000000000001000",
      "0010000001110000001110000000100",
      "0010000001110000001110000000100",
      "0100000001110000001110000000010",
      "0100000010000000000000000000010",
      "0100000110000000000000000000010",
      "1000000110000000000000000000001",
      "1000000110000000000000000000001",
      "1000000110000000000000000000001",
      "1000000110000000000000000000001",
      "1000000100000000000000000000001",
      "1000000000000000000000000000001",
      "1000000000000000000000000000001",
      "0100000000000000000000000000010",
      "0100000000000000000000000000010",
      "0100000000000000000000000000010",
      "0010000000111111111100000000100",
      "0010000000000000000000000000100",
      "0001000000000000000000000001000",
      "0000100000000000000000000010000",
      "0000010000000000000000000100000",
      "0000001000000000000000001000000",
      "0000000110000000000000110000000",
      "0000000001110000000111000000000",
      "0000000000001111111000000000000"
      );
   type assignment is array(0 to 12) of std_logic_vector(0 to 14); --paper & pencil is 13x15
   constant assignment_ROM: assignment := (
      "000001111111111",
      "000001000000001",
      "000001000000001",
      "000011011101101",
      "000101000000001",
      "001001010110101",
      "010001000000001",
      "100001011100001",
      "000001000000001",
      "000001000000001",
      "000001000000001",
      "000001000000001",
      "000001111111111"
      );
   type hand is array(0 to 19) of std_logic_vector(0 to 9); --hand is 20x10
   constant hand_ROM: hand := (
      "0000010000",
      "0011010000",
      "0001010100",
      "0001010101",
      "1001111101",
      "1011000110",
      "0110000010",
      "0010000010",
      "0010000010",
      "0010000010",
      "0010000010",
      "0001000100",
      "0001000100",
      "0001000100",
      "0001000100",
      "0001000100",
      "0001000100",
      "0001000100",
      "0001000100",
      "0001000100"
   );
   
   type backpack is array(0 to 15) of std_logic_vector(0 to 8); --backpack is 16x9
   constant backpack_ROM: backpack := (
      "000001111",
      "000111111",
      "001111011",
      "001110011",
      "011100001",
      "111000001",
      "110000101",
      "110000101",
      "110000101",
      "110000101",
      "110000001",
      "110000001",
      "111000011",
      "111000011",
      "011111111",
      "001111111"
   );

-- Signal used to control speed of ball and how often pushbuttons are checked for paddle movement.
   signal refr_tick: std_logic;

-- x, y coordinates (0,0 to (639, 479)
   signal pix_x, pix_y: unsigned(9 downto 0);
   
   signal face_on, assignment_on, hand_on, backpack_on: std_logic;
   signal face_rgb, assignment_rgb, hand_rgb, backpack_rgb: std_logic_vector(2 downto 0);
   
   signal face_addr, face_col: unsigned(9 downto 0);
   signal face_data: std_logic_vector(30 downto 0);
   signal face_bit: std_logic;
   constant FACE_POS_X: integer := 214;
   constant FACE_POS_Y: integer := 316;
   constant FACE_POS_Y_BLOCK_DOOR: integer := 220;
   
   signal assignment_addr, assignment_col: unsigned(9 downto 0);
   signal assignment_data: std_logic_vector(14 downto 0);
   signal assignment_bit: std_logic;
   constant ASSIGNMENT_POS_X: integer := 214;
   constant ASSIGNMENT_POS_Y: integer := 304;
   
   signal hand_addr, hand_col: unsigned(9 downto 0);
   signal hand_data: std_logic_vector(9 downto 0);
   signal hand_bit: std_logic;
   constant HAND_POS_X: integer := 234;
   constant HAND_POS_Y: integer := 210;
   
   signal backpack_addr, backpack_col: unsigned(9 downto 0);
   signal backpack_data: std_logic_vector(8 downto 0);
   signal backpack_bit: std_logic;
   constant BACKPACK_POS_X: integer := 180;
   constant BACKPACK_POS_Y: integer := 328;
   
   signal blocking_view_reg, blocking_view_next: std_logic;
   signal blocking_door_reg, blocking_door_next: std_logic;
   
begin
   face_rgb <= "111";
   assignment_rgb <= "111";
   hand_rgb <= "111";
   backpack_rgb <= "111";
   
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';
   
   face_addr <= pix_y - FACE_POS_Y;-- when (on_brd_btn(0) = '0') else pix_y - FACE_POS_Y_BLOCK_DOOR;
   face_data <= HAPPY_ROM(to_integer(face_addr)) when (dean_danger_normal = '0') else 
                LOSE_ROM(to_integer(face_addr)) when (dean_game_over = '1') else -- switch to the LOSE face when the "game over" signal is raised.
                SCARED_ROM(to_integer(face_addr)); -- Switch to the scared face when danger flags are reaised 
   face_col <= pix_x - FACE_POS_X;
   face_bit <= face_data(to_integer(face_col));
   face_on <= '1' when (pix_x >= FACE_POS_X) and 
                       (pix_x <= FACE_POS_X + 30) and
                       (pix_y >= FACE_POS_Y) and
                       (pix_y <= FACE_POS_Y + 30) and
                       (face_bit = '1') else '0';
   
   assignment_addr <= pix_y - ASSIGNMENT_POS_Y;
   assignment_data <= ASSIGNMENT_ROM(to_integer(assignment_addr));
   assignment_col <= pix_x - ASSIGNMENT_POS_X;
   assignment_bit <= assignment_data(to_integer(assignment_col));
   assignment_on <= '1' when (pix_x >= ASSIGNMENT_POS_X) and 
                       (pix_x <= ASSIGNMENT_POS_X + 14) and
                       (pix_y >= ASSIGNMENT_POS_Y) and
                       (pix_y <= ASSIGNMENT_POS_Y + 13) and
                       (on_brd_btn(0) = '1') and (on_brd_btn(1) = '0') and --Can't do other tasks while blocking door
                       (assignment_bit = '1') else '0';
                       
   hand_addr <= pix_y - HAND_POS_Y;
   hand_data <= HAND_ROM(to_integer(hand_addr));
   hand_col <= pix_x - HAND_POS_X;
   hand_bit <= hand_data(to_integer(hand_col));
   hand_on <= '1' when (pix_x >= HAND_POS_X) and 
                       (pix_x <= HAND_POS_X + 9) and
                       (pix_y >= HAND_POS_Y) and
                       (pix_y <= HAND_POS_Y + 20) and
                       (on_brd_btn(1) = '1') and
                       (hand_bit = '1') else '0';
                       
   backpack_addr <= pix_y - BACKPACK_POS_Y;
   backpack_data <= BACKPACK_ROM(to_integer(backpack_addr));
   backpack_col <= pix_x - BACKPACK_POS_X;
   backpack_bit <= backpack_data(to_integer(backpack_col));
   backpack_on <= '1' when (pix_x >= BACKPACK_POS_X) and 
                       (pix_x <= BACKPACK_POS_X + 8) and
                       (pix_y >= BACKPACK_POS_Y) and
                       (pix_y <= BACKPACK_POS_Y + 16) and
                       (on_brd_btn(2) = '1') and (on_brd_btn(1) = '0') and --Can't do other tasks while blocking door
                       (backpack_bit = '1') else '0';
   process(clk, reset)
      begin
      if (reset = '1') then
         blocking_view_reg <= '0';
         blocking_door_reg <= '0';
      elsif (clk'event and clk = '1') then
         blocking_view_reg <= blocking_view_next;
         blocking_door_reg <= blocking_door_next;
      end if;
   end process;
   
   blocking_view <= blocking_view_reg;
   blocking_door <= blocking_door_reg;
   
   process(refr_tick, pix_x, pix_y)
      begin
         if (video_on = '0') then
            graph_rgb <= "000";
         else
            if (face_on = '1') then
               graph_rgb <= face_rgb;
            elsif (assignment_on = '1') then
               graph_rgb <= assignment_rgb;
               doing_assignment <= '1';
            elsif (hand_on = '1') then
               graph_rgb <= hand_rgb;
               blocking_door_next <= '1';
            elsif (backpack_on = '1') then
               graph_rgb <= backpack_rgb;
               blocking_view_next <= '1';
            else
               graph_rgb <= "000";
            end if;
            
            if (on_brd_btn(1) = '0') then --BLOCK DOOR WITH HAND
               blocking_door_next <= '0';
            end if;
            
            if (on_brd_btn(2) = '0') or (on_brd_btn(1) = '1') then -- BLOCK STALL WITH BACKPACK
               blocking_view_next <= '0';
            end if;
            
            if (on_brd_btn(0) = '0') or (on_brd_btn(1) = '1') then 
               doing_assignment <= '0';
            end if;
         end if;
   end process;
                       

end player_1;












