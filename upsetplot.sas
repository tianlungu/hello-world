%let out =/pubdata/batch_job/tianlungu;

ods listing image_dpi=300;
ods graphics / attrpriority=color imagename='UpSet';

/* create imaginary data for sizes of subgroups */
data intersection_size;
xlabel1='set 1';count1=65;group='Treatment';output;
xlabel1='set 1';count1=65;group='Placebo';output;
xlabel1='set 2';count1=37;group='Treatment';output;
xlabel1='set 2';count1=36;group='Placebo';output;
xlabel1='set 3';count1=25;group='Treatment';output;
xlabel1='set 3';count1=20;group='Placebo';output;
xlabel1='set 4';count1=18;group='Treatment';output;
xlabel1='set 4';count1=20;group='Placebo';output;
xlabel1='set 5';count1=8;group='Treatment';output;
xlabel1='set 5';count1=10;group='Placebo';output;
run;

/* create imaginary data for the size of the univariate subgroups */
data covar_set_size;
xlabel2='covariate1';count2=130;output;
xlabel2='covariate2';count2=110;output;
xlabel2='covariate3';count2=73;output;
xlabel2='covariate4';count2=50;output;
run;

/* Prepare data for matrix layout */

/* allows visualising the composition of the subgroup by showing which sets are intersected. */

/* create imaginary data for intersection sets and covariates */
/* This dataset needs to contain information about interaction of covariates for each intersection set.

value=0: indicates that the covariate is absent
value=1: indicates that the covariate is present
*/

data sets;
xlabel3='set 1'; ylabel3='covariate1'; value=1; output;
xlabel3='set 1'; ylabel3='covariate2'; value=0; output;
xlabel3='set 1'; ylabel3='covariate3'; value=0; output;
xlabel3='set 1'; ylabel3='covariate4'; value=0; output;
xlabel3='set 2'; ylabel3='covariate1'; value=0; output;
xlabel3='set 2'; ylabel3='covariate2'; value=0; output;
xlabel3='set 2'; ylabel3='covariate3'; value=1; output;
xlabel3='set 2'; ylabel3='covariate4'; value=0; output;
xlabel3='set 3'; ylabel3='covariate1'; value=1; output;
xlabel3='set 3'; ylabel3='covariate2'; value=1; output;
xlabel3='set 3'; ylabel3='covariate3'; value=0; output;
xlabel3='set 3'; ylabel3='covariate4'; value=0; output;
xlabel3='set 4'; ylabel3='covariate1'; value=0; output;
xlabel3='set 4'; ylabel3='covariate2'; value=1; output;
xlabel3='set 4'; ylabel3='covariate3'; value=1; output;
xlabel3='set 4'; ylabel3='covariate4'; value=0; output;
xlabel3='set 5'; ylabel3='covariate1'; value=1; output;
xlabel3='set 5'; ylabel3='covariate2'; value=1; output;
xlabel3='set 5'; ylabel3='covariate3'; value=1; output;
xlabel3='set 5'; ylabel3='covariate4'; value=0; output;
run;

/* To join the interactions, create new variable which will tell us
which covariates to join. */

data _temp (keep = xlabel3  count newval);
set sets;
retain count ;
by xlabel3;
if first.xlabel3 then do;
count + 1;
newval = 0 ;
end;
newval + value;
if last.xlabel3;
run;

data matrix (drop=count newval);
merge sets _temp;
by xlabel3 ;
if newval > 1 and value > 0 then join = count;
else join = 0;
run;


data plotdata;
merge intersection_size covar_set_size matrix;
run;

/* template code */

proc template;
define statgraph mygraph;
begingraph;
entrytitle halign=left "UpSet Plot";
entryfootnote halign=right "Created Using GTL";
/* define an attribute map that will be used to control the appearances of the plots */
/* tip: for the matrix layout, we don't need to display the joined lines where join=0, so we will hide it by setting the linethickness=0 */

DiscreteAttrVar attrvar=MYID_VALUE var=VALUE attrmap="__ATTRMAP__MYID";
DiscreteAttrVar attrvar=MYID_JOIN var=JOIN attrmap="__ATTRMAP__MYID";
DiscreteAttrVar attrvar=MYID_GROUP var=GROUP attrmap="__ATTRMAP__MYID";
DiscreteAttrMap name="__ATTRMAP__MYID" /;
Value "0" / markerattrs=( color=CXD3D3D3) lineattrs=( thickness=0);
Value "1" / markerattrs=( color=CX000000) lineattrs=( thickness=2);
Value "Treatment" / fillattrs=( color=BIBG) ;
Value "Placebo" / fillattrs=( color=BIGB) ;
EndDiscreteAttrMap;

/* define 2x2 lattice layout w/ rowweights and columnweights */
layout lattice / rows=2 columns=2 rowweights=(0.7 0.3) columnweights=(0.2 0.8);

/* tip: keep the first cell empty */
cell;
entry "";
endcell;

/* this cell has the main plot used to represent the sizes of the subgroups across Placebo and Treament */

cell;
layout overlay / border=false walldisplay=none xaxisopts=(display=none) yaxisopts=(label="Intersection Size");
Barchart X='xlabel1'n Y='count1'n / display=(fill) barlabel=true
Group=MYID_GROUP NAME="BAR1" groupdisplay=stack includemissinggroup=False;
discretelegend "BAR1" / border=False location=inside autoalign=(topright);
endlayout;
endcell;

/* this cell contains the plot used to represent the sizes of univariate subgroups */

cell;
layout overlay / border=false walldisplay=none xaxisopts=(reverse=True label="Total") y2axisopts=(display=none);
Barchart X='xlabel2'n Y='count2'n / display=(fill) displaybaseline=off fillattrs=(color=orange)
NAME="BAR2" orient=horizontal yaxis=y2;
endlayout;
endcell;

/* this cell contains the plot used to represent the composition of subgroup  */

cell;
layout overlay / border=false walldisplay=none 
yaxisopts=(display=(tickvalues) discreteopts=(colorbands=odd colorbandsattrs=(color=lightgray transparency=0.6))) 
xaxisopts=(display=none );
ScatterPlot X='xlabel3'n Y='ylabel3'n / subpixel=off primary=true 
Group=MYID_VALUE Markerattrs=( Symbol=CIRCLEFILLED Size=12) 
LegendLabel="ylabel3" 
NAME="SCATTER";
SeriesPlot X='xlabel3'n Y='ylabel3'n / Group=MYID_JOIN 
Lineattrs=( Color=CX000000) LegendLabel="ylabel3" 
NAME="SERIES";
endlayout;
endcell;

endlayout;
endgraph;
end;
run;

ods rtf file="&out./upsetplot.rtf" nogtitle nogfootnote;
proc sgrender data=plotdata template=mygraph;
run;
ods rtf close;


