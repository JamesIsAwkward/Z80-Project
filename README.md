# Z80-Project
Z80 breadboard computer

I plan to create my hardware schematic one day, even though its just a bunch of spaghetti.

## Hardware
Z84C0010PEG - Z80<br>
CY62256NLL-70PXC - SRAM<br>
AT28C64B-15PU - EEPROM<br>
ECS-2100AX-100 - System Clock<br>
ECS-100AX-018 - UART Clock<br>
PC16550DN/NOPB - UART<br>


## Compiling Software
As of right now I have a really crappy 7 stage process to write my software to my z80 machine.<br>
I'm working on a bash script that will hopefully replace steps 3, 4, and 5.<br>

Stage 1: Write the code. I use Notepad++<br>
Stage 2: Copy code to my Debian machine<br>
Stage 3: Compile using z80asm<br>
Stage 4: Convert to "intel" hex data with xxd<br>
Stage 5: Convert to hex data to byte data<br>
Stage 6: Load byte data to Arduino<br>
Stage 7: "flash" to z80 machine with arduino<br>
