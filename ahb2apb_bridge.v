// Simplified AHB-Lite to APB Bridge
// Educational implementation

module ahb2apb_bridge (
    // AHB interface
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [3:0]  HPROT,
    input  wire [31:0] HWDATA,
    output wire [31:0] HRDATA,
    output wire        HREADY,

    // APB interface
    output wire        PCLK,
    output wire        PRESETn,
    output wire        PSEL,
    output reg  [31:0] PADDR,
    output wire        PENABLE,
    output reg         PWRITE,
    output reg  [31:0] PWDATA,
    input  wire [31:0] PRDATA,
    input  wire        PREADY,
    input  wire        PSLVERR
);

    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    reg [1:0] state, next_state;

    assign PCLK    = HCLK;
    assign PRESETn = HRESETn;

    assign HREADY  = (state == IDLE) ||
                     ((state == ACCESS) && PREADY);

    assign PSEL    = (state == SETUP) || (state == ACCESS);
    assign PENABLE = (state == ACCESS);

    assign HRDATA = PRDATA;

    // State register
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        next_state = state;

        case (state)

            IDLE: begin
                if (HSEL && HTRANS[1] && HREADY)
                    next_state = SETUP;
            end

            SETUP: begin
                next_state = ACCESS;
            end

            ACCESS: begin
                if (PREADY)
                    next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    // Address and data registers
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            PADDR  <= 32'b0;
            PWRITE <= 1'b0;
            PWDATA <= 32'b0;
        end
        else begin

            if (state == IDLE && HSEL && HTRANS[1] && HREADY) begin
                PADDR  <= HADDR;
                PWRITE <= HWRITE;
            end

            if (state == SETUP) begin
                PWDATA <= HWDATA;
            end

        end
    end

endmodule
