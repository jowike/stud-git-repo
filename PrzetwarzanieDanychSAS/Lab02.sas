libname lab2 "/folders/myfolders/Labs/Lab2/lab02";

/* Ad. 1. */
data Dataset_1;
* set random seet for results reproducibility ;
*call streaminit(123);       
n = rand("Integer", 10, 1000);
do i = 1 to n;
   x = rand("Uniform", -1, 1);     
   y = rand("Normal", 3, 1);
   output;
end;
drop n i;
run;

data MeanMax;
	retain tot_x tot_y n 0;
	retain max_x max_y .M;

	set Dataset_1;
	
	tot_x = tot_x + x;
	tot_y = tot_y + y;
	n = n + 1;
	mean_x = tot_x/n;
	mean_y = tot_y/n;
	
	if x > max_x then max_x = x;
	if y > max_y then max_y = y;
	
drop x y n tot_x tot_y;
run;

*verification of the correctness of the result in the last iteration;
proc means data = Dataset_1 mean max;
run;

/* Ad. 2. */

data MultipliedCopies;
	set lab2.l02z02;
	do i = 1 to x;
		output;
	end;
drop i;
run;

/* Ad. 3. */
/* method suitable for the if and only if an
	assumption of descending observations order is met */
data Classifier_I;
	retain id x class 0;
	set lab2.l02z03;
	if dif(x) < 0 then class = class + 1;
	output;
run;


/* methods suitable even if an assumption 
	of descending observations order is not met */
	
/* the simplest solution would be to sort the observations
 in descending order and use the method implemented above */
proc sort data = lab2.l02z03s out = l02z03s_sorted;
   by descending x;
run;

data Classifier_IIa;
	retain id x class 0;
	set l02z03s_sorted;
	if dif(x) < 0 then class = class + 1;
	output;
run;

	
/*An alternative approach:*/
	
/* extraction of distinct x values from given dataset */
proc iml;
use lab2.l02z03s;
read all var {x};
close;

dist_x = (unique(x))`;

create DistinctValues from dist_x [colname="x"];
append from dist_x;
close;
quit;

/* assigning unique classes to individual values */
data Classes;
  set DistinctValues;
  class=_n_;
run;

/* assigning classes to observations through the results merge */
proc sql;
    create table Classifier_IIb as
    select id, l02z03s.x, class
    from work.classes left join lab2.l02z03s
    on classes.x = l02z03s.x
    order by id;
quit;

/* Ad. 4. */
data FluctuationsCnt;
	retain incr decr 0;
	set lab2.l02z04 end=eof;
	diff = dif(index);
	if _n_=1 then return;
	else
		if diff > 0 then
			do;
				incr = incr + 1;
				*output;
			end;
		else if diff < 0 then
			do;
				decr = decr + 1;
				*output;
			end;
	drop index data diff;
	if eof then output;
run;


proc print
	data = FluctuationsCnt;
run;

/* Ad. 5. */

data _null_;
	put _all_;
	set lab2.l02z05;
	put _all_;
	v3 = v1 + v2;
	retain v3;
run;
	
data _null_;
	put _all_;
	set lab2.l02z05;
	v3 = v1 + v2;
	v4 = v3;
	put _all_;
	retain v3;
run;

data _null_;

	if _N_ = 1 then 
	do;
		put v1= v2= v3= v4=;
		put v1= v2= v3= v4=;
	end;
	
	set lab2.l02z05;
	if _N_ = 1 then 
	do;
		v3 = v4;
		v4 = v1 + v2;
		put v1= v2= v3= v4=;
		v3 = v4;
		put v1= v2= v3= v4=;
	end;
	else 
	do;
		v4 = v1 + v2;
		put v1= v2= v3= v4=;
		v3 = v4;
		put v1= v2= v3= v4=;
		retain v4;
	end;
run;

data _null_;
	retain x 0;
	if x = 0 then
	do;
		put v1= v2= v3= v4=;
		put v1= v2= v3= v4=;
		x = x + 1;
	end;
	set lab2.l02z05;
	retain v4;
	v4 = v1 + v2 ;
	put v1= v2= v3= v4=;
	v3 = v1 + v2;
	
	put v1= v2= v3= v4=;
run;

/* Ad. 6. */
data LocMaxCnt;
	retain cnt 0;
	* one step forward move;
	_n_ = _n_ + 1;
	if _n_ <= n then
	do;
		set lab2.l02z04 point=_n_;
		next = index;
	end;
	else
		next = .;
	set lab2.l02z04 nobs = n end = eof_inner;
	*remember the value passed on the previous call;
	prev = lag(index);
	/* if current item is smaller than both
	previous and next then this is a local maximum */
	if index > prev and index > next then cnt = cnt + 1;
	drop data index next prev;
	if eof_inner then output;
run;
	
proc print
	data = LocMaxCnt;
run;

/* Ad. 7. */
data Imputed_I;
	* one step forward move;
	_n_ = _n_ + 1;
	if _n_ <= n then
	do;
		set lab2.l02z07 point=_n_;
		next = x;
	end;
	else
		next = .;
	set lab2.l02z07 nobs = n;
	*remember the value passed on the previous call;
	prev = lag(x);
	if missing(x) then x = (next+prev)/2;
	keep x;
run;


/* In order to complete the task with a given 
assumption, that the missings may be single 
or double it is necessary to know two predecessors 
and two successors of the current item.
To extract both predecessors, it is enough to call 
lag and lag2 functions, respectively. 
While to extract information about an item that
follows the immediate successor, an auxiliary set 
is needed that stores individual observations together
with their direct successors*/

data xWithNext;
* one step forward move if possible;
	_n_ = _n_ + 1;
	if _n_ <= n then
	do;
		set lab2.l02z07s point=_n_ end=eof_outer;
		next = x;
	end;
	else
		next = .;
	set lab2.l02z07s nobs = n;
run;

data Imputed_II;
	* one step forward move;
	_n_ = _n_ + 1;
	if _n_ <= n then
	do;
		set xWithNext point=_n_ end=eof_outer;
		next2 = next;
	end;
	else
		next2 = .;
	set xWithNext nobs = n;
	*remember the value passed on the previous call;
	prev = lag(x);
	prev2 = lag2(x);
	
	if missing(x) and missing(prev) then x = (prev2+next)/2;
	else if missing(x) and missing(next) then x = (prev+next2)/2;
	else if missing(x) then x = (prev+next)/2;
	keep x;
run;

/* Ad. 8 */

*Create the empty dataset;

data xModif;
	set lab2.l02z08 ;
	do i = 1 to rand("Integer", 0, 5);
		call missing(x_modif);
		output;
	end;
	x_modif = x;
	output;
run;	

data yModif;
	set lab2.l02z08 ;
	do i = 1 to rand("Integer", 0, 5);
		call missing(y_modif);
		output;
	end;
	y_modif = y;
	output;
run;	

data MissingFill;
	merge xModif yModif;
	drop i x y;
run;

/* Ad. 9. */
data Fx;
do k = -1 to 40;
	cumulativeProp = poisson(10, k);
	output;
end;
run;

data px;
	retain k p m 0;
	set Fx;
	if k < 0 then 
	do;
		output;
		return;
	end;
	if k = 0 then
	do;
		m = -log(cumulativeProp);
		p = cumulativeProp;
		output;
		return;
	end;
	else
		p = (exp(1)**(-m) * m**k)/fact(k);
		output;
	keep k p;
run;


/* Ad. 10. */

/* a set containing independently 
generated trajectories */
data RandomWalks;
	retain partialSum1 partialSum2 0;
	output;
	do i = 1 to 10;
		item1 = sign(rand('normal',0,1));
		item2 = sign(rand('normal',0,1));
		partialSum1 = partialSum1 + item1;
		partialSum2 = partialSum2 + item2;
		output;
	end;
	drop i item1 item2;
run;

* maximum deviation from 0;
data MaxDev;
	retain x_dev y_dev .M;
	set RandomWalks end=eof;
	if abs(partialSum1) > x_dev then x_dev = abs(partialSum1);
	if abs(partialSum2) > y_dev then y_dev = abs(partialSum2);
	if eof then 
	do;
		put x_dev=;
		put y_dev=;
	end;
run;

*verification of the correctness 
of the result printed to log;
proc means data = RandomWalks;
	
* the number of common vertices;
data CommonVertCnt;
	retain cnt 0;	
	set RandomWalks end=eof;
	if partialSum1 = partialSum2 then cnt = cnt + 1;
	if eof then put cnt=;
run;
	
* the number of intersections;
data RandomWalks_II;
	* one step forward move if possible;
	_n_ = _n_ + 1;
	if _n_ <= n then
	do;
		set RandomWalks point=_n_;
		ps1_next = partialSum1;
		ps2_next = partialSum2;
	end;
	else
	do;
		ps1_next = .;
		ps2_next = .;
	end;
	set RandomWalks nobs = n;
		ps1_prev = lag(partialSum1);
		ps2_prev = lag(partialSum2);
run;

data IntersectCnt;
/* I assume that the two functions values 
alignment is equivalent to their intersection */

	retain cnt 0;
	set RandomWalks_II end = eof;
	if _n_=1 or eof then return;
	/* counting intersections by partial sums values counting intersections by comparison  */
	if partialSum1 = partialSum2 and ps1_prev < ps2_prev and ps1_next > ps2_next then cnt = cnt+1;
	if partialSum1 = partialSum2 and ps1_prev > ps2_prev and ps1_next < ps2_next then cnt = cnt+1;

	if eof then put cnt=;
run;
	
	
