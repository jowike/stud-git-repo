/*
LABORATORIUM NR: 13
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--7
UWAGI: 
*/

/*deklaracja bibliotek*/
libname lab6 "/folders/myfolders/Labs/Lab6/lab06";
libname lab8 "/folders/myfolders/Labs/Lab8/lab08";
libname lab13 "/folders/myfolders/Labs/Lab13/lab13";
libname test "/folders/myfolders/Labs/Lab13";

* Makra pomocnicze generujące zbiory ze zmiennymi numerycznymi
stworzone na potrzeby testów;
%macro numeric_sorted_testset(dataset_name, vars_cnt, grp_cnt);
	data &dataset_name;
		array nr{&vars_cnt} (&vars_cnt*1) ;
		array var_{&vars_cnt};
		retain nr:  n 1;
		
		do while(not(%do k=1 %to &vars_cnt; nr&k>&grp_cnt-1 & %end; 1=1));
			do i=1 to dim(nr);
				if (n > 1 & ranuni(1)<0.3 & nr(i)<=&grp_cnt-1) then nr(i)+1;
				var_(i)=nr(i);
			end;
			n+1;
			output;
		end;
		keep var_:;
	run;
%mend;

%macro numeric_testset(dataset_name, vars_cnt, rows_cnt);
	data &dataset_name;
		array var_{&vars_cnt};
		do r=1 to &rows_cnt;
			do i=1 to &vars_cnt;
				var_(i)=rand("Uniform");
			end;
			output;
		end;
		keep var_:;
	run;
%mend;

/*zadanie 1****************************************************************;*/
/* Makro, które w bibliotece bib znajdzie wszystkie zbiory sasowe zawierajace pare
zmiennych numerycznych grupa i wart, a nastepnie na ich podstawie wypisze do okienka 
Log te wartosc (wartosci) zmiennej grupa, która w znalezionych zbiorach wystepuje 
z najwieksza liczba róznych wartosci zmiennej wart. 
(Zakładamy, ze w bibliotece bib moga znajdowac sie zbiory sasowe, w których
zadana para zmiennych nie wystepuje.)*/

%macro ile(bib,grupa,wart);
	* Wybór zbiorów, w których wystepuje zadana para zmiennych: grupa, wart.
	METODA: filtrujemy wszystkie zbiory po nazwach biblioteki i zmiennych, wówczas ilość wystąpień zbioru
	(z wybranej biblioteki) odpowiada temu ile spośród zadanych występuje zmiennych w tym zbiorze. 
	Ostatecznie wybieramy zbiory, które w tak otrzymanej liście występują dwukrotnie.;
	proc sql noprint;
		 select distinct(memname) into: datasets separated by " &bib.." from (select memname, name from sashelp.vcolumn 
		 where libname = upcase("&bib") and (name="&grupa" or name = "&wart"))
		 group by memname
		 having count(name)=2
		 ;
	quit;
	
	* Przejście przez wybrane zbiory i ich sortowanie na potrzeby późniejszej konkatenacji;
	%let datasets=&bib..&datasets;
	
	%let i=1;
	%do %while (%scan(&datasets, &i,' ') ne );
		%let s = %scan(&datasets, &i, ' ');
		proc sort data=&s;
		by &grupa &wart;
		%let i=%eval(&i+1);
	%end;
	* Łączenie zbiorów po grupie i wartości oraz eliminacja pozostałych (nadmiarowych) zmiennych;
	data temp;
		merge &datasets;
		by &grupa &wart;
		keep &grupa &wart;
	run;
	
	* Zliczenie unikalnych wartości zmiennej "wartość" i ekstrakcja listy grup z ich maksymalną ilością;
	proc sql noprint;
	select &grupa , cnt into: grp separated by ' ' 
	from (select &grupa, count(distinct &wart) as cnt 
			from temp 
			group by &grupa)
	where cnt = (select max(cnt) 
				from (select count(distinct &wart) as cnt 
				from temp group by &grupa));
	quit;

	%put Grup(a/y) o największej ilosci różnych wartosci to: &grp;
	
%mend;

* Wywolanie testowe;
%numeric_sorted_testset(lab13.test1,3,5);
%numeric_sorted_testset(lab13.test2,1,2);
%numeric_sorted_testset(lab13.test3,4,6);
%numeric_sorted_testset(lab13.test4,2,8);
%ile(lab13, var_1, var_2);


/*zadanie 2****************************************************************;*/
/*Makro o parametrze bedacym nazwa biblioteki, które sortuje wszystkie 
zbiory z tej biblioteki po kluczu składajacym sie ze wspólnych zmiennych. 
Zmienne klucza powinny byc posortowany alfabetycznie.
Zakladamy, ze zbiory zawieraja co najmniej jedna wspólna zmienna (dodatkowo 
poszczególne zbiory moga zawierac równiez inne zmienne).*/

%macro sort_datasets(bibl);
	* Ekstrakcja nazw wszystkich zbiorów, znajdujących się w zadanej bibliotece;
	proc sql noprint;
	 select memname into: datasets separated by " "  from sashelp.vstable
	 where libname = upcase("&bibl");
	quit; 
	
	* Iteracyjne przejście przez wszystkie zbiory znajdujące się w zadanej 
	bibliotece i ekstrakcja informacji na temat kolumn w nich zawartych;
	%let i=1;
	%do %while (%scan(&datasets, &i,' ') ne );
		%let set = %scan(&datasets, &i, ' ');
		* Stworzenie zbiorów tymczasowych przechowujących nazwy zmiennych obecnych w kolejnych zbiorach;
		proc sql;
			create table columns&i as
			select name from sashelp.vcolumn
			where libname = upcase("&bibl") and memname=upcase("&set");
		quit;
		%let i=%eval(&i+1);
	%end;
	
	* Wyznaczenie wspólnego klucza.
	METODA: W pierwszej kolejności inicjalizuje się listy wspólnych zmiennych nazwami 
	kolumn z pierwszego nowoutworzonego zbioru (przechowujacego informacje o zmiennych).
	A nastepnie jej weryfikacja i uzupelnienie poprzez inner joiny z kolejnymi zbiorami 
	po nazwach zmiennych. W ostatniej linii następnie alfabetyczne sortowanie zmiennych klucza;
	%let i=%eval(&i-1);
	proc sql noprint;
		select cols1.name into: shared_vars separated by ' ' from columns1 as cols1
		%do j=2 %to &i;
			inner join columns&j as cols&j on cols%eval(&j-1).name=cols&j..name
		%end;
		order by cols1.name;
	quit;

	* Iteracyjne przejście przez wyjściowe zbiory i ich sortowanie po wspólnych zmiennych;
	%let i=1;
	%do %while (%scan(&datasets, &i,' ') ne );
		%let set = %scan(&datasets, &i, ' ');
		proc sort data=&bibl..&set out=&bibl..&set;
		by &shared_vars;
		run;
	%let i=%eval(&i+1);
	%end;
%mend;


data test.a;                    
   input z y x;
   datalines;        
	2477 198 220
	2431 1 220
	2456 155 173
	2412 116 135
	;  

data test.b;                    
   input v1 x y v2;
   datalines;        
	1 54  163 5
	2 45  198 6
	3 77  155 7
	4 54  116 8
	;

* Wywolanie testowe;
%sort_datasets(test);


/*zadanie 3****************************************************************;*/
/* Makro o parametrze bibl tworzace zbiór sasowy, w którym nazwami zmiennych sa
wszystkie nazwy zmiennych wystepujacych w zbiorach z biblioteki bibl. 
Wartosciami zmiennych sa nazwy zbiorów, w których zmienne te wystepuja */


%macro summary(lib);
	* Ekstrakcja nazw wszystkich zbiorów, znajdujących się 
	w zadanej bibliotece oraz nazw ich zmiennych;
	proc sql; 
		 create table temp as
		 select memname, name from sashelp.vcolumn 
		 where libname = upcase("&lib");
	quit;
	* Sortowanie nowoutworzonego zbioru po nazwach 
	zmiennych na potrzeby ponizszego grupowania;
	proc sort data=temp out=temp;
		by name;
	run;
	* Zliczenie ilości zmiennych i indeksowanie za pomocą
	zmiennej grp zbiorów je zawierających - w ten sposób tworzę 
	grupy, w których zbiory zawierające i-tą zmienną mają w 
	kolumnie grp indeks i;
	data temp;
		set temp end=eof;
		by name;
		if first.name then grp+1;
		if eof then call symput('n',grp);
	run;
	
	* Ekstrakcja (ze zbioru utworzonego na początku) listy 
	  unikalnych nazw wszystkich zmiennych;
	proc sql noprint;
		select distinct name into: columns separated by ' ' from temp; 
	quit;
	
	* Stworzenie jednokolumnowych podzbiorów, w których nazwa kolumny 
	odpowiada nazwie konkretnej zmiennej a wartości zbiorom je zawierającym.
	Ilość tych podzbiorów jest dokładnie taka jak liczba unikalnych nazw zmiennych.;
	data %do i=1 %to &n; temp_&i (keep=memname rename=(memname=%scan(&columns, &i,' '))) %end; ;
		set temp;
		%do i=1 %to &n;
			if grp=&i then output temp_&i. ;
		%end; 
	run;
	
	* Konkatenacja stworzonych wyżej podzbiorow;
	data Z03_output;
		merge %do i=1 %to &n; temp_&i. %end; ;
	run;
	
%mend;
	
%summary(lab6);

/*zadanie 4****************************************************************;*/
/*Napisac i zaprezentowac działanie makra, które ustawia etykiety zmiennych w formie: 
”Zmienna NAZWA ZMIENNEJ jest typu TYP, ...” a dalej, w zaleznosci od typu zmiennej:
1) dla numerycznych:
	jesli jest numeryczna: ”liczba brakujacych obserwacji to: NMISS, minimalna wartosc to: MIN,
	maksymalna wartosc to MAX, srednia to: AVG”, precyzja wyswietlania minimum i maksimum jest taka 
	jak w danych, a sredniej o rzad wielkosci wyzsza,
2) dla znakowych:
	jesli jest tekstowa: ”liczba brakujacych obserwacji to: NMISS, dlugosc zmiennej to LENGTH, 
	najkrotsza niepusta wartosc ma dlugosc MIN LENGTH, najdluzsza wartosc ma dlugosc MAX LENGTH”.*/

* Rozwiązanie metodą makrozmiennych; 
%macro macrovariables_method(lib, dataset);
	* Ekstrakcja informacji nt. nazw i długości zmiennych poszczególnych typów
	znajdujacych sie w zbiorze zadanym nazwa i macierzysta biblioteka;
	proc sql noprint;
		select name, length into :numeric separated by ' ', :nlength separated by ' '
		from sashelp.vcolumn 
		where libname=upcase("&lib") and memname=upcase("&dataset") and type='num';
		
		select name, length into :char separated by ' ', :clength separated by ' '
		from sashelp.vcolumn 
		where libname=upcase("&lib") and memname=upcase("&dataset") and type='char';
	quit;
		
	proc sql noprint;
		* Przejście po wyekstrahowanych zmiennych numerycznych;
		%let i=1;
		%do %while (%scan(&numeric, &i,' ') ne );
			%let nvar = %scan(&numeric, &i, ' ');
			* Obliczenie precyzji zaokraglenia statystyk min, max na podstawie dokladnosci danych;
			%let dec = %sysevalf(1/10**(&nlength-2));
			* Wyznaczenie z danych statystyk etykietujacych zmienne numeryczne
			oraz ich zaokrąglenie do narzuconych w treści zadania dokładności;
			select count(*)-count(&nvar), round(max(&nvar), &dec), round(min(&nvar), &dec), 
					round(avg(&nvar), %sysevalf(10*&dec)) into: nmiss, :max, :min, :avg 
				from &lib..&dataset;
			* Stworzenie etykiety;
			%let &nvar._label=liczba brakujacych obserwacji to: &nmiss,
					minimalna wartosc to: &min,
					maksymalna wartosc to &max, 
					srednia to: &avg;
		%let i= %eval(&i+1);
		%end;
		
		* Przejście po wyekstrahowanych zmiennych znakowych;
		%let i=1;
		%do %while (%scan(&char, &i,' ') ne );
			%let cvar = %scan(&char, &i, ' ');
			* Obliczenie ilości braków danych;
			select count(*)-count(&cvar) into: nmiss 
				from &lib..&dataset;
			* Obliczenie minimalnej i maksymalnej długości
			przy założeniu, że brak danych ma długość 0;
			select min(clen), max(clen) into: min, :max
				from(select case when &cvar='' then 0 
								 else length(&cvar) end 
								 as clen 
					 from &lib..&dataset)
				where clen ^= 0;
			* Stworzenie etykiety;
			%let &cvar._label=liczba brakujacych obserwacji to: &nmiss, 
				dlugosc zmiennej to %scan(&clength, &i, ' '), 
				najkrotsza niepusta wartosc ma dlugosc &min, 
				najdluzsza wartosc ma dlugosc &max;
			%let i= %eval(&i+1);
		%end;
	quit;
	
	* Przejście po wszystkich zmiennych wyjściowego zbioru;
	%let idx=1;
	data &lib..&dataset&idx;
		set &lib..&dataset;
		%let i=1;
		*Przypisanie etykiet zmiennym numerycznym;
		%do %while (%scan(&numeric, &i,' ') ne );
			%let nvar = %scan(&numeric, &i, ' ');
			label &nvar="&&&nvar._label";
		%let i= %eval(&i+1);
		%end;
		*Przypisanie etykiet zmiennym znakowym;
		%let i=1;
		%do %while (%scan(&char, &i,' ') ne );
			%let cvar = %scan(&char, &i, ' ');
			label &cvar="&&&cvar._label";
		%let i= %eval(&i+1);
		%end;
	run;
%mend;

%macrovariables_method(lab13, lab13z04);


* metoda wykorzystująca wywołanie CALL EXECUTE;

* Makro pomocnicze generujące dane do etykiet.
Wykonuje przejście po wszystkich zmiennych wyciągnięcie statystyk zależnych od typów.
W efekcie dostajemy 3 zbiory: jeden ogólny z danymi wszystkich zmiennych (nazwa, zbiór, długość, etc.),
drugi ze statystykami zmiennej numerycznej i trzeci ze statystykami zmiennej znakowej;
%macro vars_stats(lib, dataset);
	data variables_summary;
		set sashelp.vcolumn;
		if libname=upcase("&lib") && memname=upcase("&dataset"); 
		if type='num' then
		call execute("data num_stats(keep= nmiss max min avg); 
							retain min max sum nmiss n;
							set &lib..&dataset end=eof; 
							if "||name||"=. then nmiss+1;
							max=max(max,"||name||");
							min=min(min,"||name||");
							sum+"||name||" ;	
							n+1;
							if eof then do;	
								avg=sum/(n-nmiss);
								output;
							end;
					  run;");
		if type='char' then
		call execute("data char_stats(keep = min_length max_length cmiss); 
							retain min_length max_length cmiss;
							set &lib..&dataset end=eof; 
							if missing("||name||") then cmiss+1;
							else do;
								max_length=max(max_length,lengthn("||name||"));
								min_length=min(min_length,lengthn("||name||"));
							end;
							if eof then do;
								output;	
							end;
					  run;");
	run;
%mend vars_stats;

* Stworzenie i dodanie etykiet;
%macro add_labels(lib, dataset);
	* Wygenerowanie danych etykietujących za pomocą 
	zaimplementowanego wyżej makra pomocniczego;
	%vars_stats(&lib, &dataset);
	
	* Wyciągnięcie informacji o długości pól 
	numerycznych na potrzeby zaokrągleń;
	proc sql noprint;
		select length into :len
		from variables_summary;
		where type='num';
	quit;
	
	* Obliczenie precyzji zaokraglenia statystyk 
	min, max na podstawie dokladnosci danych;
	%let dec = %sysevalf(1/10**(&len-2));

	* Wyznaczenie z danych statystyk etykietujacych zmienne numeryczne
	oraz ich zaokrąglenie do narzuconych w treści zadania dokładności;
	proc sql noprint;
		select nmiss, round(max, &dec), round(min, &dec), 
			   round(avg, %sysevalf(10*&dec)) into :nmiss, :max, :min, :avg
			from num_stats;
	quit;
	* Wyznaczenie z danych statystyk etykietujacych zmienne znakowe;
	proc sql noprint;
		select min_length, max_length, cmiss into :min_length , :max_length, :cmiss
			from char_stats;
	quit;
	
	* Stworzenie i dodanie odpowiednich etykiet zależnych od typów;
	data _null_;
		%let idx = 2;
		set variables_summary;
		if type='num' then
			call execute("data &lib..&dataset&idx;
							  set &lib..&dataset;
							  label "||name||" = liczba brakujacych obserwacji to: &nmiss,
							  					 minimalna wartosc to: &min,
							  					 maksymalna wartosc to &max, 
							  					 srednia to: &avg; ");
		else do;
			%global clen;
			call symputx('clen', length);
			call execute("data &lib..&dataset&idx;
							  set &lib..&dataset&idx;
							  label "||name||" = liczba brakujacych obserwacji to: &cmiss,
							  					 dlugosc zmiennej to &clen, 
							  					 najkrotsza niepusta wartosc ma dlugosc &min_length, 
							  					 najdluzsza wartosc ma dlugosc &max_length; ");
		end;
	run;
%mend;

%add_labels(lab13,lab13z04);

/*zadanie 5****************************************************************;*/
* Obliczenie średniej zmiennej sales ze zbioru L08z02 duzy obliczona tylko dla
tych wartosci zmiennej id, które znajduja sie w zbiorze L08z02 maly;

*metoda z wykorzystaniem wywolania CALL EXECUTE;
data subset_execute;
	if _n_=1 then call execute('data _null_; 
								set lab8.l08z02_duzy 
								end=eofd;');
	set lab8.l08z02_maly end=eofm;
	call execute('if id='||strip(id)||' then do; 
				  suma+sales; 
				  n+1; 
				  end;');
	if eofm then call execute('if eofd then do; 
							   SREDNIA=suma/n; 
							   put SREDNIA=; 
							   end; 
							   run;');
run;


*metoda z wykorzystaniem wywolania procedury SQL i klauzuli :INTO;
%macro subset_SQL(big, small);
	proc sql noprint;
		* wyciągnięcie identyfikatorów znajdujących się w małym zbiorze;
		select id into: ids separated by ', ' from &small;
		
		* obliczenie średniej zmiennej sales dla obserwacji o id
		znajdujących się w małym zbiorze, które są zapisane 
		w nowoutworzonej zmiennej;
		select avg(sales) into: srednia from &big 
		where id in (&ids);
	quit;
	%put &=srednia;
%mend;
%subset_SQL(lab8.l08z02_duzy, lab8.l08z02_maly);

* metoda z wykorzystaniem wywolania polecenia %INCLUDE;

* zapis ograniczenia na identyfikatory w pliku tymczasowym;
filename T temp;
data _null_;
  file T;
  if _N_ = 1 then put 'where id in (';
  set lab8.l08z02_maly end = eof;
  put id;
  if eof = 1 then put ');';
run;

data _null_;
	* stworzenie podzbioru duzego zbioru, zawierajacego
	tylko te obserwacje, ktorych identyfikatory znajduja 
	sie w malym zbiorze;
	data temp;
	  set lab8.l08z02_duzy;
	  %include T;
	run;
	* przejscie przez nowoutworzony podzbior 
	  i obliczenie sredniej arytmetycznej zmiennej sales;
	data _null_;
	  retain sum n 0;
	  set temp end=eof;
	    sum + sales;
	    n+1;
	    if eof then do;
	      avg = sum/n;
	      put "srednia = " avg;
	    end;
run;


/*zadanie 6****************************************************************;*/
/* Makro %raport, które jako argumenty przyjmuje: liste okresów rozliczeniowych w formacie RRRRMM lub RRRRQI, 
np. 201304; 201309; 201403 (lista okresów), lub 201411 - 201509 (zakres okresów), lub 2016Q2; 2016Q4 (lista kwartałów),
lub mieszanke powyzszych, oraz nazwe zbioru (zakładamy, ze struktura zbioru jest ustalona i analogiczna ze struktura
zbioru lab13z06_reve). 
Makro generuje raport, który dla wywołania postaci: %raport(lab13z06_reve; 201901􀀀201903; 2018Q4) przygotuje
raport o postaci jak w pliku lab13z06 reve raport sql.lst.*/


%macro raport(zb, lista=)/
	PARMBUFF MINOPERATOR MINDELIMITER=','; 

	data check_dataset;
		* rozdzielenie poszczegolnych komponentow z listy argumentow podanych na wejsciu przez uzytkownika;
		
		set %scan(&syspbuff, 1,')(,'); * makrooperacja dokonuje ekstrakcji podanej nazwy zbioru;
		
			* przejscie przez pozostale argumenty, czyli 
			  podane na wejsciu zakresy czasowe;
			%let i=2;
			%do %while (%scan(&syspbuff, &i,') (,') ne );
				%let list&i = %scan(&syspbuff, &i, '(),');

				* przypadek gdy zakres podano w postaci listy kwartalow;
				%if %eval(%index(&&list&i,Q) ne 0 ) %then %do;
					* jesli data biezacego wiersza (kolumna date) pliku odpowiada dacie podanej
					na wejsciu do oznaczamy ten fakt w zmiennej check indeksem tego rekordu.
					Operacja wykonana wewnatrz cats konwertuje wartosc w kolumnie date do podanej
					na wejsciu postaci (tu postaci kwartalnej);
					if(cats(year(date),'Q',qtr(date))="&&list&i") then check=&i;
				%end;
				
				* przypadek gdy zakres podano jako przedzial (liste okresow);
				%if %eval(%index(&&list&i,-) ne 0 ) %then %do;
					%let ind=%index(&&list&i,-);
					* ponownie jeśli data (kolumna date) biezacego wiersza pliku odpowiada dacie podanej
					na wejsciu do oznaczamy ten fakt w zmiennej check indeksem tego rekordu.
					Pierwszy człon alternatywy weryfikuje czy data z biezacego wersza pliku miesci sie w zakresie 
					miedzy pierwszym dniem miesiaca bedacego dolna granica okresu rozliczeniowego a pierwszym dniem
					miesiaca bedacego gorna granica. Drugi czlon oznacza wszystkie wiersze, ktorych daty odpowiadaja
					dowolnemu dniu miesiaca podanego jako gorna granica okresu rozliczeniowego.
					Koniecznosc rozbicia na 2 warunki wynika z roznic w dlugosciach poszczegolnych miesiecy.;
					if (mdy(%substr(&&list&i,5,2),1, %substr(&&list&i,1,4) )<=date and date<= mdy(%substr(&&list&i,%eval(5+&ind),2),1,%substr(&&list&i,%eval(1+&ind),4)))
						or (month(date)=%substr(&&list&i,%eval(5+&ind),2) and year(date)=%substr(&&list&i,%eval(1+&ind),4)) then check= &i;
					%end;
				
				* Ostatni przypadek formatu, czyli gdy podano konkretny rok i miesiac.
				Dzieki warunkowi oznaczamy wszystkie wiersze, ktorych daty odpowiadaja
				dowolnemu dniu miesiecy podanych jako gorna i dolna granica okresu rozliczeniowego.;
				%if %eval(%eval(%index(&&list&i,-) = 0) &&  %eval(%index(&&list&i,Q) = 0)) %then %do;
					if(month(date)=%substr(&&list&i,5,2) and year(date)=%substr(&&list&i,1,4)) then check= &i;
				%end;
				%let i= %eval(&i+1);
			%end;
	run;
	
	* stworzenie formatow dekodujacych wartosci statusow i miesiecy;
	PROC FORMAT;
	  VALUE $ access_types 
	  'mobile_data'='Mobile Internet'
	  'mobile_phone'= 'Mobile Phone'
	  'fixed_data'='Landline Internet'
	  'fixed_phone'= 'Landline Phone'
	  OTHER=0;
	run;

	PROC FORMAT;
	  VALUE months_dict
		1='January' 
		2='February'
		3='March'
		4='April'
		5='May'
		6='June'
		7='July'
		8='August'
		9='September'
		10='October'
		11='November'
		12='December'
	  OTHER=0;
	run;

	* wczytanie tylko obserwacji wchodzących w zakres 
	  dat zadany podanymi argumentami i mapowanie zmiennych
	  miesiaca i statusu na potrzeby raportu;
	data temp;
		set check_dataset;
		* Using IF without THEN, I expect to find only observations
		meeting condition. All others would be deleted.;
		if check>0;
		year=year(date);
		month=month(date); 
		format status access_types.;
		format month months_dict.;
	run;
	
	* stworzenie raportu;
	proc sql;
		create table report as
			select year, month, status as access_type, 
				   sum(reve) as sum_of_revenue,
				   count(contract_id) as number_of_contracts 
				from temp 
				group by year, month, status;
	quit;
%mend;

options mprint;
%raport(lab13.lab13z06_reve, 201901-201903, 2018Q4, 201306, 202004);


/*zadanie 7****************************************************************;*/
/*Makro *%petla, które jako argumenty przyjmuje rozdzielona przecinkami liste 
(zmiennej długosci) wielowyrazowych napisów. Makro ma generowac napis 
bedacy produktem kartezjanskim poszczegolnych słów z listy napisów.
Wywołanie: %put *%petla(A B, 1 2 3)*; ma wydrukowac w logu napis *A1 A2 A3 B1 B2 B3*.
W szczególnosci makro ma byc napisane w taki sposób aby pozwalac na wykonanie o
peracji: %let x = %petla(A B, 1 2 3);

METODA:
1) wyznaczenie długości rozdzielonej przecinkami listy wielowyrazowych napisów
2) wyodrebnienie poszczegolych komponentow podanej na wejsciu listy;
3) przejscie przez wszystkie wielowyrazowe napisy podane na wejsciu;
4) wyznaczenie dlugosci pierwszego (j-tego) napisu, ktorego skladowe maja byc konkatenowane;
5) i - potencjalny indeks kolejnego napisu z listy argumentow;
6) stworzenie kombinacji wszystkich elementow pary list;
7) obiekt pomocniczy wynikiem konkatenacji pary wyrazow z dwoch roznych napisow;
8) obiekt out wynikowo jest oddzielona spacjami lista skonkatenowanych obiektow;*/

%macro petla(lista=)/
	PARMBUFF MINOPERATOR MINDELIMITER=','; 
	%let len= %sysfunc(countw(&syspbuff, ','));
	
	%do i=1 %to &len;
		%let list&i = %scan(&syspbuff, &i, '(),');
	%end;

	%let out=;
	
	%do j=1 %to &len;
		%let len_j = %sysfunc(countw(&&list&j, ' '));
		%let i  = %eval(&j+1);
		%if (&len+1)>&i %then %do;
			%let len_i= %sysfunc(countw(&&list&i, ' '));
			%do w=1 %to &len_j;
				%do z=1 %to &len_i;
					%let v1 = %scan(&&list&j, &w, %str(' '));
					%let v2 = %scan(&&list&i, &z, %str(' '));
					%let concat = &v1&v2;
					%let out = &out &concat; 
				%end;
			%end;
		%end;
	%end;
	
	&out.
	
%mend petla;

options mprint mlogic;
options nomprint nomlogic;

%put *%petla(A B, 1 2 3)*;
%put *%petla(A B, 1 2 3, C D)*;

%let test = %petla(A B, 1 2 3);
%put _all_;

/*
* każda z poniższych metod działa, ale nie spełnia wymagania
 możliwości wykonywania bezpośrednich przypisań;
%macro petla(lista=)/
	PARMBUFF MINOPERATOR MINDELIMITER=','; 
	%local wynik;
	%let len= %sysfunc(countw(&syspbuff, ','));
	%do i=1 %to &len;
		%let list&i = %scan(&syspbuff, &i, '(),');
	%end;

	data temp(keep=x);
		%let len= %sysfunc(countw(&syspbuff, ','));
		%do i=1 %to &len;
		do var&i=1 to countw("&&list&i");
		%end;
		x=cats(%do i=1 %to &len; scan("&&list&i", var&i), %end; '');
		output;
		%do i=1 %to &len;
		 end;
		%end;
	run;
	
	proc sql noprint;
	select x into : wynik separated by ' ' from temp;
	quit;
	
%mend petla;

options mprint mlogic;
options nomprint nomlogic;
%petla(A B, 1 2 3);


%macro petla(lista=)/
	PARMBUFF MINOPERATOR MINDELIMITER=','; 
	%local wynik;
	%let len= %sysfunc(countw(&syspbuff, ','));
	%do i=1 %to &len;
		%let list&i = %scan(&syspbuff, &i, '(),');
	%end;

	data _null_;
		length wynik $ 300;
		retain wynik "";
		%let len= %sysfunc(countw(&syspbuff, ','));
		%do i=1 %to &len;
		do var&i=1 to countw("&&list&i");
		%end;
		x=cats(%do i=1 %to &len; scan("&&list&i", var&i), %end; '');
		wynik = catx(" ", wynik, x);
		output;
		%do i=1 %to &len;
		 end;
		%end;
		
		call symputx('rezultat', wynik);
	run;
	
	%put &rezultat;
	
%mend petla;

options mprint mlogic;
options nomprint nomlogic;
%petla(A B, 1 2 3);
*/

/* KONIEC ****************************************************************;*/