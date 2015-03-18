LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY handshaking IS
PORT(
	CLOCK_50 : in std_logic;
	KEY : in std_logic_vector(3 downto 0); --for testing
	SW : in std_logic_vector(17 downto 0); --for testing/have an on/off switch here?
	GPIO_1 : inout std_logic_vector(35 downto 0); --to retrieve data from Pi via Breadboard
		--using pins 17 to 0 as input, 35 to 18 as output.
	LEDG : out std_logic_vector(17 downto 0);
);
END handshaking;

ARCHITECTURE behavioural OF handshaking IS
--	SIGNAL D0_PRIME, D0_IN, D1_PRIME, D1_IN : std_logic_vector(7 downto 0);
	SIGNAL D0_PRIME, D0_IN : std_logic_vector(1 downto 0); --for testing
--	SIGNAL VALID_PRIME, VALID_IN, READY, ACKNOWLEDGE_IN : std_logic;
	SIGNAL ACKNOWLEDGE_IN : std_logic;
BEGIN
--FSM
	PROCESS(CLOCK_50)
		type state is (Waiting, Reading, Writing, Processing);
		variable CURRENT_STATE : state := Waiting;
		variable MODE : std_logic; --0 for reading, 1 for writing
	BEGIN
		CASE CURRENT_STATE IS
			WHEN Waiting =>
				IF(GPIO_1(8) = '1') THEN --if ready/request bit is 1
					--ready to read data from Pi
					ACKNOWLEDGE_IN <= GPIO_1(9); --Acknowledge bit
					CURRENT_STATE := Reading;
				END IF;
			WHEN Reading =>
				IF(ACKNOWLEDGE_IN = '1') THEN
					MODE := '0'; --reading, redundant?
					D0_PRIME <= GPIO_1(1 downto 0); --switches as GPIO data (change to 7 downto 0)
					CURRENT_STATE := Processing;
				END IF;
--			WHEN Writing =>
--				IF() THEN
--				END IF;
			WHEN Processing =>
				IF(MODE = '0') THEN --read
					--D0_IN <= D0_PRIME;
					LEDG(1 DOWNTO 0) <= D0_IN;
					CURRENT_STATE := Waiting;
				ELSE --write
					--Do nothing yet.
				END IF;
			WHEN others => CURRENT_STATE := Waiting; --Do nothing
		END CASE;
	END PROCESS;



















--	--FSM
--	PROCESS(CLOCK_50)
--		type state_types is (Idle, Reader, Writer, Waiting); --DE2's POV
--		variable CURRENT_STATE : state_types := Idle;
--	BEGIN
--		IF(RISING_EDGE(CLOCK_50)) THEN
--			CASE CURRENT_STATE 
--				WHEN Idle =>
--					IF(GPIO_0 (17) = '1') THEN --GPIO_0(17) is Request bit
--						--Request Bit = 1, then DE2 is reading data from Pi
--						CURRENT_STATE := Reader;
--					END IF;					
--				WHEN Reader =>
--					IF() THEN
--					END IF;
--				WHEN Writer =>
--				WHEN Waiting =>
--				
--				
----				WHEN Acknowledge =>
----					ACKNOWLEDGE_IN <= '1';
----					CURRENT_STATE := Data;
----				WHEN Data =>
----					D0_PRIME <= GPIO_0(7 downto 0); --Pixel 1 from GPIO
----					D1_PRIME <= GPIO_0(15 downto 8); --Pixel 2 from GPIO
----					VALID_PRIME <= GPIO_0(16); --Valid bit from GPIO
----					CURRENT_STATE := Request;
----				WHEN Request =>
--				
--				
--					CURRENT_STATE := Acknowledge;
--			END CASE;
--		END IF;
--	END PROCESS;

--	--everything else
--	PROCESS(CLOCK_50)
--	BEGIN
--		IF(RISING_EDGE(CLOCK_50)) THEN
--			D0_IN <= D0_PRIME;
--			D1_IN <= D1_PRIME;
--			VALID_IN <= VALID_PRIME;
--		END IF;
--	END PROCESS;
--	
--	--output
--	PROCESS(CLOCK_50)
--	BEGIN
--		IF(RISING_EDGE(CLOCK_50)) THEN
--			IF(VALID_IN = '1') THEN --VALID_IN is the enable
--				GPIO_0(25 downto 18) <= D0_IN;
--				GPIO_0(33 downto 26) <= D1_IN;
--				
--				GPIO_0(34) <= ACKNOWLEDGE_IN;
--			ELSE
--				ACKNOWLEDGE_IN <= '0';
--			END IF;
--		END IF;
--	END PROCESS;
END behavioural;