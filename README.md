# VHDL-Neopixel-Controller
## Intro
This was a class project for GT's 2031 Digital Design Lab.

The aim was to create a peripheral for an SCOMP (simple computer) to be able to control a WS2811 NeoPixel driver.
Testing and simulation was done using Quartus Prime and Intel's DE-10 Lite FPGA board.

## Approach
A detailed and visual explanation to the approach can be found in "Project Summary.pdf" but I will make an attempt at a brief summary here:

  Due to the limited IO bus size (16 bits) and our desire to display 32 bit color, we had to take instructions from the SCOMP over many "OUT"s. Our solution was to create a finite state machine that, depending on the opcode, would wait for a variable amount of additional data and display an opcode dependent pattern.

  This approach has left us with an easily scalable and user friendly design. More patterns can be added with minimum effort through adding additional opcodes.

  This project took many iterations and the final product dwarfs many previous iterations in both size and complexity but we are happy with the streamlined final product.
