-- ============================================================
-- 2选1多路选择器 (2-to-1 Multiplexer)
-- 课程: 基本组合、时序逻辑电路实验 第1次课 (VHDL 文本输入)
-- 目标器件: Cyclone IV E  EP4CE55F23C8
-- 功能: s = '0' 时 y = a;  s = '1' 时 y = b
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity mux21a2223 is
    port (
        a, b : in  std_logic;   -- 两路数据输入 (CLKB0=1024Hz, CLKB1=256Hz)
        s    : in  std_logic;   -- 通道选择, 接按键1 (PIO0)
        y    : out std_logic    -- 数据输出, 接蜂鸣器 (DBT1)
    );
end entity mux21a2223;

architecture rtl of mux21a2223 is
begin
    process (a, b, s)
    begin
        if s = '0' then
            y <= a;
        else
            y <= b;
        end if;
    end process;
end architecture rtl;
