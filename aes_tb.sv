// ============================================================================
// aes_tb.sv  -  testbench 
//
// Change the values in the "EDIT HERE" block (the professor's required
// block), rerun the simulation, and read the results in the console or the
// waveform window.
//
// ============================================================================
`timescale 1ns/1ps

module aes_tb();

    // ---- declarations ----
    logic [1:0] mode;
    logic [7:0] plaintext_input[0:15];
    logic [7:0] key[0:15];
    logic [7:0] ciphertext_input[0:15];
    logic [7:0] ciphertext_output[0:15];
    logic [7:0] plaintext_output[0:15];

    // expected results, so the testbench can say PASS/FAIL
    logic [127:0] expected_ciphertext, expected_plaintext;

    // ---- control signals ----
    logic clk, rst, start, busy;

    // ---- the byte arrays packed into 128-bit buses for aes_top ----
    // byte [0] goes on the left, same order as the C++ printed it
    logic [127:0] pt_bus, key_bus, ct_in_bus, ct_out_bus, pt_out_bus;

    assign pt_bus = {plaintext_input[0],  plaintext_input[1],  plaintext_input[2],  plaintext_input[3],
                     plaintext_input[4],  plaintext_input[5],  plaintext_input[6],  plaintext_input[7],
                     plaintext_input[8],  plaintext_input[9],  plaintext_input[10], plaintext_input[11],
                     plaintext_input[12], plaintext_input[13], plaintext_input[14], plaintext_input[15]};

    assign key_bus = {key[0],  key[1],  key[2],  key[3],  key[4],  key[5],  key[6],  key[7],
                      key[8],  key[9],  key[10], key[11], key[12], key[13], key[14], key[15]};

    assign ct_in_bus = {ciphertext_input[0],  ciphertext_input[1],  ciphertext_input[2],  ciphertext_input[3],
                        ciphertext_input[4],  ciphertext_input[5],  ciphertext_input[6],  ciphertext_input[7],
                        ciphertext_input[8],  ciphertext_input[9],  ciphertext_input[10], ciphertext_input[11],
                        ciphertext_input[12], ciphertext_input[13], ciphertext_input[14], ciphertext_input[15]};

    assign ciphertext_output[0]  = ct_out_bus[127:120];  assign plaintext_output[0]  = pt_out_bus[127:120];
    assign ciphertext_output[1]  = ct_out_bus[119:112];  assign plaintext_output[1]  = pt_out_bus[119:112];
    assign ciphertext_output[2]  = ct_out_bus[111:104];  assign plaintext_output[2]  = pt_out_bus[111:104];
    assign ciphertext_output[3]  = ct_out_bus[103:96];   assign plaintext_output[3]  = pt_out_bus[103:96];
    assign ciphertext_output[4]  = ct_out_bus[95:88];    assign plaintext_output[4]  = pt_out_bus[95:88];
    assign ciphertext_output[5]  = ct_out_bus[87:80];    assign plaintext_output[5]  = pt_out_bus[87:80];
    assign ciphertext_output[6]  = ct_out_bus[79:72];    assign plaintext_output[6]  = pt_out_bus[79:72];
    assign ciphertext_output[7]  = ct_out_bus[71:64];    assign plaintext_output[7]  = pt_out_bus[71:64];
    assign ciphertext_output[8]  = ct_out_bus[63:56];    assign plaintext_output[8]  = pt_out_bus[63:56];
    assign ciphertext_output[9]  = ct_out_bus[55:48];    assign plaintext_output[9]  = pt_out_bus[55:48];
    assign ciphertext_output[10] = ct_out_bus[47:40];    assign plaintext_output[10] = pt_out_bus[47:40];
    assign ciphertext_output[11] = ct_out_bus[39:32];    assign plaintext_output[11] = pt_out_bus[39:32];
    assign ciphertext_output[12] = ct_out_bus[31:24];    assign plaintext_output[12] = pt_out_bus[31:24];
    assign ciphertext_output[13] = ct_out_bus[23:16];    assign plaintext_output[13] = pt_out_bus[23:16];
    assign ciphertext_output[14] = ct_out_bus[15:8];     assign plaintext_output[14] = pt_out_bus[15:8];
    assign ciphertext_output[15] = ct_out_bus[7:0];      assign plaintext_output[15] = pt_out_bus[7:0];

    // ---- the design being tested ----
    aes_top dut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .plaintext_in(pt_bus),
        .key_in(key_bus),
        .ciphertext_in(ct_in_bus),
        .ciphertext_out(ct_out_bus),
        .plaintext_out(pt_out_bus),
        .busy(busy));







    // ---- 1 MHz clock: flips every 500 ns, so one clock = 1000 ns ----
    initial begin
        clk = 0;
        while (1)
            #500 clk = ~clk;
    end








    // if mode = 2'b00, plaintext_input is encoded into ciphertext_output
    // if mode = 2'b01, ciphertext_input is decoded into plaintext_output
    // if mode = 2'b1X, plaintext_input is encoded into ciphertext_output AND
    //                  ciphertext_input is decoded into plaintext_output
    
    
    
    
    
    
    
    
    initial begin
    
    
    
    
    
    
    
    
    
    
    
    
        // ============================ EDIT HERE ============================
        mode = 2'b00;
        plaintext_input[0]=8'h1;  plaintext_input[1]=8'h2;  plaintext_input[2]=8'h3;  plaintext_input[3]=8'h4;
        plaintext_input[4]=8'h5;  plaintext_input[5]=8'h6;  plaintext_input[6]=8'h7;  plaintext_input[7]=8'h8;
        plaintext_input[8]=8'h9;  plaintext_input[9]=8'hA;  plaintext_input[10]=8'hB; plaintext_input[11]=8'hC;
        plaintext_input[12]=8'hD; plaintext_input[13]=8'hE; plaintext_input[14]=8'hF; plaintext_input[15]=8'h10;
        key[0]=8'h1;  key[1]=8'h2;  key[2]=8'h3;  key[3]=8'h4;
        key[4]=8'h5;  key[5]=8'h6;  key[6]=8'h7;  key[7]=8'h8;
        key[8]=8'h9;  key[9]=8'hA;  key[10]=8'hB; key[11]=8'hC;
        key[12]=8'hD; key[13]=8'hE; key[14]=8'hF; key[15]=8'h10;
        // the encryption of the plaintext above, so modes 01 and 1X decode it back
        ciphertext_input[0]=8'h34;  ciphertext_input[1]=8'hc3;  ciphertext_input[2]=8'h3b;  ciphertext_input[3]=8'h7f;
        ciphertext_input[4]=8'h14;  ciphertext_input[5]=8'hfd;  ciphertext_input[6]=8'h53;  ciphertext_input[7]=8'hdc;
        ciphertext_input[8]=8'hea;  ciphertext_input[9]=8'h25;  ciphertext_input[10]=8'he0; ciphertext_input[11]=8'h1a;
        ciphertext_input[12]=8'h02; ciphertext_input[13]=8'he1; ciphertext_input[14]=8'h67; ciphertext_input[15]=8'h27;






        // what the outputs should be (get these from the C++ prototype)
        expected_ciphertext = 128'h34c33b7f14fd53dcea25e01a02e16727;
        expected_plaintext  = 128'h0102030405060708090a0b0c0d0e0f10;
        
 
        
        // ===================================================================
    end

    // ---- run it ----
    initial begin
        rst = 1;
        start = 0;

        #2000  rst = 0;        // hold reset for 2 clocks
        #1000  start = 1;      // START pulse, 1 clock long
        #1000  start = 0;
        #15000;                // the design needs 11 clocks; wait 15 to be safe

        $display("");
        $display("MODE              %b", mode);
        $display("KEY               %h", key_bus);

        if (mode == 2'b00 || mode[1]) begin
            $display("PLAINTEXT  in     %h", pt_bus);
            $display("CYPHERTEXT out    %h", ct_out_bus);
            if (ct_out_bus == expected_ciphertext)
                $display("  PASS encode");
            else
                $display("  FAIL encode, expected %h", expected_ciphertext);
        end

        if (mode == 2'b01 || mode[1]) begin
            $display("CYPHERTEXT in     %h", ct_in_bus);
            $display("PLAINTEXT  out    %h", pt_out_bus);
            if (pt_out_bus == expected_plaintext)
                $display("  PASS decode");
            else
                $display("  FAIL decode, expected %h", expected_plaintext);
        end

        $finish;
    end

endmodule
