library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity debouncer is
Port ( clk : in STD_LOGIC; -- assumed 1kHz
deb_in : in STD_LOGIC;
deb_out : out STD_LOGIC);
end debouncer;
architecture Behavioral of debouncer is
-- counter signals
signal count: unsigned(3 downto 0) := "0100";
signal CE: std_logic := '0';
signal reset: std_logic := '1';
signal tc: std_logic;
signal T: std_logic := '0';-- t-flop
begin
deb: process(clk, count, CE, deb_in, T)
begin
if rising_edge(clk) then -- counter mechanics
if reset = '1' then
count <= "0100";
else
if CE = '1' then
if count = "0000" then
count <= "0100";
else
count <= count - 1;
end if;
end if;
end if;
T <= T xor tc; -- t flip flop mechanics
end if;
if count = "0000" and CE = '1' then -- combinational logic
tc <= '1';
else
tc <= '0';
end if;
CE <= deb_in xor T;
reset <= not(deb_in xor T);
deb_out <= T;
end process deb;
end Behavioral;
