# Assembly-Projects
Lab projects for ECE 222 - Digital Computers at the University of Waterloo. My lab partner Austin Wong and I wrote the projects in ARM Assembly and deployed on a Keil MCB1700B board with a LPC1768 microcontroller.

## Labs
Note that each lab used code/knowledge acquired in the last one, therefore:

* Subroutines are often copied to the next lab
* The most refined/clear/best version of a give subroutine is probably in Lab 4.

There were five labs in total, but the first one only involved setting up the IDE and learning how to set up projects properly. The course has supplmeental pre-labs which aren't for marks or handed in, so nobody (including myself) ended up completing them. After the first lab, the projects built off of each other with increasing complexity. I'll describe each project here:

1. **Introduction to ARM** - Make an LED flash at 1 Hz.
2. **Subroutines and Parameter Passing** - Morse code transmitter. Flash the a morse code word on the LED.
3. **Input/Output Interfacing** - Measure reaction time by flashing lights and counting how long it takes from when the light starts flashing to the user pressing a button.
4. **Interrupt Handling** - Same as Lab 3, except handle the button press by writing an interrupt service routine.

## License

Code is copyright 2014 Victor Szeto and Austin Wong, and released under the [MIT license](https://github.com/VictorVation/Assembly-Projects/blob/master/LICENSE) and therefore we will not be liable for any consequences of any use of this code.
