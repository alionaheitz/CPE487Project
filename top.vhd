LIBRARY IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

Entity top is
    port(
        CLK_100MHZ : IN STD_LOGIC;
        ACL_MISO  : IN STD_LOGIC;
        ACL_MOSI  : OUT STD_LOGIC;
        ACL_SCLK  : OUT STD_LOGIC;
        ACL_SS   : OUT STD_LOGIC;
        LED       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        SEG7_seg       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        DP        : OUT STD_LOGIC;
        PWM_OUT : OUT STD_LOGIC;
        SEG7_anode        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
End entity;

Architecture Behavioral OF top is
    
    SIGNAL w_4MHz   : STD_LOGIC;
    SIGNAL acl_dataALL : STD_LOGIC_VECTOR(14 DOWNTO 0);
    SIGNAL acl_dataX : STD_LOGIC_VECTOR(15 DOWNTO 0); 
    SIGNAL acl_dataY : STD_LOGIC_VECTOR(15 DOWNTO 0); 
    SIGNAL acl_dataZ : STD_LOGIC_VECTOR(15 DOWNTO 0); 
    
   SIGNAL wha,wha2,wha3 : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL wha4 : STD_LOGIC_VECTOR(14 DOWNTO 0);
    
    -- Scan counter → digit index 0-7
    SIGNAL scan_cnt  : UNSIGNED(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL dig       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    -- to split into 3 5 bit unsigned axis values
    SIGNAL X_bin, Y_bin, Z_bin : UNSIGNED(3 DOWNTO 0);
    -- digits for each axis
    SIGNAL X_tens, X_ones : UNSIGNED(3 DOWNTO 0);
    SIGNAL Y_tens, Y_ones : UNSIGNED(3 DOWNTO 0);
    SIGNAL Z_tens, Z_ones : UNSIGNED(3 DOWNTO 0);
    -- whole vector of 8 nibbles (4 sections)
    SIGNAL bcd32 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    component clk_gen
    PORT (
        clk_100MHz : in std_logic;
        clk_4MHz : out std_logic
    );
    End component;
    
    component spi_master
    PORT (
        clk_4MHz : IN std_logic; 
        acl_data_ALL : OUT std_logic_vector(14 downto 0); -- 4 bit precision
        acl_data_X : OUT std_logic_vector(15 downto 0); 
        acl_data_Y : OUT std_logic_vector(15 downto 0); 
        acl_data_Z : OUT std_logic_vector(15 downto 0); 
        SCLK : OUT std_logic;
        MOSI : OUT std_logic;
        MISO : IN std_logic;
        SS : OUT std_logic
    );
    End component;
    
    COMPONENT leddec16
        PORT(
            CLK_100MHZ : IN  STD_LOGIC;
            dig        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            bcd32      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            anode      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            seg        : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            dp         : OUT STD_LOGIC
        );
    END COMPONENT;
    
    component controller
        port(
            CLK_100MHZ : IN STD_LOGIC;
            acl_dataX : in STD_LOGIC_VECTOR(15 downto 0);
            pwm_out : out STD_LOGIC
        );
    end component;    
    
BEGIN

    clock_gen : clk_gen
        PORT MAP (
            CLK_100MHZ => CLK_100MHZ,
            clk_4MHz => w_4MHz
        );
        
    SPI : spi_master
        PORT MAP (
            clk_4MHz => w_4MHz,
            acl_data_ALL => acl_dataALL,
            acl_data_X => acl_dataX,
            acl_data_Y => acl_dataY,
            acl_data_Z => acl_dataZ, 
            SCLK => ACL_SCLK,
            MOSI => ACL_MOSI,
            MISO => ACL_MISO,
            SS => ACL_SS
        );
    
    display : leddec16
        PORT MAP(
            CLK_100MHZ => CLK_100MHZ,
            dig        => dig,
            bcd32      => bcd32,
            anode      => SEG7_anode,
            seg        => SEG7_seg,
            dp         => DP
        );
    
      control : Controller
        PORT MAP (
            CLK_100MHZ => CLK_100MHZ,
            acl_dataX => acl_dataX,
            pwm_out => PWM_OUT
        );  
    wha <= acl_dataX;
    wha2 <= acl_dataY;
    wha3 <= acl_dataZ;
    wha4 <= acl_dataALL;
    
      LED(15 DOWNTO 0) <= acl_dataX(15 DOWNTO 0);
      --LED(15 DOWNTO 0) <= acl_dataY(15 DOWNTO 0);
      --LED(15 DOWNTO 0) <= acl_dataZ(15 DOWNTO 0);
      --- FOR ALL 
--    LED(14 DOWNTO 10) <= acl_dataALL(14 DOWNTO 10); -- X
--    LED(9  DOWNTO 5)  <= acl_dataALL(9 DOWNTO 5);   -- Y
--    LED(4  DOWNTO 0)  <= acl_dataALL(4 DOWNTO 0);   -- Z


--    --Split 15-bit word into three 5-bit unsigned values
    X_bin <= UNSIGNED(acl_dataALL(13 DOWNTO 10));
    Y_bin <= UNSIGNED(acl_dataALL( 8 DOWNTO  5));
    Z_bin <= UNSIGNED(acl_dataALL( 3 DOWNTO  0));

    -- Converting binary 
    X_tens  <= TO_UNSIGNED( TO_INTEGER(X_bin) / 10, 4 );
    X_ones  <= TO_UNSIGNED( TO_INTEGER(X_bin) MOD 10, 4 );
    Y_tens  <= TO_UNSIGNED( TO_INTEGER(Y_bin) / 10, 4 );
    Y_ones  <= TO_UNSIGNED( TO_INTEGER(Y_bin) MOD 10, 4 );
    Z_tens  <= TO_UNSIGNED( TO_INTEGER(Z_bin) / 10, 4 );
    Z_ones  <= TO_UNSIGNED( TO_INTEGER(Z_bin) MOD 10, 4 );

    --packing eight nibbles: X_tens, X_ones, nothing , Y_tens, Y_ones, nothing, Z_tens, Z_ones
    bcd32 <= STD_LOGIC_VECTOR(X_tens) &
             STD_LOGIC_VECTOR(X_ones) &
             "1111" &  
             STD_LOGIC_VECTOR(Y_tens) &
             STD_LOGIC_VECTOR(Y_ones) &
             "1111" &
             STD_LOGIC_VECTOR(Z_tens) &
             STD_LOGIC_VECTOR(Z_ones);

    -- Digit scan so that 1 kHz per digit becomes 125 Hz overall
    scan_proc : PROCESS(w_4MHz)
    BEGIN
        IF rising_edge(w_4MHz) THEN
            scan_cnt <= scan_cnt + 1;
            dig      <= STD_LOGIC_VECTOR(scan_cnt(11 DOWNTO 9));
        END IF;
    END PROCESS;

END ARCHITECTURE;