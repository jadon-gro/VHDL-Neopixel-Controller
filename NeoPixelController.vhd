
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity NeoPixelController is

	generic (
		num_leds : integer := 8
	);
	
	port(
		clk_10M  : in   std_logic;
		resetn   : in   std_logic;
		latch_fsm   : in   std_logic;
		latch_16		: in   std_logic;
		data     : in   std_logic_vector(15 downto 0);
		sda      : out  std_logic
	); 

end entity;
architecture a of NeoPixelController is
	type state_type is (
		decode, init, starlight, rainbow, accelContr, altPattern, WriteAddr16_1, WriteAddr16_2, WriteAddr24_1,
		WriteAddr24_2, WriteAddr24_3,
		writeAddr16, writeAddr24, exec24_1, exec24_2, allLED16, allLED24, allLED24_1, allLED24_2, alternating
	);

	type lBuffer is array (0 to num_leds - 1) of std_logic_vector(23 downto 0);
	signal state : state_type;
	signal second8 : std_logic_vector(7 downto 0);
	signal led_buffer : lBuffer;
	signal first16register : std_logic_vector(15 downto 0);
	signal latch : std_logic;
	


begin
	process(latch, resetn)
	
	
	begin
		if ((resetn = '0')) then
				state <= decode;
				for i in 0 to (num_leds - 1) loop
					led_buffer(i) <= (others => '0');
				end loop;
		elsif (rising_edge(latch)) then
		if (active_16 = '1') then
			
		elsif (active_fsm = '1') then
			case state is	
				when decode =>
					second8 <= data(7 downto 0);
					case data(15 downto 8) is
						when "00000001" => -- christmas
							for i in 0 to (num_leds - 1) loop
								if (i mod 2 = 0) then
									led_buffer(i) <= ("000000001111111100000000");--(data(10 downto 5) & "00" & data(15 downto 11) & "000" & data(4 downto 0) & "000");
								else
									led_buffer(i) <= ("111111110000000000000000"); -- ((data(10 downto 5) & "00" & data(15 downto 11) & "000" & data(4 downto 0) & "000") xor "111111111111111111111111");
								end if;
							end loop;
							
							state <= decode;
						when "00000010" => --christmas2
							for i in 0 to (num_leds - 1) loop
								if (i mod 2 = 0) then
									led_buffer(i) <= ("111111110000000000000000");--(data(10 downto 5) & "00" & data(15 downto 11) & "000" & data(4 downto 0) & "000");
								else
									led_buffer(i) <= ("000000001111111100000000"); -- ((data(10 downto 5) & "00" & data(15 downto 11) & "000" & data(4 downto 0) & "000") xor "111111111111111111111111");
								end if;
							end loop;
							state <= decode;
						when OTHERS =>
							for i in 0 to (num_leds - 1) loop
								led_buffer(i) <= (data(10 downto 5) & "00" & data(15 downto 11) & "000" & data(4 downto 0) & "000");
							end loop;
						
						end case;
					
				when writeAddr16_1 =>
					
					led_buffer(TO_INTEGER(UNSIGNED(second8))) <= data(10 downto 5) & "00" & data(15 downto 11) & "000" & data(4 downto 0) & "000";
					state <= decode;
					
				when writeAddr24_1 =>
				
					first16register <= data;--(15 downto 0)
					state <= writeAddr24_2;
					
				when writeAddr24_2 =>
				
					led_buffer(TO_INTEGER(UNSIGNED(second8))) <= first16register(7 downto 0) & first16register(15 downto 8) & data(7 downto 0);
					
					
					state <= decode;
					
				when allLED24_1 =>
				
                 for i in 0 to (num_leds - 1) loop
				        led_buffer(i) <= data(15 downto 8) & second8 & data(7 downto 0);
		           end loop;
						 
                  state <= decode;
						
				when others =>
				
					state <= decode;
			end case;
		end if;
		end if;
		end process;
		
		process(clk_10M, resetn)
		-- protocol timing values (in 100s of ns)
		constant t1h : integer := 8; --7
		constant t1l : integer := 4; --6
		constant t0h : integer := 3; --3.5
		constant t0l : integer := 9; --8
		
		variable index_counter : integer range 0 to (num_leds - 1);

		-- which bit in the 24 bits is being sent
		variable bit_count   : integer range 0 to 23;
		-- counter to count through the bit encoding
		variable enc_count   : integer range 0 to 31;
		-- counter for the reset pulse
		variable reset_count : integer range 0 to 1000;
	
		
		begin
		if resetn = '0' then
			-- reset all counters
			bit_count := 23;
			enc_count := 0;
			reset_count := 1000;
			-- set sda inactive
			
			index_counter := (num_leds - 1);
			sda <= '0';

		elsif (((rising_edge(clk_10M)))) then
			-- This IF block controls the various counters
			if reset_count > 0 then
				-- during reset period, ensure other counters are reset
				bit_count := 23; --num_leds * 24) - 1
				enc_count := 0;
				index_counter := (num_leds - 1);
				-- decrement the reset count
				reset_count := reset_count - 1;
				
			else -- not in reset period (i.e. currently sending data)
				-- handle reaching end of a bit
				if led_buffer(index_counter)(bit_count) = '1' then -- current bit is 1	(bit_count mod 24)
					if enc_count = (t1h+t1l-1) then -- is end of the bit?
						enc_count := 0;
          
			 
			 
						if bit_count = 0 then -- is end of the LED's data?
							 -- begin the reset period
                             if index_counter = 0 then 
                                reset_count := 1000;
                             else
                                index_counter := index_counter - 1;
                                bit_count := 23;
                             end if;
						else
							-- if not end of data, decrement count
							bit_count := bit_count - 1;
						end if;
					else
						-- within a bit, count to achieve correct pulse widths
						enc_count := enc_count + 1;
					end if;
				else -- current bit is 0
					if enc_count = (t0h+t0l-1) then -- is end of the bit?
						enc_count := 0;
                        
								
								
						if bit_count = 0 then -- is end of the LED's data?
							-- begin the reset period
                             if index_counter = 0 then 
                                reset_count := 1000;
                             else
                                index_counter := index_counter - 1;
                                bit_count := 23;
                             end if;
						else
							bit_count := bit_count - 1;	--(bit_count mod 24)
						end if;
					else
						-- within a bit, count to achieve correct pulse widths
						enc_count := enc_count + 1;
					end if;
				end if;
			end if;
			
			-- This IF block controls sda
			if reset_count > 0 then
				-- sda is 0 during reset/latch
				sda <= '0';
			elsif 
				-- sda is 1 if it's the first part of a bit, which depends on if it's 1 or 0
				(((led_buffer(index_counter)(bit_count) = '1') and (enc_count < t1h)) --(bit_count mod 24)
				or
				((led_buffer(index_counter)(bit_count) = '0')  and (enc_count < t0h))) --(bit_count mod 24)
				then sda <= '1';
			else
				sda <= '0';
			end if;
		end if;
			
	end process;

	latch <= latch_fsm or latch_16;

end a;
				
				
				
