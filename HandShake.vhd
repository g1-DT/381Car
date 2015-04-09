library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HandShake is
  port(CLOCK_50            : in  std_logic;
		 LEDR						: out  std_logic_vector(17 downto 0);
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
	signal resetVar : std_logic;
	signal ready : std_logic;
	signal pi_ready : std_logic;
	signal de2_ackno : std_logic;
	signal kernel_mode : std_logic_vector(3 downto 0);
begin

	GPIO_1(10) <= ready;
	pi_ready <= GPIO_1(13);
	GPIO_1(12) <= de2_ackno;
	
	--DATAPATH
	process (CLOCK_50)
		subtype pixel_colour is std_logic_vector(7 downto 0);
		type colour_array is array(integer range 0 to 2, integer range 0 to 9) of pixel_colour;
		type mod_array is array(integer range 0 to 9) of pixel_colour;
		variable red_array : colour_array;
		variable green_array : colour_array;
		variable blue_array : colour_array;
		variable mod_red : mod_array;
		variable mod_green : mod_array;
		variable mod_blue : mod_array;
		type kern is array(integer range 0 to 2, integer range 0 to 2) of integer;
		variable kernel : kern;
		type store_type is (red, green, blue);
		variable readData : std_logic_vector(7 downto 0) := "00000000";
		variable modifiedData : std_logic_vector(7 downto 0) := "00000000";
		variable colour_type : store_type := red;
		variable r_x : integer := 0;
		variable r_y : integer := 0;
		variable g_x : integer := 0;
		variable g_y : integer := 0;
		variable b_x : integer := 0;
		variable b_y : integer := 0;
		variable mod_x : integer := 0;
		variable r_sum : integer := 0;
		variable g_sum : integer := 0;
		variable b_sum : integer := 0;
	begin
		if(rising_edge(CLOCK_50)) then
			readData(7 downto 0) := GPIO_1(7 downto 0);
			kernel_mode <= "0000";
			done <= '0';
			if(readbits = '1') then
				if(colour_type = red) then
					red_array(r_y,r_x) := readData(7 downto 0);
					if(r_x = 9 and r_y = 2) then
						r_y := 0;
						r_x := 0;
					elsif(r_x = 9) then
						r_x := 0;
						r_y := r_y + 1;
					else
						r_x := r_x + 1;
					end if;
					colour_type := green;
					--LEDR(17 downto 15) <= "100";
				elsif(colour_type = green) then
					green_array(g_y,g_x) := readData(7 downto 0);
					if(g_x = 9 and g_y = 2) then
						g_y := 0;
						g_x := 0;
					elsif(g_x = 9) then
						g_x := 0;
						g_y := g_y + 1;
					else
						g_x := g_x + 1;
					end if;
					colour_type := blue;
					--LEDR(17 downto 15) <= "010";
				else
					blue_array(b_y,b_x) := readData(7 downto 0);
					if(b_x = 9 and b_y = 2) then
						b_y := 0;
						b_x := 0;
					elsif(b_x = 9) then
						b_x := 0;
						b_y := b_y + 1;
					else
						b_x := b_x + 1;
					end if;
					colour_type := red;
					--LEDR(17 downto 15) <= "001";
				end if;
				--LEDG(7 downto 0) <= blue_array(1,9);
				done <= '1';
			end if;
			
			if(modifybits = '1') then
--				--Computes kernel depending on kernel mode
--				--if(GPIO_1(10) = '1') then
--					kernel(0,0) := 0;
--					kernel(0,1) := 0;
--					kernel(0,2) := 0;
--					kernel(1,0) := 0;
--					kernel(1,1) := 10;
--					kernel(1,2) := 5;
--					kernel(2,0) := 0;
--					kernel(2,1) := 5;
--					kernel(2,2) := 0;
--				
--				
--				r_sum := 0;
--				g_sum := 0;
--				b_sum := 0;
--				
--				--Compute 1 bit
--				if( NOT(mod_x = 0) AND NOT(mod_x = 9)) then
--					r_sum := r_sum + kernel(0,0) * to_integer(unsigned(red_array(r_y, mod_x - 1))) / 10 + kernel(0,1) * to_integer(unsigned(red_array(r_y, mod_x))) / 10+ kernel(0, 2) * to_integer(unsigned(red_array(r_y, mod_x + 1))) / 10;
--					r_sum := r_sum + kernel(1,0) * to_integer(unsigned(red_array((r_y + 1) mod 3, mod_x - 1))) / 10 + kernel(1,1) * to_integer(unsigned(red_array((r_y + 1) mod 3, mod_x))) / 10 + kernel(1, 2) * to_integer(unsigned(red_array((r_y + 1) mod 3, mod_x + 1))) / 10;
--					r_sum := r_sum + kernel(2,0) * to_integer(unsigned(red_array((r_y + 2) mod 3, mod_x - 1))) / 10 + kernel(2,1) * to_integer(unsigned(red_array((r_y + 2) mod 3, mod_x))) / 10 + kernel(2, 2) * to_integer(unsigned(red_array((r_y + 2) mod 3, mod_x + 1))) / 10;
--					
--					g_sum := g_sum + kernel(0,0) * to_integer(unsigned(green_array(r_y, mod_x - 1))) / 10 + kernel(0,1) * to_integer(unsigned(green_array(r_y, mod_x))) / 10+ kernel(0, 2) * to_integer(unsigned(green_array(r_y, mod_x + 1))) / 10;
--					g_sum := g_sum + kernel(1,0) * to_integer(unsigned(green_array((r_y + 1) mod 3, mod_x - 1))) / 10 + kernel(1,1) * to_integer(unsigned(green_array((r_y + 1) mod 3, mod_x))) / 10 + kernel(1, 2) * to_integer(unsigned(green_array((r_y + 1) mod 3, mod_x + 1))) / 10;
--					g_sum := g_sum + kernel(2,0) * to_integer(unsigned(green_array((r_y + 2) mod 3, mod_x - 1))) / 10 + kernel(2,1) * to_integer(unsigned(green_array((r_y + 2) mod 3, mod_x))) / 10 + kernel(2, 2) * to_integer(unsigned(green_array((r_y + 2) mod 3, mod_x + 1))) / 10;
--					
--					b_sum := b_sum + kernel(0,0) * to_integer(unsigned(blue_array(r_y, mod_x - 1))) / 10 + kernel(0,1) * to_integer(unsigned(blue_array(r_y, mod_x))) / 10+ kernel(0, 2) * to_integer(unsigned(blue_array(r_y, mod_x + 1))) / 10;
--					b_sum := b_sum + kernel(1,0) * to_integer(unsigned(blue_array((r_y + 1) mod 3, mod_x - 1))) / 10 + kernel(1,1) * to_integer(unsigned(blue_array((r_y + 1) mod 3, mod_x))) / 10 + kernel(1, 2) * to_integer(unsigned(blue_array((r_y + 1) mod 3, mod_x + 1))) / 10;
--					b_sum := b_sum + kernel(2,0) * to_integer(unsigned(blue_array((r_y + 2) mod 3, mod_x - 1))) / 10 + kernel(2,1) * to_integer(unsigned(blue_array((r_y + 2) mod 3, mod_x))) / 10 + kernel(2, 2) * to_integer(unsigned(blue_array((r_y + 2) mod 3, mod_x + 1))) / 10;
--				end if;
--				if( mod_x = 0) then
--					r_sum := r_sum + kernel(0,1) * to_integer(unsigned(red_array(r_y, mod_x))) / 10 + kernel(0, 2) * to_integer(unsigned(red_array(r_y, mod_x + 1))) / 10;
--					r_sum := r_sum + kernel(1,1) * to_integer(unsigned(red_array((r_y + 1) mod 3, mod_x))) / 10 + kernel(1, 2) * to_integer(unsigned(red_array((r_y + 1) mod 3, mod_x + 1))) / 10;
--					r_sum := r_sum + kernel(2,1) * to_integer(unsigned(red_array((r_y + 2) mod 3, mod_x))) / 10 + kernel(2, 2) * to_integer(unsigned(red_array((r_y + 2) mod 3, mod_x + 1))) / 10;
--					
--					g_sum := g_sum + kernel(0,1) * to_integer(unsigned(green_array(r_y, mod_x))) / 10+ kernel(0, 2) * to_integer(unsigned(green_array(r_y, mod_x + 1))) / 10;
--					g_sum := g_sum + kernel(1,1) * to_integer(unsigned(green_array((r_y + 1) mod 3, mod_x))) / 10 + kernel(1, 2) * to_integer(unsigned(green_array((r_y + 1) mod 3, mod_x + 1))) / 10;
--					g_sum := g_sum + kernel(2,1) * to_integer(unsigned(green_array((r_y + 2) mod 3, mod_x))) / 10 + kernel(2, 2) * to_integer(unsigned(green_array((r_y + 2) mod 3, mod_x + 1))) / 10;
--					
--					b_sum := b_sum + kernel(0,1) * to_integer(unsigned(blue_array(r_y, mod_x))) / 10 + kernel(0, 2) * to_integer(unsigned(blue_array(r_y, mod_x + 1))) / 10;
--					b_sum := b_sum + kernel(1,1) * to_integer(unsigned(blue_array((r_y + 1) mod 3, mod_x))) / 10 + kernel(1, 2) * to_integer(unsigned(blue_array((r_y + 1) mod 3, mod_x + 1))) / 10;
--					b_sum := b_sum + kernel(2,1) * to_integer(unsigned(blue_array((r_y + 2) mod 3, mod_x))) / 10 + kernel(2, 2) * to_integer(unsigned(blue_array((r_y + 2) mod 3, mod_x + 1))) / 10;
--				
--				end if;
--				if( mod_x = 9) then
--					r_sum := r_sum + kernel(0,0) * to_integer(unsigned(red_array(r_y, mod_x - 1))) / 10 + kernel(0,1) * to_integer(unsigned(red_array(r_y, mod_x))) / 10;
--					r_sum := r_sum + kernel(1,0) * to_integer(unsigned(red_array((r_y + 1) mod 3, mod_x - 1))) / 10 + kernel(1,1) * to_integer(unsigned(red_array((r_y + 1) mod 3, mod_x))) / 10;
--					r_sum := r_sum + kernel(2,0) * to_integer(unsigned(red_array((r_y + 2) mod 3, mod_x - 1))) / 10 + kernel(2,1) * to_integer(unsigned(red_array((r_y + 2) mod 3, mod_x))) / 10;
--					
--					g_sum := g_sum + kernel(0,0) * to_integer(unsigned(green_array(r_y, mod_x - 1))) / 10 + kernel(0,1) * to_integer(unsigned(green_array(r_y, mod_x))) / 10;
--					g_sum := g_sum + kernel(1,0) * to_integer(unsigned(green_array((r_y + 1) mod 3, mod_x - 1))) / 10 + kernel(1,1) * to_integer(unsigned(green_array((r_y + 1) mod 3, mod_x))) / 10;
--					g_sum := g_sum + kernel(2,0) * to_integer(unsigned(green_array((r_y + 2) mod 3, mod_x - 1))) / 10 + kernel(2,1) * to_integer(unsigned(green_array((r_y + 2) mod 3, mod_x))) / 10;
--					
--					b_sum := b_sum + kernel(0,0) * to_integer(unsigned(blue_array(r_y, mod_x - 1))) / 10 + kernel(0,1) * to_integer(unsigned(blue_array(r_y, mod_x))) / 10;
--					b_sum := b_sum + kernel(1,0) * to_integer(unsigned(blue_array((r_y + 1) mod 3, mod_x - 1))) / 10 + kernel(1,1) * to_integer(unsigned(blue_array((r_y + 1) mod 3, mod_x))) / 10;
--					b_sum := b_sum + kernel(2,0) * to_integer(unsigned(blue_array((r_y + 2) mod 3, mod_x - 1))) / 10 + kernel(2,1) * to_integer(unsigned(blue_array((r_y + 2) mod 3, mod_x))) / 10;
--				end if;
--				
--				mod_red(mod_x) := std_logic_vector(to_unsigned(r_sum, 8));
--				mod_green(mod_x) := std_logic_vector(to_unsigned(g_sum, 8));
--				mod_blue(mod_x) := std_logic_vector(to_unsigned(b_sum, 8));
--				
--				--LEDG(7 downto 0) <= mod_red(9);
--				
--				if(mod_x = 9) then
--					mod_x := 0;
--					done <= '1';
--				else
--					done <= '0';	
--					mod_x := mod_x + 1;
--				end if;
				done <= '1';
			end if;
			
    		if(writebits = '1') then
--				if(colour_type = red) then
--					GPIO_0(7 downto 0) <= mod_red(r_x);
--					LEDG(7 downto 0) <= mod_red(0);
--					if(r_x = 9) then
--						r_x := 0;
--					else
--						r_x := r_x + 1;
--					end if;
--					colour_type := green;
--					--LEDR(17 downto 15) <= "100";
--				elsif(colour_type = green) then
--					GPIO_0(7 downto 0) <= mod_green(g_x);
--					--LEDG(7 downto 0) <= mod_green(g_x);
--					if(g_x = 9) then
--						g_x := 0;
--					else
--						g_x := g_x + 1;
--					end if;
--					colour_type := blue;
--					--LEDR(17 downto 15) <= "010";
--				else
--					GPIO_0(7 downto 0) <= mod_blue(b_x);
--					--LEDG(7 downto 0) <= mod_blue(b_x);
--					if(b_x = 9) then
--						b_x := 0;
--					else
--						b_x := b_x + 1;
--					end if;
--					colour_type := red;
--					--LEDR(17 downto 15) <= "001";
--				end if;
				done <= '1';
			end if;
			
			if(resetVar = '1') then
				r_y := 0;
				r_x := 0;
				g_y := 0;
				g_x := 0;
				b_y := 0;
				b_x := 0;
				done <= '1';
			end if;
		end if;
	end process;
  
  
	--FINITE STATE MACHINE
	process (CLOCK_50)
		type state_type is (readyState, resetState, doneLoading, check1, check2, check3, readyState2, waitForDone, waitForAckno3, waitForAckno4, readState2, idleState, readState, modifyState, idleState2, idleState3, writeState, signalState, signalState2, waitState, waitForAckno, waitForAckno2, resetVariables);
		variable count_p : integer := 0;
		variable ackno : std_logic; --ackno used as an indicator from pi to DE2 that tells the DE2 to read data
		variable present_state : state_type := readyState; --present_state represents the current state
		variable next_state : state_type; --next_state represents the next state transition for next iteration
		variable count_f : integer := 0;
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
				 LEDR(3 downto 0) <= "0001";
				--Wait for acknowledge signal to know when data is in the GPIO, if acknowledge is set then go to ready state
				when idleState =>
				 if(ackno = '1') then
					LEDR(3 downto 0) <= "0010";
					ready <= '0';
					readbits <= '1';
					next_state := readState;
				 else
					readbits <= '0';
					ackno := GPIO_1(11);
					LEDR(3 downto 0) <= "0001";
					next_state := idleState;
				 end if;
				--Tell datapath to read bits in input GPIO until done signal is set
				when readState =>
				 --DE2 is done reading
				 if(count_p = 29) then
					ready <= '1';
					readbits <= '0';
					count_p := 0;
					next_state := waitForAckno2;
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
					LEDR(3 downto 0) <= "0010";
					next_state := readState;
				 end if;
				 --confirm the acknowledge is back to 0
				 when waitForAckno =>
					if(ackno = '0') then
						readbits <= '0';
						LEDR(3 downto 0) <= "1110";
						next_state := readyState;
					else
						readbits <= '0';
						ackno := GPIO_1(11);
						LEDR(3 downto 0) <= "1110";
						next_state := waitForAckno;
					end if;
				 when waitForAckno2 =>
					if(ackno = '0') then
						readbits <= '0';
						LEDR(3 downto 0) <= "1110";
						next_state := readyState2;
					else
						readbits <= '0';
						ackno := GPIO_1(11);
						LEDR(3 downto 0) <= "1110";
						next_state := waitForAckno2;
					end if;
				 when resetVariables =>
					if(done = '1') then
						resetVar <= '0';
						next_state := modifyState;
					else
						resetVar <= '1';
						next_state := resetVariables;
					end if;
				 when readyState2 => 
					readBits <= '0';
					modifybits <= '0';
					writebits <= '0';
					ackno := '0';
					ready <= '1';
					DE2_ackno <= '0';
					next_state := idleState3;
					LEDR(3 downto 0) <= "0011";
				 when idleState3 =>
				  if(ackno = '1') then
					LEDR(3 downto 0) <= "0010";
					ready <= '0';
					readbits <= '1';
					next_state := readState2;
				  else
					readbits <= '0';
					ackno := GPIO_1(11);
					LEDR(3 downto 0) <= "0111";
					next_state := idleState3;
				 end if;
				--Tell datapath to read bits in input GPIO until done signal is set
				when readState2 =>
				 --DE2 is done reading
				 if(count_p = 29) then
					ready <= '1';
					readbits <= '0';
					count_p := 0;
					next_state := waitForAckno3;
				 elsif(done = '1') then
					ready <= '1';
					count_p := count_p + 1;
					LEDR(3 downto 0) <= "0011";
					readbits <= '0';
					next_state := waitForAckno4;
			    --Set Datapath to read bits in GPIO
				 else
					ready <= '0';
					readbits <= '0';
					LEDR(3 downto 0) <= "1001";
					next_state := readState2;
				 end if;
				 --confirm the acknowledge is back to 0
				 when waitForAckno3 =>
					if(ackno = '0') then
						readbits <= '0';
						LEDR(3 downto 0) <= "1110";
						next_state := modifyState;
					else
						readbits <= '0';
						ackno := GPIO_1(11);
						LEDR(3 downto 0) <= "1110";
						next_state := waitForAckno3;
					end if;
				 when waitForAckno4 =>
					if(ackno = '0') then
						readbits <= '0';
						LEDR(3 downto 0) <= "1110";
						next_state := readyState2;
					else
						readbits <= '0';
						ackno := GPIO_1(11);
						LEDR(3 downto 0) <= "1110";
						next_state := waitForAckno4;
					end if;
				 --confirm the acknowledge is back to 0
				 --Tell datapath to modify bits that were stored in a signal
				 when modifyState =>
					--DE2 done modifying the signal, transition to writeState
					--TODO: do something cool in this state to modify bits
					if(done = '1') then
						modifybits <= '0';
						LEDR(3 downto 0) <= "1111";
						next_state := idleState2;
					else
						LEDR(3 downto 0) <= "0000";
						modifybits <= '1';
						next_state := modifyState;
					end if;
				  when idleState2 =>
						if(GPIO_1(13) = '1') then
							LEDR(3 downto 0) <= "1000";
							writebits <= '0';
							next_state := writeState;
						else
							LEDR(3 downto 0) <= "0100";
							writebits <= '0';
							next_state := idleState2; --check for other conditions afterwards
						end if;
				  when writeState =>
						if(done = '1') then
							writebits <= '0';
							DE2_ackno <= '1';
							next_state := doneLoading;
						else
							writebits <= '1';
							DE2_ackno <= '0';
							next_state := writeState;
						end if;
				  when doneLoading =>
						LEDR(3 downto 0) <= "1111";
						if(pi_ready <= '0') then
							writebits <= '0';
							DE2_ackno <= '0';
							next_state := check1;
						else
							writebits <= '0';
							DE2_ackno <= '1';
							next_state := doneLoading;
						end if;
				  when check1 =>
						LEDR(3 downto 0) <= "0001";
						if(pi_ready <= '1') then
							writebits <= '0';
							DE2_ackno <= '1';
							next_state := check2;
						else
							writebits <= '0';
							DE2_ackno <= '0';
							next_state := check1;
						end if;
				  when check2 =>
						LEDR(3 downto 0) <= "0010";
						if(pi_ready = '0') then
							writebits <= '0';
							DE2_ackno <= '0';
							next_state := resetState;
						else
							writebits <= '0';
							DE2_ackno <= '1';
							next_state := check2;
						end if;
				  when others =>
						DE2_ackno <= '0';
						writebits <= '0';
						
						next_state := idleState2;
				  end case;
			present_state := next_state;
		end if;
	end process;
end rtl;


