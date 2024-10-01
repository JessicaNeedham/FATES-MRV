#!/bin/sh
# =======================================================================================
# =======================================================================================
export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SROF_SGLC_SWAV
export RES=ELM_USRDAT
export MACH=pm-cpu                                             # Name your machine
export COMPILER=gnu                                            # Name your compiler
export PROJECT=e3sm

export SITE=PA
export PARAM_FILES=/global/homes/j/jneedham/FATES-MRV/param_files

export TAG=PA_ensemble
export CASE_ROOT=/pscratch/sd/j/jneedham/fates-mrv-runs/runs

# this whole section needs to be updated with the location of your surface and domain files
export SITE_BASE_DIR=/pscratch/sd/j/jneedham/fates-mrv-runs
export ELM_USRDAT_DOMAIN=domain_${SITE}.nc
export ELM_USRDAT_SURDAT=surf_${SITE}.nc
export ELM_SURFDAT_DIR=${SITE_BASE_DIR}/${SITE}
export ELM_DOMAIN_DIR=${SITE_BASE_DIR}/${SITE}
export DIN_LOC_ROOT_FORCE=${SITE_BASE_DIR}

export DATM_START=1980
export DATM_STOP=2022

export ninst=128



# DEPENDENT PATHS AND VARIABLES (USER MIGHT CHANGE THESE..)
# =======================================================================================
export SOURCE_DIR=/global/homes/j/jneedham/E3SM-dben/E3SM/cime/scripts
cd ${SOURCE_DIR}

export CIME_HASH=`git log -n 1 --pretty=%h`
export ELM_HASH=`(cd  ../../components/elm/src;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}
export CASE_NAME=${CASE_ROOT}/${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`


# REMOVE EXISTING CASE IF PRESENT
rm -r ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --project=${PROJECT} --ninst=$ninst


cd ${CASE_NAME}


#./xmlchange --id ELM_FORCE_COLDSTART --val on

# SET PATHS TO SCRATCH ROOT, DOMAIN AND MET DATA (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange ATM_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange LND_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange DATM_MODE=CLMCRUNCEP
./xmlchange ELM_USRDAT_NAME=${SITE_NAME}

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
./xmlchange STOP_N=50
./xmlchange RUN_STARTDATE='1991-01-01'
./xmlchange STOP_OPTION=nyears
./xmlchange REST_N=10
./xmlchange RESUBMIT=5

./xmlchange DATM_CLMNCEP_YR_START=${DATM_START}
./xmlchange DATM_CLMNCEP_YR_END=${DATM_STOP}

./xmlchange JOB_WALLCLOCK_TIME=09:59:00
./xmlchange JOB_QUEUE=regular
#./xmlchange JOB_WALLCLOCK_TIME=00:29:00
#./xmlchange JOB_QUEUE=debug
./xmlchange SAVE_TIMING=FALSE


# MACHINE SPECIFIC, AND/OR USER PREFERENCE CHANGES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange GMAKE=make
#./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
#./xmlchange DOUT_S=TRUE
#./xmlchange DOUT_S_ROOT=${CASE_NAME}/run
./xmlchange RUNDIR=${CASE_NAME}/run
./xmlchange EXEROOT=${CASE_NAME}/bld
./xmlchange SAVE_TIMING=FALSE

for x in `seq 1 1 $ninst`; do
	 expstr=$(printf %04d $x)
	 ending=$x
	 echo $expstr
	 cat >> user_nl_elm_$expstr <<EOF
fsurdat = '${ELM_SURFDAT_DIR}/${ELM_USRDAT_SURDAT}'
fates_paramfile='/global/homes/j/jneedham/DBEN_cbudget_2024/param_files/ensembles/bci/fates_params_bci_ens_${ending}.nc'
hist_empty_htapes=.true.
use_fates=.true.
hist_fincl1='FATES_VEGC_PF', 'FATES_VEGC_ABOVEGROUND', 'FATES_VEGC_ABOVEGROUND_AP', 'FATES_WOODY_ABOVEGROUND',
'FATES_WOODY_ABOVEGROUND_AP', 'FATES_WOODC_SZ',
'FATES_WOODC_PF', 'FATES_NPLANT_SZ', 'FATES_CROWNAREA_PF', 'FATES_LAI_PF', 'FATES_LAI', 'FATES_BASALAREA_PF',
 'FATES_CA_WEIGHTED_HEIGHT', 'Z0MG','FATES_SAPWOOD_ALLOC_PF', 'FATES_STRUCT_ALLOC_PF',
'FATES_MORTALITY_CSTARV_CFLUX_PF', 'FATES_MORTALITY_CFLUX_PF',
'FATES_MORTALITY_HYDRO_CFLUX_PF', 'FATES_MORTALITY_BACKGROUND_SZPF',
'FATES_MORTALITY_HYDRAULIC_SZPF', 'FATES_MORTALITY_CSTARV_SZPF',
'FATES_MORTALITY_IMPACT_SZPF', 'FATES_MORTALITY_TERMINATION_SZPF',
'FATES_MORTALITY_FREEZING_SZPF', 'FATES_MORTALITY_CANOPY_SZPF',
'FATES_MORTALITY_USTORY_SZPF', 'FATES_NPLANT_SZPF',
'FATES_NPLANT_CANOPY_SZPF', 'FATES_NPLANT_USTORY_SZPF',
'FATES_NPP_PF', 'FATES_GPP_PF', 'FATES_NEP', 'FATES_FIRE_CLOSS',
'FATES_PATCHAREA_AP', 'FATES_RECRUITMENT_CFLUX_PF',
'FATES_RECRUITMENT_PF',  'FATES_LEAFCTURN_CANOPY_SZ', 'FATES_FROOTCTURN_CANOPY_SZ',
 'FATES_STORECTURN_CANOPY_SZ', 'FATES_STRUCTCTURN_CANOPY_SZ', 'FATES_SAPWOODCTURN_CANOPY_SZ',
 'FATES_SEED_PROD_CANOPY_SZ', 'FATES_LEAF_ALLOC_CANOPY_SZ', 'FATES_FROOT_ALLOC_CANOPY_SZ',
 'FATES_SAPWOOD_ALLOC_CANOPY_SZ',
'FATES_STRUCT_ALLOC_CANOPY_SZ', 'FATES_SEED_ALLOC_CANOPY_SZ', 'FATES_STORE_ALLOC_CANOPY_SZ',
'FATES_LEAFCTURN_USTORY_SZ', 'FATES_FROOTCTURN_USTORY_SZ', 'FATES_STORECTURN_USTORY_SZ',
'FATES_STRUCTCTURN_USTORY_SZ', 'FATES_SAPWOODCTURN_USTORY_SZ', 'FATES_SEED_PROD_USTORY_SZ',
'FATES_LEAF_ALLOC_USTORY_SZ', 'FATES_FROOT_ALLOC_USTORY_SZ', 'FATES_SAPWOOD_ALLOC_USTORY_SZ',
'FATES_STRUCT_ALLOC_USTORY_SZ', 'FATES_SEED_ALLOC_USTORY_SZ', 'FATES_STORE_ALLOC_USTORY_SZ',
'FATES_GROWAR_USTORY_SZ', 'FATES_MAINTAR_USTORY_SZ', 'FATES_GROWAR_CANOPY_SZ',
'FATES_MAINTAR_CANOPY_SZ', 'FATES_ABOVEGROUND_PROD_SZPF', 'FATES_ABOVEGROUND_MORT_SZPF',
'FATES_MORTALITY_CSTARV_CFLUX_PF' 
use_fates_nocomp=.false.                                                                                    
use_fates_logging=.false.
fates_parteh_mode = 1
EOF

done
	 
for x in `seq 1 1 $ninst`; do
expstr=$(printf %04d $x)
cat >> user_nl_datm_${expstr} <<EOF
taxmode = "cycle", "cycle", "cycle"
EOF
done

for x in `seq 1 1 $ninst`; do
    expstr=$(printf %04d $x)
    echo $expstr
		      
cp /global/cfs/cdirs/e3sm/inputdata/atm/datm7/TRENDY_2022/BCI/Solar6Hrly/user_datm.streams.txt.CLMCRUNCEP.Solar user_datm.streams.txt.CLMCRUNCEP.Solar_${expstr}
cp /global/cfs/cdirs/e3sm/inputdata/atm/datm7/TRENDY_2022/BCI/Precip6Hrly/user_datm.streams.txt.CLMCRUNCEP.Precip user_datm.streams.txt.CLMCRUNCEP.Precip_${expstr}
cp /global/cfs/cdirs/e3sm/inputdata/atm/datm7/TRENDY_2022/BCI/TPQWL6Hrly/user_datm.streams.txt.CLMCRUNCEP.TPQW user_datm.streams.txt.CLMCRUNCEP.TPQW_${expstr}
done
		  
./case.setup
./case.build
./case.submit --skip-preview-namelist
