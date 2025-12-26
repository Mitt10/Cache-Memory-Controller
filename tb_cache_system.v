`timescale 1ns / 1ps
module tb_cache_system;

  // DUT inputs
  reg         clk;
  reg         rst;
  reg         cpu_read;
  reg         cpu_write;
  reg  [31:0] cpu_address;
  reg  [31:0] cpu_wdata;
  // DUT outputs
  wire [7:0]  cpu_data_out;
  wire        ready;

  // Instantiate the cache system
  cache_system uut (
    .clk(clk),
    .rst(rst),
    .cpu_read(cpu_read),
    .cpu_write(cpu_write),
    .cpu_address(cpu_address),
    .cpu_wdata(cpu_wdata),
    .cpu_data_out(cpu_data_out),
    .ready(ready)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Helper task for write
  task write(input [31:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      cpu_address = addr;
      cpu_wdata = data;
      cpu_write = 1;
      wait (ready);
      @(posedge clk);
      cpu_write = 0;
      $display("[Time %0t] WRITE @%h = %h", $time, addr, data);
    end
  endtask

  // Helper task for read
  task read(input [31:0] addr, input [7:0] expected);
    begin
      @(posedge clk);
      cpu_address = addr;
      cpu_read = 1;
      wait (ready);
      @(posedge clk);
      cpu_read = 0;
      $display("[Time %0t] READ  @%h -> %h (expected: %h)", 
               $time, addr, cpu_data_out, expected);
    end
  endtask

  // Test sequence
  initial begin
    // Reset and init
    rst = 1; cpu_read = 0; cpu_write = 0;
    cpu_address = 0; cpu_wdata = 0;
    #20; rst = 0; #10;

    // ---- 6 WRITE OPERATIONS ----
    write(32'h00000020, 32'hAAAAAAAA);  // expect: AA
    write(32'h00000040, 32'h55555555);  // expect: 55
    write(32'h00000060, 32'hCAFEC0FF);  // expect: FF
    write(32'h00000080, 32'h12345678);  // expect: 78
    write(32'h000000A0, 32'hBEEF0001);  // expect: 01
    write(32'h000000C0, 32'h00000000);  // expect: 00

    // Pause
    #20;

    // ---- 6 READ OPERATIONS ----
    read(32'h00000020, 8'hAA);
    read(32'h00000040, 8'h55);
    read(32'h00000060, 8'hFF);
    read(32'h00000080, 8'h78);
    read(32'h000000A0, 8'h01);
    read(32'h000000C0, 8'h00);

    #50;
    $finish;
  end

endmodule
