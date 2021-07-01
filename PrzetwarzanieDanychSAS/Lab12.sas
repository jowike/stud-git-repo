/*
LABORATORIUM NR: 12
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--9
UWAGI: 
*/

/*deklaracja bibliotek*/
libname lab6 "/folders/myfolders/Labs/Lab6/lab06";
libname lab12 "/folders/myfolders/Labs/Lab12/lab12";

/*zadanie 1****************************************************************;*/
/* Załózmy, ze podany jest zbiór z o zmiennych tekstowych zbior i zmienna; kazda obserwacja zawiera
nazwe zmiennej (zmienna), która nalezy wyciac ze zbioru o nazwie zbior. Napisac i zaprezentowac działanie
makra, które wczytuje zbiór z oraz odpowiednie zbiory w nim wymienione, wycina z nich odpowiednie zmienne
i skleja je jedna obok drugiej do pojedynczego zbioru sasowego (mozna załozyc, ze wczytywane zbiory maja
unikalne, w skali globalnej, nazwy zmiennych). */

%macro concat(zbior);
  data _null_;
	set &zbior nobs=n_obs;
	* stworzenie makrozmiennych przechowujących nazwy 
	wszystkich zbiorów i odpowiadających im zmiennych;
	call symput(cat('zmienna', _n_), zmienna);
	call symput(cat('zbior', _n_), zbior);
	* zliczenie zbiorów, które mają być konkatenowane;
	call symput('n_obs', n_obs);
  run;
  
  * przejście przez wszystkie zbiory i zachowanie z nich tylko 
  zadanych zmiennych. Zarówno nazwy zbiorów jak i zmiennych
  przechowywane są w nowoutworzonych makrozmiennych;
  data &zbior._output;
    merge 
      %do i=1 %to &n_obs;
        &&zbior&i(keep=&&zmienna&i) 
      %end;
      ;
  run;
%mend;

%macro z01_test_dataset(dataset_name, col_num, row_num);
	*Makro generujące zbiory testowe na potrzeby bieżącego zadania.;
	data &dataset_name;
		array var{&col_num};
			%do i=1 %to &row_num;
				do j=1 to dim(var);
					var[j]=rannor(1)*100+1;
					end;
				output;
			%end;
		drop j;
	run;
%mend z01_test_dataset;

%z01_test_dataset(zbior_testowy1, 2, 10);
%z01_test_dataset(zbior_testowy2, 3, 5);
%z01_test_dataset(zbior_testowy3, 1, 20);

data z01_testset;
 input zbior $15. zmienna $;
 cards;
	zbior_testowy1 var2
	zbior_testowy2 var3
	zbior_testowy3 var1
;
run;

%concat(z01_testset)

/*zadanie 2****************************************************************;*/
/*Napisac i zaprezentowac działanie makra, które dla danego zbioru zbior (załozyc,
ze wszystke zmiene sa tego samego typu) i danej liczby k stworzy zbiór wszystkich 
k-elementowych kombinacji elementów zbioru zbior.*/

%macro kombinacje(zbior, k);
  * stworzenie zmiennej globalnej przechowującej unikalne 
  wartości wartości w całym zbiorze;
  %global distinct_values;
	
  * wyciągnięcie informacji o nazwie kolumn z zbiorze;
  proc sql noprint;
	select name into :variables separated by " "
	from dictionary.columns
	where LIBNAME = upcase("work") and MEMNAME = upcase("&zbior");
  quit;
  
  * sprowadzenie struktury zbioru do jednokolumnowej postaci - 
  proces odbywa się przez zapis każdego wiersza zbioru w tablicy,
  przypisanie każdego z jej elementów do tej samej zmiennej w pętli 
  i wielokrotny output;
  data &zbior._temp;
	set &zbior;
	array vars{*} &variables;
	do i=1 to dim(vars);
	  var = vars(i);
	  output;
	end;
	keep var;
	run;
	
  * wyciągnięcie z nowoutworzonego, jednokolumnowego zbioru unikalnych 
  wartości, które jednocześnie są unikalnymi wartościami elementów 
  zbioru wejściowego;
  proc sql noprint;
    select distinct var into: distinct_values separated by " "
    from &zbior._temp;
  quit;
  * zliczenie unikalnych wartości;
  %let cnt = %sysfunc(countw(&distinct_values));
 
  * stworzenie kombinacji;
  data &zbior._output;
	array dist_values{&cnt} (&distinct_values);
	n = dim(dist_values);
	array c{&k};
	n_comb = comb(n, &k);
	do j=1 to n_comb;
		call allcomb(j, &k, of dist_values{*});
		do i=1 to &k;
			c(i) = dist_values(i);
		end;
		output;
	end;
	keep c:;
run;

%symdel distinct_values;

%mend;

data z02_testset;
 input x1 x2;
 cards;
	2000 4
	1098 3
	982 9
	2000 4
	456 8
	287 6
	764 4
	543 2
	764 4
	1098 3
;
run;

%kombinacje(z02_testset, 3)

/*zadanie 3****************************************************************;*/
/*Napisac i zaprezentowac działanie makra, które w dowolnym danym zbiorze sasowym (składajacym
sie jedynie ze zmiennych numerycznych) zamieni n losowo wybranych elementów brakami danych.*/

%macro amputacja(zbior, n);

	* wyznaczenie liczby kolumn w zbiorze; 
	proc sql noprint;
		select name into :variables separated by " "
		from dictionary.columns
		where LIBNAME = upcase("work") and MEMNAME = upcase("&zbior");
	quit;
	%let k = %sysfunc(countw(&variables));
	* wyznaczenie liczby obserwacji;
	data _null_;
		set &zbior nobs=nobs;
		call symput('n_obs',nobs);
	run;
	* konwencja x - numer kolumny, y - numer wiersza;
 	%global x check; 
 	%do i=1 %to &n; 
 		%let check=1; * zmienna gwarantujaca usuniecie jednej obserwacji w kazdej iteracji; 
 		%do %while(%eval(&check>=1));
 			%let y_coord=0; 
 			%let x_coord=0; 
 			%let check=0; 
			%let seed=0; *zmienna utworzona na potrzeby wywołania syscall ranuni;
 			* wylosowanie polozenia usuwanej wartosci w dwoch krokach:
 				1. wylosowanie liczb z przedziału [0, 1]
 				2. przeliczenie na położenie w zbiorze, z wykorzystaniem wymiarów zbioru; 
			%syscall ranuni(seed, y_coord);
	        %syscall ranuni(seed, x_coord);
			*ranuni zwraca liczby zmiennoprzecinkowe z przedzialu [0,1]. 
			Ponizsze mnozenie mapuje wylosowane liczby na numery wierszy 
			i kolumn, W efekcie uzyskiwane sa x, y parametryzyjace polozenie
			elementu, ktory ma zostac zastapiony brakiem;
 			%let y_coord=%sysevalf(&y_coord*&n_obs, CEIL); 
 			%let x_coord=%sysevalf(&x_coord*&k, CEIL); 
			* sprawdzenie czy wylosowany element zostal juz usuniety;
 			%do j=1 %to %eval(&i-1); 
 	        	%let tmp_y=&&y&j; 
 	        	%let tmp_x=&&x&j;
 	        	%if %eval(%eval(&tmp_y = &y_coord) & %eval(&tmp_x=&x_coord)) %then %do; 
 	            	%let check=%eval(&check+1); 
 	       		%end; 
 			%end;
 		%end; 
		* zapis wspolrzednych elementu wylosowanego do usuniecia;
 		%let y&i=&y_coord; 
 		%let x&i=&x_coord; 
 	%end; 
	* procedura usuniecia;
 	data &zbior._output; 
 		set &zbior; 
 		array var(*) _numeric_; 
 		%do i=1 %to &n; 
			if _n_=&&y&i then var(&&x&i)=.; 
 		%end; 
 	run; 

%symdel x check;
%mend amputacja;

data z3_testset;
 input x1 x2 x3 x4;
 cards;
	2000 4 1098 3
	1098 3 2000 4
	982 9 456 8
	287 6 764 4
	543 2 764 4
;
run;

%amputacja(z3_testset, 5);


/*zadanie 4****************************************************************;*/
/*Napisac i zaprezentowac działanie makra, zaleznego od parametrów lzm i lgrp, które wygeneruje losowy
zbiór sasowy zawierajacy zmienne zm_1–zm_lzm o wartosciach w zbiorze A = {"A_1", "A_2", ..., "A_lgrp"}.
Zbiór A musi byc zawarty w zbiorze wartosci kazdej zmiennej zm i. Ponadto wartosci kazdej zmiennej zm_i
musza byc uporzadkowane rosnaco tak, jak w przykładowym zbiorze L12z04_3x6.*/

%macro wygeneruj_losowy_zbior(lzm, lgrp);
  data output;
    * lista przechowująca bieżący sufix A dla każdej kolumny;
  	array curr_grp{&lzm};
    array zm_{&lzm}$; * lista zmiennych;
    * zmienna n zabezpiecza przez pominięciem wyrazu A1;
  	retain n curr_grp: 1;
    * w poniższej pętli tworzy się koniunkcja, której każda składowa
    (poza ostatnią) sprawdza, czy nie zostanie przekroczony maksymalny sufix A_.
    Ostatni komponent koniunkcji (1=1) jest zawsze True;
    do while(not(%do k=1 %to &lzm; curr_grp&k>&lgrp-1 & %end; 1=1));
  	  do i=1 to dim(curr_grp);
  	    if (n>1 & curr_grp(i) <= &lgrp-1 & rand('Bernoulli', 0.3)=1) then curr_grp(i)+1;
  	    zm_(i)=cat('A_', curr_grp(i));
  	  end;
      n+1;
      output;
    end;
    keep zm_:;
  run;
%mend;

%wygeneruj_losowy_zbior(3, 6)

/*zadanie 5****************************************************************;*/
/*Napisac makro %podzial(zbior; zmienna), które dany zbiór zbior podzieli na tyle rozłacznych zbiorów,
ile jest róznych wartosci zmiennej zmienna. Niech A = (zm1, zm2, ..., zmN) bedzie uporzadkowanym zbiorem
róznych wartosci zmiennej zmienna (porzadek jest wyznaczony przez kolejnosc pojawiania sie róznych wartosci
zmiennej zmienna w zbiorze zbior, liczac od pierwszej obserwacji). Zbiór o nazwie z i ma zawierac wyłacznie te
obserwacje ze zbioru zbior, dla których zmienna zmienna przyjmuje wartosc zmi.*/

%macro podzial(zbior, zmienna);
  data &zbior;
    * zmienna grupująca względem wartości zadanej zmiennej - 
    obserwacje o jednakowej wartości tej zmiennej znajdują się
    w jednej grupie;
    retain grp 0;
	set &zbior end=eof;
	by &zmienna;
	if first.&zmienna then grp+1;
	* wyznaczenie liczby grup na podstawie indeksu ostatniej;
	if eof then call symput('n', grp);
  run;
  *tworzenie podzbiorów i umieszczenie w nich obserwacji 
  przynależących do odpowiadających im grup;
  data %do i=1 %to &n; &zbior._output&i %end;;
    set &zbior;
    %do i=1 %to &n;
      if grp=&i then output &zbior._output&i;
      drop grp;
    %end;
  run;
%mend;

data z05_testset;
 input region $ amount number;
 cards;
	A 2000 4
	A 1098 3
	A 982 9
	B 2000 4
	B 456 8
	B 287 6
	C 764 4
	C 543 2
	D 764 4
	D 1098 3
;
run;

%podzial(z05_testset, region);
 
/*zadanie 6****************************************************************;*/
/*Napisac kod, który sprawdzi czy istnieje globalna makrozmienna o danej nazwie.*/

*makro wypisuje odpowiedni komunikat z zależności od istnienia zmiennej o zadanej nazwie;
%macro if_exists(varname);
	%if %symexist(&varname) %then %put %nrstr(%symexist(&varname)) = TRUE;
	%else %put %nrstr(%symexist(&varname)) = FALSE;
%mend;

%let global_variable='makrozmienna utworzona poza ciałem makra ma globalny charakter';
%if_exists(global_variable);

/*zadanie 7****************************************************************;*/
/*Napisac i zaprezentowac działanie makra, które dla kazdego zbioru z danej 
biblioteki znajdzie maksimum ze zmiennych numerycznych w nim zawartych.*/

%macro numeric_max(library);

  * ekstrakcja informacji o istniejących w zadanej bibliotece 
  zbiorach danych i zapis tej informacji z zmiennej;
  proc sql noprint;
	select MEMNAME into :datasets separated by ' '
	from sashelp.vstable
	where LIBNAME = upcase("&library");
  quit;
  
  * pętla iterująca po zbiorach, których nazwy przechowywane są 
  w nowoutworzonej zmiennej;
  %let i=1;
  %do %while (%scan(&datasets, &i) ne );
  	%let dataset = %scan(&datasets, &i);

  	data _null_;
  	  set &library..&dataset end=eof;
  	  retain max_val;
  	  * ekstrakcja zmiennych numerycznych z biezacego zbioru;
  	  array numvars{*} _numeric_;
  	  * uaktualnienie w locie maksymalnej wartosci;
  	  max_val = max(max_val, max(of numvars{*}));
  	  if eof then do;
  	  * wypisanie informacji o maksimum lub o braku zmiennych numerycznych w biezacym zbiorze;
  	  	if max_val = . then put "Brak zmiennych numerycznych w zbiorze &library..&dataset";
  	  	else put "Max value in  &library..&dataset dataset is: " max_val;
  	  end;
  	run;
  	%let i=%eval(&i+1);
  %end;

%mend;

%numeric_max(lab6);

/*zadanie 8****************************************************************;*/
/*Napisac i zaprezentowac działanie makra, które usunie z danego zbioru sasowego
wszystkie zmienne o nazwach konczacych sie na dana litere.*/

%macro drop(dataset, letter);
  * ekstrakcja nazw zmiennych w zbiorze, kończących się na zadaną 
  literę i umieszczenie tej informacji w zmiennej variables;
  proc sql noprint;
	select name into :variables separated by " "
	from dictionary.columns
	where LIBNAME = upcase("work") and MEMNAME = upcase("&dataset")
	and upcase(substr(name, length(name), 1)) = upcase("&letter");
  quit;
  * opuszczenie zmiennych, których nazwy zostały umieszczone w nowoutworzonej zmiennej;
  data &dataset._output(drop=&variables);
    set &dataset;
  run;
%mend;

data z06_testset;
  set lab6.l06z04_a;
run;
%drop(z06_testset, e);

/*zadanie 9****************************************************************;*/
/* Napisac i zaprezentowac działanie makra, zaleznego od dwóch parametrów bibl i dir, które wyeksportuje
jako pliki tekstowe wszystkie zbiory sasowe z biblioteki bibl do katalogu dir. Nazwy utworzonych plików
(z rozszerzeniem txt) maja byc takie same, jak nazwy zbiorów sasowych (mozna uzyc procedury EXPORT).*/

%macro export_files(bibl, dir);
	* ekstrakcja informacji o istniejących w zadanej bibliotece 
	  zbiorach danych i zapis tej informacji z zmiennej;
	proc sql noprint;
		select memname into: datasets separated by ' ' from sashelp.vstable where libname=upcase("&bibl");
	quit;
	* pętla iterująca po zbiorach, których nazwy przechowywane są w nowoutworzonej 
	zmiennej i eksport do plików tekstowych o analogicznych nazwach;
	%let i=1;
	%do %while (%scan(&datasets, &i) ne );
		%let dataset = %scan(&datasets, &i);
			proc export data=&bibl..&dataset outfile="&dir.\&dataset..txt" dbms=tab replace;
			run;
		%let i=%eval(&i+1);
	%end;
%mend;

%export_files(work, /folders/myfolders/Labs/Lab12/)
/* KONIEC ****************************************************************;*/