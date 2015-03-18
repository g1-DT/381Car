LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY data_transfer IS
PORT(
	CLOCK_50 : in std_logic;
	KEY : in std_logic_vector(3 downto 0); --for testing
	SW : in std_logic_vector(17 downto 0); --for testing (simulation of secondary input)
	-- SW(0) = Reading
	-- SW(1) = Writing
	GPIO_1 : inout std_logic_vector(35 downto 0); --to retrieve data from Pi via Breadboard
																 --using pins 17 to 0 as input, 35 to 18 as output.
	LEDG : out std_logic_vector(7 downto 0);
	LEDR : out std_logic_vector(17 downto 0)
);
END data_transfer;

ARCHITECTURE behavioural OF data_transfer IS
--	SIGNAL D0_PRIME, D0_IN, D1_PRIME, D1_IN : std_logic_vector(7 downto 0);
	SIGNAL D0_PRIME, D0_IN : std_logic_vector(1 downto 0); --for testing
--	SIGNAL VALID_PRIME, VALID_IN, READY, ACKNOWLEDGE_IN : std_logic;
	SIGNAL ACKNOWLEDGE_IN : std_logic;
	
--Internal Signals
	SIGNAL READER : std_logic := '0';
	SIGNAL WRITER : std_logic := '0';
	SIGNAL READ_READY : std_logic := '0';
	SIGNAL WRITE_READY : std_logic := '0';
	SIGNAL DONE : std_logic := '0';
	SIGNAL MUTEX : std_logic := '0';

-- Data 1 byte Test
	SIGNAL DATA : std_logic_vector (1 downto 0) := "00";
	--SIGNAL DATA : std_logic_vector (1 downto 0) :="00000000";
	
BEGIN

--Signal for reading or writing
	READER <= SW(0); -- Only need input of Reader since writer will be output signal
	--READER <= GPIO_1(0);
	WRITER <= SW(1);
	--WRITER <= GPIO_1(1);
	READ_READY <= SW(2);
	--READ_READY <= GPIO_1(2);
	WRITE_READY <= SW(3);
	--WRITE_READY <= GPIO_1(3);
	--MUTEX <= GPIO(4);
	
--TEST
	LEDR(0) <= READER;
	LEDR(1) <= WRITER;
	LEDR(2) <= READ_READY;
	LEDR(3) <= WRITE_READY;
	LEDR(17 downto 16) <= DATA;
	
	
--FSM
	PROCESS(CLOCK_50)
		type state is (Waiting, Reading, Writing, Processing);
		variable CURRENT_STATE : state := Waiting;
		variable MODE : std_logic; --0 for reading, 1 for writing
		variable DONE : std_logic := '0';
	BEGIN
		if(rising_edge(CLOCK_50)) THEN
			CASE CURRENT_STATE IS
				WHEN Waiting =>
					LEDG(1 downto 0) <= "00";
					IF(READER = '1') THEN
						CURRENT_STATE := Reading;
						MODE := '0';
					ELSIF(WRITER = '1') THEN
						CURRENT_STATE := Writing;
						--lock = 1 (add lock/mutex)
						MODE := '1';
					END IF;
				WHEN Reading =>
					LEDG(1 downto 0) <= "01";
					IF (WRITE_READY = '1') THEN
						CURRENT_STATE :=  Processing;
					END IF;
				WHEN Writing =>
					LEDG(1 downto 0) <= "10";
					IF (READ_READY = '1') THEN
						CURRENT_STATE := Processing;
					END IF;
				WHEN Processing =>
					LEDG(1 downto 0) <= "11";
					IF(MODE = '0') THEN
						--If in reader mode, read value from GPIO_1
						DATA <= SW(6 downto 5);
						--DATA <= GPIO_1(6 downto 5);
						DONE := '1';
					END IF;
					
					IF(MODE = '1') THEN
						--IF in writer mode, write value to GPIO_1
					END IF;
					
					IF (DONE = '1') THEN
						--Reinit things
						DONE := '0';
						CURRENT_STATE := Waiting;
					END IF;
				--WHEN others => CURRENT_STATE := Waiting; --Do nothing
			END CASE;
				LEDG(2) <= MODE;
			END IF;
	END PROCESS;
END behavioural;