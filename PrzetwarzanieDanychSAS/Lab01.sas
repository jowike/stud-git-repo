libname lab "/folders/myfolders/Labs/Lab1";

* ZADANIE 1. ;

* (a) ;
data suma;
	retain sum 0; *.;
	set lab.l01z01;
	
	sum = sum + n;
run;

* rownowaznie: ;
data suma;
	*retain sum 0; *.;
	set lab.l01z01;
	
	sum + n;  *sum(sum, n);
run;

/* dostep do dokumentacji:
	? -> Pomoc SAS Studio -> SAS 9.4 and SAS Viya Programming */
	
/* ponownie rownowaznie: */
data suma;
	*retain sum 0; *.;
	set lab.l01z01 end = koniec;
	
	sum + n;  *sum(sum, n);
	
	if koniec then output;
run;

* (b) ;
data silnia;
	retain factorial 1; *.;
	set lab.l01z01;
	
	factorial = factorial * n;
run;

data silnia;
	retain factorial 1; *.;
	set lab.l01z01 end = koniec;
	
	factorial = factorial * n;
	if koniec then output;
run;

* ZADANIE 2. ;

/* ponizsza sekwencja zapobiega tworzeniu nowego zbioru sasowego,
czyli pozwala na przetwarzanie danych bez tworzenia zbioru wynikowego */
data _NULL_;

	birthDate = mdy(3, 3, 1999);
	actualDate = today();
	
	daysDiff = actualDate - birthDate;
	
	put "Dates difference expressed in days: " daysDiff;
run;

* ZADANIE 3. ;
data wyniki;
	input kod $ kol1 kol2 ocena;
	cards;
	AD11423 19 23 3.5
	AG19020 16 21 3
	AW93048 35 12 4
	RG04729 4 15 2
	DR03827 8 11 2
	;
run;

* (1) ;
libname bibl "/folders/myfolders/Labs/Lab1";

data bibl.wyniki;
	set wyniki;
run;

* (3) ;
proc print data = wyniki;
	sum kol1 kol2;
run;

proc summary data = wyniki;
	var kol1 kol2;
	output out = SumOut sum = ;
run;

proc print data = SumOut noobs;
    Title 'Total';
run; 

* ZADANIE 4. ; 

proc means data = wyniki;
	var kol1 kol2;
run;

proc means data = wyniki mean;
	var kol1 kol2;
run;


* ZADANIE 6. ;

data A B C;
	set sashelp.iris;
run;

proc delete library = work data = A B C;
run;










