/*
LABORATORIUM NR: 11
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--7
UWAGI: 1. zadanie rozwiązano na dwa sposoby
*/

/*deklaracja bibliotek*/
libname lab8 "/folders/myfolders/Labs/Lab8/lab08";
libname lab9 "/folders/myfolders/Labs/Lab9/lab09";
libname lab11 "/folders/myfolders/Labs/Lab11/lab11";

/*zadanie 1****************************************************************;*/
* Makro, które dla danego numeru wypozyczenia wypisze do okienka Log: 
Imie i Nazwisko wypozyczajacego oraz marke i typ wypozyczonego samochodu;

%macro put_info(nr_wypozyczenia);
* zapis do (jednowierszowej) tablicy rekodrów spełniających założenia;
	proc sql noprint;
		create table info as(
			select wypozyczenia.nr_wypozyczenia, klienci.imie, klienci.nazwisko, samochody.marka, samochody.typ
			from lab9.l09z01_wypozyczenia as wypozyczenia
			inner join lab9.l09z01_klienci as klienci on wypozyczenia.nr_klienta = klienci.nr_klienta
			inner join lab9.l09z01_samochody as samochody on wypozyczenia.nr_samochodu = samochody.nr_samochodu
			where input(nr_wypozyczenia ,8.) = &nr_wypozyczenia);
	quit;
* zczytanie i wypisanie w logu rekordów z nowoutworzonej tablicy;
	data _null_;
		set info;
		put nr_wypozyczenia imie nazwisko marka typ;
	run;
%mend put_info;

%put_info(00000001);
%put_info(00000011);



%macro put_info2(nr_wypozyczenia);
	proc sql noprint;
	* rekodrów spełniających założenia bezpośrednio do makrozmiennych;
		select wypozyczenia.nr_wypozyczenia, klienci.imie, klienci.nazwisko, samochody.marka, samochody.typ
		into :id_wypozyczenia, :imie, :nazwisko, :marka, :typ
		from lab9.l09z01_wypozyczenia as wypozyczenia
		inner join lab9.l09z01_klienci as klienci on wypozyczenia.nr_klienta = klienci.nr_klienta
		inner join lab9.l09z01_samochody as samochody on wypozyczenia.nr_samochodu = samochody.nr_samochodu
		where input(nr_wypozyczenia ,8.) = &nr_wypozyczenia;
	quit;
	* wypisanie w logu nowoutworzonych makrozmiennych;
	%put &id_wypozyczenia &imie &nazwisko &marka &typ;
%mend put_info2;

%put_info2(00000001);
%put_info2(00000011);


/*zadanie 2****************************************************************;*/
* Ile wynosi srednia zmiennej sales ze zbioru L08z02 duzy obliczona tylko dla
tych wartosci zmiennej id, które znajduja sie w zbiorze L08z02 maly?;

%macro table_look_up(duzy, maly);
	data _null_;
		set &maly nobs=n;
		* stworzenie zmiennych i przypisanie im wartości odpowiednio:
		odpowiadajacych kazdemu id z malego zbioru i ilości wszystkich 
		obserwacji w małym zbiorze;
		call symputx(cat('id', _n_), id);
		call symputx('n_obs', n);
	run;
	
	data _null_;
		* biorąc pod uwagę wolumen danych w dużym zbiorze, lepszym 
		(zastosowanym w bieżącym rozwiązaniu) podejściem jest jego
		jednokrotne wczytwanie i wielokrotne (jeden raz dla każdego wiersza
		z dużego zbioru) iterowanie po zmiennych utworzonych na podstawie
		małego zbioru;
		set &duzy end=eof;
		retain sum cnt 0;

		* wczytuję wierszwo duży zbiór i dla każdego wiersza, idąc 
		w pętli po utworzonych wcześniej zmiennych, zawierających id 
		obserwacji z małego zbioru sprawdzam czy bieżąca obserwacja 
		z dużego zbioru zaistniała w małym zbiorze ...;
		%do i=1 %to &n_obs;
			if &&&id&i = id then do;
				* jeśli tak: zwiększam sumę i licznik, wpp. przechodzę dalej;
				sum+sales;
				cnt+1;
			end;
		%end;
		* po dojściu do końca dużego zbioru, biorąc otrzymane
		sumę i licznik, obliczam i wypisuję średnią;
		if eof then do;
			avg = sum/cnt;
			put avg=;
		end;
	run;
%mend table_look_up;

%table_look_up(lab8.l08z02_duzy, lab8.l08z02_maly);

/*zadanie 3****************************************************************;*/
* Makro dzielace dowolny zbiór na zbiory zawierajace co najwyzej n obserwacji.;

%macro split_into_subsets(dataset, n);
	* zapis liczby obserwacji w pełnym zbiorze;
	data _null_;
		set &dataset nobs=n_obs;
		call symputx('n_obs', n_obs);
	run;
	
	* obliczenie liczby podzbiorów, na które należy podzielić pełen zbiór,
	biorę sufit, aby w przypadku niepodzielności n_obs przez n podzielić zbiór
	na tyle n-elementowych podzbiorów, ile to możliwe a resztę obserwacji wpisać
	do ostatniego, mniejszego podzbioru;
	%let nr_of_subsets = %sysevalf(&n_obs/&n, ceil);
	* tworzenie w locie podzbiorów i zapis w nich obserwacji, których wybór jest
	podyktowany warunkami nałożonymi na numery ich wierszy w wyjściowym zbiorze;
	 %do i = 1 %to &nr_of_subsets;
		  data &dataset&i;
		      set &dataset;
		      * obliczenie indeksow obserwacji, wczytywanych do i-tego podzbioru;
		      if _n_ > &n*(&i-1) and _n_ <= &n*&i then output &dataset&i;
		  run;
	 %end;
%mend split_into_subsets;

%split_into_subsets(lab8.l08z02_maly, 30);

/*zadanie 4****************************************************************;*/
* Makro znajdujace dla danego id najbardziej aktualna wartosc zmiennej x w zbiorach zbiory.;

%macro z04_test_dataset(dataset_name, opt_num, row_num);
	* Makro generujące zbiór testowy na potrzeby bieżącego zadania.
		parametry:
			dataset_name <- nazwa docelowego zbioru,
			opt_num <- liczba opcjonalnych zmiennych,
			row_num <- liczba obserwacji;
	data &dataset_name;
		* tablica opcjonalnych zmiennych;
		array var{&opt_num};
		* generowanie zbioru wiersz po wierszu;
		%do i=1 %to &row_num;	
		* zgodnie z poleceniem id ma mieć format znakowy;
		id = put(&i, 10.);
		data = mdy(1,1,2015)+floor(ranuni(1)*(mdy(1,1,2020)-mdy(1,1,2010)));
			* generowanie podanej na wejściu liczby opcjonalnych obserwacji;
			do j=1 to dim(var);
				x = rannor(1)*100+1;
				* sprowadzenie x do zadanego formatu;
				format x best12.;
				var[j] = rannor(1)*100+1;
			end;
			* sprowadzenie daty do zadanego formatu;
			format data ddmmyy10.;
			output;
		%end;
	drop j;
	run;
%mend z04_test_dataset;

%macro najaktualniejszy_x(zbiory, id);
	data _null_;
		* full outer join - dopuszczamy scenariusze, w których dla 
		podanego na wejściu id dla zmiennej x nie ma braku w żadnym 
		z przeszukiwanych zbiorów, ma brak w jednym z nich lub w obydwu
		
		w celu uniknięcia niejednoznaczności nazewnictwa zmiennej x,
		która wystąpi w wyniku merga, bo we wszystkich zbiorach nazywa się
		ona tak samo, idę w makro pętli po wszystkich zbiorach i w każdym
		dodaję do nazwy tej zmiennej aliasy tożsame z nazwą zbioru, z którego
		pochodzi dana wartość;
		merge
		%local i zbior;
		%let i=1;
		%do %while (%scan(&zbiory, &i) ne );
			%let zbior = %scan(&zbiory, &i);
			&zbior(rename=(x=x&zbior data=data&zbior))
			%let i = %eval(&i+1);
		%end;
		end = eof;
		by id;
		
		najaktualniejsza_data = 0;
		najaktualniejszy_x = .;
		retain czy_wystepuje 0;
		%let i=1;
		* porównuję daty i zapisuję najaktualnieszą datę 
		i odpowiadającą jej wartość zmiennej;
		%do %while (%scan(&zbiory, &i) ne );
			%let zbior = %scan(&zbiory, &i);
			if (data&zbior > najaktualniejsza_data) then do;
				najaktualniejsza_data = data&zbior;
				najaktualniejszy_x = x&zbior;
			end;
			%let i = %eval(&i+1);
		%end;
		* w momencie dojścia do podanego na wejściu id,
		wypisuję do loga id i wyznaczone datę i wartość x 
		oraz zaznaczam w zmiennej 'czy_wystepuje' fakt 
		istnienia zadanego id w zbiorze;
		if (id=&id) then do;
			format najaktualniejsza_data ddmmyy10.;
			put id= najaktualniejszy_x= najaktualniejsza_data=;
			czy_wystepuje=1;
		end;
		
		* jeśli dane id nie wystąpiło wypisuję do loga adekwatny komunikat;
		if czy_wystepuje=0 and eof then put "nie ma takiego id";
		keep id najaktualniejszy_x;
	run;
%mend najaktualniejszy_x;

%z04_test_dataset(przykladowy_zbior1, 2, 10);
%z04_test_dataset(przykladowy_zbior2, 1, 15);
%najaktualniejszy_x(przykladowy_zbior1 przykladowy_zbior2, 2);
%najaktualniejszy_x(przykladowy_zbior1 przykladowy_zbior2, 13);
%najaktualniejszy_x(przykladowy_zbior1 przykladowy_zbior2, 17);


/*zadanie 5****************************************************************;*/
/* Makro, które ma podstawie danego zbioru i zmiennej numerycznej
   w nim wystepujacej stworzy nowy format. */

%macro z05_test_dataset(dataset_name, opt_num, row_num);
	*Makro generujące zbiór testowy na potrzeby bieżącego zadania.
		parametry:
			dataset_name <- nazwa docelowego zbioru,
			opt_num <- liczba opcjonalnych zmiennych,
			row_num <- liczba obserwacji;
	data &dataset_name;
		array var{&opt_num};
			%do i=1 %to &row_num;
				do j=1 to dim(var);
					var[j]=rannor(1)*100+1;
					end;
				output;
			%end;
		drop j;
	run;
%mend z05_test_dataset;

%macro format_macro(dataset, numeric_variable);

	*sortowanie zbioru po numeric_variable, czyli po zmiennej,
	na podstawie której tworzony jest format - posortowanie to
	umożliwi odpowiednie numerowanie obserwacji na podstawie
	wartości zmiennej;
	proc sort data = &dataset;
	by &numeric_variable;
	run;
	
	data format_tab;
		set &dataset end=eof;
		* zabezpieczenie pierwszego wiersza, dla którego lag(&numeric_variable)
		będzie brakiem i ustawienie go jako zmienną początkową 'low';
		if _n_=1 then hlo = 'l'; 
		fmtname = 'format_numerujacy';
		* kolenymi numerami rzymskimi obejmujemu zakresy 
		od poprzedniej wartości do bieżącej;
		start = lag(&numeric_variable);
		end = &numeric_variable;
		type = "N";
		label = put(_n_, roman.);
		output;
		* ustawienie ostatniej obserwacji jako zmiennej konczącej ('high');
		if eof then do; 
			start = &numeric_variable;
			end = .; 
			hlo = 'h'; 
			label = put(_n_+1, roman.);
			output; 
		end;
	run;
	proc format LIBRARY = work CNTLIN = format_tab;
	run;
%mend format_macro;


%z05_test_dataset(zbior_testowy, 4, 10);
%format_macro(zbior_testowy, var1);

data sformatowany_zbior_testowy;
	set zbior_testowy;
	format var1 format_numerujacy.;
	format var2 format_numerujacy.;
	format var3 format_numerujacy.;
	format var4 format_numerujacy.;
run;

/*zadanie 6****************************************************************;*/
/*Makro, które z danego zbioru usuwa wszystkie zmienne numeryczne,
  które zawieraja choc jedna brakujaca wartosc.*/

%macro z06_test_dataset(dataset_name, col_num, row_num);
	* Makro generujące zbiór testowy na potrzeby bieżącego zadania.;
	data &dataset_name;
		array var{&col_num};
			%do i=1 %to &row_num;
				do j=1 to dim(var);
					var[j] = rannor(1)*100+1;
					* Niewielkie p-stwo braku, aby zminimalizować ryzyko wystąpienia
					sytuacji, w której usunięte zostaną wszystkie zmienne. Jednocześnie
					jest ono dość duże aby dla dostatecznie dużego zbioru jakieś braki 
					w zbiorze wystąpiły;
					if rand("Bernoulli", 0.1) then var[j]=.;
					end;
				output;
			%end;
		drop j;
	run;
%mend z06_test_dataset;

%macro drop_dots(dataset);
	* wybor zmiennych numerycznych i zapis ich nazw w zmiennej
	  Notatka z dokumentacji:
	  	"dictionary tables allow to get data set definitions LIBNAME - library name, MEMNAME - member name";
	proc sql noprint;
		select name into :numeric_variables separated by " "
		from dictionary.columns
		where LIBNAME = upcase("work") and MEMNAME = upcase("&dataset") and type = 'num';
	quit;
	
	data &dataset;
		set &dataset;
		* definicja długości i inicjalizacja wartości zmiennej,
		która będzie przechowywać nazwy zmiennych, dla których 
		występują braki danych;
		length vars_with_dots $ 200;
		retain vars_with_dots " ";
		%local i var;
		%let i=1;
		* przejście w makropętli po zmiennych numerycznych i zapis tych z brakami w przygotowanej zmiennej;
		%do %while(%scan(&numeric_variables, &i) ne );
		   %let var = %scan(&numeric_variables, &i);
		   if &var = . then vars_with_dots = catx(' ', vars_with_dots, "&var");
		   %let i = %eval(&i + 1);
		%end;
		* zapis w zmiennej nazw kolumn do opuszczenia (dla których występują braki);
		call symput('vars_to_drop', vars_with_dots);
	run;
	* opuszczenie zmiennych;
	data &dataset(drop=&vars_to_drop vars_with_dots);
		set &dataset;
	run;
%mend drop_dots;

%z06_test_dataset(zbior_z_brakami, 5, 10)
%drop_dots(zbior_z_brakami);


/*zadanie 7****************************************************************;*/
/*Makro, które dla danego zbioru, danej zmiennej numerycznej i danej liczby n
  policzy wartosci dystrybuanty empirycznej tej zmiennej w punktach x1,...,xn, gdzie x1 i xn sa
  najmniejsza i najwieksza wartoscia zmiennej w zbiorze. Odległosci miedzy kolejnymi punktami 
  x_i i x_{i+1} maja byc jednakowe dla wszystkich i.*/

%macro cdf(dataset, num_var, n);
	* pozyskanie i zapis w zmiennych minimalnej i maksymalnej 
	wartości zadanej zmiennej numerycznej w zbiorze;
	proc sql noprint;
		select min(&num_var), max(&num_var) into :min, :max
		from &dataset;
	quit;
	
	data cdf_dataset(keep=cnt);
		do i=1 to &n;
			cnt = 0;
			do j=1 to n;
				* zbadanie ilości obserwacji przynależących 
				do przedziału zadanego przez x_{i} i x_{i+1},
				przy założeniu jednakowych odległości między
				tymi x-ami;
				set &dataset point=j nobs=n;
				if &num_var <= &min + i*(&max-&min)/&n then do;
					cnt + 1;
				end;
			end;
			* podzielenie otrzymanej ilości przez liczbę takich przedziałów 
			i sprowadzenie jej do postaci ułamkowej;
			cnt = cnt/n;
			format cnt fract.;
			output;
		end;
		stop;
	run;
%mend cdf;

%cdf(lab8.l08z02_maly, id, 20)

/* KONIEC ****************************************************************;*/