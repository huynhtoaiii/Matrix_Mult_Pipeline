`timescale 1ns / 1ps

module tb_MatrixMult4x4_pipeline_tvla;

    // Khai báo các tín hiệu
    reg clk;
    reg rst;
    reg start;
    reg [127:0] ma;
    reg [127:0] mb;
    wire [511:0] mc;
    wire done;

    integer i;
    integer trace_type; // 0: Fixed, 1: Random

    // Khởi tạo UUT (Unit Under Test)
    MatrixMult4x4_pipeline uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .matrix_a(ma),
        .matrix_b(mb),
        .done(done),
        .matrix_c(mc)
    );

    // Tạo xung clock 10ns (Tương đương tần số 100MHz)
    always #5 clk = ~clk;

    initial begin
        // 1. Cấu hình xuất file VCD chứa dữ liệu chuyển mạch
        // Đổi tên file để không bị ghi đè lên file của bản Non-pipeline
        $dumpfile("tvla_2000_traces_pipeline.vcd");
        $dumpvars(0, tb_MatrixMult4x4_pipeline_tvla);

        // 2. Khởi tạo giá trị ban đầu
        clk = 0;
        rst = 0;
        start = 0;
        ma = 128'd0;
        mb = 128'd0;

        #100; 

        // 3. Reset hệ thống (Đồng bộ với sườn xuống)
        @(negedge clk);
        rst = 1;
        #20;
        @(negedge clk);
        rst = 0;

        $display("----------------------------------------");
        $display("BAT DAU CHAY 2000 TRACES (1000 FIXED, 1000 RANDOM) CHO PIPELINE...");

        // 4. VÒNG LẶP SINH DỮ LIỆU
        for (i = 0; i < 2000; i = i + 1) begin
            
            trace_type = i % 2; // i chẵn -> 0 (Fixed), i lẻ -> 1 (Random)

            if (trace_type == 0) begin
                // TẬP FIXED: Dữ liệu cố định
                ma = 128'h10_0f_0e_0d_0c_0b_0a_09_08_07_06_05_04_03_02_01;
                // Có thể giữ nguyên mb như cũ hoặc dùng 1 số fixed khác tùy kịch bản
                mb = 128'h02000000000200000000020000000002;
            end else begin
                // TẬP RANDOM: Dữ liệu ngẫu nhiên (Ghép trực tiếp 4 số 32-bit thành 128-bit)
                ma = {$random, $random, $random, $random};
                mb = {$random, $random, $random, $random};
            end

            // Kích hoạt tính toán (Đưa dữ liệu vào Stage 1 của Pipeline)
            @(negedge clk);
            start = 1;      
            @(negedge clk);
            start = 0;      

            // Chờ mạch báo hiệu tính toán xong
            // Lưu ý: Với Pipeline, lệnh wait này chỉ mất đúng 4 chu kỳ (40ns)
            wait (done == 1);

            // In tiến độ ra Tcl Console mỗi 100 traces
            if (i % 100 == 0) begin
                $display("Da chay xong %0d / 2000 traces...", i);
            end

            #50; 
        end

        $display("HOAN THANH TOAN BO MO PHONG PIPELINE!");
        $display("----------------------------------------");
        
        #100;
        $finish;
    end

endmodule