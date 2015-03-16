LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL; --necessary?

ENTITY handshaking IS
PORT(
	CLOCK_50 : in std_logic;
	KEY : in std_logic_vector(3 downto 0); --for testing
	SW : in std_logic_vector(17 downto 0); --for testing/have an on/off switch here?
	GPIO_0 : in std_logic_vector(35 downto 0);
	GPIO_1 : in std_logic_vector(35 downto 0);
);
END handshaking;

--necessary?:
--ARCHITECTURE structural OF handshaking IS
--BEGIN
--END structural;

ARCHITECTURE behavioural OF handshaking IS
BEGIN

END behavioural;