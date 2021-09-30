# relaysbc-programs
Programs written for Joe Allen's single board relay computer (sbrc).

This repository contains community contributed programs for the sbrc, as well as a mirror of the sample code, utility programs, and firmware written by Joe Allen.

The original SourceForge project page can be found here: https://sourceforge.net/projects/relaysbc/

An introductory video from Joe Allen can be found here: https://www.youtube.com/watch?v=k1hJoalcK68

![sbrc image](sbrc.jpg)


## Programs

Community contributed programs are placed in `community/`.

| Program | Author | Description |
| --- | --- | --- |
| [Examples](examples/) | Joe Allen | Example programs and core functions (eg. multiply, divide, sqrt) |
| [Hardware Tests](hardware-tests/) | Joe Allen | Test programs for validating the correct assembly and operation of the computer hardware |
| [Primes](community/primes/) | Ryan Crosby | Prime number search programs |
| [Pi](community/pi/) | Dag Stroman | Calculate the digits of Pi to various accuracies |
| [Tetris](community/tetris/) | Ryan Crosby | A barebones Tetris game implementation |
| [Util](community/util/) | Ryan Crosby | Miscellaneous utility functions |

## Tools

Tools written in C to support the relay computer.

| Program | Author | Description |
| --- | --- | --- |
| [asm](tools/) | Joe Allen | Assembler for sbrc programs. Produces assembled listing files, which include a memory image that can be sent to the sbrc via serial. |
| [sim](tools/) | Joe Allen | Simulator for the sbrc. Allows testing of programs without access to physical hardware. |

## Firmware

Firmware files for the various microcontrollers included on the sbrc

| Program | Author | Description |
| --- | --- | --- |
| [PIC main](pic/) | Joe Allen | Firmware for the main microcontroller, which orchestrates control of the sbrc. |
| [PIC kbddisp](pic/) | Joe Allen | Firmware for the supplementary microcontroller, which controls the keyboard input and display output. |

## Documentation

| Program | Author | Description |
| --- | --- | --- |
| [htdocs](htdocs/) | Joe Allen | HTML documentation for the sbrc. |


## License

All software is licensed under the GNU GENERAL PUBLIC LICENSE Version 2, June 1991.

See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Simply fork the project and create a PR with your code, or send/email it to me any way you can and I'll include it in the repo on your behalf.

All contributed code will be licensed (and must comply with) the project license, GPLv2.