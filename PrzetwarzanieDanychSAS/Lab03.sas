/*
LABORATORIUM NR: 3
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--7
UWAGI:
*/

/*deklaracja bibliotek*/
libname lab3 "/folders/myfolders/Labs/Lab3/lab03";


/*zadanie 1****************************************************************;*/

proc contents data = lab3.l03z01;
run;

data in_z01;
	do i = rank("A") to rank("Z");
		x = byte(i);
		do j = 1 to rand('integer', 3);
			y = rand('integer', 100);
			output;
		end;
	end;
	* End-of-file flag addition;
	x = "_";
	y = .;
	output;
	keep x y;
run;


data out_z01a;
	retain sum 0 cnt 1;
	set in_z01;
	x_prev = lag(x);
	x_prev_en = rank(x_prev);
	
	if missing(x_prev) then 
	do;
		sum = y;
		cnt = 1;
		return;
	end;
	if rank(x) = x_prev_en then 
	do;
		sum = sum + y;
		cnt = cnt + 1;
	end;
	else do;
		mean = sum/cnt;
		output;
		sum = y;
		cnt = 1;
	end;
	
	keep x_prev mean;
run;

	
data out_z01b;
	retain sum cnt 0;
	set in_z01;
	by x;
	* End-of-file flag removal;
	if y=. then delete;
	
	sum = sum + y;
	cnt = cnt + 1;
	
	if first.x = 1 then
	do;
		sum = y;
		cnt = 1;
	end;
	if last.x = 1 then
	do;
		mean = sum/cnt;
		output;
	end;
	keep x mean;
run;
	
/*zadanie 2****************************************************************;*/

data in_z02;
	do i = 1 to 5e4;
		x = rand('uniform',0,120);
		if 100 < x <= 120 then layer = "(100, 120]";
		else if 80 < x <= 100 then layer = "(80, 100]";
		else if 60 < x <= 80 then layer = "(60, 80]";
		else if 40 < x <= 60 then layer = "(40, 60]";
		else if 20 < x <= 40 then layer = "(20, 40]";
		else layer = "[0, 20]";
		output;
	end;
	drop i;
run;

proc sort DATA=in_z02 OUT=in_z02;
 BY descending layer;
run;

data out_z02abc;
	retain n min max 0;
	set in_z02;
	by descending layer;
	
	n + 1;
	if x > max then max = x;
	if x < min then min = x;
	
	if first.layer = 1 then
	do;
		n = 1;
		min = x;
		max = x;
	end;
	if last.layer = 1 then
	do;
		output;
	end;
	drop x;
run;


/*zadanie 3****************************************************************;*/

data in_z03;
	retain cnt x_cnt 0 grp 1;
	set lab3.l03z03;
	by x;
	
	x_cnt + 1;
	if first.x = 1 then 
	do;
		cnt + 1;
		x_cnt = 1;
	end;
	
	if last.x = 1 then output;
	
	if cnt > 12 then 
		do;
			grp + 1;
			cnt = 1;
		end;
	drop cnt;
run;

data out_z03;
	retain max_freq argmax_freq 0;
	set in_z03;
	by grp;
	
	if last.grp = 1 then
	do;
		output;
		max_freq = 0;
		argmax_freq = 0;
	end;
	
	if x_cnt >= max_freq then 
	do;
		max_freq = x_cnt;
		argmax_freq = x;
	end;
	keep grp argmax_freq;
run;

/*zadanie 4****************************************************************;*/

* a);

/* duplicated records removal */
proc sort data=lab3.l03z04 out=in_z04a nodup;
 by liczba;
run;

proc means data=in_z04a n;
by liczba;
var liczba;
output out=out_z04(drop=_TYPE_ _FREQ_) n=/autoname;
run;

data out_z04a;
set out_z04;
if liczba_N < 4 then delete;
run;

* b);

proc sort data = out_z04 out=out_z04b;
   by descending liczba_N;
run;

data _null_;
	set out_z04b;
	by descending liczba_N;
	if last.liczba_N = 1 then 
	do;
		put "Numbers present in the greatest number of groups: " liczba;
		stop;
	end;
run;
 
* c);

data out_z04c;
	retain cnt sum 0;
	set lab3.l03z04;
	by litera;

	cnt + 1;
    sum + liczba;

    if first.litera = 1 then
        do;
            cnt = 1;
            sum = liczba;
        end;
    if cnt = 5 then 
    do;
    	mean = sum/5;
    	output;
    end;
    keep litera mean;
run;
	

* d);	
	
/* individual groups sizes */
proc means data=lab3.l03z04 n;
by litera;
var liczba;
output out=grpCnt_z04(drop=_TYPE_ _FREQ_) n=/autoname;
run;

data out_z04d;
	retain sum start 0;
	merge lab3.l03z04 grpCnt_z04;
	by litera;
	
	if first.litera = 1 then
	do;
		start = _n_ + liczba_N - 5;
		sum = 0;
	end;
	
	if _n_ >= start then 
	do;
		sum = sum + liczba;
	end;
	if last.litera = 1 then 
	do;
		mean = sum/5;
		output;
	end;
	keep litera mean;
run;


* e);

data out_z04e;
	retain flag_0 flag_9 0;
	set lab3.l03z04;
	by litera;
	
	if liczba = 0 then flag_0 = 1;
	if liczba = 9 then flag_9 = 1;
	
	if last.litera = 1 then 
	do;
		if flag_0 = 0 or flag_9 = 0 then
		do;
			output;
		end;
		
		flag_0 = 0;
		flag_9 = 0;
	end;
	keep litera;
run;
	
* f);
proc sort data=lab3.l03z04 out=in_z04f;
 by litera liczba;
run;

proc means data=in_z04f n;
by litera liczba;
var liczba;
output out=tmp_z04f(drop=_TYPE_ _FREQ_) n=/autoname;
run;


proc means data = tmp_z04f max;
by litera;
var liczba_N;
output out=out_z04f(drop=_TYPE_ _FREQ_) max=/autoname;
run;

proc sort data = out_z04f out=out_z04f;
   by descending liczba_N_Max;
run;

data _null_;
	set out_z04f;
	by descending liczba_N_Max;
	
	put "Letter with the greatest numbers of duplicates: " litera;
	
	if last.liczba_N_Max = 1 then stop;
run;



/*zadanie 5 ****************************************************************;*/

/* unique records removal */
proc sort data = lab3.l03z05 out = arg_duplicates 
	nouniquekey;
    by grupa argument;
run;

/* entirely duplicated records removal */
proc sort data = arg_duplicates out = entire_duplicates uniqueout = out_z05
     nouniquekey;
     by grupa argument wartosc;
run;
/* thus out_z05 dataset holds only these groups where for
 one argument exists more than one value*/

data _null_;
	set out_z05;
	by grupa;
	if first.grupa = 1 then 
		put "Pary zmiennych (argument, wartosc)
			 nie definiują funkcji w obrębie grup: " grupa;
run;


/*zadanie 6 ****************************************************************;*/

* a);
proc sort data=lab3.l03z06 out=in_z06a;
by plec partia;
run;


proc means data=in_z06a mean;
by plec partia;
var p;
output out=out_z06a(drop= _TYPE_ _FREQ_) mean=;
run;

* b);

proc summary data=lab3.l03z06 sum;
by id;
var p;
output out=out_z06b(drop= _TYPE_ _FREQ_) sum=;
run;

data _null_;
retain cnt 0;
set out_z06b end = eof;
if p < 100 then cnt = cnt+1;
if eof then put "Number of people considering voting 
				for parties different than these under 
				consideration is: " cnt;

run;

* c);

proc sort data=lab3.l03z06 out=in_z06c;
by id partia;
run;

proc summary data=in_z06c sum;
by id partia;
var p;
output out=tmp_z06c(drop= _TYPE_ _FREQ_) sum=;
run;


data out_z06c;
    retain count_AB count_AC count_BC 0;
    set tmp_z06c end=eof;
    by id;
    prev = lag(p);
    prev2 = lag2(p);

    if last.id then
        do;
            p_ab = prev2 + prev;
            p_ac = prev2 + p;
            p_bc = prev + p;

            if p_ab > max(p_ac, p_bc) then cnt_AB + 1;
            if p_ac > max(p_ab, p_bc) then cnt_AC + 1;
            if p_bc > max(p_ab, p_ac) then cnt_BC + 1;
        end;
    keep cnt_AB cnt_AC cnt_BC;
    if eof then output;
run;


/*zadanie 7 ****************************************************************;*/

proc sort data=lab3.l03z07 out=in_z07;
by okr;
run;

/* with an accompanying assumption that the first 
and last observation in each group cannot be a missing*/

data tmp_z07;
	retain first avg .;
	set in_z07;
	by okr;
		
	if first.okr = 1 then first = pcz;
	if last.okr = 1 then 
	do;
		avg = (first + pcz)/2;
		output;
	end;
	keep okr avg;
run;

data out_z07;
	merge in_z07 tmp_z07;
	by okr;
	
	if missing(pcz) then pcz = avg;
	output;
	keep okr pcz;
run;

/* average Adams factor level */
proc means data=out_z07 mean;
var pcz;
run;

/* range of average Adams factor level among groups  */
proc means data=out_z07 mean;
by okr;
var pcz;
output out=class_means mean=;
run;

proc means data=class_means min max range;
var pcz;
run;



/*KONIEC*******************************************************************;*/
