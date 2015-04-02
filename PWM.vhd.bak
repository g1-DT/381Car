library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM is
  port(CLOCK_50            : in  std_logic;
       SW                  : in  std_logic_vector(17 downto 0);
		 GPIO_1					: inout std_logic_vector(35 downto 0);
		 LEDG : out std_logic_vector(7 downto 0));
end PWM;

architecture rtl of PWM is
signal pwmLimit : integer;
begin
  process (CLOCK_50, SW)
	variable pwmcount : integer := 0;
	variable PWM0val : std_logic := '0';
	variable dec : integer := 0;
	variable count : integer := 1;
  begin
		if(rising_edge(CLOCK_50)) then
			pwmcount := pwmcount + 1;
			if(pwmcount >= pwmLimit and PWM0val = '1') then
				PWM0val := '0';
				pwmcount := 0;
				pwmLimit <= 15;
				GPIO_1(0) <= '0';
			elsif(pwmcount >= pwmLimit and PWM0val = '0') then
				PWM0val := '1';
				pwmcount := 0;
				pwmLimit <= 10;
				GPIO_1(0) <= '1';
			end if;
	   end if;	
		
		if(SW(0) = '1') then
			GPIO_1(3) <= '1';
		else
			GPIO_1(3) <= '0';
		end if;
		if(SW(1) = '1') then
			GPIO_1(4) <= '1';
		else
			GPIO_1(4) <= '0';
		end if;
	end process;
end rtl;

