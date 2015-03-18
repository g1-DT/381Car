LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY handshaking IS
PORT(
	CLOCK_50 : in std_logic;
	KEY : in std_logic_vector(3 downto 0); --for testing
	SW : in std_logic_vector(17 downto 0); --for testing/have an on/off switch here?
	GPIO_1 : inout std_logic_vector(35 downto 0); --to retrieve data from Pi via Breadboard
		--using pins 17 to 0 as input, 35 to 18 as output.
	LEDR : out std_logic_vector(17 downto 0);
	LEDG : out std_logic_vector(8 downto 0) --to indicate the acknowledge and ready bits
);
END handshaking;

ARCHITECTURE behavioural OF handshaking IS
--	SIGNAL D0_PRIME, D0_IN, D1_PRIME, D1_IN : std_logic_vector(7 downto 0);
	SIGNAL D0_PRIME, D0_IN : std_logic_vector(1 downto 0); --for testing
	SIGNAL D0_OUT : std_logic_vector(1 downto 0); --for testing; change to (7 downto 0);
	
--	SIGNAL VALID_PRIME, VALID_IN, READY, ACKNOWLEDGE_IN : std_logic;
	SIGNAL ACKNOWLEDGE_IN, ACKNOWLEDGE_OUT : std_logic;
BEGIN
--FSM
	PROCESS(CLOCK_50)
		type state is (Waiting, Reading, Writing, Processing, CleanReadData, SendData);
		variable CURRENT_STATE : state := Waiting;
		
		--redundant?:
		variable MODE : std_logic; --0 for reading, 1 for writing, Z for idle?
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			CASE CURRENT_STATE IS
				WHEN Waiting =>
					MODE := 'Z';
					IF(GPIO_1(8) = '1') THEN --If received ready bit from Pi.
						
						--ready to read data from Pi
						ACKNOWLEDGE_OUT <= '1'; --send acknowledge bit.
						GPIO_1(9) <= ACKNOWLEDGE_OUT; --send acknowledge bit to Pi.
						
						CURRENT_STATE := Reading;
					ELSIF(GPIO_1(8) = '0') THEN --if writing
						CURRENT_STATE := Writing;
					END IF; --IDLE OTHERWISE
					
					LEDR(8) <= GPIO_1(8); --testing: indicate ready bit from Pi.
					LEDR(7) <= GPIO_1(9); --testing: indicate acknowledge bit being sent to Pi.
					
				WHEN Reading =>
					IF(ACKNOWLEDGE_IN = '1') THEN --recieved pi acknowledge bit
						MODE := '0'; --reading
						--get data from Pi.
						D0_IN <= GPIO_1(1 downto 0); --shortened GPIO data (change to 7 downto 0)
						
						CURRENT_STATE := Processing;
					END IF;
				WHEN Writing =>
					--send request bit to Pi.
					IF(ACKNOWLEDGE_IN = '0') THEN --ensure Pi is not writing.
						MODE := '1'; --writing
						GPIO_1(18) <= '1'; --send request bit to Pi.
						CURRENT_STATE := Processing;
					END IF;
				WHEN Processing =>
					IF(MODE = '0') THEN --reading
						D0_PRIME <= D0_IN; --process data and light up LEDs.
						CURRENT_STATE := CleanReadData;
					ELSIF(MODE = '1') THEN --writing
						IF(GPIO_1(19) = '1') THEN --if recieved acknowledge bit from Pi.
							ACKNOWLEDGE_IN <= GPIO_1(19); --Acknowledge bit
							D0_OUT <= "10"; --test data
							CURRENT_STATE := SendData;
						END IF;
					ELSE --ALL OTHER CASES
						--keep it waiitng?
						CURRENT_STATE := Waiting;
					END IF;
				WHEN CleanReadData =>
					IF(MODE = '0') THEN --read
						LEDR(1 DOWNTO 0) <= D0_PRIME;--data should be processed by a flipflop at this point.
						CURRENT_STATE := Waiting;
					END IF;
				WHEN SendData =>
					IF(MODE = '1') THEN --write
						LEDR(11 DOWNTO 10) <= D0_OUT;
						GPIO_1(11 downto 10) <= D0_OUT; --shortened GPIO data (change to 17 downto 10)
						GPIO_1(18) <= '0'; --end of request.
					END IF;
				WHEN others => CURRENT_STATE := Waiting; --Do nothing
			END CASE;
		END IF;
	END PROCESS;
END behavioural;