`include "lab3_inc.sv"

// Pick your poison

parameter bg_color = BLACK;
parameter puck_color = PURPLE;
parameter paddle_color = WHITE;
parameter border_color = YELLOW;

/////////////////////////////////////////////////////////////////////////
//
//  This file is the starting point for Lab 3.  This design implements
//  a simple pong game, with a paddle at the bottom and one ball that
//  bounces around the screen.  When downloaded to an FPGA board,
//  KEY(0) will move the paddle to right, and KEY(1) will move the
//  paddle to the left.  KEY(3) will reset the game.  If the ball drops
//  below the bottom of the screen without hitting the paddle, the game
//  will reset.
//
//  This is written in a combined datapath/state machine style as
//  discussed in the second half of Slide Set 7. It looks like a
//  state machine, but the datapath operations that will be performed
//  in each state are described within the corresponding WHEN clause
//  of the state machine.  From this style, Quartus II will be able to
//  extract the state machine from the design.
//
//  In Lab 3, you will modify this file as described in the handout.
//
//  This file makes extensive use of types and constants described in
//  lab3_inc.v   Be sure to read and understand that file before
//  trying to understand this one.
//
////////////////////////////////////////////////////////////////////////

// Entity part of the description.  Describes inputs and outputs

module lab3(input logic CLOCK_50, input logic [3:0] KEY, input logic [7:0] SW,
            output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
            output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
            output logic [9:0] LEDR,
            output logic [9:0] VGA_R, output logic [9:0] VGA_G, output logic [9:0] VGA_B,
            output logic VGA_HS, output logic VGA_VS,
            output logic VGA_BLANK, output logic VGA_SYNC, output logic VGA_CLK);

// These are signals that will be connected to the VGA adapater.
// The VGA adapater was described in the Lab 2 handout.

reg resetn;
wire [7:0] x;
wire [6:0] y;
reg [2:0] colour;
reg plot;

point draw;

// The state of our state machine
draw_state_type state;

// This variable will store the x position of the paddle (left-most pixel of the paddle)
reg [DATA_WIDTH_COORD-1:0] paddle_x;
reg [DATA_WIDTH_COORD-1:0] paddle2_x;

// second ball flag
reg ball2_flag;

// counter to shrink paddle
integer paddle_counter = 0;  

// amount of cycles for counter (last number indicates seconds between shrinkages)
parameter shrink_time = 50000000 * 20;

// variable to hold temporary value of paddle length
reg [DATA_WIDTH_COORD-1:0] paddle_length;

// These variables will store the puck and the puck velocity.
// In this implementation, the puck velocity has two components: an x component
// and a y component.  Each component is always +1 or -1.

// "point" and "velocity" are structures which help declare the required x and y coords 
// See lab3_inc.sv (21)

pointy puck;
pointy puck2; 

// "puck_velocity.xy" represents the next pixel coordinate of the puck

velocity puck_velocity;
velocity puck_velocity2;

// This will be used as a counter variable in the IDLE state

integer clock_counter = 0;

// Be sure to see all the constants, types, etc. defined in lab3_inc.h

// include the VGA controller structurally.  The VGA controller
// was decribed in Lab 2.  You probably know it in great detail now, but
// if you have forgotten, please go back and review the description of the
// VGA controller in Lab 2 before trying to do this lab.

vga_adapter #( .RESOLUTION("160x120")) vga_u0(.resetn(KEY[3]), .clock(CLOCK_50), .*);

// the x and y lines of the VGA controller will be always
// driven by draw.x and draw.y. The process below will update
// signals draw.x and draw.y.

assign x = draw.x[7:0];
assign y = draw.y[6:0];

// =============================================================================
// This is the main loop. As described above, it is written in a combined
// state machine / datapath style.  It looks like a state machine, but rather
// than simply driving control signals in each state, the description describes
// the datapath operations that happen in each state.  From this Quartus II
// will figure out a suitable datapath for you.

// Notice that this is written as a pattern-3 process (se quential with an
// asynchronous reset)

always_ff @(posedge CLOCK_50, negedge KEY[3]) begin

   // first see if the reset button has been pressed.  If so, we need to
   // reset to state INIT

   if (KEY[3] == 1'b0) begin
      draw.x <= 0;
      draw.y <= 0;
      paddle_x <= PADDLE_X_START[DATA_WIDTH_COORD-1:0];
      paddle2_x <= PADDLE_X_START[DATA_WIDTH_COORD-1:0];

      // Puck 1
      puck.x[15:8] <= FACEOFF_X[DATA_WIDTH_COORD-1:0];
      puck.y[15:8] <= FACEOFF_Y[DATA_WIDTH_COORD-1:0];
      puck_velocity.x <= VELOCITY_START_X;
      puck_velocity.y <= VELOCITY_START_Y;

      // Puck 2 
      puck2.x[15:8] <= FACEOFF_X_2[DATA_WIDTH_COORD-1:0];
      puck2.y[15:8] <= FACEOFF_Y[DATA_WIDTH_COORD-1:0];
      puck_velocity2.x <= VELOCITY_START_X_2;
      puck_velocity2.y <= VELOCITY_START_Y_2;

      // Player may choose to play with 2 pucks
      if (SW[0] == 1) 
        ball2_flag <= 1;
      else
        ball2_flag <= 0;

      colour <= bg_color;
      plot <= 1'b1;
      state <= INIT;

    // Otherwise, we are here because of a rising clock edge.  This follows
    // the standard pattern for a type-3 process we saw in the lecture slides.

    end else begin

      case (state)

         // ============================================================
         // The INIT state sets the variables to their default values
         // ============================================================

          INIT : begin
            draw.x <= 0;
            draw.y <= 0;

            // Puck 1
            puck.x[15:8] <= FACEOFF_X[DATA_WIDTH_COORD-1:0];
            puck.y[15:8] <= FACEOFF_Y[DATA_WIDTH_COORD-1:0];
            puck_velocity.x <= VELOCITY_START_X;
            puck_velocity.y <= VELOCITY_START_Y;

            // Puck 2 
            puck2.x[15:8] <= FACEOFF_X_2[DATA_WIDTH_COORD-1:0];
            puck2.y[15:8] <= FACEOFF_Y[DATA_WIDTH_COORD-1:0];
            puck_velocity2.x <= VELOCITY_START_X_2;
            puck_velocity2.y <= VELOCITY_START_Y_2;

            // Player may choose to play with 2 pucks
            if (SW[0] == 1)
              ball2_flag = 1;
            else
              ball2_flag = 0;

            // Player may choose initial paddle position
            if (SW[1] == 1) begin
            
              // enable selection of paddle position
              if (SW[2] == 0) begin
            
                // place paddle on left
                paddle_x <= LEFT_LINE + 1;
                paddle2_x <= LEFT_LINE + 1;

              end else begin
                // place paddle on right
                paddle_x <= ((RIGHT_LINE - paddle_length) - 1);
                paddle2_x <= ((RIGHT_LINE - paddle_length) - 1);
            
              end   // else
            
            // if SW1 is low

            end else begin
              paddle_x <= PADDLE_X_START;
              paddle2_x <= PADDLE_X_START;
            end //  else

            colour <= bg_color;
            plot <= 1'b1;
            state <= START;
           end    // case INIT

      // ============================================================
      // the START state is used to clear the screen.  We will spend many cycles
      // in this state, because only one pixel can be updated each cycle.  The
      // counters in draw.x and draw.y will be used to keep track of which pixel
      // we are erasing.
      // ============================================================

      // The START state clears the screen every cycle, and re-draws the puck and paddle in 
      // a new or same position.

         START: begin

           // See if we are done erasing the screen
            if (draw.x == SCREEN_WIDTH-1) begin
              if (draw.y == SCREEN_HEIGHT-1) begin

         // We are done erasing the screen.

                state <= DRAW_RIGHT_ENTER;

                end else begin

         // In this cycle we will be erasing a pixel.  Update
         // draw.y so that next time it will erase the next pixel

                draw.y <= draw.y + 1'b1;
      			    draw.x <= 1'b0;
                end  // else
              end else begin

               // Update draw.x so next time it will erase the next pixel

               draw.x <= draw.x + 1'b1;

            end // if
            end // case START

      // ============================================================
      // The DRAW_TOP_ENTER state draws the first pixel of the bar on
      // the top of the screen.  The machine only stays here for
      // one cycle; the next cycle it is in DRAW_TOP_LOOP to draw the
      // rest of the bar.
      // ============================================================

      DRAW_TOP_ENTER: begin

      // Position x and y on the top left corner

      draw.x <= LEFT_LINE[DATA_WIDTH_COORD-1:0];
      draw.y <= TOP_LINE[DATA_WIDTH_COORD-1:0];

      // Set color for the top border

      colour <= border_color;

      // Move to next state

      state <= DRAW_TOP_LOOP;
      end // case DRAW_TOP_ENTER

      // ============================================================
      // The DRAW_TOP_LOOP state is used to draw the rest of the bar on
      // the top of the screen.
      // Since we can only update one pixel per cycle,
      // this will take multiple cycles
      // ============================================================

      DRAW_TOP_LOOP: begin

        // See if we have been in this state long enough to have completed the line

        if (draw.x == RIGHT_LINE) begin

        // if so, the next state is DRAW_RIGHT_ENTER

          state <= DRAW_RIGHT_ENTER;

        end else begin

        // Otherwise, update draw.x to point to the next pixel
          
          draw.y <= TOP_LINE[DATA_WIDTH_COORD-1:0];
          draw.x <= draw.x + 1'b1;

        // Do not change the state, since we want to come back at the next 
        // rising clocK edge to finish drawing the line.

        end
        end //case DRAW_TOP_LOOP
      // ============================================================
      // The DRAW_RIGHT_ENTER state draws the first pixel of the bar on
      // the right-side of the screen.  The machine only stays here for
      // one cycle; the next cycle it is in DRAW_RIGHT_LOOP to draw the
      // rest of the bar.
      // ============================================================

      DRAW_RIGHT_ENTER: begin

      // Set position to top right

      draw.x <= RIGHT_LINE[DATA_WIDTH_COORD-1:0];
      draw.y <= TOP_LINE[DATA_WIDTH_COORD-1:0] - 3;

      colour <= border_color;
      
      // Move to next state
      
      state <= DRAW_RIGHT_LOOP;
      end // case DRAW_RIGHT_ENTER

      // =================================================================
      // The DRAW_RIGHT_LOOP state is used to draw the rest of the bar on
      // the right side of the screen.
      // Since we can only update one pixel per cycle, this will take 
      // multiple cycles
      // =================================================================

      DRAW_RIGHT_LOOP: begin

      // See if we have been in this state long enough to have completed the line
       	  if (draw.y == SCREEN_HEIGHT-1) begin

      // We are done, so the next state is DRAW_LEFT_ENTER

              state <= DRAW_LEFT_ENTER;
            end else begin

      // Otherwise, update draw.y to point to the next pixel

              draw.x <= RIGHT_LINE[DATA_WIDTH_COORD-1:0];
              draw.y <= draw.y + 1'b1;
            end
           end //case DRAW_RIGHT_LOOP
      // ============================================================
      // The DRAW_LEFT_ENTER state draws the first pixel of the bar on
      // the left-side of the screen.  The machine only stays here for
      // one cycle; the next cycle it is in DRAW_LEFT_LOOP to draw the
      // rest of the bar.
      // ============================================================

      DRAW_LEFT_ENTER: begin

      // Set pixel to the top left

      draw.x <= LEFT_LINE[DATA_WIDTH_COORD-1:0];
      draw.y <= TOP_LINE[DATA_WIDTH_COORD-1:0] - 3;

      // Next state!

      state <= DRAW_LEFT_LOOP;
      end // case DRAW_LEFT_ENTER

      // ================================================================
      // The DRAW_LEFT_LOOP state is used to draw the rest of the bar on
      // the left side of the screen.
      // Since we can only update one pixel per cycle,
      // this will take multiple cycles.
      // ================================================================

      DRAW_LEFT_LOOP: begin

      // See if we have been in this state long enough to have completed the line
          if (draw.y == SCREEN_HEIGHT-1) begin

          // We are done, so get things set up for the IDLE state, which
          // comes next.

            state <= IDLE;
            clock_counter <= 0;  // initialize counter we will use in IDLE

            end else begin

      // Otherwise, update draw.y to point to the next pixel
              draw.x <= LEFT_LINE[DATA_WIDTH_COORD-1:0];
              draw.y <= draw.y + 1'b1;
            end
           end //case DRAW_LEFT_LOOP


      // ==============================================================================
      // The IDLE state is basically a delay state.  If we didn't have this,
      // we'd be updating the puck location and paddle far too quickly for the
      // the user. So, this state delays for 1/8 of a second.  Once the delay is
      // done, we can go to state ERASE_PADDLE.  Note that we do not try to
      // delay using any sort of wait statement: that won't work (not synthesziable).
      // We have to build a COUNTER to count a certain number of clock cycles.
      // ==============================================================================

        IDLE: begin

          // See if we are still counting.  LOOP_SPEED indicates the maximum
          // value of the counter

          plot <= 1'b0;  // nothing to draw while we are in this state

          if (clock_counter < LOOP_SPEED) begin
            
            clock_counter <= clock_counter + 1'b1;
          
          end else begin

         // otherwise, we are done counting.  So get ready for the
         // next state which is ERASE_PADDLE_ENTER

              clock_counter <= 0;
              state <= ERASE_PADDLE_ENTER;

          end  // if
          end // case IDLE

      // ============================================================
      // In the ERASE_PADDLE_ENTER state, we will erase the first pixel of
      // the paddle. We will only stay here one cycle; the next cycle we will
      // be in ERASE_PADDLE_LOOP which will erase the rest of the pixels
      // ============================================================

      ERASE_PADDLE_ENTER: begin

        draw.y <= PADDLE_ROW[DATA_WIDTH_COORD-1:0];
        draw.x <= paddle_x;

        // Choose background color
        colour <= bg_color;

        plot <= 1'b1;
        state <= ERASE_PADDLE_LOOP;
     end // case ERASE_PADDLE_ENTER

      // ============================================================================
      // In the ERASE_PADDLE_LOOP state, we will erase the rest of the paddle.
      // Since the paddle consists of multiple pixels, we will stay in this state for
      // multiple cycles. draw.x will be used as the counter variable that
      // cycles through the pixels that make up the paddle.
      // ===========================================================================

      ERASE_PADDLE_LOOP: begin

        // See if we are done erasing the paddle (done with this state)
       
        if ((draw.x == paddle_x + paddle_length) & 
            (paddle_x == RIGHT_LINE - paddle_length - 1'b1) ) begin     
          
          state <= DRAW_PADDLE_ENTER;  // next state is DRAW_PADDLE_ENTER

        end else if (draw.x == paddle_x + paddle_length + 1'b1) begin

          state <= DRAW_PADDLE_ENTER;
        
        end else begin

          // We are not done erasing the paddle. Erase the pixel and update
          // draw.x by increasing it by 1

          draw.y <= PADDLE_ROW[DATA_WIDTH_COORD-1:0];
          draw.x <= draw.x + 1'b1;

          // State stays the same, since we want to come back to this state
          // next time through the process (next rising clock edge) until
          // the paddle has been erased

          end // if
      end //case ERASE_PADDLE_LOOP

      // ============================================================
      // The DRAW_PADDLE_ENTER state will start drawing the paddle.  In
      // this state, the paddle position is updated based on the keys, and
      // then the first pixel of the paddle is drawn.  We then immediately
      // go to DRAW_PADDLE_LOOP to draw the rest of the pixels of the paddle.
      // ============================================================

      // paddle_x is the leftmost part of the paddle

      DRAW_PADDLE_ENTER: begin

        // We need to figure out the x location of the paddle before the
        // start of DRAW_PADDLE_LOOP. The x location does not change, unless
        // the user has pressed one of the buttons.

        if (KEY[0] == 1'b0) begin

          if (SW[3] == 0) begin

            // If the user has pressed the right button check to make sure we
            // are not already at the rightmost position of the screen.

            // the following algorithm also prevents paddle from entering borders
          
            if (paddle_x < RIGHT_LINE - paddle_length - 2 ) begin

              paddle_x = paddle_x + 2'b10;
            
            end // if

            if (paddle_x == RIGHT_LINE - paddle_length - 2) begin

              paddle_x = paddle_x + 2'b01;

            end // if

            // If the user has pressed the left button check to make sure we
            // are not already at the leftmost position of the screen

          end // if SW[3]

        end else begin
            if (KEY[1] == 1'b0) begin

              if (SW[3] == 0) begin

                // If the user has pressed the left button check to make sure we
                // are not already at the leftmost position of the screen

                if (paddle_x > LEFT_LINE + 2) begin
              
                // move paddle to two pixels to the left
              
                  paddle_x = paddle_x - 2'b10;
              
                end // if

                if (paddle_x == LEFT_LINE + 2) begin

                  paddle_x = paddle_x - 2'b01;

                end // if

              end // if SW[3]
            end // if KEY[1]
        end // else

              // In this state, draw the first element of the paddle

              draw.y <= PADDLE_ROW[DATA_WIDTH_COORD-1:0];
              draw.x <= paddle_x;  // get ready for next state

              // Enter paddle color
              colour <= paddle_color;

              // Next state
              state <= DRAW_PADDLE_LOOP;

      end // case DRAW_PADDLE_ENTER

      // ============================================================
      // The DRAW_PADDLE_LOOP state will draw the rest of the paddle.
      // Again, because we can only update one pixel per cycle, we will
      // spend multiple cycles in this state.
      // ============================================================

      DRAW_PADDLE_LOOP: begin

        if (draw.x == paddle_x + paddle_length) begin

            plot <= 1'b0;
            state <= ERASE_PADDLE2_ENTER;
        
        end else begin 

        // Otherwise, update the x counter to the next location in the paddle

            draw.y <= PADDLE_ROW[DATA_WIDTH_COORD-1:0];
            draw.x <= draw.x + 1'b1;

        // state stays the same so we come back to this state until we
        // are done drawing the paddle

        end // else
      end // case DRAW_PADDLE_LOOP

      ERASE_PADDLE2_ENTER: begin

        draw.y <= TOP_LINE[DATA_WIDTH_COORD-1:0];
        draw.x <= paddle2_x;

        // Choose background color
        colour <= bg_color;

        plot <= 1'b1;
        state <= ERASE_PADDLE2_LOOP;

      end // case

      ERASE_PADDLE2_LOOP: begin

        // See if we are done erasing the paddle (done with this state)
       
        if ((draw.x == paddle2_x + paddle_length) & 
            (paddle2_x == RIGHT_LINE - paddle_length - 1'b1) ) begin     
          
          state <= DRAW_PADDLE2_ENTER;  // next state is DRAW_PADDLE_ENTER

        end else if (draw.x == paddle2_x + paddle_length + 1'b1) begin

          state <= DRAW_PADDLE2_ENTER;
        
        end else begin

          // We are not done erasing the paddle. Erase the pixel and update
          // draw.x by increasing it by 1

          draw.y <= TOP_LINE[DATA_WIDTH_COORD-1:0];
          draw.x <= draw.x + 1'b1;

          // State stays the same, since we want to come back to this state
          // next time through the process (next rising clock edge) until
          // the paddle has been erased

          end // if

      end  // case

      DRAW_PADDLE2_ENTER: begin

        if (KEY[0] == 1'b0) begin

          if (SW[3] == 1) begin

            // If the user has pressed the right button check to make sure we
            // are not already at the rightmost position of the screen.

            // the following algorithm also prevents paddle from entering borders
          
            if (paddle2_x < RIGHT_LINE - paddle_length - 2 ) begin

              paddle2_x = paddle2_x + 2;
            
            end // if

            if (paddle2_x == RIGHT_LINE - paddle_length - 2) begin

                      paddle2_x = paddle2_x + 1;

            end // if

            // If the user has pressed the left button check to make sure we
            // are not already at the leftmost position of the screen

          end // if SW[3]

      end else begin
          if (KEY[1] == 1'b0) begin

            if (SW[3] == 1) begin

              // If the user has pressed the left button check to make sure we
              // are not already at the leftmost position of the screen

              if (paddle2_x > LEFT_LINE + 2) begin
            
              // move paddle to two pixels to the left
            
                paddle2_x = paddle2_x - 2;
            
              end // if

              if (paddle2_x == LEFT_LINE + 2) begin

                paddle2_x = paddle2_x - 1;

              end // if

            end // if SW[3]
          end // if KEY[1]
      end // else

            // In this state, draw the first element of the paddle

            draw.y <= TOP_LINE[DATA_WIDTH_COORD-1:0];
            draw.x <= paddle2_x;  // get ready for next state

            // Enter paddle color
            colour <= paddle_color;

            // Next state
            state <= DRAW_PADDLE2_LOOP;
     
      end  // case

      DRAW_PADDLE2_LOOP: begin

        if (draw.x == paddle2_x + paddle_length) begin

            plot <= 1'b0;
            state <= ERASE_PUCK;
        
        end else begin 

        // Otherwise, update the x counter to the next location in the paddle

            draw.y <= TOP_LINE[DATA_WIDTH_COORD-1:0];
            draw.x <= draw.x + 1'b1;

        // state stays the same so we come back to this state until we
        // are done drawing the paddle

        end // else
      end // case DRAW_PADDLE2_LOOP

      // ============================================================
      // The ERASE_PUCK state erases the puck from its old location
      // and also calculates the new location of the puck. Note that since
      // the puck is only one pixel, we only need to be here for one cycle.
      // ============================================================

      ERASE_PUCK:  begin
        colour <= bg_color;  // erase by setting color to background's color
        plot <= 1'b1;
        draw.x <= puck.x[15:8];
        draw.y <= puck.y[15:8];
        state <= DRAW_PUCK;

        // Border-puck position rounding mechanism
        if (puck.x[7] == 1) begin
        
          puck.x = puck.x + 1'b1 + puck_velocity.x;
        
        end else begin
        
          puck.x = puck.x + puck_velocity.x;
        
        end // if

        if (puck.y[7] == 1) begin
          
          puck.y = puck.y + 1'b1 + puck_velocity.y;
        
        end else begin
        
          puck.y = puck.y + puck_velocity.y;
        
        end // if

        // See if we have bounced off the top paddle
        if (puck.y[15:8] == TOP_LINE + 1) begin

          if ((puck.x[15:8] >= paddle2_x) & 
              (puck.x[15:8] <= paddle2_x + paddle_length)) begin
          
            puck_velocity.y = 0 - puck_velocity.y;
        
          end else begin

          state <= INIT;

          end // else
        end // if

        // See if we have bounced off the right or left of the screen
        if ((puck.x[15:8] == LEFT_LINE + 1) |
            (puck.x[15:8] == RIGHT_LINE - 1)) begin
          
          puck_velocity.x = 0 - puck_velocity.x;
        
        end // if

        // See if we have bounced of the paddle on the bottom row of screen

        if (puck.y[15:8] == PADDLE_ROW - 1) begin
          
          if ((puck.x[15:8] >= paddle_x) &
          (puck.x[15:8] <= paddle_x + paddle_length)) begin

          // We have bounced off the paddle
          puck_velocity.y = 0 - puck_velocity.y;
    
        end else begin
        // We are at the bottom row, but missed the paddle.  Reset game!
      
        state <= INIT;
          
        end // if
        end // if
      end // ERASE_PUCK

      // ============================================================
      // The DRAW_PUCK draws the puck.  Note that since
      // the puck is only one pixel, we only need to be here for one cycle.
      // ============================================================

      DRAW_PUCK: begin
        colour <= puck_color;
        plot <= 1'b1;
        draw.x <= puck.x[15:8];
        draw.y <= puck.y[15:8];

        // check if player chose to play with two pucks
        if (ball2_flag == 1) 
         
          state <= ERASE_PUCK2;  // next state is DRAW_PUCK.
         
          else
         
          state <= IDLE;
          
          // next state is IDLE (which is the delay state)
        end // case DRAW_PUCK

      ERASE_PUCK2: begin
        colour <= bg_color;
        plot <= 1'b1;
        draw.x <= puck2.x[15:8];
        draw.y <= puck2.y[15:8];
        state <= DRAW_PUCK2;

        // Border-puck position rounding mechanism
        
        if (puck2.x[7] == 1) begin
        
          puck2.x = puck2.x + 1'b1 + puck_velocity2.x;
        
        end else begin
        
          puck2.x = puck2.x + puck_velocity2.x;
        
        end // if

        if (puck2.y[7] == 1) begin
        
          puck2.y = puck2.y + 1'b1 + puck_velocity2.y;
        
        end else begin
        
          puck2.y = puck2.y + puck_velocity2.y;
        
        end // if

        // See if we have bounced off the top paddle
        if (puck2.y[15:8] == TOP_LINE + 1) begin

          if ((puck2.x[15:8] >= paddle2_x) & 
              (puck2.x[15:8] <= paddle2_x + paddle_length)) begin
          
            puck_velocity2.y = 0 - puck_velocity2.y;
        
          end else begin

          state <= INIT;

          end // else
        end // if

        // See if we have bounced off the right or left of the screen
        if ((puck2.x[15:8] == LEFT_LINE + 1) | (puck2.x[15:8] == RIGHT_LINE - 1)) begin
        
          puck_velocity2.x = 0 - puck_velocity2.x;
        
        end // if

        // see if we have bounced off the paddle on the bottom row of the screen

        if (puck2.y[15:8] == PADDLE_ROW - 1) begin
         
          if ((puck2.x[15:8] >= paddle_x) & (puck2.x[15:8] <= paddle_x + paddle_length)) begin
                
                // bounce off the paddle
                puck_velocity2.y = 0 - puck_velocity2.y;
         
          end else begin
            
            // we are at the bottom row, but missed the paddle. Reset game!
            state <= INIT;
              
          end // else
        end // if
      end // ERASE_PUCK2

      DRAW_PUCK2: begin
        colour <= puck_color;
        plot <= 1'b1;

        draw.x <= puck2.x[15:8];
        draw.y <= puck2.y[15:8];

        state <= IDLE;
        
        // next state is IDLE (which is the delay state)

      end // case DRAW_PUCK2

 		  // ============================================================
      // We'll never get here, but good practice to include it anyway
      // ============================================================

        default:
        state <= START;

     endcase
    end
end

always_ff @(posedge CLOCK_50) begin

  if (KEY[3] == 1'b0 | state == INIT) begin
    
    // initialize flag & counter at reset
    paddle_length = PADDLE_WIDTH[DATA_WIDTH_COORD-1:0];
    paddle_counter = 0;
  
  end else if (paddle_length <= 3) begin  
  // Use 3 because for some reason, you start with paddle 11 pixels wide

    paddle_counter <= 0;  

  end else if (paddle_counter == shrink_time) begin

    paddle_length <= paddle_length - 1'b1;
    paddle_counter <= 0;
    
  end else begin
    
    paddle_counter = paddle_counter + 1'b1;
  
  end

end // always_ff
endmodule
