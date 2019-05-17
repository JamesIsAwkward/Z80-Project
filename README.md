# Z80-Project
Z80 breadboard computer

I plan to create my hardware schematic one day, even though its just a bunch of spaghetti.

## Hardware
# Z80 SBC
Z84C0010PEG - Z80<br>
CY62256NLL-70PXC - SRAM<br>
AT28C64B-15PU - EEPROM<br>
ECS-2100AX-100 - System Clock<br>
ECS-100AX-018 - UART Clock<br>
PC16550DN/NOPB - UART<br>

# Arduino Programmer Circuit
Arduino Nano x2 (one for progrmaming, one to set Z80 to "program mode" or "run mode"<br>
74HC595 x2<br>


## Old compiling and EEPROM writing process
As of right now I have a really tedious 7 stage process to write my software to my z80 machine.<br>

Stage 1: Write the code. I use Notepad++<br>
Stage 2: Copy code to my Debian machine<br>
Stage 3: Compile using z80asm<br>
Stage 4: Convert to "intel" hex data with xxd<br>
Stage 5: Convert to hex data to byte data<br>
Stage 6: Load byte data to Arduino<br>
Stage 7: "flash" to z80 machine with arduino<br>


## New compiling and EEPROM writing process
So my old process worked but was kind of inefficient. I was having to manually manipulate the data at each stage and then actually burn it to the arduino. Once the arduino booted it would dump the stored data to an EEPROM or SRAM.

I opted to find a way to combine stage 3-7, and bash makes this pretty trivial. Also I wanted to stop burning my ROM to the Arduino and actually send the arduino my data via serial. Then the Arduino can burn to the EEPROM or SRAM as it recieves the serial data. This will also be useful if my software ever becomes larger than the space available in the Arduno's ROM.
