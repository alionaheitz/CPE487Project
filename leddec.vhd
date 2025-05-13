LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY leddec16 IS
	PORT (
	   CLK_100MHZ : in std_logic;
	   dig        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);        
       bcd32      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);    
	   anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); -- which anode to turn on
	   seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0); -- segment code for current digit
	   dp : out std_logic
	   );
	  
END leddec16;

ARCHITECTURE Behavioral OF leddec16 is
    
     SIGNAL nibble : STD_LOGIC_VECTOR(3 DOWNTO 0);
begin
    
    PROCESS(dig, bcd32)
        VARIABLE idx : integer;
    BEGIN
        idx := TO_INTEGER(UNSIGNED(dig)) * 4;
        nibble <= bcd32(idx+3 DOWNTO idx);
    END PROCESS;

    seg <= "0000001" WHEN nibble = "0000" ELSE  -- 0
           "1001111" WHEN nibble = "0001" ELSE  -- 1
           "0010010" WHEN nibble = "0010" ELSE  -- 2
           "0000110" WHEN nibble = "0011" ELSE  -- 3
           "1001100" WHEN nibble = "0100" ELSE  -- 4
           "0100100" WHEN nibble = "0101" ELSE  -- 5
           "0100000" WHEN nibble = "0110" ELSE  -- 6
           "0001111" WHEN nibble = "0111" ELSE  -- 7
           "0000000" WHEN nibble = "1000" ELSE  -- 8
           "0000100" WHEN nibble = "1001" ELSE  -- 9
           "1111111";                            

    dp <= '1';

    anode <= "11111110" WHEN dig = "000" ELSE
             "11111101" WHEN dig = "001" ELSE
             "11111011" WHEN dig = "010" ELSE
             "11110111" WHEN dig = "011" ELSE
             "11101111" WHEN dig = "100" ELSE
             "11011111" WHEN dig = "101" ELSE
             "10111111" WHEN dig = "110" ELSE
             "01111111";  -- dig = "111"
	      
END Behavioral;