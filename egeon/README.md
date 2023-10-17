# MONAN - Model for Ocean-laNd-Atmosphere PredictioN

### *Quick Start for Egeon version 0.2.1*


## History:

v0.1.0 - Workshop version

v0.2.1 - This version
 - Eliminating spack and WPS compilation
 - Reducing number of scripts and extra steps
 - Improvements in performance
 - Using MONAN string instead of MPAS

## Quick Start

This manual describes a quick procedure for the developer to compile and run MONAN (currently pure MPAS 8.0.1 code) in the Egeon supercomputing environment.
Please refer to MONAN_V0.1.0_QuickStart.md for more details

### Steps:

Create your fork from https://github.com/monanadmin/MONAN-Model 

Execute:
~~~
cd /mnt/beegfs/$USER

git clone https://github.com/monanadmin/MONAN-scripts.git

cd /mnt/beegfs/$USER/MONAN-scripts

git checkout 0.2.1

cd /mnt/beegfs/$USER/MONAN-scripts/egeon

./1.install_monan.bash https://github.com/<MY_USER_GITHUB>/<MONAN-Model.git>

./2.pre_monan.bash

./3.run_monan.bash

./4.pos_monan.bash

module load imagemagick-7.0.8-7-gcc-11.2.0-46pk2go

display ./MONAN/testcase/runs/ERA5/2021010100/postprd/MONAN.png
~~~

Check the displayed figure.
