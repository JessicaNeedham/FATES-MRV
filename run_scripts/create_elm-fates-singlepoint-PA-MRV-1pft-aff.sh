#!/bin/sh
# =======================================================================================
# =======================================================================================
export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SROF_SGLC_SWAV  
export RES=ELM_USRDAT                                
export MACH=pm-cpu                                             # Name your machine
export COMPILER=gnu                                            # Name your compiler
export PROJECT=e3sm

export SITE=PA                                        # Name your site
export PARAM_FILES=/global/homes/j/jneedham/FATES-MRV/param_files

export TAG=fates-MRV-${SITE}-aff-full  # give your run a name
export CASE_ROOT=/pscratch/sd/j/jneedham/fates-mrv-runs/runs  # where in scratch should the run go?



# this whole section needs to be updated with the location of your surface and domain files
export SITE_BASE_DIR=/pscratch/sd/j/jneedham/fates-mrv-runs
export ELM_USRDAT_DOMAIN=domain_${SITE}.nc
export ELM_USRDAT_SURDAT=surf_${SITE}.nc
export ELM_SURFDAT_DIR=${SITE_BASE_DIR}/${SITE}
export ELM_DOMAIN_DIR=${SITE_BASE_DIR}/${SITE}
export DIN_LOC_ROOT_FORCE=${SITE_BASE_DIR}

# climate data will recycle data between these years
export DATM_START=1980
export DATM_STOP=2022


# DEPENDENT PATHS AND VARIABLES (USER MIGHT CHANGE THESE..)
# =======================================================================================
export SOURCE_DIR=/global/homes/j/jneedham/E3SM/cime/scripts  # change to the path where your E3SM/cime/sripts is
cd ${SOURCE_DIR}

export CIME_HASH=`git log -n 1 --pretty=%h`
export ELM_HASH=`(cd  ../../components/elm/src;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}
export CASE_NAME=${CASE_ROOT}/${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`

# REMOVE EXISTING CASE IF PRESENT
rm -r ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --project=${PROJECT}

cd ${CASE_NAME}


# SET PATHS TO SCRATCH ROOT, DOMAIN AND MET DATA (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange ATM_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange LND_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange DATM_MODE=CLM1PT
./xmlchange ELM_USRDAT_NAME=${SITE}
./xmlchange DIN_LOC_ROOT_CLMFORC=${DIN_LOC_ROOT_FORCE}
./xmlchange CIME_OUTPUT_ROOT=${CASE_NAME}

./xmlchange PIO_VERSION=2

# For constant CO2
./xmlchange CCSM_CO2_PPMV=412
./xmlchange DATM_CO2_TSERIES=none
./xmlchange ELM_CO2_TYPE=constant


# SPECIFY PE LAYOUT FOR SINGLE SITE RUN (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange NTASKS_ATM=1
./xmlchange NTASKS_CPL=1
./xmlchange NTASKS_GLC=1
./xmlchange NTASKS_OCN=1
./xmlchange NTASKS_WAV=1
./xmlchange NTASKS_ICE=1
./xmlchange NTASKS_LND=1
./xmlchange NTASKS_ROF=1
./xmlchange NTASKS_ESP=1
./xmlchange ROOTPE_ATM=0
./xmlchange ROOTPE_CPL=0
./xmlchange ROOTPE_GLC=0
./xmlchange ROOTPE_OCN=0
./xmlchange ROOTPE_WAV=0
./xmlchange ROOTPE_ICE=0
./xmlchange ROOTPE_LND=0
./xmlchange ROOTPE_ROF=0
./xmlchange ROOTPE_ESP=0
./xmlchange NTHRDS_ATM=1
./xmlchange NTHRDS_CPL=1
./xmlchange NTHRDS_GLC=1
./xmlchange NTHRDS_OCN=1
./xmlchange NTHRDS_WAV=1
./xmlchange NTHRDS_ICE=1
./xmlchange NTHRDS_LND=1
./xmlchange NTHRDS_ROF=1
./xmlchange NTHRDS_ESP=1

# SPECIFY RUN TYPE PREFERENCES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange DEBUG=FALSE
./xmlchange STOP_N=100 # how many years should the simulation run
./xmlchange RUN_STARTDATE='1900-01-01'
./xmlchange STOP_OPTION=nyears
./xmlchange REST_N=25 # how often to make restart files
./xmlchange RESUBMIT=4 # how many resubmits 

./xmlchange DATM_CLMNCEP_YR_START=${DATM_START}
./xmlchange DATM_CLMNCEP_YR_END=${DATM_STOP}

./xmlchange JOB_WALLCLOCK_TIME=08:59:00
#./xmlchange JOB_WALLCLOCK_TIME=00:29:00
./xmlchange JOB_QUEUE=shared
#./xmlchange JOB_QUEUE=debug
./xmlchange SAVE_TIMING=FALSE


# MACHINE SPECIFIC, AND/OR USER PREFERENCE CHANGES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange GMAKE=make
./xmlchange RUNDIR=${CASE_NAME}/run
./xmlchange EXEROOT=${CASE_NAME}/bld

./xmlchange SAVE_TIMING=FALSE

# point to your parameter file
# add any history variables you want 
cat >> user_nl_elm <<EOF
fsurdat = '${ELM_SURFDAT_DIR}/${ELM_USRDAT_SURDAT}'
fates_paramfile='${PARAM_FILES}/fates_params_1pft_pa.nc'
use_fates=.true.
use_fates_nocomp=.false.
use_fates_logging=.false.
use_fates_inventory_init = .false.
fluh_timeseries=''
hist_fincl1=
'FATES_VEGC', 'FATES_VEGC_ABOVEGROUND', 
'FATES_NPLANT_SZ', 'FATES_CROWNAREA_PF', 
'FATES_LAI', 'FATES_BASALAREA_SZPF', 'FATES_CA_WEIGHTED_HEIGHT', 'Z0MG',
'FATES_MORTALITY_CSTARV_CFLUX_PF', 'FATES_MORTALITY_CFLUX_PF',
'FATES_MORTALITY_HYDRO_CFLUX_PF', 'FATES_MORTALITY_BACKGROUND_SZ',
'FATES_MORTALITY_HYDRAULIC_SZ', 'FATES_MORTALITY_CSTARV_SZ',
'FATES_MORTALITY_IMPACT_SZ', 'FATES_MORTALITY_TERMINATION_SZ',
'FATES_MORTALITY_FREEZING_SZ', 
'FATES_NPP', 'FATES_GPP', 'FATES_NEP', 'FATES_FIRE_CLOSS',
'FATES_ABOVEGROUND_PROD_SZPF', 'FATES_ABOVEGROUND_MORT_SZPF', 
'FATES_NPLANT_CANOPY_SZ', 'FATES_NPLANT_USTORY_SZ', 
'FATES_DDBH_CANOPY_SZ', 'FATES_DDBH_USTORY_SZ', 
'FATES_MORTALITY_CANOPY_SZ', 'FATES_MORTALITY_USTORY_SZ'
EOF
	 
cat >> user_nl_datm <<EOF
taxmode = "cycle", "cycle", "cycle"
EOF

# Setup case
./case.setup
./preview_namelists
 
# Make change to datm stream field info variable names (specific for this tutorial) - DO NOT CHANGE
CLM1PTFILE="run/datm.streams.txt.CLM1PT.ELM_USRDAT"
sed -i '/ZBOT/d' ${CLM1PTFILE}
#sed -i '/RH/d' ${CLM1PTFILE}
#sed -i '/FLDS/a QBOT shum' ${CLM1PTFILE}

cp run/datm.streams.txt.CLM1PT.ELM_USRDAT user_datm.streams.txt.CLM1PT.ELM_USRDAT

# Build and submit the case
./case.build 
./case.submit
