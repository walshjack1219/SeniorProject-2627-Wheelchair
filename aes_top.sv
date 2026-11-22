// aes_top.sv  is the upper wireing connecting all functions to eachother and reading input modes

module aes_top(
    input  logic         clk,
    input  logic         rst,
    input  logic         start,
    input  logic [1:0]   mode,             // 00 encode, 01 decode, 1X both
    input  logic [127:0] plaintext_in,
    input  logic [127:0] key_in,
    input  logic [127:0] ciphertext_in,
    output logic [127:0] ciphertext_out,
    output logic [127:0] plaintext_out,
    output logic         busy);

    // 1. round keys
    // (key_in must stay the same while busy is high)
    logic [127:0] rk0, rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10;


    key_expansion u_keys(
        .key(key_in),
        .rk0(rk0), .rk1(rk1), .rk2(rk2), .rk3(rk3), .rk4(rk4), .rk5(rk5),
        .rk6(rk6), .rk7(rk7), .rk8(rk8), .rk9(rk9), .rk10(rk10));



    // 2. MODE
    logic do_encode, do_decode;
    assign do_encode = (mode == 2'b00) || mode[1];
    assign do_decode = (mode == 2'b01) || mode[1];
    logic enc_busy, dec_busy;


    aes_encrypt u_enc(
        .clk(clk),
        .rst(rst),
        .start(start && do_encode),
        .plaintext(plaintext_in),
        .rk0(rk0), .rk1(rk1), .rk2(rk2), .rk3(rk3), .rk4(rk4), .rk5(rk5),
        .rk6(rk6), .rk7(rk7), .rk8(rk8), .rk9(rk9), .rk10(rk10),
        .ciphertext(ciphertext_out),
        .busy(enc_busy));

    aes_decrypt u_dec(
        .clk(clk),
        .rst(rst),
        .start(start && do_decode),
        .ciphertext(ciphertext_in),
        .rk0(rk0), .rk1(rk1), .rk2(rk2), .rk3(rk3), .rk4(rk4), .rk5(rk5),
        .rk6(rk6), .rk7(rk7), .rk8(rk8), .rk9(rk9), .rk10(rk10),
        .plaintext(plaintext_out),
        .busy(dec_busy));


    // 3. BUSY
    assign busy = enc_busy || dec_busy;


endmodule
