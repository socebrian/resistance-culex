#!/bin/bash

#SBATCH --job-name=sort_merge_fix
#SBATCH --output=merge_bams_%A_%a.out
#SBATCH --error=merge_bams_%A_%a.err
#SBATCH --cpus-per-task=2
#SBATCH --array=1-20
#SBATCH --time=02:00:00

module load miniconda3
conda activate culex
module load samtools

dir=${1}
input=${2}

# File setup
list="/mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/md-bams/1.noviembre/${input}"
input_dir="/mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/md-bams/${dir}"
output_dir="/mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/merged/${dir}"

# Get sample from array index
sample=$(awk -v taskid=$SLURM_ARRAY_TASK_ID '$1 == taskid {print $2}' "$list")

echo "Fixing sample: $sample"

# Check if output already exists (optional — uncomment to skip already merged samples)
if [ -f "${output_dir}/${sample}.merged.bam" ]; then
     echo "Merged BAM already exists for $sample. Skipping."
     exit 0
 fi

# Temporary sorted BAM dir
tmp_dir="tmp_sorted_bams/${sample}"
mkdir -p "$tmp_dir"

# Find input BAMs
bam_files=( $(ls ${input_dir}/${sample}*.md.bam) )

sorted_bams=()
for bam in "${bam_files[@]}"; do
    sorted_bam="${tmp_dir}/$(basename ${bam%.bam}).sorted.bam"
    samtools sort -@ 9 -o "$sorted_bam" "$bam"
    sorted_bams+=("$sorted_bam")
done

# Merge sorted BAMs
output_bam="${output_dir}/${sample}.merged.bam"
samtools merge -@ 9 -o "$output_bam" "${sorted_bams[@]}"

# Check if merge succeeded and then clean up
if [ $? -eq 0 ]; then
    echo "Merge successful for $sample. Cleaning up temp files."
    rm -r "$tmp_dir"
else
    echo "Merge failed for $sample. Keeping temp files for inspection."
fi

# Optional: create BAM index
samtools index "$output_bam"

echo "Finished sample: $sample"

echo "Done with sample: $sample"
