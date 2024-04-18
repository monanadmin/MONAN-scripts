# MONAN-scripts

This repository aims to maitains MONAN system execution scripts
Each folder has your own purpose. Check documentation at each folder below:

Folders:

- egeon: MONAN Quick Start for developers. Scripts for prepare, install and run MONAN on Egeon cluster.
- egeon_sdummont: Quick Start for developers. Scripts for prepare, install and run MONAN on Santos Dummont supercomputer.
- egeon_oper: MONAN "Testes Contínuos" versions for testing MONAN with GFS at Egeon.
  - At some point this code will be migrated to https://github.com/monanadmin/scripts_CD-CT

**HISTORY**

- v0.1.0 - egeon folder: Quick Start initial version
- v0.2.0 - egeon_oper folder: Initial developments for using GFS as IC
- v0.2.1 - egeon folder: Eliminating spack and WPS compilation; Reducing number of scripts and extra steps; Improvements in performance; Using MONAN string instead of MPAS
- v0.2.2 - egeon folder: general improvements
- v0.2.3 - egeon_oper folder: Bug Fix in step 2 static.sh e make_static.sh
- v0.2.4 - egeon_oper folder: including namelists removed from model, parametrizing branch name



