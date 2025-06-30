#!/bin/bash

#SBATCH --output=list_index_%j.out
#SBATCH --error=list_index_%j.err
#SBATCH --mem-per-cpu=500M
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=scebrian27@gmail.com

#this script creates a list with all the samples and necessary information to index them (bam files)
dir=${1} #3.repetidas
output=${2} # name of output file

# Construct the full path for the output file
output_path="//mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/bams/${dir}/${output}"

# Write the header line to the output file
echo -e "taskid\tid\ttlane\ttread\text" > $output_path

# Initialize a counter for the ID column
taskid=1

# List all files in the directory
for filename in "/mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/bams/${dir}"/*.bam; do
    # Check if the file ends with any of the specified suffixes
    if [[ "$filename" =~ \.(R1|R2|PR)\.bam$ ]]; then
        # Extract the base name of the file (without the directory path)
        base_filename=$(basename "$filename")
        # Split the filename into components using the dot (.) as a delimiter
        IFS='.' read -r id lane read ext <<< "$base_filename"
        # Write the extracted parts to the output file
        echo -e "$taskid\t$id\t$lane\t$read\t$ext" >> "$output_path"
        # Increment the task ID counter
        taskid=$((taskid + 1))
    fi
done


# sbatch list-job-array.sh 3.repetidas/bams list-index-bams.txt