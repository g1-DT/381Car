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
	signal done : std_logic;
	signal readbits : std_logic;	
	signal ready : std_logic;
begin

	GPIO_1(10) <= ready;
	
	process (CLOCK_50)
	variable readData : std_logic_vector(7 downto 0) := "00000000";
	begin
		if(rising_edge(CLOCK_50)) then
			done <= '0';
			if(readbits = '1') then
				readData := GPIO_1(7 downto 0);
				done <= '1';
			end if;
			LEDG <= readData(7 downto 0);
		end if;
	end process;
  
	process (CLOCK_50)
		type state_type is (readyState, idleState, readState);
		variable ackno : std_logic;
		variable present_state : state_type := idleState;
		variable next_state : state_type;
	begin
		if(rising_edge(CLOCK_50)) then
			case present_state is
				when readyState =>
				 readBits <= '0';
				 ackno := '0';
				 ready <= '1';
				 next_state := idleState;
				when idleState =>
				 --do stuff here
				 if(ackno = '1') then
					ready <= '0';
					next_state := readState;
				 else
					ackno := GPIO_1(11);
					LEDR(1 downto 0) <= "01";
					next_state := idleState;
				 end if;
				when others =>
				 if(done = '1') then
					readbits <= '0';
					next_state := readyState;
				 else
					readbits <= '1';
					LEDR(1 downto 0) <= "10";
					next_state := readState;
				 end if;
			end case;
			
			present_state := next_state;
		end if;
	end process;
end rtl;


