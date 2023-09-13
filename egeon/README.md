This scripts aim to configure and execute the pre processing, MONAN model and the post processing. Them must be executed in the following order:

- 1.install_spack.bash - installs spack, used to install WPS
  - After installing, a message will ask for run source env_wps.sh. Do it before continue to the next script
- 2.install_wps.bash   - installs WPS, used in pre processing
- 3.install_monan.bash - compiile and installs atmosphere_model and init_atmosphere
- 4.pre_monan.bash     - this script will download test case and data, copy the MPAS_ori/testcase/script to the folder MPAS and run the scripts to execute pre processing. Runs inits_atmosphere
- 5.monan.bash         - runs atmosphere_model
- 6.pos_monan.bash     - runs MONAN post processing

The folder MPAS_ori/testcase/scripts contains scripts versioned here that will ovewrite scripts executed in MPAS/testcase/scripts. The 4.pre_monan.bash copies the files from MPAS_ori to MPAS before execution.

After script 1.install_spack.bash, in case of log off the egeon system, you need to execute again source spack_wps/env_wps.sh, to load spack and modules.

