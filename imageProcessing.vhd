library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Image processing currently uses the VGA starter files provided in EECE 353 Labs.

entity imageProcessing is
	port(
		 CLOCK_50            : in  std_logic;
		 KEY                 : in  std_logic_vector(3 downto 0);
		 SW                  : in  std_logic_vector(17 downto 0);
		 COLOUR_BYTE			: in  std_logic_vector(7 downto 0); --reading in R, G, B one byte at a time
		 LEDR						: out std_logic_vector(17 downto 0);
		 LEDG						: out std_logic_vector(7 downto 0)
	 );
--  port(CLOCK_50            : in  std_logic;
--       KEY                 : in  std_logic_vector(3 downto 0);
--       SW                  : in  std_logic_vector(17 downto 0);
--		 COLOUR_BYTE			: in  std_logic_vector(7 downto 0); --reading in R, G, B one byte at a time
--       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
--       VGA_HS              : out std_logic;
--       VGA_VS              : out std_logic;
--       VGA_BLANK           : out std_logic;
--       VGA_SYNC            : out std_logic;
--       VGA_CLK             : out std_logic);
end imageProcessing;

architecture behavioural of imageProcessing is
--	--Component from the Verilog file: vga_adapter.v
--
--  component vga_adapter
--    generic(RESOLUTION : string);
--    port (resetn                                       : in  std_logic;
--          clock                                        : in  std_logic;
--          colour                                       : in  std_logic_vector(2 downto 0);
--          x                                            : in  std_logic_vector(7 downto 0);
--          y                                            : in  std_logic_vector(6 downto 0);
--          plot                                         : in  std_logic;
--          VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
--          VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
--  end component;
--
--  signal x      : std_logic_vector(7 downto 0);
--  signal y      : std_logic_vector(6 downto 0);
--  signal colour : std_logic_vector(2 downto 0);
--  signal plot   : std_logic;
  
	type pixel_colour is array (159 downto 0) of std_logic_vector(23 downto 0);
	type data is array(119 downto 0) of pixel_colour;
	
	signal image_data : data;
--	signal DRAW_VGA : std_logic;
	signal store_pixel : std_logic;
	signal PIXEL_DATA : std_logic_vector(23 downto 0);
	signal PIXEL_DATA_ROW : pixel_colour;
begin
--  -- includes the vga adapter, which should be in your project 
--
--  vga_u0 : vga_adapter
--    generic map(RESOLUTION => "160x120") 
--    port map(resetn    => KEY(3),
--             clock     => CLOCK_50,
--             colour    => colour,
--             x         => x,
--             y         => y,
--             plot      => plot,
--             VGA_R     => VGA_R,
--             VGA_G     => VGA_G,
--             VGA_B     => VGA_B,
--             VGA_HS    => VGA_HS,
--             VGA_VS    => VGA_VS,
--             VGA_BLANK => VGA_BLANK,
--             VGA_SYNC  => VGA_SYNC,
--             VGA_CLK   => VGA_CLK);

--Image Processing Code for EECE 381:
	PROCESS(CLOCK_50, KEY(0))
--		type state is (initialize, read_red, read_green, read_blue, draw, idle);

		type state is (initialize, read_red, read_green, read_blue, store, display, idle);
		variable CURRENT_STATE : state := initialize;
		variable current_pixel : std_logic_vector(23 downto 0) := (others => '0');
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			CASE CURRENT_STATE IS
				WHEN initialize =>
					LEDG(7 downto 0) <= (others => '0');
					LEDR(17 downto 0) <= (others => '0');
--					--mock data:
--					pixel_colour <= (others => '0');
--					image_data <= (others => pixel_colour); --test cyan image
--					DRAW_VGA <= '0';
--					IF(KEY(1) = '0') THEN --draw signal
--						CURRENT_STATE := display;
--					END IF;
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
					IF(STORE_PIXEL = '0') THEN
						CURRENT_STATE := display;
					END IF;
				WHEN display =>
					LEDR(16 downto 0) <= current_pixel(23 downto 8);
					LEDG(7 downto 0) <= current_pixel(7 downto 0);
					CURRENT_STATE := idle;
--				WHEN draw =>
--					DRAW_VGA <= '1';
--					IF(DRAW_VGA <= '0') THEN
--						CURRENT_STATE := idle;
--					END IF;
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
		variable image_column : data;
	BEGIN
		IF(RISING_EDGE(CLOCK_50)) THEN
			IF(STORE_PIXEL = '1') THEN
				IF(x_coord < 120 ) THEN
					image_column := image_data(x_coord);
					IF(y_coord < 160) THEN
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
--					DRAW_VGA <= '0'; --stop drawing
					STORE_PIXEL <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
--	PROCESS(CLOCK_50, DRAW_VGA)
--		variable x_coord : integer := 0;
--		variable y_coord : integer := 0;
--		variable image_column : std_logic_vector(119 downto 0);
--		variable image_x : std_logic;
--	BEGIN
--		IF(RISING_EDGE(CLOCK_50)) THEN
--			IF(DRAW_VGA = '1') THEN
--				IF(x_coord < 120 ) THEN
--					image_column := image_data(x_coord);
--					IF(y_coord < 160) THEN
--						x <= std_logic_vector(to_unsigned(x_coord, x'length));
--						y <= std_logic_vector(to_unsigned(y_coord, y'length));
--						colour <= image_column(y_coord);
--						plot <= '1';
--						y_coord := y_coord + 1;
--					ELSE
--						x_coord := x_coord + 1;
--					END IF;
--				ELSE
--					x_coord := 0;
--					y_coord := 0;
--					DRAW_VGA <= '0'; --stop drawing
--				END IF;
--			END IF;
--		END IF;
--	END PROCESS;
end behavioural;


