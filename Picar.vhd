library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Picar is
  port(CLOCK_50            : in  std_logic;
		 LEDR						: out  std_logic_vector(17 downto 0);
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
		 GPIO_1					: inout std_logic_vector(35 downto 0);
		 GPIO_0					: inout std_logic_vector(35 downto 0);
		 LEDG : out std_logic_vector(7 downto 0));
end Picar;

architecture rtl of Picar is
	subtype pixel_colour is std_logic_vector(7 downto 0);
	type colour_array is array(integer range 0 to 2, integer range 0 to 9) of pixel_colour;
	signal red_array : colour_array;
	signal green_array : colour_array;
	signal blue_array : colour_array;
	signal done : std_logic;
	signal modifybits : std_logic;
	signal writebits : std_logic;
	signal readbits : std_logic;
	signal resetVar : std_logic;
	signal ready : std_logic;
	signal pi_ready : std_logic;
	signal de2_ackno : std_logic;
	signal read_row : integer := 0;
begin

	GPIO_1(10) <= ready;
	pi_ready <= GPIO_1(13);
	GPIO_1(12) <= de2_ackno;
	
	--DATAPATH
	process (CLOCK_50)
		type store_type is (red, green, blue);
		variable readData : std_logic_vector(7 downto 0) := "00000000";
		variable modifiedData : std_logic_vector(7 downto 0) := "00000000";
		variable colour_type : store_type := red;
		variable r_x : integer := 0;
		variable g_x : integer := 0;
		variable b_x : integer := 0;
	begin
		if(rising_edge(CLOCK_50)) then
			readData(7 downto 0) := GPIO_1(7 downto 0);
			done <= '0';
			if(readbits = '1') then
				if(colour_type = red) then
					red_array(read_row,r_x) <= readData(7 downto 0);
					if(r_x = 9) then
						r_x := 0;
					else
						r_x := r_x + 1;
					end if;
					colour_type := green;
					LEDR(17 downto 15) <= "100";
				elsif(colour_type = green) then
					green_array(read_row,g_x) <= readData(7 downto 0);
					if(g_x = 9) then
						g_x := 0;
					else
						g_x := g_x + 1;
					end if;
					colour_type := blue;
					LEDR(17 downto 15) <= "010";
				else
					blue_array(read_row,b_x) <= readData(7 downto 0);
					if(b_x = 9) then
						b_x := 0;
					else
						b_x := b_x + 1;
					end if;
					colour_type := red;
					LEDR(17 downto 15) <= "001";
				end if;
				LEDG(7 downto 0) <= green_array(0,8);
				done <= '1';
			end if;
			
			if(modifybits = '1') then
				
				done <= '1';
			end if;
			
			if(writebits = '1') then
				--GPIO_0(7 downto 0) <= modifiedData(7 downto 0);
				done <= '1';
			end if;
			
			if(resetVar = '1') then
				r_x := 0;
				g_x := 0;
				b_x := 0;
				done <= '1';
			end if;
		end if;
	end process;
  
  
	--FINITE STATE MACHINE
	process (CLOCK_50)
		type state_type is (startState, idleState, initState, modifyState, idleState2, writeState, signalState, waitState, waitForAckno, resetVariables, readState);
		variable count_p : integer := 0;
		variable ackno : std_logic; --ackno used as an indicator from pi to DE2 that tells the DE2 to read data
		variable present_state : state_type := idleState; --present_state represents the current state
		variable next_state : state_type; --next_state represents the next state transition for next iteration
	begin
		if(rising_edge(CLOCK_50)) then
			case present_state is
				--Preinitialize the DE2 to be ready to intake data via handshaking
				when startState => 
				 readBits <= '0';
				 modifybits <= '0';
				 writebits <= '0';
				 ready <= '1';
				 DE2_ackno <= '0';
				 next_state := idleState;
				 LEDR(3 downto 0) <= "0000";
				--Wait for acknowledge signal to know when data is in the GPIO, if acknowledge is set then go to ready state
				when idleState =>
				 if(ackno = '1') then
					LEDR(3 downto 0) <= "0010";
					ready <= '0';
					readbits <= '1';
					next_state := initState;
				 else
					readbits <= '0';
					ackno := GPIO_1(11);
					LEDR(3 downto 0) <= "0001";
					next_state := idleState;
				 end if;
				--Tell datapath to read bits in input GPIO until done signal is set
				when initState =>
				 --DE2 is done reading
				 if(count_p = 29) then
					ready <= '1';
					readbits <= '0';
					count_p := 0;
					ackno := '0';
					LEDR(3 downto 0) <= "1010";
					next_state := readState;
				 elsif(done = '1') then
					ready <= '1';
					count_p := count_p + 1;
					LEDR(3 downto 0) <= "0011";
					readbits <= '0';
					next_state := waitForAckno;
			    --Set Datapath to read bits in GPIO
				 else
					ready <= '0';
					readbits <= '0';
					LEDR(3 downto 0) <= "0111";
					next_state := initState;
				 end if;
				 --confirm the acknowledge is back to 0
				 when waitForAckno =>
					if(ackno = '0') then
						readbits <= '0';
						LEDR(3 downto 0) <= "1110";
						next_state := idleState;
					else
						readbits <= '0';
						ackno := GPIO_1(11);
						LEDR(3 downto 0) <= "1110";
						next_state := waitForAckno;
					end if;
				  when readState =>
					if(GPIO_1(11) = '1') then
						LEDR(3 downto 0) <= "1011";
						next_state := modifyState;
					else
						readbits <= '0';
						LEDR(3 downto 0) <= "0000";
						next_state := readState;
					end if;
				  when others =>
					LEDR(3 downto 0) <= "1111";
				  end case;
			present_state := next_state;
		end if;
	end process;
end rtl;


