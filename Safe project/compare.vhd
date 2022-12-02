library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity compare is
Port ( clk : in STD_LOGIC;
serial_input : in STD_LOGIC_VECTOR(3 downto 0);
shift_en : in STD_LOGIC;
sr_CLR : in STD_LOGIC;
load_C : in STD_LOGIC;
load_M : in STD_LOGIC;
M_CLR : in STD_LOGIC;
delay_CLR : in std_logic;
tc_VAL: in std_logic_vector(16 downto 0);
delay_CE : in std_logic;
disp_output : out STD_LOGIC_VECTOR(15 downto 0);
RP : out STD_LOGIC;
UL : out STD_LOGIC;
delay_TC : out std_logic);
end compare;
architecture Behavioral of compare is
constant master_code : std_logic_vector(15 downto 0) := "0001001000110100"; --Master Code: 1234
constant unlock_key : std_logic_vector(3 downto 0) := "1010"; --Unlock key is A
constant reprogram_key : std_logic_vector(3 downto 0) := "1011";--Reprogram key is B
signal shift_output : std_logic_vector(19 downto 0) := "00000000000000000000";
signal temp_code : std_logic_vector(15 downto 0) := "0001000100100011"; --Reprogramable Code is defaulted to 1234
signal main_reg : std_logic_vector(19 downto 0) := "00000000000000000000";
signal delay : unsigned(16 downto 0) := "00000000000000000"; -- delay timer count
signal terminal_value : unsigned(16 downto 0); -- delay timer terminal value, adjusted via input tc_VAL
begin
disp_output <= shift_output(15 downto 0);
--SHIFTS BIT INTO REGISTER WHEN shift_en IS ENABLED--
SHIFT_PROCESS: process(clk, shift_en, serial_input)
begin
if rising_edge(clk) then
if shift_en = '1' then
shift_output <= shift_output(15 downto 0) & serial_input;
end if;
if sr_CLR = '1' then
shift_output <= (others => '0');
end if;
end if;
end process SHIFT_PROCESS;
--LOADS C REGISTER WITH THE CURRENT CODE IN SHIFT REGISTER WHEN load_C IS ENABLED--
NEW_COMBO: process(clk)
begin
if rising_edge(clk) then
if load_C = '1' then
temp_code <= shift_output(19 downto 4);
end if;
end if;
end process NEW_COMBO;
--LOADS/CLEARS MAIN REGISTER WHEN load_M/M_CLR IS ENABLED--
LOAD_PROC: process(clk, load_M, M_CLR)
begin
if rising_edge(clk) then
if load_M = '1' then
main_reg <= shift_output;
elsif M_CLR = '1' then
main_reg <= (others => '0');
end if;
end if;
end process LOAD_PROC;
-- ADJUSTABLE TIMER USED TO DELAY TRANSITION INTO COMPARE STATE, AVOID TIMING CONFLICT --
delay_timer: process(clk, delay_CE, delay_CLR, tc_VAL, terminal_value, delay)
begin
terminal_value <= unsigned(tc_VAL);
if rising_edge(clk) then
if delay_CLR = '1' then
delay <= "00000000000000000";
else
if delay_CE = '1' then
if delay = terminal_value then
delay <= terminal_value;
else
delay <= delay + 1;
end if;
end if;
end if;
end if;
if delay = terminal_value then delay_TC <= '1'; else delay_TC <= '0';
end if;
end process delay_timer;
--COMPARES THE VALUE OF THE CODE LOADED INTO THE MAIN REGISTER AND THE MASTER/TEMP
--CODE THEN IF CORRECT CODE IF A OR B IS PRESSED SENDS UNLOCK OR REPROGRAM.--
COMPARE: process(clk, main_reg)
begin
if rising_edge(clk) then
if (main_reg(19 downto 4) = master_code) or (main_reg(19 downto 4) = temp_code) then
if main_reg(3 downto 0) = unlock_key then
UL <= '1';
elsif main_reg(3 downto 0) = reprogram_key then
RP <= '1';
end if;
else
UL <= '0';
RP <= '0';
end if;
end if;
end process COMPARE;
end Behavioral;
