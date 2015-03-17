LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY handshaking IS
PORT(
	CLOCK_50 : in std_logic;
	KEY : in std_logic_vector(3 downto 0); --for testing
	SW : in std_logic_vector(17 downto 0); --for testing/have an on/off switch here?
	GPIO_0 : in std_logic_vector(35 downto 0); --to retrieve data from Pi via Breadboard
	GPIO_1 : out std_logic_vector(35 downto 0) --to send data to Pi via Breadboard
);
END handshaking;

ARCHITECTURE behavioural OF handshaking IS
	SIGNAL D0_PRIME, D0_IN, D1_PRIME, D1_IN : std_logic_vector(7 downto 0);
	SIGNAL VALID_PRIME, VALID_IN, READY, ACKNOWLEDGE : std_logic;
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
		END IF;
	END PROCESS;
	
	--output
	PROCESS(CLOCK_50)
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			IF(VALID_IN = '1') THEN
				GPIO_1(7 downto 0) <= D0_IN;
				GPIO_1(15 downto 8) <= D1_IN;
			END IF;
		END IF;
	END PROCESS;
END behavioural;