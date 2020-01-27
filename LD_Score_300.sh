######## Please use our data disk (/mnt/YangFSS/data) for input and output of all BFGWAS jobs
for num in {1..300}; do
  study=bfGWAS_${num}
  line=$(($num + 1))p
  pheno_var=$(sed -n ${line} /mnt/YangFSS/data/jchen/20block_simulation/simulation_info.txt | awk -F '\t' '{print $6}')
  filehead=/mnt/YangFSS/data/WingoLab-Data/WGS_JointCall/LDdetect_SegmentedVCF_CADDsubset/FileHead_1703_anno_chr19.bed
  pheno=/mnt/YangFSS/data/jchen/20block_simulation/wkdir_${num}/pheno.txt
  geno_dir=/mnt/YangFSS/data/WingoLab-Data/WGS_JointCall/LDdetect_SegmentedVCF
  LD_dir=/mnt/YangFSS/data/jchen/20block_simulation/wkdir_${num}/LDstatistic
  Score_dir=/mnt/YangFSS/data/jchen/20block_simulation/wkdir_${num}/Score
  if [[ ! -e ${LD_dir} ]]; then
      mkdir ${LD_dir}
  fi
  if [[ ! -e ${Score_dir} ]]; then
        mkdir ${Score_dir}
  fi

  LDwindow=1000000
  qsub -j y -wd ${Score_dir} -N GetRefLD_${study} -t 1 -tc 100 -pe smp 4 /home/jchen/bfGWAS/GetRefLD.sh ${geno_dir} ${pheno} ${filehead} ${LD_dir} ${Score_dir} ${LDwindow}

done



######## Example scripts are under /home/jyang/ResearchProjects/ROSMAP_GWAS/BFGWAS/Scripts
######### Tool directory
AnnoNumber=4
bfGWAS_SS_dir="/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation"

######## Specify file directories and variable values for BFGWAS
study=cogdx # project name
N=1102  # sample size
pheno_var=3.081258 # phenotype variance
# genome-block names

# FileHead=/home/jyang/Collaborations/IrwinSAGE/SummaryData/FileHead_AA_2581.txt

# phenotype directory
pheno=/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/Test/simulation/pheno.txt
# genotype directory
geno_dir=/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/Test/simulation

######### Please first generate summary statistics (LD and score statistics files) files for best computation speed
# LD coefficient directory
LD_dir=/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/Test/simulation/LDstatistic
# Score statistics directory
Score_dir=/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/Test/simulation/cogdx_Score
LDwindow=1000000
AnnoNumber=3

# Submit Array jobs with GetRefLD.sh
qsub -j y -wd ${Score_dir} -N GetRefLD_${study} -t 1 -tc 100 -pe smp 4 /home/jchen/bfGWAS/GetRefLD.sh ${geno_dir} ${pheno} ${filehead} ${LD_dir} ${Score_dir} ${LDwindow}

####### Command to run BFGWAS for genome-wide blocks
##  run_BFGWAS.sh will call the perl script gen_mkf.pl to generate a makefile with all BFGWAS_SS jobs run by run_make.sh
## The executible file /home/jyang/GIT/bfGWAS_SS/bin/Estep_mcmc was run by run_Estep.sh, which is called by make
## Then clean all previous outputs and re-run the generated Makefile
## Please test with ~10 genome-blocks instead of running the whole genome-wide data

# Hyper parameter file
hfile=/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/Test/simulation/hypval.current

# Annotation file directory and Annotation code for categories (optional)
annoDir=/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/Test/simulation
#annoCode=/mnt/YangFSS/data/WingoLab-Data/WGS_JointCall/Annocode10ROSMAP.txt

# Set up Working directory
wkdir=/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/Test/test_output
mkdir -p $wkdir
cd $wkdir

###### Call gen_mkf.pl to generate Make file
# directory for run_Estep.sh and run_Mstep.sh
EMdir=/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/bin
# Specify computation specs
em=5 # EM steps
burnin=10000 # Burn-in iterations in MCMC
Nmcmc=10000 # MCMC iteration number
mkfile=${wkdir}/${study}_BFGWAS.mk

/home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/bin/gen_mkf.pl \
--EMdir ${EMdir} --hyp ${hfile} \
-n ${N} --pv ${pheno_var} \
-w ${wkdir} --geno sumstat \
-f ${filehead} -l local \
--ad ${annoDir} \
--LDdir ${LD_dir} --Scoredir ${Score_dir} \
-j BFGWAS_${study} --em ${em} -b ${burnin} -N ${Nmcmc} \
--mf ${mkfile} --AnnoNumber ${AnnoNumber}


######### Submit the job for running the makefile (run_Estep.sh and run_Mstep.sh were called by make)
j=1 # Number of cores to run the job in parallel
qsub -q b.q -j y -pe smp ${j} -wd ${wkdir} -N BFGWAS_${study} /home/jchen/bfGWAS/bfGWAS_QuantitativeAnnotation/bin/run_make.sh ${wkdir} ${mkfile} ${j}


#########  See example Rscript for Analyzing BFGWAS results
/mnt/icebreaker/data2/home/jyang/ResearchProjects/ROSMAP_GWAS/BFGWAS/Scripts/BFGWAS.r

######## EPACTS
/mnt/YangFSS/data/gpathtest/Gpath_Score/score.txt

############################################
## The following script is for test single BFGWAS_SS jobs for one genome-block
############################################

########### Single example BFGWAS_SS job for one genome-block
study=AA; # study name
N=3272 ; # sample size
pheno_var=6.598844; # phenotype variance
filehead=NewYaleSAGE_CHR_1_10583_1577084
# Tool directory
bfGWAS_SS_dir="/home/jyang/GIT/bfGWAS_SS"

cd /home/jyang/ResearchProjects/ROSMAP_GWAS/BFGWAS/Test

### Run single BFGWAS_SS with job individual level data and save summary statistics (-saveSS -zipSS options is for saving LD and score summary statistics)
# outputs were saved under ./output/

${bfGWAS_SS_dir}/bin/Estep_mcmc \
-g ${geno_dir}/${filehead}.geno.gz -p ${pheno} \
-hfile ${hfile} \
-bvsrm -maf 0.01 -win 100 -smin 0 -smax 10 -w 10000 -s 10000 \
-o ${filehead}_indv -initype 3 -seed 2017 \
-LDwindow 1000000  -saveSS -zipSS  > ${filehead}_indv.output.txt &

### Run single BFGWAS_SS with summary statistics file (as generated by the above command using individual level data)
score_file=/home/jyang/Collaborations/IrwinSAGE/BFGWAS_Analysis/${study}/test/output/${filehead}_indv.score.txt.gz
ld_file=/home/jyang/Collaborations/IrwinSAGE/BFGWAS_Analysis/${study}/test/output/${filehead}_indv.LDcorr.txt.gz

## -inputSS is the option to specify input files are summary statistics files (LD and score stat)
${bfGWAS_SS_dir}/bin/Estep_mcmc \
-score ${score_file} -LDcorr ${ld_file} \
-n ${N} -pv ${pheno_var} -inputSS \
-hfile ${hfile} \
-bvsrm -maf 0.01 -win 100 -smin 0 -smax 10 -w 10000  -s 10000  \
-o ${filehead}_ss -initype 3 -seed 2017 > ${filehead}_ss.output.txt  &
