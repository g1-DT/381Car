library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HandShake is
  port(CLOCK_50            : in  std_logic;
		 LEDR						: out  std_logic_vector(1 downto 0);
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
		 GPIO_1					: inout std_logic_vector(35 downto 0);
		 LEDG : out std_logic_vector(7 downto 0));
end HandShake;

architecture rtl of HandShake is
	signal readbits : std_logic;
	signal done  : std_logic;
	signal data1 : std_logic;
	signal ready : std_logic;
begin

	GPIO_1(1) <= ready;
	
	process (CLOCK_50)
	begin
		if(rising_edge(CLOCK_50)) then
			LEDG(0) <= readbits;
		end if;
	end process;
  
	process (CLOCK_50, KEY(3))
		type state_type is (resetState, idleState, readState);
		variable ackno : std_logic := '0';
		variable present_state : state_type := resetState;
	begin
		if(KEY(0) = '0') then
			present_state := resetState;
		elsif(rising_edge(CLOCK_50)) then
			case present_state is
				when resetState =>
				 ready <= '1';
				 ackno := GPIO_1(0);
				 LEDR(1 downto 0) <= "00";
				 present_state := idleState;
				when idleState =>
				 --do stuff here
				 if(ackno = '1') then
					ready <= '0';
					present_state := readState;
				 else
					LEDR(1 downto 0) <= "01";
					present_state := present_state;
				 end if;
				when readState =>
				 if(KEY(3) = '0') then
					readbits <= '1';
					present_state := resetState;
				 else
					LEDR(1 downto 0) <= "10";
					present_state := present_state;
				 end if;
			end case;
		end if;
	end process;
end rtl;


