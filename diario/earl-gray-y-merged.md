# Resistance culex pipiens and perexiguus - proyecto ecogen
## sonia cebrian camison scebrian27@gmail.com/sonia.cebrian@ebd.csic.es
### 29/04/2025


I used culex TE for RM.lib as a library for the repeatmasker. Is done for Culex quinquefasciatus and can be found here https://figshare.com/s/1f6a69f78f20107734e0?file=41108324
 
Estoy pasando ref de quinque a poppy para correr ahy earlgray y luego ya lo vuelvo a pasar a cesga. 
 
screen -s earlgrey
conda activate earlgrey
earlGrey -g cx_quinque_jhb_rename.fna -s cx_quinqueTE -t 16 -l culex_TE_for_RM.lib -c yes -d yes -o ./ |& tee run.log

