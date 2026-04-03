entity ADC_SPI is
    port(
        CLOCK      : in  std_logic;
        RESETN     : in  std_logic;
        ADC_CONVST : out std_logic;
        ADC_SCK    : out std_logic;
        ADC_SDI    : out std_logic;
        ADC_SDO    : in  std_logic;
        RESULT     : out std_logic_vector(11 downto 0)
    );
end entity;