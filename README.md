# REDUCTION

This repository contains the reduction code for the Moletai Astronomical Observatory Spectrometer (MAOS).

![MAOS Solar Spectrum](docs/figures/vumps_spec.png)

##Dependencies

This code is written in [IDL](http://www.exelisvis.com/ProductsServices/IDL.aspx) and makes use of the following libraries:

1. The built-in [IDL](http://www.exelisvis.com/ProductsServices/IDL.aspx) library
2. The [IDLAstro](https://github.com/mattgiguere/IDLAstro) package
3. The [idlutils](https://github.com/mattgiguere/idlutils) package
4. The [MPFIT](https://www.physics.wisc.edu/~craigm/idl/fitting.html) package
5. The [coyote](http://www.idlcoyote.com/documents/programs.php) library


##Getting Started

###Install the dependencies:

    cd ~/projects
    git clone https://github.com/mattgiguere/IDLAstro.git
    git clone https://github.com/mattgiguere/idlutils.git
    wget https://www.physics.wisc.edu/~craigm/idl/down/mpfit.tar.gz
    mkdir mpfit; tar -xvf mpfit.tar.gz -C mpfit
    wget http://www.idlcoyote.com/programs/zip_files/coyoteprograms.zip
    unzip coyoteprograms.zip -d .
    
###Logsheets

The reduction code requires a logsheet in order to determine the resolution modes, bias frames, flat fielding frames, etc. The essential elements in the logsheet are the sequence number, object name, observation mid-time, exposure time, and slit mode. Below is an example of a logsheet used during the commissioning of the spectrometer.

```text
                VUMPS Spectrograph Observing Log 
  
-------------------------------------------------------------------------------------
Observer: Giguere, Jurgenson, Sawyer, McCracken, Mossman  Telescope: MAO Prefix: vumps150524.
UT Date: 2015, May 24             Chip: 201 (e2v 4k, 15micron)  Foc:  mm
Ech: VUMPS     Fixed Cross-disperser position                  Foc FWHM: 
-------------------------------------------------------------------------------------
 Obs            Object      Mid-Time     Exp   Slit    Comments
number           Name         (UT)      time           
1000              bg38    00:00:00     0.1    low    ~1.2k peaks
1001              bg38    00:00:00     0.1    low    ~1.2k peaks

```

###Parameter file

Lastly, the reduction code uses a global parameter file for specifying the instrument and machine specific information. Initially, this file can be found in `VUMPS/REDUCTION/code/maos.par`. Set the precise path to the parameter file with the VUMPS_PAR_PATH environment variable. This is included in the `vumpsr.sh` startup script (see below).

###Update the startup script

This repository contains a convenience routine, called `vumpsr.sh` that sets up the IDL environment for the VUMPS reduction code. After installing the dependencies, update the vumpsr.sh file with the appropriate path information. Next, simply type `./vumpsr.sh` at the command line to start up the reduction code environment:

    ./vumpsr.sh
    Now setting the path to +/projects/VUMPS/REDUCTION/code:+/idl/mpfit:+projects/idlutils:+/idl:+/projects/IDLAstro/pro:+/projects/coyote:+/Applications/exelis/idl/lib
    Now changing the directory to: /projects/VUMPS/REDUCTION/code
    IDL Version 8.2.2, Mac OS X (darwin x86_64 m64). (c) 2012, Exelis Visual Information Solutions, Inc.
    Installation number: 2.
    Licensed for use by: VUMPS1
    IDL> 

###Running the reduction code

Lastly, to run the reduction code use the `vumps_reduce_all` command. This will extract and wavelength calibrate all the data for the given night, which is specified by passing the date in yymmdd format to `vumps_reduce_all`. For example, to reduce all the data for all 3 resolution modes for data taken on May 24, 2015, use the following command:

    vumps_reduce_all, date='150524'

