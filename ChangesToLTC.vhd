elsif state = TRANSFER then
    if sclk_rise = '1' then
        rx_reg <= rx_reg(10 downto 0) & miso;
        -- If this is the last bit, latch to output immediately
        if bit_cnt = 0 then
            rx_data <= rx_reg(10 downto 0) & miso;
        end if;
    end if;
    if sclk_fall = '1' then
        tx_reg <= tx_reg(10 downto 0) & '0';
        mosi   <= tx_reg(10);
    end if;

elsif state = HOLD then
    -- rx_data already latched above, nothing needed here
    null;
