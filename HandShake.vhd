library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HandShake is
  port(CLOCK_50            : in  std_logic;
		 LEDR						: out  std_logic_vector(3 downto 0);
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
		 GPIO_1					: inout std_logic_vector(35 downto 0);
		 GPIO_0					: inout std_logic_vector(35 downto 0);
		 LEDG : out std_logic_vector(7 downto 0));
end HandShake;

architecture rtl of HandShake is
	signal done : std_logic;
	signal modifybits : std_logic;
	signal writebits : std_logic;
	signal readbits : std_logic;	
	signal ready : std_logic;
	signal pi_ready : std_logic;
	signal de2_ackno : std_logic;
begin

	GPIO_1(10) <= ready;
	pi_ready <= GPIO_1(13);
	GPIO_1(12) <= de2_ackno;
	
	--DATAPATH
	process (CLOCK_50)
	variable readData : std_logic_vector(7 downto 0) := "00000000";
	variable modifiedData : std_logic_vector(7 downto 0) := "00000000";
	begin
		if(rising_edge(CLOCK_50)) then
			done <= '0';
			if(readbits = '1') then
				readData := GPIO_1(7 downto 0);
				done <= '1';
			end if;
			if(modifybits = '1') then
				modifiedData := not readData;
				done <= '1';
			end if;
			if(writebits = '1') then
				LEDG <= modifiedData(7 downto 0);
				GPIO_0(7 downto 0) <= modifiedData(7 downto 0);
				done <= '1';
			end if;
		end if;
	end process;
  
  
	--FINITE STATE MACHINE
	process (CLOCK_50)
		type state_type is (readyState, idleState, readState, modifyState, idleState2, writeState, signalState, waitState);
		variable ackno : std_logic; --ackno used as an indicator from pi to DE2 that tells the DE2 to read data
		variable present_state : state_type := idleState; --present_state represents the current state
		variable next_state : state_type; --next_state represents the next state transition for next iteration
	begin
		if(rising_edge(CLOCK_50)) then
			case present_state is
				--Preinitialize the DE2 to be ready to intake data via handshaking
				when readyState => 
				 readBits <= '0';
				 modifybits <= '0';
				 writebits <= '0';
				 ackno := '0';
				 ready <= '1';
				 DE2_ackno <= '0';
				 next_state := idleState;
				 LEDR(3 downto 0) <= "0000";
				--Wait for acknowledge signal to know when data is in the GPIO, if acknowledge is set then go to ready state
				when idleState =>
				 if(ackno = '1') then
					LEDR(3 downto 0) <= "0010";
					ready <= '0';
					next_state := readState;
				 else
					ackno := GPIO_1(11);
					LEDR(3 downto 0) <= "0001";
					next_state := idleState;
				 end if;
				--Tell datapath to read bits in input GPIO until done signal is set
				when readState =>
				 --DE2 is done reading
				 if(done = '1') then
					LEDR(3 downto 0) <= "0011";
					readbits <= '0';
					modifybits <= '1';
					next_state := modifyState;
			    --Set Datapath to read bits in GPIO
				 else
					readbits <= '1';
					modifybits <= '0';
					LEDR(3 downto 0) <= "0010";
					next_state := readState;
				 end if;
				 --Tell datapath to modify bits that were stored in a signal
				 when modifyState =>
					--DE2 done modifying the signal, transition to writeState
					if(done = '1') then
						modifybits <= '0';
						readbits <= '0';
						ready <= '1';
						LEDR(3 downto 0) <= "0100";
						next_state := idleState2;
					else
						LEDR(3 downto 0) <= "0011";
						modifybits <= '1';
						ready <= '0';
						readbits <= '0';
						next_state := modifyState;
					end if;
				  when idleState2 =>
						if(GPIO_1(13) = '1') then
							LEDR(3 downto 0) <= "1000";
							next_State := writeState;
						else
							LEDR(3 downto 0) <= "0100";
							modifybits <= '0';
							readbits <= '0';
							next_State := idleState2; --check for other conditions afterwards
						end if;
				  when writeState =>
					 if(done = '1') then
						LEDR(3 downto 0) <= "1000";
						writebits <= '0';
						DE2_ackno <= '1';
						next_state := waitState;
					 else
						LEDR(3 downto 0) <= "0111";
						readbits <= '0';
						modifybits <= '0';
						writebits <= '1';
						next_state := writeState;
					 end if;
				  when waitState => --wait until the ready is set to 0
					 if(pi_ready = '0') then
						LEDR(3 downto 0) <= "1001";
						next_state := signalState;
					 else
						LEDR(3 downto 0) <= "1000";
						next_state := waitState;
					 end if;
				  when others =>
						if(pi_ready = '1') then
							LEDR(3 downto 0) <= "0000";
							DE2_ackno <= '0';
							next_state := readyState;	
						else
							LEDR(3 downto 0) <= "1001";
							next_state := signalState;
						end if;
				  end case;
			present_state := next_state;
		end if;
	end process;
end rtl;


