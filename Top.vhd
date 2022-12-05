----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Professor Jim Plusquellic
-- 
-- Create Date:
-- Design Name: 
-- Module Name:    Top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

-- ===================================================================================================
-- ===================================================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

library work;
use work.DataTypes_pkg.all;

entity Top is
   port (
      Clk: in std_logic;
      reset : in STD_LOGIC;
      GPIO_Ins: in std_logic_vector(31 downto 0);
      GPIO_Outs: out std_logic_vector(31 downto 0);
      PNL_BRAM_addr: out std_logic_vector (12 downto 0);
      PNL_BRAM_din: out std_logic_vector (15 downto 0);
      PNL_BRAM_dout: in std_logic_vector (15 downto 0);
      PNL_BRAM_we: out std_logic_vector (0 to 0);
      hdmi_red : out STD_LOGIC_VECTOR ( 7 downto 0 );
      hdmi_green : out STD_LOGIC_VECTOR ( 7 downto 0 );
      hdmi_blue : out STD_LOGIC_VECTOR ( 7 downto 0 );
      hdmi_hsync : out STD_LOGIC;
      hdmi_vsync : out STD_LOGIC;
      hdmi_enable : out STD_LOGIC;
      btn: in std_logic_vector(3 downto 0);
      on_brd_btn: in std_logic_vector(3 downto 0)
  --    DEBUG_IN: in std_logic;
   --   DEBUG_OUT: out std_logic
      );
end Top;

architecture beh of Top is

-- GPIO INPUT BIT ASSIGNMENTS
   constant IN_CP_RESET: integer := 31;
   constant IN_CP_START: integer := 30;
   constant IN_CP_LM_ULM_LOAD_UNLOAD: integer := 26;
   constant IN_CP_LM_ULM_DONE: integer := 25;
   constant IN_CP_HANDSHAKE: integer := 24;

-- GPIO OUTPUT BIT ASSIGNMENTS
   constant OUT_SM_READY: integer := 31;
   constant OUT_SM_HANDSHAKE: integer := 28;

-- Signal declarations
   signal RESET_final: std_logic;

   signal pixel_x: unsigned(10 downto 0);
   signal pixel_y: unsigned(9 downto 0);
   signal pixel_x_std: std_logic_vector(9 downto 0);
   signal pixel_y_std: std_logic_vector(9 downto 0);

   signal LM_ULM_start, LM_ULM_ready: std_logic;
   signal LM_ULM_stopped, LM_ULM_continue: std_logic;
   signal LM_ULM_done: std_logic;
   signal LM_ULM_base_address: std_logic_vector(PNL_BRAM_ADDR_SIZE_NB-1 downto 0);
   signal LM_ULM_upper_limit: std_logic_vector(PNL_BRAM_ADDR_SIZE_NB-1 downto 0);
   signal LM_ULM_load_unload: std_logic;

   signal DataIn: std_logic_vector(WORD_SIZE_NB-1 downto 0);
   signal DataOut: std_logic_vector(WORD_SIZE_NB-1 downto 0);

   signal graph_rgb: std_logic_vector(2 downto 0);
   signal background_rgb: std_logic_vector(2 downto 0);
   signal player_rgb: std_logic_vector(2 downto 0);
   signal level_bar_rgb: std_logic_vector(2 downto 0);
   signal student_rgb: std_logic_vector(2 downto 0);
   signal teacher_rgb: std_logic_vector(2 downto 0);
   signal dean_rgb: std_logic_vector(2 downto 0);
   signal dean_danger_normal: std_logic;
   signal dean_danger_urgent: std_logic;
   signal dean_game_over: std_logic;
   signal teacher_game_over: std_logic;
   signal teacher_cant_hear: std_logic;
   signal hdmi_enable_out: STD_LOGIC;
   
   --Boolean signals for player actions
   signal doing_assignment: std_logic;
   signal holding_breath: std_logic;
   signal blocking_view: std_logic;
   signal blocking_door: std_logic;

-- =======================================================================================================
   begin

-- Light up LED if LoadUnLoadMemMod is ready for a command
--   DEBUG_OUT <= LM_ULM_ready;

-- =====================
-- INPUT control and status signals
-- Software (C code) plus hardware global reset
   RESET_final <= GPIO_Ins(IN_CP_RESET) or reset;

-- Start signal from C program. 
   LM_ULM_start <= GPIO_Ins(IN_CP_START);

-- C program controls whether we are loading or unloading memory
   LM_ULM_load_unload <= GPIO_Ins(IN_CP_LM_ULM_LOAD_UNLOAD);

-- C program asserts if done reading or writing memory (or a portion of it)
   LM_ULM_done <= GPIO_Ins(IN_CP_LM_ULM_DONE);

-- Handshake signal
   LM_ULM_continue <= GPIO_Ins(IN_CP_HANDSHAKE);

-- Data from C program
   DataIn <= GPIO_Ins(WORD_SIZE_NB-1 downto 0);

-- =====================
-- OUTPUT control and status signals
-- Tell C program whether LoadUnLoadMemMod is ready 
   GPIO_Outs(OUT_SM_READY) <= LM_ULM_ready; 

-- Handshake signals
   GPIO_Outs(OUT_SM_HANDSHAKE) <= LM_ULM_stopped; 

-- Data to C program
   GPIO_Outs(WORD_SIZE_NB-1 downto 0) <= DataOut;

-- =====================
-- Setup memory base and upper_limit
   LM_ULM_base_address <= std_logic_vector(to_unsigned(PN_BRAM_BASE, PNL_BRAM_ADDR_SIZE_NB));
   LM_ULM_upper_limit <= std_logic_vector(to_unsigned(PNL_BRAM_NUM_WORDS_NB -1, PNL_BRAM_ADDR_SIZE_NB));

-- Secure BRAM access control module
   LoadUnLoadMemMod: entity work.LoadUnLoadMem(beh)
      port map(Clk=>Clk, RESET=>RESET, start=>LM_ULM_start, ready=>LM_ULM_ready, load_unload=>LM_ULM_load_unload, stopped=>LM_ULM_stopped, 
         continue=>LM_ULM_continue, done=>LM_ULM_done, base_address=>LM_ULM_base_address, upper_limit=>LM_ULM_upper_limit, 
         CP_in_word=>DataIn, CP_out_word=>DataOut, 
         PNL_BRAM_addr=>PNL_BRAM_addr, PNL_BRAM_din=>PNL_BRAM_din, PNL_BRAM_dout=>PNL_BRAM_dout, PNL_BRAM_we=>PNL_BRAM_we);


    hdmi_sync_i: entity work.hdmi_sync(rtl)
       port map (clk=>Clk, reset=>reset, hdmi_hsync=>hdmi_hsync, hdmi_vsync=>hdmi_vsync, hdmi_enable=>hdmi_enable_out, pixel_x=>pixel_x, pixel_y=>pixel_y);

   pixel_x_std <= std_logic_vector(pixel_x(9 downto 0));
   pixel_y_std <= std_logic_vector(pixel_y);
   pong_i: entity work.Background(bathroom)
      port map (clk=>Clk, reset=>reset, video_on=>hdmi_enable_out, pixel_x=>pixel_x_std, pixel_y=>pixel_y_std, graph_rgb=>background_rgb);
   
   player_1: entity work.player(player_1)
      port map (clk=>Clk, reset=>reset, on_brd_btn=>on_brd_btn, video_on=>hdmi_enable_out, pixel_x=>pixel_x_std, pixel_y=>pixel_y_std, graph_rgb=>player_rgb, 
                doing_assignment=>doing_assignment, 
                holding_breath=>holding_breath, 
                blocking_view=>blocking_view,
                blocking_door=>blocking_door,
                dean_danger_normal=>dean_danger_normal,
                dean_game_over=>dean_game_over);
                
   level_progress_bar: entity work.level_timer_bar(Class_Bar)
      port map (clk=>Clk, 
                reset=>reset, 
                video_on=>hdmi_enable_out, 
                pixel_x=>pixel_x_std, 
                pixel_y=>pixel_y_std, 
                graph_rgb=>level_bar_rgb);

   renderer: entity work.renderer(renderer_arch)
      port map (clk=>Clk, 
                reset=>reset, 
                video_on=>hdmi_enable_out, 
                pixel_x=>pixel_x_std, 
                pixel_y=>pixel_y_std, 
                background_rgb => background_rgb,
                player_rgb => player_rgb,
                level_bar_rgb => level_bar_rgb,
                student_rgb => student_rgb,
                teacher_rgb => teacher_rgb,
                dean_rgb => dean_rgb,
                rgb_out => graph_rgb,
                dean_game_over => dean_game_over,
                teacher_game_over => teacher_game_over);
                
   student_npc: entity work.student_npc(student)
      port map(clk=>Clk, 
               reset=>reset, 
               video_on=>hdmi_enable_out, 
               pixel_x=>pixel_x_std, 
               pixel_y=>pixel_y_std,
               SUMMON_STUDENT=>btn(0),
               teacher_cant_hear=>teacher_cant_hear,
               graph_rgb=>student_rgb);

   teacher_npc: entity work.teacher_npc(teacher)
      port map(clk=>Clk, 
               reset=>reset, 
               video_on=>hdmi_enable_out, 
               pixel_x=>pixel_x_std, 
               pixel_y=>pixel_y_std,
               SUMMON_TEACHER=>btn(1),
               doing_assignment=>doing_assignment,
               blocked_stall=>blocking_view,
               teacher_cant_hear=>teacher_cant_hear,
               graph_rgb=>teacher_rgb,
               teacher_game_over =>teacher_game_over);
               
   dean_npc: entity work.dean_npc(dean)
      port map(clk=>Clk, 
               reset=>reset, 
               on_brd_btn=>on_brd_btn,
               video_on=>hdmi_enable_out, 
               pixel_x=>pixel_x_std, 
               pixel_y=>pixel_y_std,
               SUMMON_DEAN=>btn(2),
               graph_rgb=>dean_rgb,
               blocked_door=>blocking_door,
               dean_danger_normal=>dean_danger_normal,
               doing_assignment=>doing_assignment,
               dean_game_over=>dean_game_over);

--    hdmi_red <= std_logic_vector(resize(pixel_x, 8)) when sw_r = '1' else (others => '0');
--    hdmi_green <= std_logic_vector(resize(pixel_y, 8)) when sw_g = '1' else (others => '0');
   hdmi_red <= "11111111" when graph_rgb(0) = '1' else (others => '0');
   hdmi_green <= "11111111" when graph_rgb(1) = '1' else (others => '0');
   hdmi_blue <= "11111111" when graph_rgb(2) = '1' else (others => '0');

   hdmi_enable <= hdmi_enable_out;

end beh;

