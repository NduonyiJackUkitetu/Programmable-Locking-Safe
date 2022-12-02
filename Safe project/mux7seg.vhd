library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
entity mux7seg is
Port ( clk : in STD_LOGIC; -- runs on a 1kHz clock
in0, in1, in2, in3 : in STD_LOGIC_VECTOR (3 downto 0); -- digits
seg : out STD_LOGIC_VECTOR(0 to 6); -- segments (a...g)
an : out STD_LOGIC_VECTOR (3 downto 0); -- anodes
disp_load : in std_logic;
disp_CLR : in std_logic);
end mux7seg;
architecture Behavioral of mux7seg is
constant NCLKDIV: integer := 2; -- 1 kHz / 2^2 = 250 Hz
constant MAXCLKDIV: integer := 2**NCLKDIV-1; -- max count of clock divider
signal cdcount: unsigned(NCLKDIV-1 downto 0); -- clock divider counter register
signal CE : std_logic; -- clock enable
signal adcount : unsigned(1 downto 0) := "00"; -- anode / mux selector count
signal anb: std_logic_vector(3 downto 0);
signal muxy : std_logic_vector(3 downto 0); -- mux output
signal segh : std_logic_vector(0 to 6); -- segments (high true)
signal y0 : std_logic_vector(3 downto 0):= "0000";
signal y1 : std_logic_vector(3 downto 0):= "0000";
signal y2 : std_logic_vector(3 downto 0) := "0000";
signal y3 : std_logic_vector(3 downto 0) := "0000";
begin
-- Clock divider sets the rate at which the display hops from one digit to the next. A larger value of
-- MAXCLKDIV results in a slower clock-enable (CE)
ClockDivider:
process(clk)
begin
if rising_edge(clk) then
if cdcount < MAXCLKDIV then
CE <= '0';
cdcount <= cdcount+1;
else CE <= '1';
cdcount <= (others => '0');
end if;
end if;
end process ClockDivider;
--LOAD OR CLEAR THE DISPLAY WITH VALUES FROM ins--
d_reg: process(clk, disp_load, disp_CLR)
begin
if rising_edge(clk) then
if disp_CLR = '1' then
y0 <= "0000";
y1 <= "0000";
y2 <= "0000";
y3 <= "0000";
else
if (disp_load) = '1' then
y0 <= in0;
y1 <= in1;
y2 <= in2;
y3 <= in3;
else
y0 <= y0;
y1 <= y1;
y2 <= y2;
y3 <= y3;
end if;
end if;
end if;
end process d_reg;
--SEQUENTIALLY DRIVE THE ANODES LOAD TO CYCLE THROUGH THEM--
AnodeDriver:
process(clk, adcount)
begin
if rising_edge(clk) then
if CE='1' then
adcount <= adcount + 1;
end if;
end if;
case adcount is
when "00" => anb <= "1110";
when "01" => anb <= "1101";
when "10" => anb <= "1011";
when "11" => anb <= "0111";
when others => anb <= "1111";
end case;
end process AnodeDriver;
an <= anb or "0000"; --- blank digit 3
--CHANGE SEGMENTS BASED ON WHICH ANODE IS BEING DRIVEN LOW--
Multiplexer:
process(adcount, y0, y1, y2, y3)
begin
case adcount is
when "00" => muxy <= y0;
when "01" => muxy <= y1;
when "10" => muxy <= y2;
when "11" => muxy <= y3;
when others => muxy <= x"0";
end case;
end process Multiplexer;
-- Seven segment decoder
with muxy select segh <=
"1111110" when x"0", -- active-high definitions
"0110000" when x"1",
"1101101" when x"2",
"1111001" when x"3",
"0110011" when x"4",
"1011011" when x"5",
"1011111" when x"6",
"1110000" when x"7",
"1111111" when x"8",
"1111011" when x"9",
"1110111" when x"a",
"0011111" when x"b",
"1001110" when x"c",
"0111101" when x"d",
"1001111" when x"e",
"1000111" when x"f",
"0000000" when others;
seg <= not(segh); -- Convert to active-low
end Behavioral;
