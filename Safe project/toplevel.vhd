library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL; -- needed for arithmetic
use ieee.math_real.ALL; -- needed for automatic register sizing
library UNISIM; -- needed for the BUFG component
use UNISIM.Vcomponents.ALL;
entity toplevel is
port (mclk : in std_logic; -- FPGA board master clock (100 MHz)
-- interface to keypad
rows : in std_logic_vector(3 downto 0);
cols : out std_logic_vector(3 downto 0);
-- multiplexed seven segment display
segs : out std_logic_vector(0 to 6);
ans : out std_logic_vector(3 downto 0);
LOCK_LED : out std_logic;
UNLOCK_LED : out std_logic;
FAIL_LED : out std_logic;
REPRO_LED : out std_logic );
end toplevel;
architecture Behavioral of toplevel is
-- COMPONENT DECLARATIONS
component compare is
Port ( clk : in STD_LOGIC;
serial_input : in STD_LOGIC_VECTOR(3 downto 0);
shift_en : in STD_LOGIC;
sr_CLR : in STD_LOGIC;
load_C : in STD_LOGIC;
load_M : in STD_LOGIC;
m_CLR : in STD_LOGIC;
disp_output : out STD_LOGIC_VECTOR(15 downto 0);
RP : out STD_LOGIC;
UL : out STD_LOGIC;
delay_CE : in std_logic;
delay_TC : out std_logic; -- temp
delay_CLR : in std_logic;
tc_VAL : in std_logic_vector(16 downto 0));
end component compare;
component key_counter is
Port( clk : in STD_LOGIC;
CE : in STD_LOGIC;
count_CLR : in STD_LOGIC;
TC : out STD_LOGIC;
disp_Update : out STD_LOGIC );
end component key_counter;
component mux7seg is
Port( clk : in STD_LOGIC;
in0 : in std_logic_vector(3 downto 0);
in1 : in std_logic_vector(3 downto 0);
in2 : in std_logic_vector(3 downto 0);
in3 : in std_logic_vector(3 downto 0);
disp_load : in STD_LOGIC;
disp_CLR : in STD_LOGIC;
seg : out STD_LOGIC_VECTOR(0 to 6);
an : out STD_LOGIC_VECTOR( 3 downto 0) );
end component mux7seg;
component keypad_decoder is
Port( clk : in STD_LOGIC;
row : in STD_LOGIC_VECTOR(3 downto 0);
col : out STD_LOGIC_VECTOR(3 downto 0);
digit_out : out STD_LOGIC_VECTOR(3 downto 0);
Key_Pressed_mp : out STD_LOGIC;
Cancel : out STD_LOGIC );
end component keypad_decoder;
component controller is
Port( clk : in STD_LOGIC;
Key_Pressed_mp : in STD_LOGIC;
Cancel : in STD_LOGIC;
TC : in STD_LOGIC;
RP : in STD_LOGIC;
UL : in STD_LOGIC;
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
delay_CE : out std_logic;
delay_TC : in std_logic; -- temp
delay_CLR : out std_logic;
tc_VAL : out std_logic_vector(16 downto 0));
end component controller;
-- System Clock Divider Signals:
constant SCLK_DIVIDER_VALUE: integer := 50000; -- 1MHz/50000 = 2 kHz, divided again by flip flop to 1 kHz
constant COUNT_LEN: integer := integer(ceil( log2( real(SCLK_DIVIDER_VALUE) ) ));
signal sclkdiv: unsigned(COUNT_LEN-1 downto 0) := (others => '0'); -- clock divider counter
signal sclk_unbuf: std_logic := '0'; -- unbuffered serial clock
signal sclk: std_logic := '0'; -- internal serial clock
signal disp_en, disp_clear, count_en, terminal_count, count_clear, shift_enable, sr_clear, L_C, L_M, M_clear, RPro, ULo, Cncl, KPmp, del_CE, del_TC, del_CLR : std_logic := '0';
signal serial : std_logic_vector(3 downto 0);
signal disp_vector : std_logic_vector(15 downto 0);
signal delay_value : std_logic_vector(16 downto 0);
begin
-- Clock buffer for sclk
-- The BUFG component puts the signal onto the FPGA clocking network
Slow_clock_buffer: BUFG
port map (I => sclk_unbuf,
O => sclk );
-- Divide the 100 MHz clock down to 2 kHz, then toggling a flip flop gives the final
-- 1 kHz system clock
Serial_clock_divider: process(mclk, sclk)
begin
if rising_edge(mclk) then
if sclkdiv = SCLK_DIVIDER_VALUE-1 then
sclkdiv <= (others => '0');
sclk_unbuf <= NOT(sclk_unbuf);
else
sclkdiv <= sclkdiv + 1;
end if;
end if;
end process Serial_clock_divider;
display: mux7seg port map(
clk => sclk,
in0 => disp_vector(15 downto 12),
in1 => disp_vector(11 downto 8),
in2 => disp_vector(7 downto 4),
in3 => disp_vector(3 downto 0),
disp_load => disp_en,
disp_CLR => disp_clear,
seg => segs,
an => ans );
counter: key_counter port map(
clk => sclk,
CE => count_en,
TC => terminal_count,
count_CLR => count_clear,
disp_Update => disp_en );
compares : compare port map(
clk => sclk,
serial_input => serial,
shift_en => shift_enable,
sr_CLR => sr_clear,
load_C => L_C,
load_M => L_M,
m_CLR => M_clear,
disp_output => disp_vector,
RP => RPro,
UL => ULo,
delay_CE => del_CE,
delay_TC => del_TC,
delay_CLR => del_CLR,
tc_VAL => delay_value);
kp_decoder : keypad_decoder port map(
clk => sclk,
row => rows,
col => cols,
digit_out => serial,
Key_Pressed_mp => KPmp,
Cancel => Cncl );
controllers : controller port map(
clk => sclk,
Key_Pressed_mp => KPmp,
Cancel => Cncl,
TC => terminal_count,
RP => RPro,
UL => ULo,
CE => count_en,
count_CLR => count_clear,
shift_en => shift_enable,
sr_CLR => sr_clear,
disp_CLR => disp_clear,
load_C => L_C,
load_M => L_M,
m_CLR => M_clear,
LOCK => LOCK_LED,
UNLOCK => UNLOCK_LED,
FAIL => FAIL_LED,
REPROG => REPRO_LED,
delay_CE => del_CE,
delay_TC => del_TC,
delay_CLR => del_CLR,
tc_VAL => delay_value);
end Behavioral;
