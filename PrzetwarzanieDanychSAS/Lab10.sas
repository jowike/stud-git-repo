/*
LABORATORIUM NR: 10
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--9
UWAGI:
*/

/*deklaracja bibliotek*/
libname lab10 "/folders/myfolders/Labs/Lab10/lab10";

/*zadanie 1****************************************************************;*/

* Makro tworzące N zbiorów o nazwach prefiks1,...,prefiksN.
Każdy zbiór ma mieć k zmiennych i l obserwacji, pochodzących z rozkładu normalnego N(10, 1).;
%macro stworz(prefiks,N,k,l);
	%do i=1 %to &N;
	    data &prefiks&i;
	      array arr[&k];
	      do i=1 to &l;
	        do j=1 to &k;
	          arr[j]=rand('normal', 10, 1);
	        end;
	        output;
	      end;
	      drop i j;
	    run;
	%end;
%mend stworz;

%stworz(testowy_prefiks, 3, 4, 5);

/*zadanie 2****************************************************************;*/

* Napisać makro, które dla każdej podanej na liście zmiennej ze zbioru 
zbior znajdzie liczbę obserwacji większych niż liczba n.;

data test_set;
    do i=1 to 10;
      x=floor(rand('uniform', 0, 200));
      y=floor(rand('uniform', 50, 80));
      output;
    end;
    drop i;
run;

%macro zlicz(zbior, zmienne, n);
    data _null_;
    	%let blank=;
		%let k=1;
		
		%do %while (%scan(&zmienne, &k, ' ') ne &blank);
	    	%let zmienna = %scan(&zmienne, &k, ' ');
	    	data _null_;
      			set &zbior end=eof;
      			if &zmienna > &n then cnt+1;
      			if eof then put "Liczba obserwacji, dla których zmienna &zmienna jest większa niż &n  wynosi: " cnt;
    		run;
	    	%let k = %eval(&k + 1);
		%end;
    run;
%mend zlicz;

%zlicz(test_set,x y, 100);


/*zadanie 3****************************************************************;*/

* Przekształcić zbiór L10z03.kropki do L10z03.bezkropek.;
%macro usun_kropki(kropki, bezkropek, N);
    %do i=1 %to &N;
      data tmp&i;
        do until (eof);
          set &kropki end=eof;
            if(z&i=.) then do;
              continue;
            end;
            output;
        end;
        keep z&i;
      run;
    %end;
  
    data &bezkropek;
      set tmp1;
    run;
 
    %do i=2 %to &N;
      data &bezkropek;
        merge &bezkropek tmp&i;
      run;
    %end;
%mend usun_kropki;

%usun_kropki(lab10.l10z03_kropki, tmp_test, 54);
proc transpose data=tmp_test out=tmp_test_T (drop=_NAME_) prefix=z;
run;

%usun_kropki(tmp_test_T, test_bezkropek, 14);
proc transpose data=test_bezkropek out=out_z03_bezkropek (drop=_NAME_) prefix=z;
run;

/*zadanie 4****************************************************************;*/

* Załóżmy, że zbiór sasowy A zawiera jedną zmienną numeryczną i N obserwacji 
  (N dowolna liczba naturalna większa od 100).;
  
data A;
    do i=1 to 50;
      x=floor(rand('uniform', 1, 10)*100+1);
      output;
    end;
    drop i;
run;  
  
* Napisać makro tworzące zbiór srednie o jednej zmiennej i N obserwacjach. 
  i-ta obserwacja w zbiorze srednie ma być średnią obserwacji ze zbioru A, o numerach {i,...,N}. 
  Zadanie rozwiązać dwoma sposobami:;

* I) Łącząc kopie zbioru A (z odpowiednio przesuniętymi obserwacjami);
%macro srednie_I(zbior, N);
    %do i=1 %to &N ;
      data A&i;
        set &zbior(rename=(x=a&i));
        if _n_ >= &i;
        rename x=a&i;
      run;
    %end;

    data tmp;
      merge A:;
    run;

    data out_srednie_I(keep=srednia);
      set tmp;
      array arr{*} a1-a&N;
      suma=0;
      do j=1 to &N;
        suma+arr(j);
        if arr(j)=. then do;
          srednia=suma/(j-1);
          leave;
        end;
        if j=&N then srednia=suma/j;
      end;
    run;
%mend srednie_I;

%srednie_I(A, 50);

* II) Transponując zbiór A (licząc średnie z odpowiednich kolumn).;
%macro srednie_II(zbior);

	proc transpose data=&zbior out=srednie_T(drop=_NAME_);
	run;
	
	data tmp;
		set srednie_T ;
	    array arr{*} col:;
	    do i=1 to dim(arr);
	      	n=1;
	      	do j=i+1 to dim(arr);
	        	n+1;
	        	arr[i]+arr[j];
	      	end;
	      	arr[i]=arr[i]/n;
	    end;
	    drop i j n;
	run;
	
	proc transpose data=tmp out=out_srednie_II(drop=_NAME_ rename=(col1=srednia));
	run;
%mend srednie_II;

%srednie_II(A);

/*zadanie 5****************************************************************;*/

* Napisać makra o parametrach NAPIS i LITERA, zapisujące każde słowo z podanej 
makrozmiennej NAPIS jako osobną makrozmienną, a jako jej wartość:;

* I) liczbę liter w słowie, np. NAPIS=Ala ma aparat, wynik: Ala=3 ma=2 aparat=6;
%macro macro_napis(NAPIS) ;
	%let i = 1;
	%let blank=;
	%do %while (%scan(&NAPIS, &i) ne &blank);
    	%let slowo = %scan(&NAPIS, &i);
    	%put &slowo;
    	%let j = 1;
    
    	%do %while (%substr(&slowo, &j, 1) ne &blank);
    		%let j = %eval(&j+1);
    	%end;
    
    	%let j = %eval(&j-1);
    	%put "&slowo = &j";
    	%let i = %eval(&i+1);
  	%end;
%mend macro_napis;

%macro_napis(Ala ma aparat);


* II) liczbę wystąpień litery LITERA w słowie, np. NAPIS=Ala ma aparat, LITERA=a, 
	  wynik: Ala=2 ma=1 aparat=3.;
%macro macro_litera(NAPIS, LITERA) ;
	%let i = 1;
	%let blank=;
	%do %while (%scan(&NAPIS, &i) ne &blank);
		%let slowo = %scan(&NAPIS, &i);
	  	%let cnt = 0;
	  	%let j = 1;
	    %do %while (%substr(&slowo, &j, 1) ne &blank);
	      	%if &LITERA=%substr(%lowcase(&slowo), &j, 1) %then %let cnt=%eval(&cnt+1);
	        %let j = %eval(&j + 1);
	    %end;
	    %put "&slowo = &cnt";
	    %let i = %eval(&i + 1);
	%end;
%mend macro_litera;

%macro_litera(Ala ma aparat, a);
%macro_litera(Ala ma kota, k);
%macro_litera(Ala ma kota, x);

/*zadanie 6****************************************************************;*/

* Napisać makro przyjmujące argument postaci: n!, n!!, n!!!, itd. obliczające ”zmodyfikowaną silnię” np.:
a) 5! = 5 · 4 · 3 · 2 · 1 - zwykła silnia
b) 7!! = 7·(7−2)·(7−4)·(7−6) = 7·5·3·1 - iloczyn nieujemnych wartości
c) 12!!! = 12·(12−3)·(12−6)·(12−9) = 12·9·6·3 - iloczyn nieujemnych wartości
Makro ma nie zawierać DATA STEPu;

%macro zmodyfikowana_silnia(formula);
	%let i=1;
	%let l_cyfr=0;
	%let l_wykrzyknikow=0;
	%let zmodyfikowana_silnia=1;
	%let blank=;

  * ustalenie ilosci cyfr w liczbie i ilosci wykrzyknikow;
	%do %while (%substr(&formula, &i, 1) ne &blank);
    	%if %substr(&formula, &i, 1) ne ! %then %let l_cyfr=%eval(&l_cyfr+1);
    	%if %substr(&formula,&i,1) = ! %then %let l_wykrzyknikow=%eval(&l_wykrzyknikow+1);
    	%let i = %eval(&i + 1);
    %end;

	%let skladowa = %substr(&formula, 1, &l_cyfr);

  * obliczenie wartosci zwracanej;
    %do %while (&skladowa>0);
    	%let zmodyfikowana_silnia = %eval(&zmodyfikowana_silnia*&skladowa);
    	%let skladowa = %eval(&skladowa-&l_wykrzyknikow);
    %end;

    %put "zmodyfikowana_silnia = &zmodyfikowana_silnia";
%mend zmodyfikowana_silnia;

* testy;
%zmodyfikowana_silnia(5!);
%zmodyfikowana_silnia(7!!);
%zmodyfikowana_silnia(12!!!);
%zmodyfikowana_silnia(12!!!!);
%zmodyfikowana_silnia(16!!!!);

/*zadanie 7****************************************************************;*/

* Napisać makro zależne od dwóch parametrów NAZWY i ZNAKI, które z zadanego 
napisu NAZWY wypisze do okienka log wszystkie wyrazy, które nie zawierają 
znaków podanych w parametrze ZNAKI, np. NAPIS=Ala ma kota! l, ZNAKI=! l, 
makro zwraca słowo 'ma';

%macro macro_nazwy_znaki(NAZWY, ZNAKI);
	%let i = 1;
	%let blank=;
	
	%do %while (%scan(&NAZWY, &i) ne &blank);
		%let slowo = %scan(&NAZWY, &i,' ');
		%let cnt = 0;
		%let j = 1;
	        %do %while (%substr(&slowo,&j,1) ne &blank);
	        	%let k=1;
		        %do %while (%scan(&ZNAKI, &k, ' ') ne &blank);
		            %let znak = %scan(&ZNAKI, &k, ' ');
		            %if &znak=%substr(&slowo,&j,1) %then %let cnt= %eval(&cnt+1);
		            %let k = %eval(&k + 1);
		        %end;
		        %let j = %eval(&j + 1);
		    %end;
	     %if &cnt=0 %then %put "&slowo";
	     %let i = %eval(&i + 1);
	%end;
%mend macro_nazwy_znaki;

%macro_nazwy_znaki(Ala ma kota!, ! l);

/*zadanie 8****************************************************************;*/
* Wygenerować N makrozmiennych o nazwach z1,...,zN tak, aby wartość każdej 
z nich była losową wielką literą. Oczywiście może się zdarzyć, że wartości różnych
makrozmiennych są takie same. Wypisać wszystkie makrozmienne (wraz z wartościami)
o niepowtarzających się wartościach.;

%macro wypisz_unikalne(N);
    %do i=1 %to &N;
        %let rnd=%sysfunc(ranuni(2137));
        %let rnd=%sysevalf(26 * &rnd);
        %let rnd=%sysfunc(floor(&rnd));
        %let rnd=%eval(65 + &rnd);
        %let z&i=%sysfunc(byte(&rnd));
    %end;

    %put "z1=&z1";
    
    %do i=2 %to &N;
        %let cnt=0;
        %do j=1 %to %eval(&i-1);
            %if (&&z&i=&&z&j) %then %do;
                %let cnt=%eval(&cnt+1);
            %end;
        %end;
        %if (&cnt=0) %then %do;
            %put "z&i=&&z&i";
        %end;
    %end;

%mend wypisz_unikalne;

%wypisz_unikalne(100);

* Wygenerować N makrozmiennych o nazwach z1,...,zN tak, aby wartość każdej 
z nich była INNĄ losową wielką literą. Zakładamy, że N<=26.;

%macro wygeneruj_rozne(N);
    %do i=1 %to &N;
        %do %until(&cnt=0);
            %let cnt=0;
            %let rnd=%sysfunc(ranuni(2137));
            %let rnd=%sysevalf(26 * &rnd);
            %let rnd=%sysfunc(floor(&rnd));
            %let rnd=%eval(65 + &rnd);
            %let z&i=%sysfunc(byte(&rnd));
            %if (&i=1) %then %let cnt=0;
            %else %do;
                %do j=1 %to %eval(&i-1);
                    %if (&&z&i=&&z&j) %then %do;
                        %let cnt=%eval(&cnt+1);
                    %end;
            	%end;
        	%end;
        %end;
        %put "z&i=&&z&i";
    %end;
%mend wygeneruj_rozne;

%wygeneruj_rozne(26);
%wygeneruj_rozne(10);

option mlogic;
option nomlogic;


/*zadanie 9****************************************************************;*/
* Napisać makro %komb(n, k), tworzące dla danych n, k ∈N zbiór sasowy kombinacje
o k zmiennych i comb(n, k) obserwacjach. 
Wiersze zbioru kombinacje mają zawierać k-elementowe kombinacje zbioru {1,...,n}.;

%macro komb(nazwa_zbioru,n,k);
    %let first=1;
    %let last = %eval(&n-&k);
    data &nazwa_zbioru;
    	retain j 1;
        %do i = 1 %to &k;
            %let last = %eval(&last + 1);
            do var&i = &first to &last;
                %let first = %str(%(var&i + 1 %));
        %end;
        output;
        j + 1 ;
        %do i = 1 %to &k;
        	end;
        %end;
        drop j;
    run;
%mend komb;

%komb(komb_5_2,5,2);
%komb(komb_5_3,5,3);
%komb(komb_5_4,5,4);

/* KONIEC ****************************************************************;*/