library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM is
  port(CLOCK_50            : in  std_logic;
       SW                  : in  std_logic_vector(17 downto 0);
		 GPIO_1					: inout std_logic_vector(35 downto 0);
		 --35 downto 32 output to PWM
		 --31 downto 28 input from pi
		 LEDG : out std_logic_vector(7 downto 0));
end PWM;

architecture rtl of PWM is
signal motor_l, motor_r : std_logic_vector(1 downto 0);
signal go_forward, go_reverse, go_left, go_right : std_logic;

component servo_pwm  
		Port ( clk      : in  STD_LOGIC;
             reset    : in  STD_LOGIC; 
             button_l : in  STD_LOGIC;  
             button_r : in  STD_LOGIC; 
             pwm      : out  STD_LOGIC);
end component;

begin
	servo : servo_pwm port map(
			clk=>CLOCK_50,
			reset=>SW(17),
			button_l=>SW(16),
			button_r=>SW(15),
			pwm=>GPIO_1(0));
	

	--currently using controls from the Pi
	go_forward <= GPIO_1(28);
	--go_forward <= SW(0);
	go_reverse <= GPIO_1(29);
	--go_reverse <= SW(1);
	go_left <= GPIO_1(30);
	--go_left <= SW(2);
	go_right <= GPIO_1(31);
	--go_right <= SW(3);
	
	--output to the DC motors
	GPIO_1(35 downto 34) <= motor_l;
	GPIO_1(33 downto 32) <= motor_r;

  process (CLOCK_50)
	variable pwmcount : integer := 0;
	variable PWM0val : std_logic := '0';
	variable dec : integer := 0;
	variable count : integer := 1;
  begin
		if(rising_edge(CLOCK_50)) then
			if(go_forward = '1') then
				LEDG(2 downto 0)<="101";
				motor_l <= "01";
				motor_r <= "01";
			elsif(go_reverse = '1') then
				LEDG(2 downto 0)<="001";
				motor_l <= "10";
				motor_r <= "10";
			elsif(go_left = '1') then
				LEDG(2 downto 0)<="010";
				motor_l <= "00";
				motor_r <= "01";
			elsif(go_right = '1') then
				LEDG(2 downto 0)<="100";
				motor_l <= "01";
				motor_r <= "00";
			else
				LEDG(2 downto 0)<="111";
				motor_l <= "00";
				motor_r <= "00";
			end if;
		end if;
	end process;
end rtl;


--begin
-- process (CLOCK_50, SW)
--	variable pwmcount : integer := 0;
--	variable PWM0val : std_logic := '0';
--	variable dec : integer := 0;
--	variable count : integer := 1;
--  begin
--		if(rising_edge(CLOCK_50)) then
--			pwmcount := pwmcount + 1;
--			if(pwmcount >= pwmLimit and PWM0val = '1') then
--				PWM0val := '0';
--				pwmcount := 0;
--				pwmLimit <= 15;
--				--GPIO_1(0) <= '0';
--			elsif(pwmcount >= pwmLimit and PWM0val = '0') then
--				PWM0val := '1';
--				pwmcount := 0;
--				pwmLimit <= 10;
--				GPIO_1(0) <= '1';
--			end if;
--	   end if;	
--		
--		if(SW(0) = '1') then
--			GPIO_1(3) <= '1';
--		else
--			GPIO_1(3) <= '0';
--		end if;
--		if(SW(1) = '1') then
--			GPIO_1(4) <= '1';
--		else
--			GPIO_1(4) <= '0';
--		end if;
--	end process;
--end rtl;
