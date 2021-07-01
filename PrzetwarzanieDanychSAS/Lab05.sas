/*
LABORATORIUM NR: 5
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--12
UWAGI:
*/

/*deklaracja bibliotek*/
libname lab5 "/folders/myfolders/Labs/Lab5/lab05";

/*zadanie 1****************************************************************;*/

*PLIK 1.;
data L05z01_plik1;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z01_plik1.txt";
	length nazwisko $ 20; /* deklaracja długości zmiennej tekstowej($) */
	input id nazwisko $ wzrost plec $ stan_konta;
run;

proc contents data=L05z01_plik1;
run;

* Wcześniejsza deklaracja długości zmiennej tekstowej spowodowała 
zczytanie danych z pliku, ale z dokładnością do permutacji kolumn.
Aby uzyskać zbiór o wyjściowej kolejności kolumn zastosuję zmianę
formatu z wykorzystaniem instrukcji sterującej ":".

Format $ w. jest równoważny formatowi $CHAR w., gdzie w oznacza
długość pola;

data L05z01_plik1;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z01_plik1.txt";
	input id nazwisko: $20. wzrost plec $ stan_konta;
run;

proc contents data=L05z01_plik1;
run;

*PLIK 2.;
data L05z01_plik2;
	*separatory w pliku się zmieniają, 
	więc przekazuję separator przez zmienną;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z01_plik2.txt";
	input @1 separator $1. @;
	* symbol @ na końcu zostawia w tym samym wierszu;
	* dlm = delimiter;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z01_plik2.txt" dlm = separator;
 	input id nazwisko: $20. stan_konta imie: $10. plec $ waga;
run;

proc contents data=L05z01_plik2;
run;

*PLIK 3.;
data L05z01_plik3;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z01_plik3.txt";
	input id 1-2 imie $ 3-12 nazwisko $ 13-18 waga 19-21 plec $ 22 wzrost 23-25;
run;

proc contents data=L05z01_plik3;
run;

*PLIK 4.;
data L05z01_plik4;
	* w bieżącym pliku separatorem może byc wiecej niz jeden znak, DLMSTR=;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z01_plik4.txt" dlmstr="  ";
	input id kto: $30. stan_konta: commax6. data: date11. plec $;
	format data date11.;
run;

proc contents data=L05z01_plik4;
run;

*PLIK 5.;
data L05z01_plik5;
	* W bieżącym pliku istnieje konieczność wczytywania kilku linijek pliku tekstowego naraz.
	Służy do tego opcja N= do instrukcji INFILE
	Dla N=7 jak niżej bufor obejmuje 7 linii tekstu
	#(liczba) - wskazanie na linię w buforze
	@ - pozostanie w buforze;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z01_plik5.txt" N=7;
	input #(1) id @;
	input #(2) imie $10. @;
	input #(3) nazwisko $20. @;
	input #(4) waga @;
	input #(5) wzrost @;
	input #(6) plec $ @;
	input #(7) stan_konta;
	
run;

proc contents data=L05z01_plik5;
run;

/*zadanie 2****************************************************************;*/

data out_z02;
	* W bieżącym pliku nie wszystkie pomiary są jednakowo opisane - 
	tylko pierwszy i ostatni pomiar dokonany w ramach eksperymentu ma
	adnotację odpowiednio START/STOP.
	Opcja missover pozwala na wstawienie dla wszystkich nieopisanych
	pomiarów brak danych w miejscu adnotacji;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z02_eksperyment.txt" missover end=eof;
	input data_pomiaru yymmdd8. wartosc_pomiaru adnotacja $;
	retain data_pocz wart_poczatkowa nr_eksperymentu r_max r_argmax 0;
	if adnotacja="START" then 
	do;
		data_pocz = data_pomiaru;
		wart_poczatkowa = wartosc_pomiaru;
		nr_eksperymentu+1;
	end;
	if adnotacja="STOP" then 
	do;
		if abs(wartosc_pomiaru-wart_poczatkowa)>r_max then 
		do;
			r_max = abs(wartosc_pomiaru-wart_poczatkowa);
			r_argmax = nr_eksperymentu;
		end;
		czas_trwania = data_pomiaru-data_pocz+1; 
		output;
	end;
	if eof then put "Największą różnicę wskazań pomiędzy pierwszym,
	a ostatnim dniem pomiarów zaobserwowano dla eksperymentu nr: " r_argmax;
	keep nr_eksperymentu czas_trwania;
run;	

/*zadanie 3****************************************************************;*/

data L05z03_plik;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z03_plik.txt" missover;
	input date yymmdd10. l1 $ 12-13 v1 15-16 
						 l2 $ 18-19 v2 21-22
						 l3 $ 24-25 v3 27-28 
						 l4 $ 30-31 v4 33-34 
						 l5 $ 36-37 v5 39-40; 
						 
	retain last_date;
	array labels{5} l1-l5;
	array values{5} v1-v5;
	array q{5};
	
	if missing(date) then date=last_date;
	format date yymmdd10.;
	
	do i=1 to dim(labels);
		do j=1 to dim(q);
			if labels(i) = cats("q", j) then q(j) = values(i);
		end;
	end;
	
	last_date = date;
	keep date q1-q5;
run;

/*zadanie 4****************************************************************;*/

data L05z04_plik;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z04_plik.txt" missover;
	input id os1 $ 5-9 os2 $ 11-15 k1 k2 data: yymmdd10.;
	
	retain dat;
	if missing(data) then data=dat;
	dat = data;
	
	osoba = os1;
	kwota = k1;
	output;
	osoba = os2;
	kwota = k2;
	output;
	
	format data date11.;
	format kwota dollar10.2;
	
	keep id data osoba kwota ;
run;

/*zadanie 5****************************************************************;*/

data L05z05_plika(keep= id wynik) L05z05_plikb;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z05_plik.txt" missover;
	input id $ @; 
	do until (kod = '');
		input kod $ wynik @;
		if kod = 'k' then output L05z05_plika;
		if kod = "" then leave;
		output L05z05_plikb;
	end;
run;
	

/*zadanie 6****************************************************************;*/

data out_z06;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z06_plik.txt";
	input in1-in12;
	
	array in{12}; *tutaj zapisują się wczytane z pliku in1-in2;
	array v{3};
	idx = 1;
	
	do i=1 to dim(in);
		if (not missing(in(i))) & idx <= dim(v) then 
		do;
			v(idx) = in(i);
			idx+1;
		end;
	end;
	
	keep v:;
run;

/*zadanie 7****************************************************************;*/

* W bieżącym pliku istnieje konieczność wczytywania pięciowierszowych bloków,
więc korzystam z możliwości utworzenia pięciowierszowego bufora;

data out_z07;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z07_plik.txt" missover N=5;
	array r[1977:1981] r1977-r1981;
	
	do i=1 to 12; 
		do j=1 to 5;
			* używając #(j) wczytuję kolejne wiersze (wskazane przez j)
			 a do poprawnego wczytania kolejnych elementów używam inputu 
			 ze startem wczytywania z okreslonego znaku w wierszu - ponieważ
			 liczby w zbiorze są dwucyfrowe to kolejne elementy wczytuję co 
			 3 znaki (iteracyjnie: 3+3*i);
			input #(j) @1 year @;
			input #(j) @(3+3*i) r[year] 2. @;
		end;
		output;
	end;
	keep r:;
run;
		
/*zadanie 8****************************************************************;*/

data out_z08;
	infile "/folders/myfolders/Labs/Lab5/lab05/pliki_tekstowe/L05z08_plik.txt" missover;
	input in1-in12;
	array in{12};
	* n jest numerem wczytywanej linii;
	retain n 1;
	* w tablicy tymczasowej przechowam pierwszą linię pliku 
	z numerami wierszy, które mają zostać wczytane do zbioru;
	array temp{12} _temporary_;
	
	* zapis pierwszego wiersza pliku do tablicy temp;
	if n=1 then
	do;
		do i=1 to dim(temp);
			temp(i) = in(i);
		end;
	end;
	
	* wypisanie do zbioru wierszy o numerach przechowywanych w temp;
	do i=1 to dim(temp);
		if n=temp(i) then output;
	end;

	n+1;
	keep in:;
run;

/*zadanie 9****************************************************************;*/

data out_z09a;
	set lab5.l05z09;
	array kol{12} kol1-kol12;

	* zastosowanie tablicy tymczasowej analogiczne jak w zadaniu 8.;
	array temp{12} _temporary_;
	
	* zapis pierwszego wiersza pliku do tablicy temp;
	if _n_=1 then
	do;
		do i=1 to dim(temp);
			temp(i) = kol(i);
		end;
	end;
	
	* wypisanie do zbioru wierszy o numerach przechowywanych w temp;
	do i=1 to dim(temp);
		if _n_ = temp(i) then output;
	end;

	keep kol:;
run;

data out_z09b;
	_n_ = 1;
	set lab5.l05z09 point=_n_;
	array kol{12} kol1-kol12;

	* zastosowanie tablicy tymczasowej analogiczne jak w zadaniu 8.;
	array temp{12} _temporary_;
	
	do i=1 to dim(temp);
		temp(i) = kol(i);
	end;
	
	call sortn (of temp(*));
	
	do i=1 to dim(temp);
		_n_ = temp(i);
		set lab5.l05z09 point=_n_;
		output;
	end;
	
	stop;
	keep kol:;
run;

/*zadanie 10****************************************************************;*/
data out_z10;
	*zadana ścieżka startuje z korzenia (wierzchołek nr 1);
	retain pointer 1; 
	
	do while(not missing(pointer));
		set lab5.l05z10_drzewo point=pointer;
		node = pointer;
		output;
		if rand("Bern", 0.5) then pointer=prawy;
		else pointer=lewy;
	end;
	stop;
	keep node;
run;
	
/*zadanie 11***************************************************************;*/

filename raport "/folders/myfolders/Labs/Lab5/raport.txt";

data _null_;
	file raport;
	retain nr_eksperymentu 0;
	
	set lab5.l05z05_plikb;
	by id notsorted;
	
	if first.id then 
	do;
		nr_eksperymentu+1;
		put '          Podsumowanie eksperymentu         ' nr_eksperymentu;
		put 'Dane pacjenta nr ' id;
		put '+-------------------------------------------+';
		if not last.id then put 'Wyniki eksperymentow posrednich:';
	end;
	
	if not last.id then put wynik @;
	if last.id then 
	do;
		put " ";
		put 'Wynik koncowy to: ' wynik;
		put '+-------------------------------------------+';
	end;

run;

/*zadanie 12***************************************************************;*/

proc export data=lab5.l05z03_plik
outfile="/folders/myfolders/Labs/Lab5/L05z03.xlsx" dbms=xls
replace;
*nadpisanie istniejącego pliku;
run;

proc export data=lab5.l05z04_plik 
outfile="/folders/myfolders/Labs/Lab5/L05z04.csv" dbms=csv
replace; 
run;

/*KONIEC*******************************************************************;*/
