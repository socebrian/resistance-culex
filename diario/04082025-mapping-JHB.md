# Resistance culex pipiens and perexiguus - proyecto ecogen
## sonia cebrian camison scebrian27@gmail.com/sonia.cebrian@ebd.csic.es
### 08/04/2025

In this project we will study genes responsible of resistance to insecticides in CUlex pipiens and Culex perexiguus from wouthwestern Spain
We will be using a pipeline developed by French collegues (names?). First step is alligning my samples to a Cx quinquefasciatus reference genome
 https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_015732765.1/
I will use all 3 chromosomes, MT and any scaffolds there is and will be alligning only paired reads.


La cosa esque los archifos fastp.gz de  los tres primeros batch estan en POPPY y no en CESGA porque los movi. 
He hecho espacio en cesga y he movido los fastp aqui. Ya no estan en poppy. No estoy queriendo duplicar documentos.

Primero checkear cromosomas del ref genome.
grep ">" reference_genome.fasta | cut -d ' ' -f 1

>NC_051861.1 Culex quinquefasciatus strain JHB chromosome 1, VPISU_Cqui_1.0_pri_paternal, whole genome shotgun sequence
>NC_051862.1 Culex quinquefasciatus strain JHB chromosome 2, VPISU_Cqui_1.0_pri_paternal, whole genome shotgun sequence
>NC_051863.1 Culex quinquefasciatus strain JHB chromosome 3, VPISU_Cqui_1.0_pri_paternal, whole genome shotgun sequence

and the rest are inplaced scaffolds. But as i talked with mari, were gonna use all of them. 

Lets rename the chromosomes
```bash
zcat cx_quinque_jhb.fna.gz | sed 's/^>NC_051861.1/>1/' | sed 's/^>NC_051862.1/>2/' | sed 's/^>NC_051863.1/>3/' | sed 's/^>NC_014574.1/>MT/'  > cx_quinque_jhb_rename.fna

# indice para BWA
bwa index cx_quinque_jhb_rename.fna
# indice general
samtools faidx cx_quinque_jhb_rename.fna
# diccionario para gatk
samtools dict cx_quinque_jhb_rename.fna -o cx_quinque_jhb_rename.dict
```
Hago la lista para mapeo de 4.enero
```bash
for file in *.gz; do
    # Extract the first 9 characters of the file name
    sample_id="${file:0:9}"
    echo "$sample_id"
done | uniq | nl > list-align-output.txt
```

run mapping 
```bash
 sbatch -n 1 --cpus-per-task=15 --mem-per-cpu=10G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 3.repetidas list-al
ign-output.txt cx_quinque_jhb_rename.fna

sbatch --array=51-69 -n 1 --cpus-per-task=15 --mem-per-cpu=8G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 1.noviembre list-align-output.txt cx_quinque_jhb_rename.fna
# 11841402 F1-50, 11854623 51-69

sbatch --array=31-77 -n 1 --cpus-per-task=15 --mem-per-cpu=8G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 2.mayo list-align-output.txt cx_quinque_jhb_rename.fna
#11854626 1-30, 11860680 las demas

sbatch --array=101-150 -n 1 --cpus-per-task=5 --mem-per-cpu=8G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 4.enero list-align-output.txt cx_quinque_jhb_rename.fna
#11860752, 1-50, pero borre desde el 44 en adelante
#44-100 11866522 11893941

167
dir=${1} #3.repetidas
input=${2} #3.list-fastp-output.txt
ref=${3} # idCulPipi1.1.primary.fa
```

12, 13, , 14, 25, 37, 47, 56, 66, 74, 82, 83, 88, 
12  PP1036.L5
13  PP1040.L2
14  PP1041.L2
25  PP1157.L6
37  PP1221.L2
47  PP1312.L2
56  PP1411.L5
66  PP1490.L7
74  PP1552.L5
82  PP1589.L2
83  PP1592.L6
88  PP1636.L6
100  PP1685.L7  

Estos se cortaron por falta de tiempo. Borro los bams y repito
```bash
sbatch --array=12,13,14,25,37,47,56,66,74,82,83,88,100 -n 1 --cpus-per-task=10 --mem-per-cpu=15G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 4.enero list-align-output.txt cx_quinque_jhb_rename.fna
#12255156

sbatch --array=101-150 -n 1 --cpus-per-task=10 --mem-per-cpu=15G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 4.enero list-align-output.txt cx_quinque_jhb_rename.fna
# 12255170

sbatch --array=151-167 -n 1 --cpus-per-task=10 --mem-per-cpu=15G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 4.enero list-align-output.txt cx_quinque_jhb_rename.fna
# 12255209

sbatch --array=148 -n 1 --cpus-per-task=20 --mem-per-cpu=20G -t 6:00:00 --job-name=map1jhb bwa-align-array-cesga.sh 4.enero list-align-output.txt cx_quinque_jhb_rename.fna
#12273347
```
Todos estan bien asi que sigo con el indexing y sorting

```bash
sbatch --array=1-5 -n 1 --cpus-per-task=1 --mem-per-cpu=15G -t 03:00:00 --job-name=3rep.index  index-bam-array-cesga.sh 3.repetidas list-index.txt
#12495926_1
sbatch --array=1-69 -n 1 --cpus-per-task=1 --mem-per-cpu=2G -t 03:00:00 --job-name=3rep.index  index-bam-array-cesga.sh 1.noviembre list-index.txt
#12592723
sbatch --array=1-30 -n 1 --cpus-per-task=1 --mem-per-cpu=2G -t 03:00:00 --job-name=3rep.index  index-bam-array-cesga.sh 2.mayo list-index.txt
#12592794 1-20
# 31-77 12595462
sbatch --array=91-167 -n 1 --cpus-per-task=1 --mem-per-cpu=5G -t 03:00:00 --job-name=3rep.index  index-bam-array-cesga.sh 4.enero list-index.txt
#1-50 12595566
#51-90 12597162
#91-167 13065522
sbatch --array=148 -n 1 --cpus-per-task=1 --mem-per-cpu=20G -t 6:00:00 --job-name=3rep.index  index-bam-array-cesga.sh 4.enero list-index.txt
#313099235
```

flagstat.sh para cesga 
```bash
#SBATCH --mem-per-cpu=500M
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=15
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=scebrian27@gmail.com
#SBATCH --output=bam_index_%j.out
#SBATCH --error=bam_index_%j.err

module load samtools
dir=${1} #3.repetidas
for bam in /mnt/lustre/scratch/nlsas/home/csic/dbl/scc/resistencias/bams/1.noviembre/*sorted.rg.bam; do
    id=$(basename "${bam}" | cut -d '.' -f 1)
    lane=$(basename "${bam}" | cut -d '.' -f 2)
    echo "Processing ${id} ${lane}"
    samtools flagstat "${bam}" > "${id}.${lane}.stats"
    done
done
echo "all done"


sbatch -n 1 --cpus-per-task=1 --mem-per-cpu=20G -t 6:00:00 flagstats.sh
#13114014
 sbatch -n 1 --cpus-per-task=1 --mem-per-cpu=20G -t 6:00:00 flagstats.sh 2.mayo
# 13171474
 sbatch -n 1 --cpus-per-task=1 --mem-per-cpu=20G -t 6:00:00 flagstats.sh 3.repetidas
#13171475
sbatch -n 1 --cpus-per-task=1 --mem-per-cpu=20G -t 6:00:00 flagstats.sh 4.enero
#mv bam  13171476

```
Did the check of below 60% properly mapped

(base) [csdblscc@login210-18 ~]$ cat below60-properly-mapped.txt
PP1001.L7       73229459        67958962        90.30   41269980        60.73
PP1036.L5       112241581       104873898       85.80   62607546        59.70
PP1094.L8       50771252        47062828        90.00   26892488        57.14
PP1095.L8       44969824        41688530        90.08   24734192        59.33
PP1120.L6       43014970        39906502        91.00   23714456        59.43
PP1146.L2       6085727         5655078         90.18   3271220         57.85
PP1146.L6       37749521        34992472        90.34   20048418        57.29
PP1149.L2       5788523         5378406         89.81   3117420         57.96
PP1149.L7       40934162        37966866        89.79   21682748        57.11
PP1151.L8       42729888        39604964        89.64   22237216        56.15
PP1152.L7       41717374        38702836        89.06   21815848        56.37
PP1158.L7       45564074        42200358        90.63   24008260        56.89
PP1173.L6       70570713        68859972        56.01   26157932        37.99
PP1205.L3       6917396         6437420         89.62   3778328         58.69
PP1205.L7       37634485        34968048        89.71   20437628        58.45
PP1207.L8       43973079        40758860        89.73   23167520        56.84
PP1208.L2       5386482          5004166        89.63   2848212         56.92
PP1208.L8       40820411        37865954        89.65   21288586        56.22
PP1233.L8       47181258        43709428        90.09   25397634        58.11
PP1234.L2       5653950         5250414         89.13   3085252         58.76
PP1234.L8       41069130        38082266        89.07   22059976        57.93
PP1253.L2       18751826        17435654        89.64   10329998        59.25
PP1253.L6       25977261        24108604        89.90   14297740        59.31
PP1254.L7       37954364        35190834        90.47   21074190        59.89
PP1284.L7       42111379        39012318        89.26   21649510        55.49
PP1353.L8       41919105        38884706        90.05   22305328        57.36
PP1397.L5       40879911        39480426        61.61   16221936        41.09
PP1399.L2       14183284        13186918        89.99   7641400         57.95
PP1399.L6       29486540        27382058        90.20   15898574        58.06
PP1400.L6       42680830        39664262        89.45   22966022        57.90
PP1401.L2       14692632        13669440        90.16   8078912         59.10
PP1401.L6       28108064        26089700        90.17   15083024        57.81
PP1407.L2       8247825         7670958         89.74   4359232         56.83
PP1407.L7       39710441        36871570        89.86   20792474        56.39
PP1408.L2       4637295          4316430         90.37   2507462        58.09
PP1408.L7       37757868        35086164        90.38   20148196        57.42
PP1440.L7       61482341        59393686        61.38   24229350        40.79
PP1524.L8       52821868        50164426        62.33   19064324        38.00
PP1589.L2       124322118       119931820       62.35   49568214        41.33
PP1599.L4       71053519        68538156        64.74   30742156        44.85
PP1615.L7       71637432        69907800        57.47   28060296        40.14
PP1621.L7       73016389        70608846        60.50   28180344        39.91
PP1640.L7       50049447        46460990        88.02   25878772        55.70
PP1661.L5       9145343         8477650         89.63   5071328         59.82
PP1666.L7       68893883        66508752        61.41   26844606        40.36
PP1667.L2       6838595         6356464         88.97   3637410         57.22
PP1667.L7       41304809        38322270        89.01   21671444        56.55
PP1668.L2       79310346        73951378        85.76   44055560        59.57
PP1710.L8       42070624        39012906        89.65   22184818        56.87
PP1734.L8       46947553        43540700        89.48   24951352        57.31
PP1759.L2       73303723        70750548        61.84   28812416        40.72
PP1792.L2       6271926         5818770         89.88   3326048         57.16
PP1792.L7       38082956        35263392        89.91   19917162        56.48
PP1803.L7       77602001        74955038        62.06   31229018        41.66
PP1850.L7       72647674        70168668        61.83   29001284        41.33
PP1867.L2       117803298       113647676       64.33   50535356        44.47
PP1876.L8       48357918        44843574        89.86   25759044        57.44
PP1895.L7       20798805        19248570        89.14   11275420        58.58
PP1895.L8       26834869        24836278        89.62   14862518        59.84
PP1932.L8       44724961        41496580        90.53   24116628        58.12
PP1988.L7       43221711        40267078        84.34   21180766        52.60
PP2009.L8       46721806        43339906        89.10   24665492        56.91
PP2038.L8       44372295        41216408        88.37   23081696        56.00
PP2047.L5       10522081        9771212         87.77   5785474         59.21
PP2051.L5       46672541        43405844        88.10   25923162        59.72
PP2070.L2       6086694         5651852         90.32   3297120         58.34
PP2070.L7       39701885        36807546        90.34   21210346        57.62
PP2084.L2       6384016         5933438         89.83   3447288         58.10
PP2084.L7       39616475        36742000        89.89   21115664        57.47
PP2094.L2       7492923         6963930         87.97   3862644         55.47
PP2094.L7       39432233        36591728        87.93   20052272        54.80
PP2114.L2       5664450         5267028         89.44   3030130         57.53
PP2114.L7       39021785        36222494        89.39   20461210        56.49
PP2132.L7       42644597        39544948        90.04   22932944        57.99
PP2219.L8       44708935        41537710        88.60   23419980        56.38

BELOW 55
PP1173.L6       70570713        68859972        56.01   26157932        37.99
PP1397.L5       40879911        39480426        61.61   16221936        41.09  ++++++
PP1440.L7       61482341        59393686        61.38   24229350        40.79
PP1524.L8       52821868        50164426        62.33   19064324        38.00  ++++++
PP1589.L2       124322118       119931820       62.35   49568214        41.33
PP1599.L4       71053519        68538156        64.74   30742156        44.85
PP1615.L7       71637432        69907800        57.47   28060296        40.14
PP1621.L7       73016389        70608846        60.50   28180344        39.91
PP1666.L7       68893883        66508752        61.41   26844606        40.36
PP1759.L2       73303723        70750548        61.84   28812416        40.72
PP1803.L7       77602001        74955038        62.06   31229018        41.66
PP1850.L7       72647674        70168668        61.83   29001284        41.33
PP1867.L2       117803298       113647676       64.33   50535356        44.47
PP1988.L7       43221711        40267078        84.34   21180766        52.60
PP2094.L7       39432233        36591728        87.93   20052272        54.80

PP1397 y PP1524  tambien acabaron saliendose fuera del analisis en el otro proyecto. Nada fuera de lo normal.
Todos los demas por debajo de 55% mapeo son los que se salieron del analisis en el otro proyecto.

El mapeo si que es muy muy bajo.


## 3. marking suplicates
```bash	
ls *.sorted.rg.bam | sed 's/\.PR\.sorted\.rg\.bam$//' | sort -u | awk 'BEGIN { print "taskid\tsample" } { print NR "\t" $0 }' > md-list.txt
```
```bash
sbatch -n 1 --array=1-69 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 mark-duplicates-cesga.sh 1.noviembre md-list.txt
#mark_dup_13252549_9
sbatch -n 1 --array=1-100 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 mark-duplicates-cesga.sh 4.enero md-list.txt
#13299527
sbatch -n 1 --array=1-5 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 mark-duplicates-cesga.sh 3.repetidas md-list.txt
#13301391
sbatch -n 1 --array=1-77 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 mark-duplicates-cesga.sh 2.mayo md-list.txt
#13335507
sbatch -n 1 --array=101-167 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 mark-duplicates-cesga.sh 4.enero md-list.txt
#13337163
```
ahora hacer el merge

sbatch -n 1 --array=1-48 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 1.noviembre list-to-merge-bams.txt
sbatch -n 1 --array=1-47 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 2.mayo list-to-merge-bams.txt
sbatch -n 1 --array=1-3 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 3.repetidas list-to-merge-bams.txt
sbatch -n 1 --array=1-134 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 4.enero list-to-merge-bams.txt

   13394058_[1-3]            
   13394057_[1-47]            
   13394056_[1-48]  
se me olvido hacer merge de los md que habia que hacer merge asi que ktengo que corregirlo. primero hice dos listas para hacer cada dir del 1 al 3, una con las muestras que hay que repetir y otra con las que no

then i did this for each directory
```bash
mkdir -p 3.repetidas_to_fix

while read sample; do
    mv merged/3.repetidas/${sample}.merged.bam merged/3.repetidas_to_fix/
done < md-bams/3.repetidas/3.repetidas_samples_to_remerge.txt

```


mmodify the scriptto include the sorting and rerun first 3
sbatch -n 1 --array=1-48 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 1.noviembre list-to-merge-bams.txt
sbatch -n 1 --array=1-47 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 2.mayo list-to-merge-bams.txt
sbatch -n 1 --array=1-3 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 3.repetidas list-to-merge-bams.txt
sbatch -n 1 --array=1-50 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 4.enero list-to-merge-bams.txt

  13549579_[1-48]            short sort_mer csdblscc PD       0:00      1 (None)
  13569545_[1-50]            short sort_mer csdblscc PD       0:00      1 (Priority) enero
   13569542_[1-47]            short sort_mer csdblscc PD       0:00      1 (Priority)
    13569530_[1-3]            short sort_mer csdblscc PD       0:00      1 (Priority)

sbatch -n 1 --array=51-134 --cpus-per-task=10 --mem-per-cpu=20G -t 6:00:00 merge-bams-cesga.sh 4.enero list-to-merge-bams.txt
13584459