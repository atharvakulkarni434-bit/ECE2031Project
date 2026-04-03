-- ADC_PERIPHERAL.vhd
--
-- SCOMP peripheral for the LTC2308 ADC on the DE10 board.
--
-- I/O Map:
--   OUT 0xC0 : Select ADC channel. Bits 2:0 = channel number (0-7).
--              Example: LOADI 2 / OUT 0xC0  -> select channel 2
--   IN  0xC1 : Read the most recent 12-bit conversion result.
--              Result is in bits 11:0. Bits 15:12 are always 0.
--              Value range: 0x000 (0V) to 0xFFF (4.096V), 1 LSB = 1mV
--
-- Behavior:
--   The peripheral continuously samples the selected channel in the background
--   without any action required from the SCOMP programmer. An IN 0xC1
--   instruction always returns the most recently completed conversion result
--   immediately -- no waiting or polling is needed.
--
-- Note on channel changes:
--   After an OUT 0xC0, the new channel takes effect on the next conversion
--   cycle. There may be one stale reading from the previous channel before
--   fresh data from the new channel is available.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity ADC_PERIPHERAL is
    port(
        CLOCK      : in    std_logic;
        RESETN     : in    std_logic;
        -- SCOMP I/O bus
        IO_ADDR    : in    std_logic_vector(10 downto 0);
        IO_DATA    : inout std_logic_vector(15 downto 0);
        IO_READ    : in    std_logic;
        IO_WRITE   : in    std_logic;
        -- LTC2308 SPI physical pins
        ADC_CONVST : out   std_logic;
        ADC_SCK    : out   std_logic;
        ADC_SDI    : out   std_logic;
        ADC_SDO    : in    std_logic
    );
end entity ADC_PERIPHERAL;


architecture internals of ADC_PERIPHERAL is

    component LTC2308_ctrl is
        generic (CLK_DIV : integer := 1);
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

    -- Channel selection (3 bits covers channels 0-7)
    signal channel_reg  : std_logic_vector(2 downto 0);

    -- Signals going to/from LTC2308_ctrl
    signal tx_data_sig  : std_logic_vector(11 downto 0);
    signal rx_data_sig  : std_logic_vector(11 downto 0);
    signal busy_sig     : std_logic;
    signal start_sig    : std_logic;

    -- Counter for generating periodic start pulses to the SPI controller.
    -- Period of 250 cycles keeps conversions running continuously while
    -- guaranteeing start='0' is seen by the HOLD state before each re-trigger.
    -- At 25MHz: 250 cycles = 10us between triggers (max ADC conversion is ~2us)
    signal start_cnt    : integer range 0 to 249;

    -- Bus driver enable
    signal io_en        : std_logic;

begin

    ---------------------------------------------------------------------------
    -- Build the 12-bit SPI config word from the channel register.
    --
    -- The LTC2308 expects a 6-bit DIN word, MSB first:
    --   Bit 5: S/D  = 1 (single-ended mode, not differential)
    --   Bit 4: O/S  = channel(2) (MSB of 3-bit channel address)
    --   Bit 3: S1   = channel(1)
    --   Bit 2: S0   = channel(0)
    --   Bit 1: UNI  = 1 (unipolar mode: 0V to 4.096V)
    --   Bit 0: SLP  = 0 (no sleep, stay powered between conversions)
    --
    -- The remaining 6 bits are padding zeros clocked out after the config.
    ---------------------------------------------------------------------------
    tx_data_sig <= '1'             -- S/D  = single-ended
                 & channel_reg(2)  -- O/S  = channel MSB
                 & channel_reg(1)  -- S1   = channel middle bit
                 & channel_reg(0)  -- S0   = channel LSB
                 & '1'             -- UNI  = unipolar
                 & '0'             -- SLP  = no sleep
                 & "000000";       -- padding

    ---------------------------------------------------------------------------
    -- Instantiate the SPI controller.
    -- CLK_DIV=1 gives SCK = system_clock / 2.
    -- At 25MHz: SCK = 12.5MHz, safely below the 40MHz maximum.
    ---------------------------------------------------------------------------
    adc_ctrl : LTC2308_ctrl
        generic map (CLK_DIV => 1)
        port map(
            clk     => CLOCK,
            nrst    => RESETN,
            start   => start_sig,
            tx_data => tx_data_sig,
            rx_data => rx_data_sig,
            busy    => busy_sig,
            sclk    => ADC_SCK,
            conv    => ADC_CONVST,
            mosi    => ADC_SDI,
            miso    => ADC_SDO
        );

    ---------------------------------------------------------------------------
    -- Periodic Start Pulse Generator
    --
    -- Produces a one-cycle start='1' pulse every 250 clock cycles.
    -- This keeps the ADC sampling continuously in the background.
    --
    -- Why a counter instead of start <= not busy?
    --   The LTC2308_ctrl HOLD state requires start='0' before it will return
    --   to IDLE. With 249 cycles of start='0' between pulses, HOLD always
    --   gets the low it needs and cleanly exits before the next trigger arrives.
    ---------------------------------------------------------------------------
    process(CLOCK, RESETN)
    begin
        if RESETN = '0' then
            start_cnt <= 0;
            start_sig <= '0';
        elsif rising_edge(CLOCK) then
            if start_cnt = 249 then
                start_cnt <= 0;
                start_sig <= '1';   -- one-cycle start pulse
            else
                start_cnt <= start_cnt + 1;
                start_sig <= '0';
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Channel Select: OUT 0xC0
    --
    -- Latches the low 3 bits of the written value into channel_reg.
    -- The new channel takes effect on the next conversion cycle.
    --
    -- SCOMP programmer usage:
    --   LOADI  3        ; channel 3
    --   OUT    0xC0     ; select it
    ---------------------------------------------------------------------------
    process(CLOCK, RESETN)
    begin
        if RESETN = '0' then
            channel_reg <= "000";   -- default: channel 0
        elsif rising_edge(CLOCK) then
            if IO_WRITE = '1' and IO_ADDR = "00011000000" then  -- 0x0C0
                channel_reg <= IO_DATA(2 downto 0);
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Read Result: IN 0xC1
    --
    -- Drives IO_DATA with the latest 12-bit ADC result when SCOMP reads
    -- from address 0xC1. The result is zero-padded into 16 bits.
    -- The lpm_bustri component tri-states the bus when io_en is low,
    -- which is required so other peripherals can still drive IO_DATA.
    --
    -- SCOMP programmer usage:
    --   IN     0xC1     ; AC = 0x000 (0V) to 0xFFF (4.096V)
    ---------------------------------------------------------------------------
    io_en <= '1' when IO_READ = '1' and IO_ADDR = "00011000001"  -- 0x0C1
             else '0';

    io_bus : lpm_bustri
        generic map (lpm_width => 16)
        port map(
            data     => "0000" & rx_data_sig,  -- zero-pad upper 4 bits
            enabledt => io_en,
            tridata  => IO_DATA
        );

end architecture internals;
