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
                    // Do nothing, wait for reset
                end
            endcase
        end
    end
endmodule

/*module accelerator (
    input reset,
    input clk,
    input start,
    input [130:0] A,    // 131-bit input A
    input [127:0] B,    // 128-bit input B
    output [258:0] result // Output result (263-bit)
);

    // Define the padded versions of A and B
    logic [131:0] A_Buffered, B_Buffered;
    
    // Define the halves of the padded inputs
    logic [65:0] A_low, A_high, B_low, B_high;
    logic [66:0] A_sum, B_sum;
    logic [131:0] z0, z2;
    logic [133:0] z1;
    
    logic [258:0] z2_shifted;
    logic [133:0] z1_subtracted;
    logic [197:0] z1_shifted;
    logic [258:0] result_temp;
    
    localparam IDLE = 4'd0;
    localparam START = 4'd1;
    localparam BUFFER = 4'd2;
    localparam SPLIT = 4'd3;
    localparam FIRST_ADD = 4'd4;
    localparam MULT = 4'd5;
    localparam Z2_SHIFT = 4'd6;
    localparam Z1_SUB = 4'd7;
    localparam Z1_SHIFT = 4'd8;
    localparam SECOND_ADD = 4'd9;
    localparam DONE = 4'd10;
    
    logic [3:0] current_state, next_state;
    
    always_ff@(posedge clk or posedge reset) begin
      if(reset) begin
        current_state <= IDLE;
      end
      else begin
        current_state <= next_state;
      end
    end
    
    
    always_comb begin
    
      next_state = current_state;
    
      case(current_state)
      
        IDLE: begin
          if(start) begin
            next_state = START;
          end else begin
            next_state = IDLE;
          end
        end
          
        START: begin
          next_state = BUFFER;
        end
        
        BUFFER: begin
          next_state = SPLIT;
        end
        
        SPLIT: begin
          next_state = FIRST_ADD;
        end
        
        FIRST_ADD: begin
          next_state = MULT;
        end
        
        MULT: begin
          next_state = Z2_SHIFT;
        end
        
        Z2_SHIFT: begin
          next_state = Z1_SUB;
        end
        
        Z1_SUB: begin
          next_state = Z1_SHIFT;
        end
        
        Z1_SHIFT: begin
          next_state = SECOND_ADD;
        end
        
        SECOND_ADD: begin
          next_state = DONE;
        end
        
        DONE: begin
          next_state = IDLE;
        end
        
        default: begin
          next_state = IDLE;
        end
                    
      endcase
    end
    
    
    always_ff@(posedge clk or posedge reset) begin
      if(reset) begin
        A_Buffered <= 132'b0;
        B_Buffered <= 132'b0;
        
        A_low <= 66'b0;
        A_high <= 66'b0;
        B_low <= 66'b0;
        B_high <= 66'b0;
        
        A_sum <= 67'b0;
        B_sum <= 67'b0;
        
        z0 <= 132'b0;
        z2 <= 132'b0;
        z1 <= 134'b0;
        
        z2_shifted <= 259'b0;
        z1_subtracted <= 134'b0;
        z1_shifted <= 198'b0;
        result_temp <= 259'b0;
      end
      else begin
        case(current_state)
        
          BUFFER: begin
            //Pad A and B up to 132 bits
            A_Buffered <= {1'b0, A};
            B_Buffered <= {4'b0, B};
          end
          
          SPLIT: begin
            // Split A and B into high and low parts
            A_low <= A_Buffered[65:0];
            A_high <= A_Buffered[131:66];
            B_low <= B_Buffered[65:0];
            B_high <= B_Buffered[131:66];
          end
          
          FIRST_ADD: begin
            // Sum of parts of A and B
            A_sum <= A_low + A_high;
            B_sum <= B_low + B_high;
          end
          
          MULT: begin
            // Compute intermediate products
            z0 <= A_low * B_low;                   // Low part product
            z2 <= A_high * B_high;                 // High part product
            z1 <= A_sum * B_sum;
          end
          
          Z2_SHIFT: begin
            z2_shifted <= {127'b0, z2} << 127;
          end
          
          Z1_SUB: begin
            z1_subtracted <= z1 - {2'b0, z2} - {2'b0, z0};
          end
          
          Z1_SHIFT: begin
            z1_shifted <= {64'b0, z1_subtracted} << 64;
          end
          
          SECOND_ADD: begin
            result_temp <= z2_shifted + {61'b0, z1_shifted} + {127'b0, z0};
          end
          
          default: begin
            //don't do anything
          end
        
        endcase
      end //else end (not reset)
    end //end always_ff
    
    assign result = result_temp;


endmodule*/
