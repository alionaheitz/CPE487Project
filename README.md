# CPE487Project

### Overview :
This project is in the progress of creating a flight control system that uses the Nexys A7-100T's accelerometer x y and z's axis data to compute a real time orientation and generate a corresponding PWM signal used to control a servo motor, mimicking flight components adjusting to plane's orientation to restabilize. 



### Hierarchy of the files : 
- XDC file mapping clocks, LEDs, switches, 7‑segment display, and PWM pin
- top.vhd        — Top‑level entity instantiating all submodules
- clk_gen.vhd    — Generates 4 MHz clock from 100 MHz input
- spi_master.vhd — FSM for ADXL362 configuration and SPI data reads
- leddec16.vhd   — Packs and drives eight BCD digits on the seven‑segment display
- controller.vhd — Computes servo‑style PWM duty cycle from X‑axis acceleration




### Data Collection (spi_master)
- Implements a 92‑state FSM at 1 MHz SPI clock to configure and read the ADXL362.
- Captures three 16‑bit axis values plus raw 15‑bit concatenation for LEDs.

### Data Display
- **7‑Segment Display (leddec16)**
  - Converts each 5 bit axis value into two BCD digits via division/modulo.
  - Packs eight nibbles into a 32‑bit vector and time‑multiplexes across digits.
- **LED Array**
  - SW[2:0] chooses which axis to show: "001"→X, "010"→Y, "100"→Z.
  - Lights each LED bit high/low according to the raw binary data.

### Servo Control (controller)
- Compares X‑axis acceleration against ±threshold to decide left/center/right.
- Smoothly slews a PWM duty cycle toward 1 ms, 1.5 ms, or 2 ms pulses at 50 Hz.
- Outputs `PWM_OUT` for hobby servo actuation.






