LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SPI_master is
    PORT (
    clk_4MHz : IN std_logic; -- 4MHz
    acl_data_ALL : OUT std_logic_vector(14 downto 0);
    acl_data_X : OUT std_logic_vector(15 downto 0); 
    acl_data_Y : OUT std_logic_vector(15 downto 0); 
    acl_data_Z : OUT std_logic_vector(15 downto 0);  
    SCLK : OUT std_logic;
    MOSI : OUT std_logic;
    MISO : IN std_logic;
    SS : OUT std_logic
    );
end SPI_master;

architecture Behavioral of spi_master is 
    type state_type is (
        S0, S1, S2, S3, S4, S5, S6, S7,
        S8, S9, S10, S11, S12, S13, S14,
        S15, S16, S17, S18, S19, S20, S21,
        S22, S23, S24, S25, S26, S27, S28,
        S29, S30, S31, S32, S33, S34, S35,
        S36, S37, S38, S39, S40, S41, S42,
        S43, S44, S45, S46, S47, S48, S49,
        S50, S51, S52, S53, S54, S55, S56,
        S57, S58, S59, S60, S61, S62, S63,
        S64, S65, S66, S67, S68, S69, S70,
        S71, S72, S73, S74, S75, S76, S77,
        S78, S79, S80, S81, S82, S83, S84,
        S85, S86, S87, S88, S89, S90, S91,
        S92
    );
    
    signal current_state, next_state : state_type := S0;
    signal count       : integer := 0;
    signal temp_x    : std_logic_vector(15 downto 0) := (others => '0');
    signal temp_y    : std_logic_vector(15 downto 0) := (others => '0');
    signal temp_z    : std_logic_vector(15 downto 0) := (others => '0');
    signal temp_acl_ALL : std_logic_vector(14 downto 0) := (others => '0');
    signal temp_acl_X, temp_acl_Y, temp_acl_Z : std_logic_vector(15 downto 0) := (others => '0');
    signal mosi_reg     : std_logic := '0';
    signal sclk_reg : std_logic := '0';
    signal ss_reg       : std_logic := '1';
    signal sclk_prev : std_logic := '0';
    signal sclk_curr : std_logic := '0';
    signal sclk_rising : std_logic := '0';
    signal sclk_falling : std_logic := '0';
    signal sclk_counter : integer range 0 to 3 := 0;    
    
    constant write_instr : std_logic_vector(7 downto 0) := "00001010"; -- 0x0A
    constant write_addr : std_logic_vector(7 downto 0) := "00101101"; -- 0x2D
    constant write_byte : std_logic_vector(7 downto 0) := "00000010"; -- 0x02
    constant Read_instr : std_logic_vector(7 downto 0) := "00001011"; -- 0x0B
    constant Read_addr : std_logic_vector(7 downto 0) := "00001110"; -- 0x0E

begin 
    sclk <= sclk_reg;
    mosi <= mosi_reg;
    ss   <= ss_reg;

    process(clk_4MHz) -- creates the 1MHz from 4MHz
    begin
        if rising_edge(clk_4MHz) then
            if sclk_counter = 1 then
                sclk_counter <= 0;
                sclk_reg <= not sclk_reg;
            else
                sclk_counter <= sclk_counter + 1;
            end if;
        end if;
    end process;
   
    -- State Transition Logic 
    process(clk_4MHz) -- detects rising edge of 1MHz for sclk
    begin
        if rising_edge(clk_4MHz) then
            sclk_prev <= sclk_curr;
            sclk_curr <= sclk_reg;
            
            if (sclk_prev = '0' and sclk_curr = '1') then
                sclk_rising <= '1';  -- Rising edge detected
            else
                sclk_rising <= '0';  
            end if;

            if (sclk_prev = '1' and sclk_curr = '0') then
                sclk_falling <= '1'; -- Falling edge detected
            else
                sclk_falling <= '0';
            end if;

        current_state <= next_state;
        
        case current_state is

            when S0 =>
                if count < 24000 then
                    count <= count + 1;
                end if;
                
            when S26 =>
                if count < 160000 then
                    count <= count + 1;
                end if;

            when S92 =>
                temp_acl_ALL <= (temp_x(11 downto 7) & temp_y(11 downto 7) & temp_z(11 downto 7));
                temp_acl_X <= temp_x;
                temp_acl_Y <= temp_y;
                temp_acl_Z <= temp_z;
                
                if count < 40000 then
                    count <= count + 1;
                end if;

            when others =>
                count <= 0;
        end case;
        end if;
    end process;
    
    process(current_state, sclk_rising, sclk_falling, count, MISO) 
    begin
        ss_reg <= '1';  
        mosi_reg <= '0';
   
        case current_state is
            ---- Power up waits 6ms
            when S0 => 
                if count < 24000 then -- 6ms
                    next_state <= S0;
                else
                    next_state <= S1;
                end if; 
            ---- Sends CS = Low
            when S1 => 
                ss_reg <= '0';
                next_state <= S2;
            ---- Sends Write command Byte 0x0A
            when S2 =>  -- Bit 7 (0)
                ss_reg <= '0';
                mosi_reg <= write_instr(7);
                if sclk_falling = '1' then 
                    next_state <= S3;
                else
                    next_state <= S2;
                end if;
            when S3 =>
                ss_reg <= '0';
                mosi_reg <= write_instr(6);
                if sclk_falling = '1' then 
                    next_state <= S4;
                else
                    next_state <= S3;
                end if;    
            when S4 =>  
                ss_reg <= '0';
                mosi_reg <= write_instr(5);
                if sclk_falling = '1' then 
                    next_state <= S5;
                else
                    next_state <= S4;
                end if;   
            when S5 =>
                ss_reg <= '0';
                mosi_reg <= write_instr(4);
                if sclk_falling = '1' then 
                    next_state <= S6;
                else
                    next_state <= S5;
                end if;   
            when S6 =>
                ss_reg <= '0';
                mosi_reg <= write_instr(3);  
                if sclk_falling = '1' then 
                    next_state <= S7;
                else
                    next_state <= S6;
                end if;   
            when S7 =>
                ss_reg <= '0';
                mosi_reg <= write_instr(2);
                if sclk_falling = '1' then 
                    next_state <= S8;
                else
                    next_state <= S7;
                end if;   
            when S8 =>  
                ss_reg <= '0';
                mosi_reg <= write_instr(1);     
                if sclk_falling = '1' then 
                    next_state <= S9;
                else
                    next_state <= S8;
                end if;   
            when S9 =>
                ss_reg <= '0';
                mosi_reg <= write_instr(0);
                if sclk_falling = '1' then 
                    next_state <= S10;
                else
                    next_state <= S9;
                end if;   
            ----Sends Write address Byte 0x2D
            when S10 =>
                ss_reg <= '0';
                mosi_reg <= write_addr(7);
                if sclk_falling = '1' then 
                    next_state <= S11;
                else
                    next_state <= S10;
                end if;   
            when S11 =>
                ss_reg <= '0';
                mosi_reg <= write_addr(6);
                if sclk_falling = '1' then 
                    next_state <= S12;
                else
                    next_state <= S11;
                end if;
            when S12 =>
                ss_reg <= '0';
                mosi_reg <= write_addr(5);
                if sclk_falling = '1' then 
                    next_state <= S13;
                else
                    next_state <= S12;
                end if;
            when S13 =>
                ss_reg <= '0';
                mosi_reg <= write_addr(4);
                if sclk_falling = '1' then 
                    next_state <= S14;
                else
                    next_state <= S13;
                end if;
            when S14 =>
                ss_reg <= '0';
                mosi_reg <= write_addr(3);
                if sclk_falling = '1' then 
                    next_state <= S15;
                else
                    next_state <= S14;
                end if;
            when S15 =>
                ss_reg <= '0';
                mosi_reg <= write_addr(2);
                if sclk_falling = '1' then 
                    next_state <= S16;
                else
                    next_state <= S15;
                end if;
            when S16 =>
                ss_reg <= '0';
                mosi_reg <= write_addr(1);
                if sclk_falling = '1' then 
                    next_state <= S17;
                else
                    next_state <= S16;
                end if;
            when S17 =>
                ss_reg <= '0';
                mosi_reg <= write_addr(0);
                if sclk_falling = '1' then
                    next_state <= S18;
                else
                    next_state <= S17;
                end if;
            ----Send Write Byte 0x02 for measurement mode  
            when S18 =>
                ss_reg <= '0';
                mosi_reg <= write_byte(7);
                if sclk_falling = '1' then 
                    next_state <= S19;
                else
                    next_state <= S18;
                end if;
            when S19 =>
                ss_reg <= '0';
                mosi_reg <= write_byte(6);
                if sclk_falling = '1' then
                    next_state <= S20;
                else
                    next_state <= S19;
                end if;
            when S20 =>
                ss_reg <= '0';
                mosi_reg <= write_byte(5);
                if sclk_falling = '1' then 
                    next_state <= S21;
                else
                    next_state <= S20;
                end if;
            when S21 =>
                ss_reg <= '0';
                mosi_reg <= write_byte(4);
                if sclk_falling = '1' then 
                    next_state <= S22;
                else
                    next_state <= S21;
                end if;
            when S22 =>
                ss_reg <= '0'; 
                mosi_reg <= write_byte(3);
                if sclk_falling = '1' then 
                    next_state <= S23;
                else
                    next_state <= S22;
                end if;
            when S23 =>
                ss_reg <= '0';
                mosi_reg <= write_byte(2);
                if sclk_falling = '1' then 
                    next_state <= S24;
                else
                    next_state <= S23;
                end if;
            when S24 =>
                ss_reg <= '0';
                mosi_reg <= write_byte(1);
                if sclk_falling = '1' then 
                    next_state <= S25;
                else
                    next_state <= S24;
                end if;
            when S25 =>
                ss_reg <= '0';
                mosi_reg <= write_byte(0);
                if sclk_falling = '1' then 
                    next_state <= S26;
                else
                    next_state <= S25;
                end if;              
            ---- Send CS = High
            when S26 => 
                ss_reg <= '1';
                if count < 160000 then -- 4MHz * 40ms 
                    next_state <= S26;
                else
                    next_state <= S27;
                end if;
            ---- Send CS = Low
            when S27 =>
                ss_reg <= '0';
                next_state <= S28; 
            ---- Sends Read command Byte 0x0B
            when S28 =>
                ss_reg <= '0';
                mosi_reg <= read_instr(7);
                if sclk_falling = '1' then 
                    next_state <= S29;
                else
                    next_state <= S28;
                end if;
            when S29 =>
                ss_reg <= '0'; 
                mosi_reg <= read_instr(6);
                if sclk_falling = '1' then 
                    next_state <= S30;
                else
                    next_state <= S29;
                end if;
            when S30 => 
                ss_reg <= '0'; 
                mosi_reg <= read_instr(5);
                if sclk_falling = '1' then 
                    next_state <= S31;
                else
                    next_state <= S30;
                end if;
            when S31 =>
                ss_reg <= '0';
                mosi_reg <= read_instr(4);
                if sclk_falling = '1' then
                    next_state <= S32;
                else
                    next_state <= S31;
                end if;
            when S32 => 
                ss_reg <= '0'; 
                mosi_reg <= read_instr(3);
                if sclk_falling = '1' then 
                    next_state <= S33;
                else
                    next_state <= S32;
                end if;
            when S33 =>
                ss_reg <= '0';
                mosi_reg <= read_instr(2);
                if sclk_falling = '1' then
                    next_state <= S34;
                else
                    next_state <= S33;
                end if;
            when S34 =>
                ss_reg <= '0'; 
                mosi_reg <= read_instr(1);
                if sclk_falling = '1' then 
                    next_state <= S35;
                else
                    next_state <= S34;
                end if;
            when S35 =>
                ss_reg <= '0';
                mosi_reg <= read_instr(0);
                if sclk_falling = '1' then 
                    next_state <= S36;
                else
                    next_state <= S35;
                end if;
            ---- Sends Read address Byte 0x0E aka X-data LSB
            when S36 =>
                ss_reg <= '0';
                mosi_reg <= read_addr(7);
                if sclk_falling = '1' then 
                    next_state <= S37;
                else
                    next_state <= S36;
                end if;
            when S37 =>
                ss_reg <= '0';
                mosi_reg <= read_addr(6);
                if sclk_falling = '1' then 
                    next_state <= S38;
                else
                    next_state <= S37;
                end if;
            when S38 =>
                ss_reg <= '0';
                mosi_reg <= read_addr(5);
                if sclk_falling = '1' then 
                    next_state <= S39;
                else
                    next_state <= S38;
                end if;
            when S39 =>
                ss_reg <= '0';
                mosi_reg <= read_addr(4);
                if sclk_falling = '1' then 
                    next_state <= S40;
                else
                    next_state <= S39;
                end if;
            when S40 =>
                ss_reg <= '0';
                mosi_reg <= read_addr(3);
                if sclk_falling = '1' then 
                    next_state <= S41;
                else
                    next_state <= S40;
                end if;
            when S41 =>
                ss_reg <= '0';
                mosi_reg <= read_addr(2);
                if sclk_falling = '1' then 
                    next_state <= S42;
                else
                    next_state <= S41;
                end if;
            when S42 =>
                ss_reg <= '0';
                mosi_reg <= read_addr(1);
                if sclk_falling = '1' then 
                    next_state <= S43;
                else
                    next_state <= S42;
                end if;
            when S43 =>
                ss_reg <= '0';
                mosi_reg <= read_addr(0);
                if sclk_falling = '1' then 
                    next_state <= S44;
                else
                    next_state <= S43;
                end if;
            ---- X-data LSB
            when S44 =>
                ss_reg <= '0';
                temp_x(7) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S45;
                else
                    next_state <= S44;
                end if;
            when S45 =>
                ss_reg <= '0';
                temp_x(6) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S46;
                else
                    next_state <= S45;
                end if;
            when S46 =>
                ss_reg <= '0';
                temp_x(5) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S47;
                else
                    next_state <= S46;
                end if;
            when S47 =>
                ss_reg <= '0';
                temp_x(4) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S48;
                else
                    next_state <= S47;
                end if;
            when S48 =>
                ss_reg <= '0';
                temp_x(3) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S49;
                else
                    next_state <= S48;
                end if;
            when S49 =>
                ss_reg <= '0';
                temp_x(2) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S50;
                else
                    next_state <= S49;
                end if;
            when S50 =>
                ss_reg <= '0';
                temp_x(1) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S51;
                else
                    next_state <= S50;
                end if;
            when S51 =>
                ss_reg <= '0';
                temp_x(0) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S52;
                else
                    next_state <= S51;
                end if;
            ---- X-data MSB
            when S52 =>
                ss_reg <= '0';
                temp_x(15) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S53;
                else
                    next_state <= S52;
                end if;
            when S53 =>
                ss_reg <= '0';
                temp_x(14) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S54;
                else
                    next_state <= S53;
                end if;
            when S54 =>
                ss_reg <= '0';
                temp_x(13) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S55;
                else
                    next_state <= S54;
                end if;
            when S55 =>
                ss_reg <= '0';
                temp_x(12) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S56;
                else
                    next_state <= S55;
                end if;
            when S56 =>
                ss_reg <= '0';
                temp_x(11) <= MISO;
                if sclk_rising = '1' then 
                    --temp_x(11) <= MISO;
                    next_state <= S57;
                else
                    next_state <= S56;
                end if;
            when S57 =>
                ss_reg <= '0';
                temp_x(10) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S58;
                else
                    next_state <= S57;
                end if;
            when S58 =>
                ss_reg <= '0';
                temp_x(9) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S59;
                else
                    next_state <= S58;
                end if;
            when S59 =>
                ss_reg <= '0';
                temp_x(8) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S60;
                else
                    next_state <= S59;
                end if;
            ---- Y-data LSB
            when S60 =>
                ss_reg <= '0';
                temp_y(7) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S61;
                else
                    next_state <= S60;
                end if;
            when S61 =>
                ss_reg <= '0';
                temp_y(6) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S62;
                else
                    next_state <= S61;
                end if;
            when S62 =>
                ss_reg <= '0';
                temp_y(5) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S63;
                else
                    next_state <= S62;
                end if;
            when S63 =>
                ss_reg <= '0';
                temp_y(4) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S64;
                else
                    next_state <= S63;
                end if;              
            when S64 =>
                ss_reg <= '0';
                temp_y(3) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S65;
                else
                    next_state <= S64;
                end if;
            when S65 =>
                ss_reg <= '0';
                temp_y(2) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S66;
                else
                    next_state <= S65;
                end if;
            when S66 =>
                ss_reg <= '0';
                temp_y(1) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S67;
                else
                    next_state <= S66;
                end if;
            when S67 =>
                ss_reg <= '0';
                temp_y(0) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S68;
                else
                    next_state <= S67;
                end if;
            ---- Y-data MSB
            when S68 =>
                ss_reg <= '0';
                temp_y(15) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S69;
                else
                    next_state <= S68;
                end if;
            when S69 =>
                ss_reg <= '0';
                temp_y(14) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S70;
                else
                    next_state <= S69;
                end if;
            when S70 =>
                ss_reg <= '0';
                temp_y(13) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S71;
                else
                    next_state <= S70;
                end if;
            when S71 =>
                ss_reg <= '0';
                temp_y(12) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S72;
                else
                    next_state <= S71;
                end if;                
            when S72 =>
                ss_reg <= '0';
                temp_y(11) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S73;
                else
                    next_state <= S72;
                end if;
            when S73 =>
                ss_reg <= '0';
                temp_y(10) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S74;
                else
                    next_state <= S73;
                end if;
            when S74 =>
                ss_reg <= '0';
                temp_y(9) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S75;
                else
                    next_state <= S74;
                end if;
            when S75 =>
                ss_reg <= '0';
                temp_y(8) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S76;
                else
                    next_state <= S75;
                end if;
            ---- Z-data LSB
            when S76 =>
                ss_reg <= '0';
                temp_z(7) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S77;
                else
                    next_state <= S76;
                end if;
            when S77 =>
                ss_reg <= '0';
                temp_z(6) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S78;
                else
                    next_state <= S77;
                end if;
            when S78 =>
                ss_reg <= '0';
                temp_z(5) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S79;
                else
                    next_state <= S78;
                end if;
            when S79 =>
                ss_reg <= '0';
                temp_z(4) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S80;
                else
                    next_state <= S79;
                end if;
            when S80 =>
                ss_reg <= '0';
                temp_z(3) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S81;
                else
                    next_state <= S80;
                end if;
            when S81 =>
                ss_reg <= '0';
                temp_z(2) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S82;
                else
                    next_state <= S81;
                end if;
            when S82 =>
                ss_reg <= '0';
                temp_z(1) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S83;
                else
                    next_state <= S82;
                end if;
            when S83 =>
                ss_reg <= '0';
                temp_z(0) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S84;
                else
                    next_state <= S83;
                end if;
            ---- Z-data MSB
            when S84 =>
                ss_reg <= '0';
                temp_z(15) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S85;
                else
                    next_state <= S84;
                end if;
            when S85 =>
                ss_reg <= '0';
                temp_z(14) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S86;
                else
                    next_state <= S85;
                end if;
            when S86 =>
                ss_reg <= '0';
                temp_z(13) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S87;
                else
                    next_state <= S86;
                end if;
            when S87 =>
                ss_reg <= '0';
                temp_z(12) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S88;
                else
                    next_state <= S87;
                end if;
            when S88 =>
                ss_reg <= '0';
                temp_z(11) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S89;
                else
                    next_state <= S88;
                end if;
            when S89 =>
                ss_reg <= '0';
                temp_z(10) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S90;
                else
                    next_state <= S89;
                end if;
            when S90 =>
                ss_reg <= '0';
                temp_z(9) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S91;
                else
                    next_state <= S90;
                end if;
            when S91 =>
                ss_reg <= '0';
                temp_z(8) <= MISO;
                if sclk_rising = '1' then 
                    next_state <= S92;
                else
                    next_state <= S91;
                end if;
            ---- Send CS = high
            when S92 =>
                ss_reg <= '1';
                if count < 40000 then
                    next_state <= S92;
                else
                    next_state <= S27;
                end if; 
                
            when others =>
                next_state <= S0;
        
            end case;
    end process;

    acl_data_ALL <= temp_acl_ALL;
    acl_data_X <= temp_acl_X;
    acl_data_Y <= temp_acl_Y;
    acl_data_Z <= temp_acl_Z;

end Behavioral;