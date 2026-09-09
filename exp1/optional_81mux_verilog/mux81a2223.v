// ============================================================
// 8选1多路选择器 (8-to-1 Multiplexer) —— 选做实验 (Verilog)
// 课程: 数字系统设计基础实验 第1次课 (2026)
// 要求: 8选1, 数据宽度为 8bit (8路数据, 每路8位)
// 功能: y = d{s}, s = 0..7 依次选择 d0..d7
// ============================================================
module mux81a2223 (
    input  wire [7:0] d0,   // 数据通道 0 (8bit)
    input  wire [7:0] d1,   // 数据通道 1 (8bit)
    input  wire [7:0] d2,   // 数据通道 2 (8bit)
    input  wire [7:0] d3,   // 数据通道 3 (8bit)
    input  wire [7:0] d4,   // 数据通道 4 (8bit)
    input  wire [7:0] d5,   // 数据通道 5 (8bit)
    input  wire [7:0] d6,   // 数据通道 6 (8bit)
    input  wire [7:0] d7,   // 数据通道 7 (8bit)
    input  wire [2:0] s,    // 3 位通道选择
    output reg  [7:0] y     // 数据输出 (8bit)
);

    always @(*) begin
        case (s)
            3'd0: y = d0;
            3'd1: y = d1;
            3'd2: y = d2;
            3'd3: y = d3;
            3'd4: y = d4;
            3'd5: y = d5;
            3'd6: y = d6;
            3'd7: y = d7;
            default: y = 8'b0;
        endcase
    end

endmodule
