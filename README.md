# `pmod_ad1_example`
An example application using the [PMOD AD1](https://digilent.com/reference/pmod/pmodad1/reference-manual) module on the
[Arty A7 35T](https://digilent.com/reference/programmable-logic/arty-a7/reference-manual) FPGA development board.

The Arty A7 35T continuously reads from both channels on the PMOD AD1. The sample data for each channel is fed into a
PWM module that changes the brightness of the RGB LEDs. The top 4 bits of channel 0 are also hooked up to the four
standard LEDs.

## Requirements
The following hardware is required to run the examples:
* [Arty A7 35t](https://store.digilentinc.com/arty-a7-artix-7-fpga-development-board/) FPGA development board
* [PMOD AD1](https://digilent.com/reference/pmod/pmodad1/reference-manual) analog to digital converter

The PMOD AD1 module gets plugged into the top row (pins 1-6) of JA on the Arty A7 35t.

As for software, install the following:
* [Vivado](https://developer.xilinx.com/en/products/vivado.html) (I use 2019.2 with the free WebPACK license)
* [FuseSoC](https://fusesoc.readthedocs.io/en/stable/user/installation.html)

After that, you will need to install my FuseSoC cores library.
```bash
fusesoc library add --global CoreOrchard https://github.com/adwranovsky/CoreOrchard.git
```

## Building and programming to the board
Synthesis, implementation, bitstream generation and programming to the dev board are all scripted with FuseSoC using the
following command:
```bash
fusesoc run --target arty_a7_35t 'adwranovsky:full_designs:pmod_ad1_example'
```

FuseSoC will pull in all dependencies automatically as long as my cores library was added correctly above!
