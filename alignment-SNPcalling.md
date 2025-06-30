# Proyec: SNPS Culex - ECOGEN
# pipieline for fastp trimming, alignment, variant calling and filtering
## sonia cebrian camison scebrian27@gmail.com/sonia.cebrian@ebd.csic.es
### 10/09/2024 - 15/1/2025

### 1: fastp trimming (culex conda env on CESGA pipiens 123) (talapas conda env fastp pipiens4 y perex)
Was done for the project on genomic structure and variance of Culex pipiens, check the project for more details.
## Error checking through the workflow
Was done the same way than for the project on genomic structure and variance of Culex pipiens, check the project for more details.

### 2. alining (culex conda env on talapas)
We used cx_quinque_jhb_rename.fna  reference genome. https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_015732765.1/ 
We renamed the reference to have the chormosomes names like 1, 2 and 3

Then was indexed using  
```bash
# indice para BWA
bwa index cx_quinque_jhb_rename.fna
samtools faidx cx_quinque_jhb_rename.fna
# diccionario para gatk
samtools dict cx_quinque_jhb_rename.fna -o cx_quinque_jhb_rename.dict
```

List to align samples were done like this:
Hago la lista para mapeo de 4.enero
```bash
for file in *.gz; do
    # Extract the first 9 characters of the file name
    sample_id="${file:0:9}"
    echo "$sample_id"
done | uniq | nl > list-align-output.txt
```
 * <bwa-align-array.cesga.sh> : get paired ends files and align. We are not currently using unpaired alligns for snp calling so they are not included iun the allignment.
 
```bash   
sbatch -n 1 --cpus-per-task=15 --mem-per-cpu=10G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 3.repetidas list-al
ign-output.txt cx_quinque_jhb_rename.fna
```

   ### 3. BAM indexing (culex conda env on talapas)
* <list-array-index-cesga.sh>: creates a list of taskid with samples an all their info of reads (reasds 1 or R2) and lanes to do the indexing
* <index-bam-array-cesga.sh>: take the list we just created and index all the bams with info about batch, lane, etc.
    * flagstat-summary.sh: generates a summary report with the flagstat results of all the samples in a single file.
```bash
sbatch --array=1-5 -n 1 --cpus-per-task=1 --mem-per-cpu=15G -t 03:00:00 --job-name=3rep.index  index-bam-array-cesga.sh 3.repetidas list-index.txt
```

 ### 4. Check mapping quality and properly mapped reads

After the alignment, I checked the mapping quality of the samples using <flagstats.sh> and <flagstat-summary.sh> to generate a summary report with the flagstat results of all the samples in a single file. The script was run like this:

```bash
sbatch -n 1 --cpus-per-task=1 --mem-per-cpu=20G -t 6:00:00 flagstats.sh
bash flagstat-summary.sh
```

Then I examined which samples had less than 60% and 55%  of properly mapped reads using:
```bash
 awk -F'\t' 'NR==1 || ($6 < 60)' summary.txt > below60-properly-mapped.txt
awk -F'\t' 'NR==1 || ($6 < 55)' summary.txt > below55-properly-mapped.txt
```
This samples were not excluded yet, but the imformation was taking into acount.

### 5. Mark duplicates (vcf environment on talapas)

We use 2 scripts for that:
I did the list of the samples to work with using 
```bash	
ls *.sorted.rg.bam | sed 's/\.PR\.sorted\.rg\.bam$//' | sort -u | awk 'BEGIN { print "taskid\tsample" } { print NR "\t" $0 }' > md-list.txt
```
* <mark-duplicates-array.sh>: it takes the list of samples works as an array eliminating all the duplicates from each file. As we are working with different runs (lanes) from the same samples that we are later going to merge, is better to erase all the duplicates instead of just marking them. I put the new bams resistencias/md-bams
```bash
mkdir resistencias/md-bams/1.noviembre
mkdir resistencias/md-bams/2.mayo
mkdir resistencias/md-bams/3.repetidas
mkdir resistencias/md-bams/4.enero

 

In the case of batch 4 of samples, we run flagstat again to check if the percentage of properly mapped reads was still low. The results were similar to the ones obtained before marking duplicates, so we decided to keep the samples with low mapping quality for now. In batches 1-3 we did not check this again.

```bash

As a result of using picard MarkdDuplicates we obtain for each sample on txt file with metrics about the duplications <PP1271.L6_marked_dup_metrics.txt>. To quickly check the percentage of duplications all the samples had I created one summary report for each bash of samples using this:
```bash
for file in /home/scamison/kernlab/scamison/1.noviembre/mark-duplicates/*_marked_dup_metrics.txt; do
    sample=$(basename "$file" | sed 's/_marked_dup_metrics.txt//')
    percent_dup=$(awk '/PERCENT_DUPLICATION/ {getline; print $9}' "$file")
    echo -e "${sample}\t${percent_dup}" >> 1.noviembre/mark-duplicates/duplicates-summary-1nov.txt
done
```
According tot the report, the duplication levels for each batch of samples were:
* --------------------

After this we indexed all samples
```bash
for bam in ./*bam ; do echo "indexing $bam"; samtools index $bam; done
```
#### mark-duplicates-array.sh
```bash
#variables
dir=${1} #3.repetidas
input=${2} #list of bam files

# Specify the path to the config file
sample_list="/home/scamison/kernlab/scamison/${dir}/bams/${input}"
bam_dir="/home/scamison/kernlab/scamison/${dir}/bams"
out_dir="/home/scamison/kernlab/scamison/${dir}/mark-duplicates"

# Read the sample ID for the current array task
sample=$(awk -v taskid="$SLURM_ARRAY_TASK_ID" '$1 == taskid {print $2}' "$sample_list")
in_bam="$bam_dir/${sample}.PR.sorted.rg.bam"
# Define output filenames
output_bam="$out_dir/${sample}.md.bam"
output_metrics="$out_dir/${sample}_marked_dup_metrics.txt"

# Debug: Print the sample variable
echo "Sample: $sample"
java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
    I=$in_bam \
    O=$output_bam \
    M=$output_metrics \
    REMOVE_DUPLICATES=true
```

### 5. Merge alignments form same sample, differente reads/lanes (culex conda env on talapas)

We use 2 scripts:
* <list-to-merge-bams.sh> : generates a list of samples with only PP**** codes, so can be used in future steps that only need to identify samples. This list need to have info separated for sample id and lane.
*<merge-bams-array.sh>: merge all the indexed bams correspondign to the same sample (paired and unpaired reads)
```bash
mkdir 3.repetidas/merged
sbatch list-to-merge-bams.sh 3.repetidas/mark-duplicates list-to-merge-bams.txt 
sbatch --array=1-50%5 -n 1 --cpus-per-task=1 --mem-per-cpu=2G -t 02:00:00 --job-name=2mayo.merge merge-bams-array.sh 2.mayo list-merge-bams.txt
```
Then merged files should be indexing
```bash
for bam_file in 3.repetidas/merged/*.bam; do
    echo "Indexing BAM file: $bam_file"
    samtools index "$bam_file"
done
#repeat for the other batch
```
#### merge-bams-aray.sh
```bash
# Directory containing BAM files
dir=${1} #3.repetidas
input=${2} #3.list-to-merge-bams.txt

sample_list="/home/scamison/kernlab/scamison/${dir}/mark-duplicates/${input}"
bam_dir="/home/scamison/kernlab/scamison/${dir}/mark-duplicates"
out_dir="/home/scamison/kernlab/scamison/${dir}/merged"

# Read the sample ID for the current array task
sample=$(awk -v taskid="$SLURM_ARRAY_TASK_ID" '$1 == taskid {print $2}' "$sample_list")

# Debug: Print the sample variable
echo "Sample: $sample"

# Find all BAM files for the current sample
bam_files=$(ls "$bam_dir"/"${sample}"*.md.bam)

# Check if BAM files exist
if [ -z "$bam_files" ]; then
    echo "Error: Input BAM files not found for sample ${sample} at ${bam_dir}"
    exit 1
fi

# Merge the BAM files
output_bam="$out_dir/${sample}.merged.bam"
samtools merge "$output_bam" $bam_files
```


### 5.checking of final bams: quality, duplicates and coverage (culex env on talapas)
1. To check the quality of the mapping qualimaps + multibamqc 
2. To check if there is new PCR duplicates: re-run MarkDuplicates
3. control coverage along the genome (to-do) 

1. qualimaps + multibamqc - QualiMap v.2.3

First I did qualimaps of everything using <qualimap.sh> and then did <qualimap multi-bamqc> for each batch of samples.
To run <qualimap multi-bamqc> I need to create a configuration file with info of all the samples I want to add to the report (id, path to bamqc results and "condition"-in my case, batch-). 

```bash
find /home/scamison/kernlab/scamison/3.repetidas/qualimaps -mindepth 1 -maxdepth 1 -type d | awk -F/ '{print $NF "\t" $0 "\t3.repetidas"}' > multibamqc_config_file.txt
find /home/scamison/kernlab/scamison/2.mayo/qualimaps -mindepth 1 -maxdepth 1 -type d | awk -F/ '{print $NF "\t" $0 "\t2.mayo"}' >> multibamqc_config_file.txt
find /home/scamison/kernlab/scamison/1.noviembre/qualimaps -mindepth 1 -maxdepth 1 -type d | awk -F/ '{print $NF "\t" $0 "\t2.mayo"}' >> multibamqc_config_file.txt

#then run multibamqc
qualimap multi-bamqc -d multibamqc/multibamqc_config_file.txt -outdir "./multibamqc" -outfile "pipiens_1234batch_multibamqc_report.pdf" -outformat PDF:HTML
```

SUMMARY
Number of samples 	230
Number of groups 	4 (4 batches of sequencing)
Total number of mapped reads 	11,270,506,831
Mean samples coverage 	12.18
Mean samples GC-content 	39.17
Mean samples mapping quality 	32.85
Mean samples insert size 	316

PCA shows some batch effects clustering samples from 2-3 separated bt PC1 from samples from batch 4. Biggest differences are shown between samples within batch 4.
Batch 4 clearly shows bigger probblems with GC content and mapping quality across the reverence. Some samples ave better coverage but sime others have way less than in precvious batches.

#### qualimap.sh
```bash
dir=${1} #3.repetidas

# Paths and variables
input_dir="/home/scamison/kernlab/scamison/${dir}/merged"	
output_dir="/home/scamison/kernlab/scamison/${dir}/qualimaps"

## Loop through each merged BAM file in the input directory
for bam_file in "$input_dir"/*merged.bam; do
    # Check if the BAM file exists to avoid errors
    if [[ -f "$bam_file" ]]; then
        # Extract sample ID from filename
        sample_id=$(basename "$bam_file" .merged.bam)

        echo "Running qualimap for sample: ${sample_id}"
        qualimap bamqc -bam "$bam_file" -outdir "${output_dir}/${sample_id}" -outfile "${sample_id}.merged.bamqc.pdf"  -outformat PDF:HTML
    else
        echo "No BAM files found in ${input_dir}"
    fi
done
```
#### 
2. To check if there is new PCR duplicates: re-run MarkDuplicates
I marked duplicates again with <mark-duplicates2.sh> yo check if there was any new duplicates created from merging. I redid a report with the results an all samples from 3 batches had <0.5% of duplicates.

Batches 1,2,3 show that there are not duplicates created by the merging process. Batch 4 was assumed to have not created duplicate reads either, so it was not checked again. 


3. check the coverage along the genome
* <coverage-mosdepth.sh>: loop thorught all the files within the actual directory to calculate depth statistics on each of them
* <mosdepth-coverage.R>: Uses the output <sample.mosdepth.global.dist.txt> from each sample to plot the distribution of depth along the genome (proportion of genome with different levels of depth). Then uses <sample.regions.bed.gz> to plot the mean coverage on 100K bases windows along each of the chormosomes. This script is run directly on an R session on the shell.

HACER RESUMEN DE CADA MUESTRA 
```bash
sbatch -n 1 --cpus-per-task=10 --mem-per-cpu=20G -t 23:00:00 coverage-mosdepth.sh
```
* Overview of Mosdepth outputs
    * sample.mosdepth.global.dist.txt: A global coverage distribution across all bases in the genome “How many bases have coverage 0, coverage 1, coverage 2, etc.?”
    * sample.mosdepth.region.dist.txt: Coverage distribution restricted to the intervals in your BED file (if you used --by somefile.bed or --by <size>). Similar to the global distribution but only for those “regions” as defined by the user or by Mosdepth’s default intervals.
    * sample.mosdepth.summary.txt A one-line summary for each “region set” (or entire genome) with average depth, total bases covered, etc. Quick overall stats, not detailed coverage along the genome.
    * sample.per-base.bed.gz Coverage for each individual base position in your sequence. The file will have lines like: chrom    start    end    coverage where start/end differ by 1 base. This can be very large if your genome is big.  Useful if you want to do your own binning later, but heavy on memory/disk.
    * sample.regions.bed.gz  Coverage summarized by each region. Where do these regions come from?
        If you used --by 100000, then these are 100 kb windows.
        If you provided a BED file of intervals, these regions match those intervals.
        If you did not provide any --by arguments, Mosdepth will produce coverage by “contigs” or by smaller default windows (depending on your version/config).
    Each line typically has:  chrom    start    end    mean_coverage. This is usually the most convenient file for plotting coverage in fixed windows.
    * Index files (.csi): These are just index files for the .bed.gz coverage data. Typically you can ignore them unless your downstream tool (e.g., samtools, bcftools, or some R packages) needs random-access to the coverage file.



