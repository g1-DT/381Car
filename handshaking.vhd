LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY handshaking IS
PORT(
	CLOCK_50 : in std_logic;
	KEY : in std_logic_vector(3 downto 0); --for testing
	SW : in std_logic_vector(17 downto 0); --for testing/have an on/off switch here?
	GPIO_0 : inout std_logic_vector(35 downto 0) --to retrieve data from Pi via Breadboard
		--using pins 17 to 0 as input, 35 to 18 as output.
);
END handshaking;

ARCHITECTURE behavioural OF handshaking IS
	SIGNAL D0_PRIME, D0_IN, D1_PRIME, D1_IN : std_logic_vector(7 downto 0);
	SIGNAL VALID_PRIME, VALID_IN, READY, ACKNOWLEDGE_IN : std_logic;
BEGIN
	PROCESS(CLOCK_50)
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			D0_PRIME <= GPIO_0(7 downto 0); --Pixel 1 from GPIO
			D1_PRIME <= GPIO_0(15 downto 8); --Pixel 2 from GPIO
			VALID_PRIME <= GPIO_0(16); --Valid bit from GPIO
		END IF;
	END PROCESS;
	
	PROCESS(CLOCK_50)
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			D0_IN <= D0_PRIME;
			D1_IN <= D1_PRIME;
			VALID_IN <= VALID_PRIME;
			
			ACKNOWLEDGE_IN <= '1';
		END IF;
	END PROCESS;
	
	--output
	PROCESS(CLOCK_50)
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			IF(VALID_IN = '1') THEN --VALID_IN is the enable
				GPIO_0(25 downto 18) <= D0_IN;
				GPIO_0(33 downto 26) <= D1_IN;
				
				GPIO_0(34) <= ACKNOWLEDGE_IN;
			END IF;
		END IF;
	END PROCESS;
END behavioural;