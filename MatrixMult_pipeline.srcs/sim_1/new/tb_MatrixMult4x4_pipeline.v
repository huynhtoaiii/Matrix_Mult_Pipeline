`timescale 1ns / 1ps

module tb_MatrixMult4x4_pipeline;

    // Khai báo các tín hiệu kết nối với module RTL
    reg clk;
    reg rst;
    reg start;
    reg [127:0] ma;
    reg [127:0] mb;
    wire [511:0] mc;
    wire done;

    // Các biến phụ dùng để in kết quả ra màn hình console
    integer i, j;
    reg [31:0] temp_val;

    // Khởi tạo module RTL (Unit Under Test - UUT) - Bản PIPELINE
    MatrixMult4x4_pipeline uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .matrix_a(ma),
        .matrix_b(mb),
        .done(done),
        .matrix_c(mc)
    );

    // Tạo xung clock 100MHz (Chu kỳ = 10ns)
    always #5 clk = ~clk;

    initial begin
        // 1. Cấu hình xuất file VCD chứa dữ liệu chuyển mạch (Switching Activity) cho TVLA
        // Đổi tên file để phân biệt với bản non-pipeline
        $dumpfile("tvla_switching_traces_pipeline.vcd");
        // Dump toàn bộ tín hiệu của module testbench (bao gồm uut bên trong)
        $dumpvars(0, tb_MatrixMult4x4_pipeline);

        // 2. Khởi tạo giá trị ban đầu
        clk = 0;
        rst = 0;
        start = 0;
        ma = 128'd0;
        mb = 128'd0;

        // ========================================================
        // QUAN TRỌNG: Đợi 100ns cho Xilinx GSR (Global Set/Reset) xả xong.
        // Đây là khoảng thời gian chip FPGA khởi tạo mạng điện ảo trong mô phỏng Post-Synthesis.
        #100; 
        // ========================================================

        // 3. Reset hệ thống (Đồng bộ với sườn xuống của clock)
        @(negedge clk);
        rst = 1;
        #20; // Giữ reset trong 2 chu kỳ clock cho chắc chắn
        @(negedge clk);
        rst = 0;

        // 4. Bơm dữ liệu cho Ma trận A và B (Dựa trên giá trị hex từ waveform của bạn)
        // Ma trận A: Các số từ 1 đến 16
        ma = 128'h10_0f_0e_0d_0c_0b_0a_09_08_07_06_05_04_03_02_01;
        // Ma trận B: Các phần tử đường chéo bằng 2
        mb = 128'h02000000000200000000020000000002;

        // 5. Kích hoạt tính toán (Đồng bộ sườn xuống tránh lệch timing)
        $display("----------------------------------------");
        $display("BAT DAU TINH TOAN PIPELINE MA TRAN 4x4...");
        
        @(negedge clk); // Đợi sườn xuống của xung clock
        start = 1;      // Bật tín hiệu start (Dữ liệu sẽ được nạp vào Stage 1)
        
        @(negedge clk); // Đợi sườn xuống tiếp theo (giữ start trong đúng 1 chu kỳ)
        start = 0;      // Kéo start về 0

        // 6. Chờ cho đến khi module RTL báo tính toán xong
        // Lưu ý: Đối với Pipeline, tín hiệu done này sẽ xuất hiện rất nhanh (sau 4 chu kỳ clk)
        wait (done == 1);

        // 7. Lấy dữ liệu và in kết quả ra màn hình (Tcl Console)
        $display("----------------------------------------");
        $display("HOAN THANH (SAU 4 CHU KY)! KET QUA MA TRAN C:");
        for (i = 0; i < 4; i = i + 1) begin
            $write("[ ");
            for (j = 0; j < 4; j = j + 1) begin
                // Trích xuất từng block 32-bit từ thanh ghi 512-bit
                temp_val = mc[((i * 4 + j) * 32) +: 32];
                $write("%4d ", temp_val);
            end
            $write("]\n");
        end
        $display("----------------------------------------");

        // 8. Đợi thêm một chút để lưu lại sóng phần đuôi rồi kết thúc
        #100;
        $finish;
    end

endmodule