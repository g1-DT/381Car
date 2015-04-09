library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM is
  port(CLOCK_50            : in  std_logic;
       SW                  : in  std_logic_vector(17 downto 0);
		 GPIO_1					: inout std_logic_vector(35 downto 0));
		 --35 downto 32 output to PWM
		 --31 downto 28 input from pi
		 --LEDG : out std_logic_vector(7 downto 0));
end PWM;

architecture rtl of PWM is
signal sensor1,sensor2,sensor3,sensor4 : std_logic;
signal motor_l, motor_r : std_logic_vector(1 downto 0);
signal go_forward, go_reverse, go_left, go_right : std_logic;
signal motor_L1,motor_L2,motor_R1,motor_R2 : std_logic;
signal motor_LR,motor_RR,reset : std_logic;

component servo_pwm  
		Port ( clk      : in  STD_LOGIC;
             reset    : in  STD_LOGIC; 
             button_l : in  STD_LOGIC;  
             button_r : in  STD_LOGIC; 
             pwm      : out  STD_LOGIC);
end component;

begin
	servoL_1 : servo_pwm port map(
			clk=>CLOCK_50,
			reset=>NOT motor_L1,
			button_l=>SW(16),
			button_r=>motor_L1,
			pwm=>GPIO_1(34)
			);
	servoL_2 : servo_pwm port map(
			clk=>CLOCK_50,
			reset=>NOT motor_L2,
			button_l=>SW(16),
			button_r=>motor_L2,
			pwm=>GPIO_1(35)
			);
	servoR_1 : servo_pwm port map(
			clk=>CLOCK_50,
			reset=>NOT motor_R1,
			button_l=>SW(16),
			button_r=>motor_R1,
			pwm=>GPIO_1(32)
			);
	servoR_2 : servo_pwm port map(
			clk=>CLOCK_50,
			reset=>NOT motor_R2,
			button_l=>SW(16),
			button_r=>motor_R2,
			pwm=>GPIO_1(33)
			);
	

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
	--GPIO_1(35 downto 34) <= motor_l;
	--GPIO_1(33 downto 32) <= motor_r;
	
	sensor1 <= GPIO_1(24);
	sensor2 <= GPIO_1(25);
	sensor3 <= GPIO_1(26);
	sensor4 <= GPIO_1(27);
	
--process(CLOCK_50)
--begin
--	if(rising_edge(CLOCK_50)) then
--		if(sensor1 = '0') then
--			LEDG(7)<='1';
--			LEDG(6)<='0';
--		else
--			LEDG(6)<='1';
--			LEDG(7)<='0';
--		end if;
--	end if;
--end process;

process (CLOCK_50)
begin
	if(rising_edge(CLOCK_50)) then	
--		if(sensor1 = '0' OR sensor2 = '0' OR sensor3 = '0' OR sensor4 = '0' ) then
--				motor_L1<='0';
--				motor_L2<='0';
--				motor_R1<='0';
--				motor_R2<='0';
--		end if;
		
		--sensor1 = back, sensor2 = left, sensor3 = right, sensor4 = front
		
			if(go_left = '1' AND sensor2 = '1') then
				--LEDG(2 downto 0)<="010";
				--reset<='0';
				motor_L1<='0';
				motor_L2<='1';
				motor_R1<='1';
				motor_R2<='0';
				--motor_l <= "00";
				--motor_r <= "01";
			elsif(go_right = '1' AND sensor3 = '1') then
				--LEDG(2 downto 0)<="100";
				--reset<='0';
				motor_L1<='1';
				motor_L2<='0';
				motor_R1<='0';
				motor_R2<='1';
				--motor_l <= "01";
				--motor_r <= "00";
			elsif(go_forward = '1' AND sensor4 = '1') then
				--LEDG(2 downto 0)<="101";
				--reset<='0';
				motor_L1<='1';
				motor_L2<='0';
				motor_R1<='1';
				motor_R2<='0';
				--motor_l <= "01";
				--motor_r <= "01";
			elsif(go_reverse = '1' AND sensor1 = '1') then
				--LEDG(2 downto 0)<="001";
				--reset<='0';
				motor_L1<='0';
				motor_L2<='1';
				motor_R1<='0';
				motor_R2<='1';
				--motor_l <= "10";
				--motor_r <= "10";
			else
				--LEDG(2 downto 0)<="111";
				--reset<='1';
				motor_L1<='0';
				motor_L2<='0';
				motor_R1<='0';
				motor_R2<='0';
				--motor_l <= "00";
				--motor_r <= "00";
				
			end if;	
	end if;
end process;
end rtl;
