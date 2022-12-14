library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity key_counter is
Port ( clk : in STD_LOGIC;
CE : in STD_LOGIC;
count_CLR : in STD_LOGIC;
TC : out STD_LOGIC;
disp_Update : out STD_LOGIC);
end key_counter;
architecture Behavioral of key_counter is
signal count: unsigned (2 downto 0) := "000";
begin
increment: process(clk, count)
begin
if rising_edge(clk) then
if count_CLR = '1' then -- reset counter
count <= "000";
else
if CE = '1' and count < "101" then -- if count enabled & count <5, increment
count <= count + 1;
end if;
end if;
end if;
if count = "101" then -- assert TC @ 4 (after 5 keypresses)
TC <= '1';
disp_Update <= '0';
else
TC <= '0';
disp_Update <= '1';
end if;
end process increment;
end Behavioral;
