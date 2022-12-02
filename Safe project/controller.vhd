----------------------------------------------------------------------------------
-- Company: ENGS 31
-- Engineer: Phil Butler and Miles Bock
--
-- Create Date: 08/14/2018 04:11:51 PM
-- Design Name:
-- Module Name: controller - Behavioral
-- Project Name: Final Project - Combinational Lock
-- Target Devices: Digilent Basys 3 board (Artix 7)
-- Tool versions: Vivado 2017.3
-- Description: Controls the state of the program and produces signals which
-- come from the controller.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 1.00 - Added pre-m state to deal with timing issue
-- Revision 2.00 - Removed pre-m state and fixed timing issue with delay -- timer in compare
-- Revision 3.00 - Edited change-of-state behavior for unlock and failure, -- now it uses same variable delay timer to hold lock/failure for a second
-- before going back to idle.
--
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity controller is
Port ( clk : in STD_LOGIC;
Key_Pressed_mp : in STD_LOGIC;
Cancel : in STD_LOGIC;
TC : in STD_LOGIC;
RP : in STD_LOGIC;
UL : in STD_LOGIC;
delay_TC : in STD_LOGIC;
CE : out STD_LOGIC;
count_CLR : out STD_LOGIC;
shift_en : out STD_LOGIC;
sr_CLR : out STD_LOGIC;
disp_CLR : out STD_LOGIC;
load_C : out STD_LOGIC;
load_M : out STD_LOGIC;
m_CLR : out STD_LOGIC;
LOCK : out STD_LOGIC;
UNLOCK : out STD_LOGIC;
FAIL : out STD_LOGIC;
REPROG : out STD_LOGIC;
delay_CE : out STD_LOGIC;
delay_CLR : out STD_LOGIC;
tc_VAL : out STD_LOGIC_VECTOR(16 downto 0));
end controller;
architecture Behavioral of controller is
type state_type is (idle, typing, ty_take_sample, load_M_reg,
compare, unlocked, failure, reprogram,
rp_take_sample, load_C_reg);
signal current_state, next_state: state_type := idle;
begin
--NEXT STATE AND OUTPUT LOGIC--
COMBONATIONAL_LOGIC:
process(clk, current_state, Key_Pressed_mp, Cancel, TC, RP, UL, delay_TC)
begin
next_state <= current_state;
CE <= '0';
count_CLR <= '0';
shift_en <= '0';
sr_CLR <= '0';
disp_CLR <= '0';
load_C <= '0';
load_M <= '0';
m_CLR <= '0';
LOCK <= '1';
UNLOCK <= '0';
FAIL <= '0';
REPROG <= '0';
delay_CLR <= '0';
delay_CE <= '0';
tc_VAL <= "11111111111111111"; 
case current_state is
when idle =>
sr_CLR <= '1';
disp_CLR <= '1';
count_CLR <= '1';
delay_CE <= '0';
delay_CLR <= '1';
if Key_Pressed_mp = '1' then
next_state <= ty_take_sample;
end if;
when ty_take_sample =>
shift_en <= '1';
CE <= '1';
if Cancel = '1' then
next_state <= idle;
else
next_state <= typing;
end if;
when typing =>
if Cancel = '1' then
next_state <= idle;
elsif TC = '1' then
next_state <= load_M_reg;
elsif Key_Pressed_mp = '1' then
next_state <= ty_take_sample;
end if;
when load_M_reg =>
load_M <= '1';
delay_CLR <= '0';
delay_CE <= '1';
tc_VAL <= "00000000000001111"; -- delay timer: .016 sec
if delay_TC = '1' then
next_state <= compare;
end if;
when compare =>
delay_CE <= '0';
delay_CLR <= '1';
sr_CLR <= '1';
count_CLR <= '1';
disp_CLR <= '1';
if RP = '1' then
next_state <= reprogram;
elsif UL = '1' then
next_state <= unlocked;
else
next_state <= failure;
end if;
when unlocked =>
m_CLR <= '1';
UNLOCK <= '1';
LOCK <= '0';
delay_CE <= '1';
delay_CLR <= '0';
if delay_TC = '1' then -- hold unlock for roughly 2 sec
next_state <= idle;
end if;
when failure =>
m_CLR <= '1';
FAIL <= '1';
delay_CE <= '1';
delay_CLR <= '0';
if delay_TC = '1' then -- hold failure for roughly 2 sec
next_state <= idle;
end if;
when reprogram =>
m_CLR <= '1';
REPROG <= '1';
if Cancel = '1' then
next_state <= idle;
elsif TC = '1' then
next_state <= load_C_reg;
elsif Key_Pressed_mp = '1' then
next_state <= rp_take_sample;
end if;
when rp_take_sample =>
shift_en <= '1';
CE <= '1';
if Cancel = '1' then
next_state <= idle;
else
next_state <= reprogram;
end if;
when load_C_reg =>
load_C <= '1';
next_state <= idle;
end case;
end process COMBONATIONAL_LOGIC;
--UPDATES STATE TO NEXT_STATE--
UPDATE_STATE : process(clk)
begin
if rising_edge(clk) then
current_state <= next_state;
end if;
end process UPDATE_STATE;
end Behavioral;