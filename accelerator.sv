module accelerator (
    input clk,
    input rst_n,
    input start,
    input [130:0] A,  // 131-bit input A
    input [127:0] B,  // 128-bit input B
    output reg [258:0] P,  // 259-bit output P
    output reg ready
);

    
    logic [65:0] A_low;
    logic [64:0] A_high;
    logic [63:0] B_low, B_high;
    
    reg [258:0] partial_sum;  // Accumulated partial product sum
    reg [258:0] partial_product;  // Intermediate partial product

    reg [1:0] state; // State counter (0 to 3)
    reg [1:0] step;  // Step index for partial products

    
    //wire [129:0] mult_result;  // Result of a 66x66 multiplication
    wire [129:0] mult_result_Alow_Blow;
    wire [129:0] mult_result_Alow_Bhigh;
    wire [128:0] mult_result_Ahigh_Blow;
    wire [128:0] mult_result_Ahigh_Bhigh;
    
    //reg [65:0] mult_a, mult_b;

    //assign mult_result_65 = mult_a * mult_b;
    assign mult_result_Alow_Blow = A_low * B_low;
    assign mult_result_Alow_Bhigh = A_low * B_high;
    assign mult_result_Ahigh_Blow = A_high * B_low;
    assign mult_result_Ahigh_Bhigh = A_high * B_high;

    // Split inputs into high and low parts (66 bits each)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_low <= 0;
            A_high <= 0;
            B_low <= 0;
            B_high <= 0;
        end else if (start) begin
            A_low <= A[65:0];  // A[65:0] is the lower 66 bits of A
            A_high <= A[130:66];  // A[130:66] is the higher 65 bits of A
            B_low <= B[63:0];  // B[63:0] is the lower 64 bits of B
            B_high <= B[127:64];  // B[127:64] is the higher 64 bits of B
        end
    end

    // Control logic for multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            step <= 0;
            partial_sum <= 0;
            partial_product <= 0;
            ready <= 0;
        end else if (start) begin
            state <= 0;
            step <= 0;
            partial_sum <= 0;
            partial_product <= 0;
            ready <= 0;
        end else begin
            case (state)
                0: begin
                    // Select operands based on the current step
                    /*case (step)
                        2'b00: begin mult_a <= A_low;  mult_b <= B_low;  end // A_low * B_low
                        2'b01: begin mult_a <= A_low;  mult_b <= B_high; end // A_low * B_high
                        2'b10: begin mult_a <= A_high; mult_b <= B_low;  end // A_high * B_low
                        2'b11: begin mult_a <= A_high; mult_b <= B_high; end // A_high * B_high
                    endcase */
                    state <= 1;
                end

                1: begin
                    // Wait for the multiplication result
                    case(step)
                      2'b00: partial_product <= {129'b0, mult_result_Alow_Blow};
                      2'b01: partial_product <= {129'b0, mult_result_Alow_Bhigh};
                      2'b10: partial_product <= {130'b0, mult_result_Ahigh_Blow};
                      2'b11: partial_product <= {130'b0, mult_result_Ahigh_Bhigh};
                    endcase
                    //partial_product <= {129'b0, mult_result};
                    state <= 2;
                end

                2: begin
                    // Accumulate the result with appropriate shift
                    case (step)
                        2'b00: partial_sum <= partial_sum + partial_product;  // A_low * B_low
                        2'b01: partial_sum <= partial_sum + (partial_product << 64);  // A_low * B_high
                        2'b10: partial_sum <= partial_sum + (partial_product << 64);  // A_high * B_low
                        2'b11: partial_sum <= partial_sum + (partial_product << 128);  // A_high * B_high
                    endcase

                    step <= step + 1;
                    if (step == 2'b11) begin
                        P <= partial_sum;
                        ready <= 1;
                        state <= 3; // Done
                    end else begin
                        state <= 0; // Process next step
                    end
                end

                3: begin
                  ready <= 0;
                    // Do nothing, wait for reset
                end
            endcase
        end
    end
endmodule
