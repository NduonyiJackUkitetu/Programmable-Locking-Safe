----------------------------------------------------------------------------------
-- Company: ENGS 31
-- Engineer: Miles Bock & Phil Butler
--
-- Create Date: 08/14/2018 02:58:46 PM
-- Design Name:
-- Module Name: keypad_decoder - Behavioral
-- Project Name: Final Project - Combinational Lock
-- Target Devices: Basys 3 / Artyx 7
-- Tool Versions: Vivado 2017.3
-- Description: Decoder used to sequentially drive low signals to the -- keypad's columns and for each signal to sequentially read the -- corresponding low-High output from the keypad's rows
--
-- Dependencies: debouncer.vhdl
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 1.00 - Moved digit decode statements inside dec_driver process
-- changed cclk to a take_sample process
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity keypad_decoder is
Port ( clk : in STD_LOGIC; -- assumed 1000 Hz
row : in STD_LOGIC_VECTOR (3 downto 0);
col : out STD_LOGIC_VECTOR (3 downto 0);
digit_out : out STD_LOGIC_VECTOR (3 downto 0);
Key_Pressed_mp : out STD_LOGIC;
Cancel : out STD_LOGIC);
end keypad_decoder;
architecture Behavioral of keypad_decoder is
component debouncer is
Port ( clk : in STD_LOGIC;
deb_in : in STD_LOGIC;
deb_out : out STD_LOGIC);
end component;
signal div_count: unsigned(3 downto 0) := "1001"; -- clk divider count
signal CE: STD_LOGIC; -- divided clk signal
signal dec_count: unsigned(3 downto 0) := "0000"; -- decoder counter
signal dec_count_en: STD_LOGIC := '1'; -- decoder counter enable
signal drive_col: unsigned(1 downto 0); -- column driven addresss
signal read_row: unsigned(1 downto 0); -- row to read from address
signal row_status: STD_LOGIC; -- signal held on row being read
signal digit_decode: unsigned(3 downto 0); -- decoded output of dec_count
signal ss_sync: STD_LOGIC_VECTOR(1 downto 0) := "00"; -- monopulse logic signals
signal button_held: STD_LOGIC := '0';
signal ss: STD_LOGIC;
begin
deb: debouncer port map(
clk=>clk, deb_in=>row_status, deb_out=>dec_count_en);
key_press: process(clk, row, ss_sync, dec_count_en, digit_decode, ss) -- adapted from Prof. Hansen's lab4_shell
begin
if dec_count_en = '0' and digit_decode /= "0000" then button_held <= '1';
else button_held <= '0';
end if;
if rising_edge(clk) then -- monopulse send_scan when a key is pressed
ss_sync <= button_held & ss_sync(1);
end if;
ss <= ss_sync(1) and not(ss_sync(0));
Key_Pressed_mp <= ss;
end process key_press;
take_sample: process(clk, div_count) -- clk divider to drive at 100 Hz
begin
if rising_edge(clk) then
if div_count = "0000" then div_count <= "1001";
else div_count <= div_count - 1;
end if;
end if;
if div_count = "0000" then CE <= '1';
else CE <= '0';
end if;
end process take_sample;
dec_driver: process(clk, dec_count) -- decoder driver
begin
if rising_edge(clk) then
Cancel <= '0';
if CE = '1' then
if dec_count_en = '1' then
dec_count <= dec_count + 1;
digit_decode <= "0000";
else
if dec_count = "0000" then digit_decode <= "0001"; -- c0,r0: 1
elsif dec_count = "0001" then digit_decode <= "0100"; -- c0,r1: 4
elsif dec_count = "0010" then digit_decode <= "0111"; -- c0,r2: 7
elsif dec_count = "0011" then digit_decode <= "0000"; -- c0,r3: 0
elsif dec_count = "0100" then digit_decode <= "0010"; -- c1,r0: 2
elsif dec_count = "0101" then digit_decode <= "0101"; -- c1,r1: 5
elsif dec_count = "0110" then digit_decode <= "1000"; -- c1,r2: 8
elsif dec_count = "0111" then digit_decode <= "1111"; -- c1,r3: F
elsif dec_count = "1000" then digit_decode <= "0011"; -- c2,r0: 3
elsif dec_count = "1001" then digit_decode <= "0110"; -- c2,r1: 6
elsif dec_count = "1010" then digit_decode <= "1001"; -- c2,r2: 9
elsif dec_count = "1011" then digit_decode <= "1110"; -- c2,r3: E
elsif dec_count = "1100" then digit_decode <= "1010"; -- c3,r0: A
elsif dec_count = "1101" then digit_decode <= "1011"; -- c3,r1: B
elsif dec_count = "1110" then Cancel <= '1'; digit_decode <= "1100";-- c3,r2 -- C: cancel
else digit_decode <= "1101";
end if;
end if;
end if;
digit_out <= std_logic_vector(digit_decode);
end if;
drive_col <= dec_count(3 downto 2); -- rename highest and lowest order bits
read_row <= dec_count(1 downto 0);
end process dec_driver;
drive_mux: process(drive_col) -- changing dec_count's highest order bits to one cold
begin
if drive_col = "00" then col <= "0111";
elsif drive_col = "01" then col <= "1011";
elsif drive_col = "10" then col <= "1101";
elsif drive_col = "11" then col <= "1110";
else col <= "1110"; -- remove latch, could have eliminated last case
end if;
end process drive_mux;
read_dec: process(read_row, row) -- changing dec_count's lowest order bits to one cold
begin
if read_row = "00" then row_status <= row(3);
elsif read_row = "01" then row_status <= row(2);
elsif read_row = "10" then row_status <= row(1);
elsif read_row = "11" then row_status <= row(0);
else row_status <= row(0); -- remove latch, could have eliminated last case
end if;
end process read_dec;
end Behavioral;