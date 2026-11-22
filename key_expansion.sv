//key_expansion.sv contains the logic for editing the key used for each of the 10 rounds of scrambling. 
module next_round_key(
    input  logic [127:0] key,
    input  logic [7:0]   rcon,
    output logic [127:0] next_key);


    //four S-boxes on bytes 13, 14, 15, 12
    logic [7:0] s13, s14, s15, s12;
    sbox b13 (.in(key[23:16]), .out(s13));   // byte 13
    sbox b14 (.in(key[15:8]),  .out(s14));   // byte 14
    sbox b15 (.in(key[7:0]),   .out(s15));   // byte 15
    sbox b12 (.in(key[31:24]), .out(s12));   // byte 12


    //t gets the concat of all s boxes
    logic [31:0] t;
    assign t = {rcon ^ s13, s14, s15, s12};


    //the four new columns
    logic [31:0] n0, n1, n2, n3;
    assign n0 = key[127:96] ^ t;
    assign n1 = key[95:64] ^ n0;
    assign n2 = key[63:32] ^ n1;
    assign n3 = key[31:0] ^ n2;

    assign next_key = {n0, n1, n2, n3};

endmodule


module key_expansion(
    input  logic [127:0] key,
    output logic [127:0] rk0, rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10);

    assign rk0 = key;

    next_round_key k1  (.key(rk0), .rcon(8'h01), .next_key(rk1));
    next_round_key k2  (.key(rk1), .rcon(8'h02), .next_key(rk2));
    next_round_key k3  (.key(rk2), .rcon(8'h04), .next_key(rk3));
    next_round_key k4  (.key(rk3), .rcon(8'h08), .next_key(rk4));
    next_round_key k5  (.key(rk4), .rcon(8'h10), .next_key(rk5));
    next_round_key k6  (.key(rk5), .rcon(8'h20), .next_key(rk6));
    next_round_key k7  (.key(rk6), .rcon(8'h40), .next_key(rk7));
    next_round_key k8  (.key(rk7), .rcon(8'h80), .next_key(rk8));
    next_round_key k9  (.key(rk8), .rcon(8'h1b), .next_key(rk9));
    next_round_key k10 (.key(rk9), .rcon(8'h36), .next_key(rk10));

endmodule
