// aes_encrypt.sv is the Encoder half

//xtime: multiply a byte by 2 in AES math
module xtime(
    input  logic [7:0] a,
    output logic [7:0] out);
   //trunc'd contdional relplaces ifelse from our C++ code 
   assign out = (a[7]) ? ({a[6:0], 1'b0} ^ 8'h1b) : {a[6:0], 1'b0};

endmodule

// sub_bytes: run all 16 bytes through an S-box.
module sub_bytes(
    input  logic [127:0] in,
    output logic [127:0] out);

    sbox s0 (.in(in[127:120]), .out(out[127:120]));   // byte 0
    sbox s1 (.in(in[119:112]), .out(out[119:112]));   // byte 1
    sbox s2(.in(in[111:104]), .out(out[111:104]));  // byte 2
    sbox s3(.in(in[103:96]), .out(out[103:96]));  // byte 3
    sbox s4(.in(in[95:88]), .out(out[95:88]));  // byte 4
    sbox s5(.in(in[87:80]), .out(out[87:80]));  // byte 5
    sbox s6(.in(in[79:72]), .out(out[79:72]));  // byte 6
    sbox s7(.in(in[71:64]), .out(out[71:64]));  // byte 7
    sbox s8(.in(in[63:56]), .out(out[63:56]));  // byte 8
    sbox s9(.in(in[55:48]), .out(out[55:48]));  // byte 9
    sbox s10(.in(in[47:40]), .out(out[47:40]));  // byte 10
    sbox s11(.in(in[39:32]), .out(out[39:32]));  // byte 11
    sbox s12(.in(in[31:24]), .out(out[31:24]));  // byte 12
    sbox s13(.in(in[23:16]), .out(out[23:16]));  // byte 13
    sbox s14(.in(in[15:8]), .out(out[15:8]));  // byte 14
    sbox s15(.in(in[7:0]), .out(out[7:0]));  // byte 15
endmodule

//shift_rows: rotate row r left by r places.
//   output byte:  0  1  2  3   4  5  6  7   8  9 10 11  12 13 14 15
//   FROM:         0  5 10 15   4  9 14  3   8 13  2  7  12  1  6 11

module shift_rows(
    input  logic [127:0] in,
    output logic [127:0] out);
    assign out = { in[127:120], in[87:80], in[47:40], in[7:0],     
                   in[95:88], in[55:48], in[15:8], in[103:96], 
                   in[63:56], in[23:16], in[111:104], in[71:64],
                   in[31:24], in[119:112], in[79:72], in[39:32]};      
endmodule

//mix_one_column: mix ONE column (4 bytes a0..a3 -> b0..b3).
//   b0 = 2*a0 ^ 3*a1 ^   a2 ^   a3
//   b1 =   a0 ^ 2*a1 ^ 3*a2 ^   a3
//   b2 =   a0 ^   a1 ^ 2*a2 ^ 3*a3
//   b3 = 3*a0 ^   a1 ^   a2 ^ 2*a3
module mix_one_column(
    input  logic [31:0] col,
    output logic [31:0] out);

    // split the column into its 4 bytes (top byte = row 0)
    logic [7:0] a0, a1, a2, a3;
    assign a0 = col[31:24];
    assign a1 = col[23:16];
    assign a2 = col[15:8];
    assign a3 = col[7:0];

    // 2*a for each byte, using four copies of the xtime block
    logic [7:0] x0, x1, x2, x3;
    xtime t0 (.a(a0), .out(x0));
    xtime t1 (.a(a1), .out(x1));
    xtime t2 (.a(a2), .out(x2));
    xtime t3 (.a(a3), .out(x3));

    // TODO: write b0..b3 using a0..a3, x0..x3 and ^
    //   example: 3*a1 is (x1 ^ a1)
    logic [7:0] b0, b1, b2, b3;
    assign b0 = x0 ^ (x1 ^ a1) ^ a2 ^ a3;
    assign b1 = a0 ^ x1 ^ (x2 ^ a2) ^ a3; 
    assign b2 = a0 ^ a1 ^ x2 ^ (x3 ^ a3);
    assign b3 = (x0 ^ a0) ^ a1 ^ a2 ^ x3;

    assign out = {b0, b1, b2, b3};

endmodule

//mix_columns: four mix_one_column blocks, one per column 
module mix_columns(
    input  logic [127:0] in,
    output logic [127:0] out);

    mix_one_column c0 (.col(in[127:96]), .out(out[127:96]));
    mix_one_column c1 (.col(in[95:64]),  .out(out[95:64]));
    mix_one_column c2 (.col(in[63:32]),  .out(out[63:32]));
    mix_one_column c3 (.col(in[31:0]),   .out(out[31:0]));

endmodule

// aes_encrypt: one round of hardware, used 10 times
module aes_encrypt(
    input  logic         clk,
    input  logic         rst,          // active high
    input  logic         start,        // 1-clock pulse: begin
    input  logic [127:0] plaintext,
    input  logic [127:0] rk0, rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10,
    output logic [127:0] ciphertext,   // valid once busy goes back to 0
    output logic         busy);

    logic [127:0] state;          // the 4x4 grid, stored in flip-flops
    logic [3:0]   round;          // which round happens on the next clock

    // --- one round of logic ---
    logic [127:0] after_sub, after_shift, after_mix;
    sub_bytes   u_sub   (.in(state),       .out(after_sub));
    shift_rows  u_shift (.in(after_sub),   .out(after_shift));
    mix_columns u_mix   (.in(after_shift), .out(after_mix));

    // --- pick this round's key (a multiplexer) ---
    logic [127:0] round_key;
    always_comb
        case (round)
            4'd1:    round_key = rk1;
            4'd2:    round_key = rk2;
            4'd3:    round_key = rk3;
            4'd4:    round_key = rk4;
            4'd5:    round_key = rk5;
            4'd6:    round_key = rk6;
            4'd7:    round_key = rk7;
            4'd8:    round_key = rk8;
            4'd9:    round_key = rk9;
            4'd10:   round_key = rk10;
            default: round_key = rk0;
        endcase

    //round result defined with conditional that separates the logic 
    //that occurs on the first 9 and the skipped mixed on the 10th
    logic [127:0] round_result;
    assign round_result = (round == 4'd10) ? (after_shift ^ round_key) : (after_mix ^ round_key);

    //the register: save one round per clock
    always_ff @(posedge clk)
        if (rst) begin
            state <= 128'h0;
            round <= 4'd0;
            busy  <= 1'b0;
        end
        else if (start && !busy) begin
            state <= plaintext ^ rk0;      // round 0: just AddRoundKey
            round <= 4'd1;
            busy  <= 1'b1;
        end
        else if (busy) begin
            state <= round_result;
            round <= round + 4'd1;
            if (round == 4'd10)
                busy <= 1'b0;              // that was the last round
        end

    assign ciphertext = state;
endmodule
