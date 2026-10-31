`timescale 1ns/1ps

module tb_ahb2apb_bridge;

    reg HCLK;
    reg HRESETn;
    reg HSEL;
    reg [31:0] HADDR;
    reg [1:0] HTRANS;
    reg HWRITE;
    reg [2:0] HSIZE;
    reg [3:0] HPROT;
    reg [31:0] HWDATA;

    wire [31:0] HRDATA;
    wire HREADY;

    wire PCLK;
    wire PRESETn;
    wire PSEL;
    wire [31:0] PADDR;
    wire PENABLE;
    wire PWRITE;
    wire [31:0] PWDATA;

    reg [31:0] PRDATA;
    reg PREADY;
    reg PSLVERR;

    // APB memory model
    reg [31:0] mem [0:255];

    integer i;

    ahb2apb_bridge dut (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HSEL(HSEL),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HPROT(HPROT),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PADDR(PADDR),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    // Clock generation
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end

    // APB peripheral model
    always @(*) begin
        PRDATA = mem[PADDR[9:2]];
        PREADY = 1'b1;
    end

    // Write operation
    always @(posedge PCLK) begin
        if (PRESETn && PSEL && PENABLE && PREADY && PWRITE)
            mem[PADDR[9:2]] <= PWDATA;
    end

    // AHB transfer task
    task start_transfer;
        input [31:0] address;
        input write;
        input [31:0] write_data;

        begin
            @(negedge HCLK);

            while (HREADY !== 1'b1)
                @(negedge HCLK);

            HSEL   = 1'b1;
            HADDR  = address;
            HWRITE = write;
            HTRANS = 2'b10;

            @(negedge HCLK);

            HSEL   = 1'b0;
            HTRANS = 2'b00;
            HWDATA = write_data;

            while (HREADY !== 1'b1)
                @(negedge HCLK);

            @(negedge HCLK);
            HWDATA = 32'b0;
        end
    endtask

    // Test sequence
    initial begin

        HRESETn = 0;
        HSEL    = 0;
        HADDR   = 0;
        HTRANS  = 0;
        HWRITE  = 0;
        HSIZE   = 3'b010;
        HPROT   = 0;
        HWDATA  = 0;
        PSLVERR = 0;

        for (i = 0; i < 256; i = i + 1)
            mem[i] = 0;

        repeat (2) @(negedge HCLK);
        HRESETn = 1;

        // Write transaction
        start_transfer(
            32'h00001000,
            1'b1,
            32'hDEADBEEF
        );

        // Read transaction
        start_transfer(
            32'h00001000,
            1'b0,
            32'b0
        );

        // Check read data
        if (HRDATA === 32'hDEADBEEF)
            $display("PASS: Read data matches 0xDEADBEEF");
        else
            $display("FAIL: Expected 0xDEADBEEF, received %h", HRDATA);

        #10;
        $finish;

    end

endmodule
