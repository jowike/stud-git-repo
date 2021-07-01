/*
LABORATORIUM NR: 6
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--6
UWAGI:
*/

/*deklaracja bibliotek*/
libname lab6 "/folders/myfolders/Labs/Lab6/lab06";

/*  -> Informats tell SAS how to read a variable.
	-> Formats tell SAS how to display a variable 
	     when printed to the output.  
*/


/*zadanie 1****************************************************************;*/

*a);
data out_z01a;	
	set lab6.l06z01 end=eos;
	*zapis dat eksperymentów w tablicy;
	array events{4} event_:;
	* przygotowanie tablicy na zmienne event: po konwersji;
	array dates{4} date_A date_B date_C date_D;
	
	* ANYDTDTE Informat: reads and extracts the date
	value from various date, time, and datetime forms.;

	do i=1 to dim(events);
		dates(i) = input(events(i), anydtdte11.);
	end;
	format date_: yymmdd10.;
	
	* wybór minimalnej i maksymalnej daty dla danego
	uczestnika (bieżącego wiersza);
	
	max_subject_date = max(of date_:);
	min_subject_date = min(of date_:);
	
	* porównanie minimum i maksimum lokalnych 
	z odpowiednio minimum i maksimum globalnymi;
	if _n_=1 then 
		do;
			min_date = min_subject_date;
			max_date = max_subject_date;
		end;
	else 
		do;
			if min_subject_date < min_date then min_date=min_subject_date;
			if max_subject_date > max_date then max_date=max_subject_date;
		end;
	* obliczenie czasu trwania całego eksperymentu;
	if eos then 
		do;
			duration_exp = max_date-min_date+1;
			output;
			keep duration_exp;
		end;
	retain min_date max_date;
run;

*b);
data out_z01b;
	set lab6.l06z01;
	
	array events{4} event_:;
	array dates{4} date_A date_B date_C date_D;
	
	
	do i=1 to dim(events);
		dates(i) = input(events(i), anydtdte11.);
	end;
	format date_: yymmdd10.;
	
	max_subject_date = max(of date_:);
	min_subject_date = min(of date_:);
	
	*obliczenie czasu trwania eksperymentu dla bieżącego uczestnika;
	duration_subject = max_subject_date-min_subject_date+1;
	format max_subject_date max_subject_date yymmdd10.;
	drop i event_:; 
run;

*c);
data out_z01c;
	retain exp_duration;
	merge out_z01a out_z01b;
	
	if _n_=1 then exp_duration=duration_exp;
	*obliczenie największego wspólnego dzielnika
	w celu skrócenia ułamka ratio a następnie 
	posortowania względem licznika/mianownika;
	greatest_divisor = gcd(duration_subject, exp_duration);
	numerator = duration_subject/greatest_divisor;
	denominator = exp_duration/greatest_divisor;
	
	*utworzenie zmiennej znakowej (ułamka zwykłego);
	ratio = cats(numerator,"/",denominator);
run;


proc sort data=out_z01c out=out_z01c(keep=lastname firstname sex height weight ratio);
by numerator denominator;
run;

/*zadanie 2****************************************************************;*/
data in_z02(keep=alph:);
   array vars{12} $1 alph1-alph12;
   do i=1 to 24;
      do j=1 to dim(vars);
      *zakres bajtów odpowiadającym literom 
      odpowiednio wielkim i małym: 65-90, 97-122.
      Małe i wielkie litery losuję zgodnie z rozkładem
      Bernoulliego parametryzowanym przez p=0.5;
      if rand("Bern", 0.5) then vars(j)=byte(int(65+26*ranuni(0))); 
      else vars(j)=byte(int(97+26*ranuni(0))); 
      end;
      output;
   end;
run;

* bez TRANSPOSE;


data out_z02a(keep=col:);
	array col{24} $ col1-col24;	
	array alph{12} $ alph1-alph12;
	*Zewnętrzna pętla iteruje po kolumnach a wewnętrzna 
	po wierszach.
	Wykorzystuję set z pointem ustawionym na iterator wierszy 
	i w celu przeprowadzenia transpozycji stosuję przypisanie:
	col(iterator wiersza)  = alph(iterator kolumny);
	do i=1 to 12;
		do j=1 to 24;
			set in_z02 point=j;
			
			col(j) = alph(i);
		end;
		output;
	end;
	*należy wprost przerwać DATA STEP,
	bo stosując POINT to wyłączamy domyślny stop;
	stop;
run;


* z TRANSPOSE;
proc transpose data=in_z02 OUT=out_z02b name=alph;
   var alph:; *names of variables to transpose;
run;


/*zadanie 3****************************************************************;*/

*transpozycja aby z nazw zmiennych stworzyć zmienną znakową,
która następnie będzie mogła zostać posortowana;
proc transpose data=lab6.l06z03 out=out_z03(rename=(_name_=id));
run;
proc sort data=out_z03 out=out_z03;
	by id;
run;

proc transpose data=out_z03 out=out_z03(drop=_name_);
	id id; *names of variables whose formatted values
			are used to form the names of the variables
			in the output data set.;
run;


/*zadanie 4****************************************************************;*/

*konwersja typów i stworzenie etykiet;
data temp_z04;
	set lab6.l06z04_a;
	index = put(index_val, commax6.);
	date_lab = put(date, date11.);
	lab = 'wynik z dnia: ' || date_lab;
	drop index_val date_lab;
run;

proc sort data = temp_z04 out = temp_z04;
	by firstname lastname;
run;

proc transpose data = temp_z04 out = out_z04(drop=_name_) let prefix=d_;
	format date yymmddn8.;
	by firstname lastname;
	id date;
	var index;
	idlabel lab; *names the variable whose values the procedure uses 
				  to label the variables that the ID statement names.;
run;


/*zadanie 5****************************************************************;*/

* dopóki między kolejnymi wartościami zmiennej grp jest zachowany 
porządek rosnący przypisuje wszystkie do tej samej grupy - 
to czy jest zachowany kontroluję porównując parami bieżącą i poprzednią
wart. tej zmiennej;
data temp_set;
	set lab6.l06z05_a;
	retain group 1;
	group_lag = lag(grp);
	if grp <= group_lag then group+1;
	drop group_lag;
run;

proc transpose data=temp_set out=out_z05(drop=_name_ group) let; 
*let allows duplicate values of an ID variable.;
	by group;
	id grp;
run;

/*zadanie 6****************************************************************;*/

proc sort data=lab6.l06z06_a out=out_z06;
	by descending j;
run;

*equals specifies the order of the observations in the output data set.
The NUMERIC_COLLATION option allows integers, expressed as text in a 
character string, to be ordered numerically;
proc sort data=out_z06 equals
	sortseq = linguistic(case_first=lower locale=pl_PL NUMERIC_COLLATION=ON);
	by i;
run;


/*KONIEC*******************************************************************;*/
