library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity imageProcessing is
	port(
		 CLOCK_50            : in  std_logic;
		 KEY                 : in  std_logic_vector(3 downto 0);
		 SW                  : in  std_logic_vector(17 downto 0);
		 COLOUR_BYTE			: in  std_logic_vector(7 downto 0); --reading in R, G, B one byte at a time
		 LEDR						: out std_logic_vector(17 downto 0);
		 LEDG						: out std_logic_vector(7 downto 0)
	 );
end imageProcessing;

architecture behavioural of imageProcessing is
	type pixel_colour is array (319 downto 0) of std_logic_vector(23 downto 0);
	type data is array(239 downto 0) of pixel_colour;
	
	signal image_data : data;
	signal store_pixel : std_logic;
	signal store_done : std_logic;
	signal PIXEL_DATA : std_logic_vector(23 downto 0);
	signal PIXEL_DATA_ROW : pixel_colour;
begin
	PROCESS(CLOCK_50, KEY(0))
		type state is (initialize, read_red, read_green, read_blue, store, display, idle);
		variable CURRENT_STATE : state := initialize;
		variable current_pixel : std_logic_vector(23 downto 0) := (others => '0');
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			CASE CURRENT_STATE IS
				WHEN initialize =>
					LEDG(7 downto 0) <= (others => '0');
					LEDR(17 downto 0) <= (others => '0');
					CURRENT_STATE := read_red;
				WHEN read_red =>
					current_pixel(23 downto 16) := COLOUR_BYTE;
					CURRENT_STATE := read_green;
				WHEN read_green =>
					current_pixel(15 downto 8) := COLOUR_BYTE;
					CURRENT_STATE := read_blue;
				WHEN read_blue =>
					current_pixel(7 downto 0) := COLOUR_BYTE;
					STORE_PIXEL <= '1';
					CURRENT_STATE := store;
				WHEN store =>
					PIXEL_DATA <= current_pixel;
					IF(STORE_done = '1') THEN
						STORE_PIXEL <= '0';
						CURRENT_STATE := display;
					END IF;
				WHEN display =>
					LEDR(15 downto 0) <= current_pixel(23 downto 8);
					LEDG(7 downto 0) <= current_pixel(7 downto 0);
					CURRENT_STATE := idle;
				WHEN others =>
					IF(KEY(0) = '0') THEN
						CURRENT_STATE := initialize;
					END IF;
				END CASE;
		END IF;
	END PROCESS;
	
	PROCESS(CLOCK_50, STORE_PIXEL)
		variable x_coord : integer := 0;
		variable y_coord : integer := 0;
		variable image_column : pixel_colour;
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			IF(STORE_PIXEL = '1') THEN
				store_done <= '0';
				IF(x_coord < 240 ) THEN
					image_column := image_data(x_coord);
					IF(y_coord < 320) THEN
						PIXEL_DATA_ROW(y_coord) <= PIXEL_DATA;
						y_coord := y_coord + 1;
					ELSE
						image_data(x_coord) <= PIXEL_DATA_ROW;
						x_coord := x_coord + 1;
						y_coord := 0;
					END IF;
				ELSE
					x_coord := 0;
					y_coord := 0;
					store_done <= '1';
				END IF;
			END IF;
		END IF;
	END PROCESS;
end behavioural;


