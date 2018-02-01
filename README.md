# Lab 3: It's all fun and games until the Kraken shows up

## Contents

* [Overview](#overview)
  * [Task 1: Run the game](#task-1-run-the-game)
  * [Task 2: RTFC](#task-2-rtfc)
  * [Task 3: Tap ’em signals\!](#task-3-tap-em-signals)
  * [Task 4: Three easy pieces](#task-4-three-easy-pieces)
  * [Task 5: The magical shrinking paddle](#task-5-the-magical-shrinking-paddle)
  * [Task 6: Angles and dangles](#task-6-angles-and-dangles)
  * [Task 7: Double trouble](#task-7-double-trouble)
  * [Task 8: Demo mode](#task-8-demo-mode)
  * [BONUS: Enter the Kraken\!](#bonus-enter-the-kraken)
* [Deliverables](#deliverables)

## Overview

In this lab, you will learn how to work with fixed-point numbers and arithmetic. You will also be introduced to an important debugging tool, SignalTap. Finally, you will get some more experience working with non-trivial datapath circuits.

Unlike Labs 1 and 2, where you wrote most of the code yourself, here you will be given a working RTL implementation that you will enhance in several ways. Although this means that the amount of SystemVerilog that you write in this lab is less than in other labs, it also means you will need to spend some time understanding someone else's code. In the industry, rarely will you get to write your own code from scratch; usually projects are done by modifying an existing code base. The ability to read and understand existing code is as important as being able to write your own code.


### Task 1: Run the game

Connect your DE1-SoC to a monitor via a VGA cable, and then synthesize and download the game. The VGA core is the same as in the previous lab, so you should already be familiar with it.

You should see a ball (called a “puck” in the code) bouncing off the walls on three sides of the playing area, and a paddle at the bottom which you can control using `KEY0` and `KEY1`.


### Task 2: RTFC

Study the SystemVerilog code in the task2 folder (it's the same as the code in task1). You don't have to read the VGA adapter sources in vga-core.

Notice that the Verilog is written using the _implicit_ datapath design method we discussed in lecture. In this style, the state machine and state transitions are explicit, however the structure of the datapath is implicitly defined within the state machine process. Draw the the state machine bubble diagram, indicating the condition that causes state transitions and describing what occurs in each state; this will help you understand how the circuit works and you will have to show it to your TA anyway.

Some questions you should be able to answer at this point (you do not have to hand in the answers, but these are examples of very basic things a TA could ask you during the marking week):

1. Why is the `IDLE` state required? It seems like it does nothing. Is it true that we are in the `IDLE` state whenever the user is not pressing `KEY0` and `KEY1`? Why/why not?
2. What is the difference between `DRAW_PADDLE_ENTER` and `DRAW_PADDLE_LOOP`? Why do we have two different states? How many cycles would the machine stay in `DRAW_PADDLE_ENTER`? How many cycles would it stay in `DRAW_PADDLE_LOOP`?
3. In what state does the circuit check if the user is pressing `KEY0` or `KEY1`? In what state does the circuit check if the ball has hit the wall or a paddle?
4. Why is each velocity component a signed value, while the puck location is an unsigned value? It seems that when the ball hits a wall or paddle, the sign of the velocity is flipped (+1 or -1). Why?
5. If you wanted to draw another line on the screen, where would you add code to do this? How would you do it? Would you need another state?

**Do not go onto Task 3 until you are relatively comfortable with the provided SystemVerilog.**


### Task 3: Tap ’em signals!

Work through the [SignalTap tutorial](signaltap.md). Take a screenshot or photo of your waveform at the end, and show this to the TA during your demo session.


### Task 4: Three easy pieces

The game we have given you isn't much fun as-is. In this task, your job will be to make it a little more fun by making a few trivial changes.

1. Everything is black and white. Choose a new colour scheme. The ball and paddles should be different colours (not white). This is trivial.

2. Playing with only one ball on the screen is too easy. Add a second ball (so there are two balls moving on the screen at the same time). Set the start positions of the two balls so they are not on-top of each other. One of the balls should start moving up and to the right at 45 degrees, while the other ball should start by moving to the right and down at 45 degrees, as illustrated in the following diagram. (Hint: this is fairly easy, and the easiest solution involves adding extra states to the existing state machine. If you find yourself adding a second state machine, you are probably making it much harder than it has to be.) The player should be able to choose how many balls to play with: if `SW[0]` == 1, we will have two balls, and if `SW[0]` == 0, we will have the one original ball.

3. The initial conditions are a bit boring. If `SW[1]` is high, then the paddle should start flushed all the way left (if `SW[2]` == 0) or all the way right (if `SW[2]` == 1). If `SW[1]` == 0, the paddle should start in the centre as in the original code.


### Task 5: The magical shrinking paddle

In the original circuit, the paddle is always 10 pixels wide (in the _x_ dimension). Modify the circuit so that, every twenty seconds, the paddle gets 1 pixel shorter — until it reaches 4 pixels, at which point it doesn't get any shorter.


### Task 6: Angles and dangles

In the original circuit, the balls move at 45° only. A more realistic game would, however, allow the balls to move at different angles. In this case, the two components of the velocity vector would not be limited to -1 or 1, but may take on fractional values. In this task, you are to generalize the angles at which the balls move.

The simplest way to implement this is to use a fixed-point representation for the ball position and the ball velocity. For each, use **8 integer bits and 8 fractional bits**.

In the fixed-point implementation, when the ball collides with a wall or paddle, it should exit the bounce at the correct angle, so if it comes into the wall at 30 degrees, it should exit the wall at 30 degrees. (This isn't nearly as hard as it sounds.)

Once you have your implementation, test your design with several initial velocity vectors for each ball. To get ready for the following tasks, set your initial velocity vectors as shown in this diagram (this corresponds to 30 degrees for Ball 1 and 15 degrees for Ball 2).


### Task 7: Double trouble

If we have two balls, why not two paddles? In this task you will remove the top wall and instead place an additional paddle there.

Both paddles should start at the same location, and should be controlled by the same keys. Only one should move at a time, however, controlled by `SW[3]`: when `SW[3]` is 0, the keys should control the bottom paddle, and when it's 1, the top paddle.


### Task 8: Demo mode

A game this good needs a demo mode for when the venture capitalists come calling.

Whenever `SW[4]` is 1, the game should play itself, subject to the following rules:

1. Only one paddle moves at a time (i.e., one movement of either the top or bottom paddle for each frame). Your implementation needs to choose somewhat intelligently which paddle to move in each frame.
2. Paddles do not move any faster than if manually controlled (i.e., one pixel per frame). That is, no warping the paddles to right under the ball :)
3. Your demo needs to work for all initial paddle positions and sizes.

This is a fair amount easier than it might initially appear.


### BONUS: Enter the Kraken!

Add a hungry Kraken to the game. This should be a 5×5 red square that appears when `KEY2` is pressed, and moves directly towards the _closest_ ball (your choice which one) with the same speed as the balls. If one of the Kraken's pixels occupies the same square as a ball, the ball is eaten (as noted, the Kraken is hungry). If there are two balls, the game continues with one ball, and the Kraken starts chasing the other ball.

## Deliverables

Note that for tasks 3–8, your submission **must not** contain code for any later tasks.

### Tasks 1 and 2

No deliverables.

### Task 3 [1 mark]

- You must show your SignalTap picture to the TA. The TA may ask you how SignalTap works.
- A `task3/signaltap.png` file with the screenshot/photo from Task 3 in PNG format.

### Task 4 [1 mark]

- The `task4/lab3.sv` toplevel and all other files required to implement your Task 4 design
- Any `task4/tb_*.sv` testbenches you used to test your code

### Task 5 [2 marks]

- The `task5/lab3.sv` toplevel and all other files required to implement your Task 4–5 design
- Any `task5/tb_*.sv` testbenches you used to test your code

### Task 6 [2 marks]

- The `task6/lab3.sv` toplevel and all other files required to implement your Task 4–6 design
- Any `task6/tb_*.sv` testbenches you used to test your code

### Task 7 [2 marks]

- The `task7/lab3.sv` toplevel and all other files required to implement your Task 4–7 design
- Any `task7/tb_*.sv` testbenches you used to test your code

### Task 8 [2 marks]

- The `task8/lab3.sv` toplevel and all other files required to implement your Task 4–8 design
- Any `task8/tb_*.sv` testbenches you used to test your code

### The Kraken

- You must demonstrate the working Kraken demo (with all the features from tasks 4–8) to your TA to qualify
- The `kraken/lab3.sv` toplevel and all other files required to implement your Task 4–8 design together with the Kraken feature
- Any `kraken/tb_*.sv` testbenches you used to test your code
