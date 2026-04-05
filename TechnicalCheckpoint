-- ADC_PERIPHERAL.vhd
-- ECE 2031 L13 Technical Checkpoint 
-- Jaivardhan Jain, Atharva Kulkarni, Bret Harvey, Jad Kahla
--
-- Description:
-- This peripheral provides SCOMP with read access to a multi-channel analog-to-digital converter by continuously sampling the selected input channel in the background via an SPI interface
-- The SCOMP programmer selects the desired channel by writing a value from 0 to 7 to address 0xC0, and reads the most recent 12-bit conversion result from address 0xC1
-- The result is an unsigned value from 0 to 4095, where each step represents approximately 1mV of input voltage.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use lpm.lpm_components.all;

-- SCOMP peripheral to interface with the LTC2308 ADC to allow easier use in an SCOMP program.
entity ADC_PERIPHERAL is
    port(
        -- Basic clock and reset for this peripheral to be clocked and reset by.
        CLOCK      : in    std_logic;
        RESETN     : in    std_logic;

       -- Buses for SCOMP and this peripheral to communicate with each other: ADDR selects the peripheral, DATA carries data, READ and WRITE control read and write operations.
        IO_ADDR    : in    std_logic_vector(10 downto 0);
        IO_DATA    : inout std_logic_vector(15 downto 0);
        IO_READ    : in    std_logic;
        IO_WRITE   : in    std_logic;

        -- Ports used to communicate to the ADC: CONVST starts conversation, SCK clocks data, SDI sends commands, SDO returns conversation data.
        ADC_CONVST : out   std_logic;
        ADC_SCK    : out   std_logic;
        ADC_SDI    : out   std_logic;
        ADC_SDO    : in    std_logic
    );
end entity ADC_PERIPHERAL;

architecture internals of ADC_PERIPHERAL is

    component LTC2308_ctrl is --this is like pseudo-defining an LTC2308 object
    --very important, sort of like saying ‘this object exists in our ecosystem and looks like this’
    -- we will later ‘instantiate’ a vers. of this ‘object’ by passing our signals to it later on!
    --keep in mind these are software analogies, yet we are describing actual hardware being wired together!
	 
        generic (CLK_DIV : integer := 1); --setting this generic parameter as given by Kevin’s vhdl
       -- the following declarations follow the syntax dictated by the object we wish to define
        port (
            clk      : in  std_logic;
            nrst     : in  std_logic;
            start    : in  std_logic;
            tx_data  : in  std_logic_vector(11 downto 0);
            rx_data  : out std_logic_vector(11 downto 0);
            busy     : out std_logic;
            sclk     : out std_logic;
            conv     : out std_logic;
            mosi     : out std_logic;
            miso     : in  std_logic
        );
    end component;

    -- Channel selection, aka the selected channel is saved in this register
    signal channel_reg  : std_logic_vector(2 downto 0);

    -- internal wires connecting this peripheral to the LTC_ctrl
    signal tx_data_sig  : std_logic_vector(11 downto 0);
    signal rx_data_sig  : std_logic_vector(11 downto 0);
    signal busy_sig     : std_logic;
    signal start_sig    : std_logic;

    
    signal start_cnt    : integer range 0 to 249; --counter for periodic pulsing/clocking

    -- bus driver enable so our peripheral can drive ADC result when needed, else left undriven to be reused
    signal io_en        : std_logic;
	 
	 -- Setting up the opcode
	 -- 12 bits overall, 6 bits configuration, 6 bits padding
	 
begin    
    tx_data_sig <= '1'             -- hard-coding S/D  to single-ended
                 & channel_reg(2)  -- channel MSB
                 & channel_reg(1)  -- S1  channel middle bit
                 & channel_reg(0)  -- S0  channel LSB
                 & '1'             -- UNI  = unipolar
                 & '0'             -- SLP  = no sleep
                 & "000000";       -- padding
					  
-- instantiating the LTC2308 SPI controller 
    adc_ctrl : LTC2308_ctrl
        generic map (CLK_DIV => 1)
        port map(
            clk => CLOCK,
            nrst  => RESETN,
            start => start_sig,
            tx_data => tx_data_sig,
            rx_data => rx_data_sig,
            busy  => busy_sig,
            sclk => ADC_SCK,
            conv => ADC_CONVST,
            mosi => ADC_SDI,
            miso => ADC_SDO
        );

    
    process(CLOCK, RESETN)
    begin
        if RESETN = '0' then  -- Reset the counter and no trigger action when reset is pressed
            start_cnt <= 0;  
            start_sig <= '0';
        elsif rising_edge(CLOCK) then  -- On every rising edge, check the counter
            if start_cnt = 249 then  -- When counter hits 249, fire a new trigger to start a new ADC reading, counter should reset
                start_cnt <= 0;
                start_sig <= '1';   -- one-cycle start pulse
            else  -- If 249 hasn’t been reached yet, just keep counting, stay idle
                start_cnt <= start_cnt + 1;
                start_sig <= '0';
            end if;
        end if;
    end process;

end architecture internals;

