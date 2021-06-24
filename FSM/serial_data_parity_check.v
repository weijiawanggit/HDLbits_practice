module top_module(
    input clk,
    input in,
    input reset,    // Synchronous reset
    output [7:0] out_byte,
    output done
    // output [7:0] state_wire
); //


    parameter  TCQ = 1;

    // Use FSM from Fsm_serial

    // New: Datapath to latch input bits.
    // declare the two states 
    parameter IDEL=8'd0, START=8'd1, WAIT=8'd2, ERROR=8'd3, PARITY=8'd4;
    parameter DATA0=8'd5, DATA1=8'd6, DATA2=8'd7, DATA3=8'd8, DATA4=8'd9, DATA5=8'd10, DATA6=8'd11, DATA7=8'd12;
    parameter PARITY1=8'd13, PARITY2=8'd14;

    reg [7:0] state;
    wire sum_data;
    
    // counter
   
    reg [8:0]cnt_8;
    reg en_cnt_8;
    reg end_cnt_8;
    reg full_cnt_8;
    reg reset_counter;
    reg lagger_cnt_8; // to record if the counter now is lagger than 8
    
    reg done_reg;
    reg reset_odd;
    
    reg [7:0] data_input_reg;

    //  count 8 clock cycle
    always@(posedge clk)
    begin
        //  synchronous reset
        if ( reset_counter==1 )       
            cnt_8 <=  #TCQ 9'd0;
        else if(end_cnt_8)     //2nd set
            cnt_8 <= #TCQ 9'd7;
        else if (en_cnt_8)
            cnt_8 <=  #TCQ cnt_8 + 1'd1;
        else
            cnt_8 <= #TCQ  9'd0;   
    end


    //end_cnt_8 flag circuit
    always@(posedge clk)
    begin
        //  synchronous reset
        if ( reset_counter==1 )  
        begin
            end_cnt_8 <= #TCQ 1'b0;
            lagger_cnt_8 <= #TCQ 1'b0;
        end
        else if (cnt_8 == (9'd7))
            begin
                end_cnt_8 <= #TCQ   1'b1;
                lagger_cnt_8 <= #TCQ  1'b0;
            end
        else if (cnt_8 >= (9'd7))
            begin
                end_cnt_8 <= #TCQ  1'b0;
                lagger_cnt_8 <= #TCQ  1'b1;
            end
                // different than lemmings, the end_cnt_8 only have one time for a high level.
                // in the WATI state, just judge if the cnt_8 have 8 clock cycle, otherwise, it is wrong transmission
                
       else
            begin
                lagger_cnt_8 <= #TCQ  1'b0;
                end_cnt_8 <= #TCQ 1'b0;
            end
    end
    
         
         
        always @(posedge clk) 
        begin
        // State flip-flops with synchronous reset
         if (reset==1)
                    begin
                        state <= #TCQ  IDEL;
                        done_reg <= #TCQ  0;
                        reset_counter <= #TCQ 1;
                        en_cnt_8 <= #TCQ 0;
                        data_input_reg <= 8'b0;
                    end
        else
            begin
                case(state)
                IDEL:   
                        begin
                            if (in==0)   // the start indication
                                begin
                                     state <= #TCQ  START;
                                     done_reg <= #TCQ  0;
                                     data_input_reg <=  8'b0;    // clear the data memory
                                     reset_odd <=#TCQ   0;   // disable the reset
                                     
                                
                                end                            
                            else
                                begin
                                     state <= #TCQ IDEL;
                                     done_reg <= #TCQ 0;
                                end

                        end

                START:   // collect the odd
                begin
                    state <= #TCQ  DATA0;
                    // start to collect the data in (1 bit)
                    data_input_reg <= {in,{data_input_reg[7:1]}};
                    done_reg <=#TCQ  0;
                end

                DATA0:
                begin
                    state <= #TCQ  DATA1;
                    // start to collect the data in (1 bit)
                    data_input_reg <= {in,{data_input_reg[7:1]}};
                    done_reg <=#TCQ  0;
                end
                DATA1:
                begin
                    state <= #TCQ  DATA2;
                    // start to collect the data in (1 bit)
                    data_input_reg <= {in,{data_input_reg[7:1]}};
                    done_reg <=#TCQ  0;
                end
                DATA2:
                begin
                    state <= #TCQ  DATA3;
                    // start to collect the data in (1 bit)
                    data_input_reg <= {in,{data_input_reg[7:1]}};
                    done_reg <=#TCQ  0;
                end
                DATA3:
                begin
                    state <= #TCQ  DATA4;
                    // start to collect the data in (1 bit)
                    data_input_reg <= {in,{data_input_reg[7:1]}};
                    done_reg <=#TCQ  0;
                end
                DATA4:
                begin
                    state <= #TCQ  DATA5;
                    // start to collect the data in (1 bit)
                    data_input_reg <= {in,{data_input_reg[7:1]}};
                    done_reg <=#TCQ  0;
                end

                DATA5:
                begin
                    state <= #TCQ  DATA6;
                    // start to collect the data in (1 bit)
                    data_input_reg <= {in,{data_input_reg[7:1]}};
                    done_reg <=#TCQ  0;
                end
                DATA6:
                begin
                    state <= #TCQ  DATA7;
                    // start to collect the data in (1 bit)
                    data_input_reg <= {in,{data_input_reg[7:1]}};
                    done_reg <=#TCQ  0;
                end
                DATA7:
                begin
                    // state <= #TCQ  PARITY;
                    if ((sum_data==0)&(in==1))
                        begin
                                state <= #TCQ  PARITY1;
                                done_reg <=#TCQ  0;
                                reset_odd <= #TCQ 1; 
                        end
                    else if ((sum_data==1)&(in==0))
                        begin
                                state <= #TCQ  PARITY2;
                                done_reg <=#TCQ  0;
                                reset_odd <= #TCQ 1; 
                        end
                    else 
                        begin
                                state <= #TCQ  ERROR;
                                done_reg <=#TCQ  0;
                                reset_odd <= #TCQ 1; 
                        end
                 end

                    // start to collect the data in (1 bit)
                    // data_input_reg <= {in,{data_input_reg[7:1]}};

                

                // WAIT:
                //       begin
                //             if ((in==1)&&(end_cnt_8==1))   // the end indication
                //                 begin
                //                      state <= #TCQ FINISH;     // the correct transmission
                //                      done_reg <= #TCQ 1;
                //                      reset_counter <= #TCQ 1;   // reset the counter
                //                      en_cnt_8 <= #TCQ 0;        // start the counter
                                
                //                 end                            
                //             else if (lagger_cnt_8==1)   // no matter the in is 0 or 1, the error happens, goes to the reset
                //                 begin
                //                      state <= #TCQ ERROR;
                //                      done_reg <= #TCQ 0;        // the wrong transmission
                //                      reset_counter <= #TCQ 1;   // disable the counter
                //                      en_cnt_8 <= #TCQ  0;   // disable the counter
                //                 end
                //             else
                //                 begin
                //                      state <= #TCQ  WAIT;
                //                      // start to collect the data in (1 bit)
                //                      data_input_reg <= {in,{data_input_reg[7:1]}};
                //                      done_reg <=#TCQ  0;
                //                      reset_counter <= #TCQ 0;   // disable the counter reset
                //                      en_cnt_8 <= #TCQ 1;        // start the counter
                //                 end    
                //         end  
                
                PARITY1:
                    begin
                            if (in==1)   // the start indication, directly go to the next stage for receiving new data
                                begin
                                     state <= #TCQ IDEL;
                                     done_reg <=#TCQ  1;
                                     // reset_odd <= #TCQ 0;   
                                end                            
                            else
                                begin
                                     state <= #TCQ ERROR;
                                     done_reg <=#TCQ 0;
                                     // reset_odd <=#TCQ  1;   // disable the counter
                                     
                                end
                    end

                        

                PARITY2:                      
                    begin
                            if (in==1)   // the start indication, directly go to the next stage for receiving new data
                                begin
                                     state <= #TCQ IDEL;
                                     done_reg <=#TCQ  1;
                                     // reset_odd <= #TCQ 0;   
                                     
                                
                                end                            
                            else
                                begin
                                     state <= #TCQ ERROR;
                                     done_reg <=#TCQ 0;
                                     // reset_odd <=#TCQ  1;   // disable the counter
                                     
                                end

                    end


                ERROR:
                      begin
                          if (in==1)   // the start indication
                                begin
                                     state <= #TCQ IDEL;
                                     done_reg <= #TCQ 0;
                                     // reset_odd <= #TCQ 0;   // start the counter
                                    
                                
                                end                            
                            else
                                begin
                                     state <= #TCQ ERROR;
                                     done_reg <= #TCQ 0;
                                     // reset_odd <= #TCQ  1;   // disable the counter
                                     
                                end

                        end    
                   default:
                            begin
                                    state <= IDEL;
                            end
                       
                        
                          
                 endcase
                
            end 

     end
    
    
    assign done = done_reg;
    assign out_byte = data_input_reg;
    
    assign sum_data = data_input_reg[0] + data_input_reg[1] + data_input_reg[2] + data_input_reg[3] + data_input_reg[4] + data_input_reg[5] + data_input_reg[6] + data_input_reg[7];
    
    // assign state_wire = state;
    
endmodule
