module led_matrix_driver (
    input  wire        clk,        // System Clock from your testbench
    input  wire        rst_n,      // Active-low Reset
    input  wire [15:0] tx_data,    // The 16-bit packet (Address + Data)
    input  wire        start,      // Trigger signal to kick off transmission
    
    output reg         ready,      // High when resting, Low when busy
    output reg         spi_clk,    // Clock line to the matrix
    output reg         spi_cs,     // Chip Select line (Active Low)
    output reg         spi_din     // Serial Data line
);

    // State Machine States
    localparam STATE_IDLE      = 2'b00;
    localparam STATE_LOAD      = 2'b01;
    localparam STATE_TRANSMIT  = 2'b10;
    localparam STATE_LATCH     = 2'b11;

    reg [1:0]  current_state, next_state;
    reg [15:0] shift_reg;
    reg [4:0]  bit_counter;   // Counts up to 16 bits
    reg [3:0]  clk_divider;   // Small divider to make the SPI clock visible in simulation

    // 1. State Transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= STATE_IDLE;
        else        current_state <= next_state;
    end

    // 2. Next State Logic Checklist
    always @(*) begin
        case (current_state)
            STATE_IDLE:     next_state = (start) ? STATE_LOAD : STATE_IDLE;
            STATE_LOAD:     next_state = STATE_TRANSMIT;
            STATE_TRANSMIT: next_state = (bit_counter == 16 && clk_divider == 4'd15) ? STATE_LATCH : STATE_TRANSMIT;
            STATE_LATCH:    next_state = STATE_IDLE;
            default:        next_state = STATE_IDLE;
        endcase
    end

    // 3. Shifting and Pin Output Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b1; spi_cs <= 1'b1; spi_clk <= 1'b0; spi_din <= 1'b0;
            bit_counter <= 0; clk_divider <= 0;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    ready   <= 1'b1;
                    spi_cs  <= 1'b1;
                    spi_clk <= 1'b0;
                    bit_counter <= 0;
                end
                
                STATE_LOAD: begin
                    ready       <= 1'b0;
                    spi_cs      <= 1'b0;       // Pull CS Low to alert the matrix
                    shift_reg   <= tx_data;    // Load the 16-bit packet into shift register
                    bit_counter <= 0;
                    clk_divider <= 0;
                end
                
                STATE_TRANSMIT: begin
                    clk_divider <= clk_divider + 1;
                    spi_din     <= shift_reg[15]; // Always send out the leftmost bit
                    
                    // Generate SPI Clock toggle based on our divider
                    if (clk_divider == 4'd7) begin
                        spi_clk <= 1'b1;       // Rising edge
                    end else if (clk_divider == 4'd15) begin
                        spi_clk   <= 1'b0;     // Falling edge
                        shift_reg <= {shift_reg[14:0], 1'b0}; // Slide bits LEFT
                        bit_counter <= bit_counter + 1; // Increment bit count
                        clk_divider <= 0;
                    end
                end
                
                STATE_LATCH: begin
                    spi_cs <= 1'b1;            // Pull CS High to lock data into the display
                    ready  <= 1'b0;
                end
            endcase
        end
    end
endmodule