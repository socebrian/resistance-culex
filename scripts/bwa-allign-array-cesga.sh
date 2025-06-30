#!/bin/bash
#SBATCH --mem-per-cpu=500M
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=15
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=scebrian27@gmail.com
#SBATCH --output=bwamem_array_%A_%a.out
#SBATCH --error=bwamem_array_%A_%a.err
#SBATCH --array=1-50


module load miniconda3
conda activate culex
module load bwa
module load samtools

#variables
dir=${1} #3.repetidas
input=${2} #3.list-fastp-output.txt
ref=${3} # idCulPipi1.1.primary.fa

# Specify the path to the config file
config="/mnt/lustre/scratch/nlsas/home/csic/dbl/scc/${dir}/to-map/${input}"

# need to put in txt nombre=${1} # PP2114-c60.L7
name=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

#paired alignment
bwa mem \
    /home/csic/dbl/scc/data/${ref}\
    /mnt/lustre/scratch/nlsas/home/csic/dbl/scc/${dir}/to-map/${name}.R1.fastp.fq.gz \
    /mnt/lustre/scratch/nlsas/home/csic/dbl/scc/${dir}/to-map/${name}.R2.fastp.fq.gz \
    -t 15|
samtools view -hbS - -o /mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/bams/${dir}/${name}.PR.bam -@ 15

#sbatch -n 1 --cpus-per-task=15 --mem-per-cpu=20G -t 12:00:00 --job-name=L2fG30paired-bwa -o escribiroutput.txt bwa-allignment.sh PP2114-fG30_L2 idCulPipi.chrom.fa 

