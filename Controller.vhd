library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
    port(
        CLK_100MHZ : IN STD_LOGIC;
        acl_dataX : in STD_LOGIC_VECTOR(15 downto 0);
        acl_dataY : in STD_LOGIC_VECTOR(15 downto 0);
        pwm_out : out STD_LOGIC
    );
end controller;

Architecture Behavioral of controller is
    
    signal x_raw : signed(15 downto 0);
    signal pwm_cnt : integer range 0 to 2000000 := 0; -- 20ms at 100MHz
    signal pwm_duty : integer := 150000;
    signal target_duty : integer := 150000;
    constant threshold : signed(15 downto 0) := to_signed(200, 16);
    
    begin
        x_raw <= signed(acl_dataX);
        
        process(CLK_100MHZ)
        begin
            if rising_edge(CLK_100MHZ) then
                if x_raw > threshold then
                    target_duty <= 200000; -- 2ms, right turn
                elsif x_raw < -threshold then
                    target_duty <= 100000; -- 1ms, left turn
                else
                    target_duty <= 150000; -- 1.5ms, middle
                end if;
                
                -- Slowly move pwm_duty toward target_duty
                if pwm_duty < target_duty then
                    pwm_duty <= pwm_duty + 100;  -- Tune this step size for speed
                elsif pwm_duty > target_duty then
                    pwm_duty <= pwm_duty - 100;
                end if;
            end if;
        end process;
        
        -- 50Hz signal with variable duty cycle
        process(CLK_100MHZ)
        begin
            if rising_edge(CLK_100MHZ) then
                if pwm_cnt < pwm_duty then
                    pwm_out <= '1';
                else
                    pwm_out <= '0';
                end if;
                
                if pwm_cnt = 1999999 then
                    pwm_cnt <= 0;
                else
                    pwm_cnt <= pwm_cnt + 1;
                end if;
            end if;
        end process; 
            
end behavioral;