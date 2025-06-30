#!/bin/bash
#SBATCH --mem-per-cpu=500M
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=15
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=scebrian27@gmail.com
#SBATCH --output=mark_dup_%A_%a.out
#SBATCH --error=mark_dup_%A_%a.err
#SBATCH --array=1-50

#this script takes a list of bam files and remove duplicates

# Load any necessary modules
module load miniconda3
#conda activate vcf
module load racs-eb/1
module load samtools
module load picard

#variables
dir=${1} #3.repetidas
list=${2} #list of bam files

# Specify the path to the config file
input="/mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/bams/${list}/${list}"
bam_dir="/mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/bams/${dir}"
out_dir="/mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/md-bams/${dir}"

IFS=$'\t' read -r -a samples <<< $(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$input")
# Extract parameters
id=${samples[1]}
name="${id}.PR.sorted.rg.bam"
# Read the sample ID for the current array task
in_bam="$bam_dir/${name}"
# Define output filenames
output_bam="$out_dir/${id}.md.bam"
output_metrics="$out_dir/${id}_marked_dup_metrics.txt"


# Debug: Print the sample variable
echo "Sample: ${id}"
java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
    I=$in_bam \
    O=$output_bam \
    M=$output_metrics \
    REMOVE_DUPLICATES=true

##sbatch --array=1-5 -n 1 --cpus-per-task=10 --mem-per-cpu=20G -t 12:00:00 --job-name=3rep.markdup  mark-duplicates-array.sh 3.repetidas list-mark-duplicates.txt
