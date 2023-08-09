# VideoBus

Verification Components for VideoBus interface. 

Consists of VideoBusRx for receiving and VideoBusTx for transmitting, and a bitmap logger for visual inspection. An example testbench is included to show how one might use these VCs, using a simple passthrough DUT. 

VideoBus is a simple protocol to stream video using fval (frame valid) / lval (line valid) / dval (data valid). The library has a configurable number of data streams, in case multiple pixels are sent per cycle. 

Below is an example of how a 4x4 image may be transmitted over a single data stream. 
![timing diagram of clk/fval/lval/dval/data](VideoBusInterface.png)

When using multiple data streams, multiple sequential pixels are sent simultaneously. Below is an example of how the same 4x4 image may be transmitted over 2 data streams.
![timing diagram of clk/fval/lval/dval/data1/data2](VideoBusInterface_2ds.png)

Notice that the timing regarding the fval/lval/dval signals is not strict. For example, this would still be a valid transmission of the same 4x4 image:
![timing diagram of clk/fval/lval/dval/data1/data2 with non-strict timing](VideoBusInterface_timing_example.png)

To this regard, the VideoBusTx VC has 3 model options which can be configured: 
1. FVAL_GUARD_CYCLES: number of cycles between successive frames
2. LVAL_GUARD_CYCLES: number of cycles between successive lines
3. DVAL_GUARD_CYCLES: number of cycles between lval high -> dval high / dval low -> lval low

These are all set to 1 by default, resulting in the timing as shown in the first 2 Figures. 

## Compile OSVVM and run the tests
----------------------------------------------------

If you are using Aldec’s Rivera-PRO or Siemen’s QuestaSim/ModelSim do the following.

* Step 1: Create a directory named sim that is in the same directory that contains the OsvvmLibraries directory.
* Step 2: Start your simulator and go to the sim directory.
* Step 3: Do the following in your simulator command line:

```
source ../OsvvmLibraries/Scripts/StartUp.tcl
build  ../OsvvmLibraries
build  ../OsvvmLibraries/VideoBus/RunAllTests.pro
```

The last command will automatically recompile the ./src directory, and then run all the tests in ./testbench. The received frames will be logged as .bmp images in sim/bmp_logs/bmp_frame_X.