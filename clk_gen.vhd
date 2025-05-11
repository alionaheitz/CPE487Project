library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clk_gen is
    port (
        clk_100MHz : in std_logic;
        clk_4MHz : out std_logic
    );
end clk_gen;

architecture Behavioral of clk_gen is
    signal counter : integer range 0 to 24 :=0 ;
    signal clk_reg : std_logic := '1';
begin
    ---- keeps track of 25 system clock cycles to create the 4MHz signal ~52% duty cycle
    process(clk_100MHz) 
    begin
        if rising_edge(clk_100MHz) then
            if counter = 12 then  
                clk_reg <= not clk_reg;
                counter <= counter + 1;
            elsif counter = 24 then
                clk_reg <= not clk_reg;
                counter <= 0;
            else    
                counter <= counter + 1;
            end if;
        end if;
    end process;

    clk_4MHz <= clk_reg;

end Behavioral;    