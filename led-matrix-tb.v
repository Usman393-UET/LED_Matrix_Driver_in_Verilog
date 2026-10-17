`timescale 1ns / 1ps

module led_matrix_driver_tb;

    // Inputs to the driver (turn into registers in the testbench)
    reg         clk;
    reg         rst_n;
    reg  [15:0] tx_data;
    reg         start;

    // Outputs from the driver (turn into wires in the testbench)
    wire        ready;
    wire        spi_clk;
    wire        spi_cs;
    wire        spi_din;

    // Instantiate (plug in) the Matrix Driver module
    led_matrix_driver uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .start(start),
        .ready(ready),
        .spi_clk(spi_clk),
        .spi_cs(spi_cs),
        .spi_din(spi_din)
    );

    // Generate a steady clock signal (toggles every 10ns = 50MHz clock)
    always #10 clk = ~clk;

    initial begin
        // Step 1: Initialize everything
        clk = 0;
        rst_n = 0;
        tx_data = 16'b0;
        start = 0;

        // Step 2: Hold Reset for a brief moment, then release it
        #40;
        rst_n = 1;
        #40;

        // Step 3: Load sample packet (Address: Row 4 = 0x04 | Data: Pattern = 0x55)
        // Combined 16-bit binary packet: 0000 0100 0101 0101
        tx_data = 16'h0455; 
        
        // Step 4: Pulse the start trigger "doorbell"
        start = 1;
        #20;
        start = 0; // Clear it so it doesn't re-trigger

        // Step 5: Wait for the hardware to finish marching out all 16 bits
        // We wait long enough for the transmission loop to execute fully
        #6000;

        // Stop the simulation
        $stop;
    end

endmodule