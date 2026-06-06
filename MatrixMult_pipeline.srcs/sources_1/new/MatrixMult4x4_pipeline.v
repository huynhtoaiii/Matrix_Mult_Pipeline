`timescale 1ns / 1ps

module MatrixMult4x4_pipeline (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [127:0] matrix_a, 
    input wire [127:0] matrix_b,
    
    output reg done,
    output wire [511:0] matrix_c 
);

    genvar gi, gj;
    integer r, c, d;

    wire [7:0] A [0:3][0:3];
    wire [7:0] B [0:3][0:3];

    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : gen_unpack_A
            for (gj = 0; gj < 4; gj = gj + 1) begin : gen_unpack_B
                assign A[gi][gj] = matrix_a[((gi * 4 + gj) * 8) +: 8];
                assign B[gi][gj] = matrix_b[((gi * 4 + gj) * 8) +: 8];
            end
        end
    endgenerate

    // Control Pipeline (Thanh ghi dịch để đẩy tín hiệu start -> done)
    reg [2:0] pipe_valid;

    // Stage 1: Thanh ghi chứa 64 kết quả nhân song song
    reg [15:0] stg1_mult [0:3][0:3][0:3]; // [hàng i][cột j][phần tử k]

    // Stage 2: Thanh ghi chứa 16 kết quả cộng dồn
    reg [31:0] stg2_sum [0:3][0:3];       // [hàng i][cột j]

    // Stage 3: Thanh ghi đầu ra (đã làm phẳng)
    reg [31:0] stg3_out [0:15];           


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pipe_valid <= 3'b000;
            done <= 0;
            
            // Khởi tạo 0 cho toàn bộ thanh ghi để mạch TVLA sạch nhiễu
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    stg2_sum[r][c] <= 0;
                    for (d = 0; d < 4; d = d + 1) begin
                        stg1_mult[r][c][d] <= 0;
                    end
                end
            end
            for (r = 0; r < 16; r = r + 1) stg3_out[r] <= 0;
            
        end else begin
            // -------------------------------------------------------------
            // CONTROL PATH: Đẩy tín hiệu hợp lệ qua từng tầng
            // -------------------------------------------------------------
            pipe_valid[0] <= start;
            pipe_valid[1] <= pipe_valid[0];
            pipe_valid[2] <= pipe_valid[1];
            done          <= pipe_valid[2]; // Chu kỳ 4: Done lên 1

            // -------------------------------------------------------------
            // STAGE 1 (Chu kỳ 1): Thực hiện 64 phép nhân song song
            // -------------------------------------------------------------
            if (start) begin
                for (r = 0; r < 4; r = r + 1) begin
                    for (c = 0; c < 4; c = c + 1) begin
                        for (d = 0; d < 4; d = d + 1) begin
                            stg1_mult[r][c][d] <= A[r][d] * B[d][c];
                        end
                    end
                end
            end

            // -------------------------------------------------------------
            // STAGE 2 (Chu kỳ 2): Cộng dồn 4 tích của mỗi phần tử C[i][j]
            // -------------------------------------------------------------
            if (pipe_valid[0]) begin
                for (r = 0; r < 4; r = r + 1) begin
                    for (c = 0; c < 4; c = c + 1) begin
                        stg2_sum[r][c] <= stg1_mult[r][c][0] + 
                                          stg1_mult[r][c][1] + 
                                          stg1_mult[r][c][2] + 
                                          stg1_mult[r][c][3];
                    end
                end
            end

            // -------------------------------------------------------------
            // STAGE 3 (Chu kỳ 3): Đẩy vào mảng 1D để sẵn sàng xuất ra
            // -------------------------------------------------------------
            if (pipe_valid[1]) begin
                for (r = 0; r < 4; r = r + 1) begin
                    for (c = 0; c < 4; c = c + 1) begin
                        stg3_out[r*4 + c] <= stg2_sum[r][c];
                    end
                end
            end
        end
    end

    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : gen_output
            assign matrix_c[(gi * 32) +: 32] = stg3_out[gi];
        end
    endgenerate

endmodule