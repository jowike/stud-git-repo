/*
LABORATORIUM NR: 8
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--10
UWAGI: 
*/

/*deklaracja bibliotek*/
libname lab8 "/folders/myfolders/Labs/Lab8/lab08";

/*zadanie 1****************************************************************;*/
/* Porównanie ciągów i wypisanie numeru pierwszej różnicy
   i liczby wszystkich różnic */
data out_z01 (keep=x1 x2);
  retain cnt idx 0;
  
  if (eof1 and eof2) then do;
    put "Liczba elementów, którymi różnią się porówywane ciągi: " cnt 
    ". Numer wiersza, w którym wystąpiła pierwsza różnica: " idx;
    stop;
  end;
  * wczytanie obydwu ciągów element po elemencie;
  if not eof1 then do;
    set lab8.l08z01_c1 end=eof1;
    x1 = x;
  end;
  if not eof2 then do;
  	set lab8.l08z01_c2 end=eof2;
  	x2 = x;
  end;
  
  if not(x1 = x2) then do;
    if cnt = 0 then idx = _N_;
    cnt + 1;
  end;
run;


/*zadanie 2****************************************************************;*/

/* Średnia zmiennej sales ze zbioru L08z02_duzy obliczona tylko dla tych wartości 
   zmiennej id, które znajdują się w zbiorze L08z02_maly;*/
proc contents data=lab8.l08z02_duzy;
run;
* I - rozwiązanie z wykorzystaniem tablic;
proc transpose data=lab8.l08z02_maly out=z02_idx(keep=col:) let;
var id;
run;

data out_z02_I;
  retain sum 0;
  
  set z02_idx end=eof1;
    array idx_arr{*} col:;
  if eof1 then do until(eof2=1);
  	set lab8.l08z02_duzy end=eof2;
  	if id in idx_arr then sum = sum + sales;
  	output;
  end;
  
  if eof2 then do;
    avg = sum/dim(idx_arr);
    put "Średnia zmiennej sales ze zbioru L08z02_duzy obliczona dla wybranych id wynosi: " avg;
  end;
  
  retain idx_arr;
run;

* II - rozwiązanie z wykorzystaniem opcji point;
proc sort data=lab8.l08z02_duzy out=l08z02_duzy_sort;
by id;
run;

data _null_;
  retain sum cnt 0;
  
  set lab8.l08z02_maly end=eof1;
    row_num = id-9999;
  	set l08z02_duzy_sort end=eof2 point=row_num;
  	  sum + sales;
  	  cnt + 1;
    if eof1 then do;
      avg = sum/cnt;
      put "Średnia zmiennej sales ze zbioru L08z02_duzy obliczona dla wybranych id wynosi: " avg;
    end;
run;

* III - rozwiązanie z wykorzystaniem procedury SQL;
proc sql;
select avg(sales) 
from lab8.l08z02_duzy 
where id in(select id from lab8.l08z02_maly)
;
quit;

* IV - rozwiązanie z wykorzystaniem procedury SQL i produktu kartezjańskiego;
proc sql;
select avg(sales)
from lab8.l08z02_duzy 
where id in(
  select id
  from lab8.l08z02_duzy 
intersect
  select id
  from lab8.l08z02_maly);
quit;


* V - rozwiązanie z wykorzystaniem procedury SQL i JOIN;
proc sql;
select avg(sales)
from lab8.l08z02_duzy as d
inner join lab8.l08z02_maly as m on m.id=d.id;
quit;

* VI - rozwiązanie z wykorzystaniem polecenia merge;
proc sort data=lab8.l08z02_maly out=l08z02_maly_sort;
by id;
run;

data _null_;
retain sum cnt 0;
merge l08z02_duzy_sort(in=d_in) l08z02_maly_sort(in=m_in) end=eom;
by id;
if d_in and m_in then do;
  sum + sales;
  cnt + 1;
  *output;
end;
if eom then do;
  avg = sum/cnt;
  put "Średnia zmiennej sales ze zbioru L08z02_duzy obliczona dla wybranych id wynosi: " avg;
end;
run;

/*zadanie 3****************************************************************;*/
/* Średnia zmiennej sales ze zbioru L08z02 duzy obliczona tylko dla obserwacji,
   których numery znajdują się w zbiorze L08z03 numery */
  
* I - rozwiązanie z wykorzystaniem opcji point;
data _null_;
  retain sum cnt 0;
  
  set lab8.l08z03_numery end=eof1;
  	set l08z02_duzy_sort end=eof2 point=numer;
  	    sum + sales;
  	    cnt + 1;
    if eof1 then do;
      avg = sum/cnt;
      put "Średnia zmiennej sales ze zbioru L08z02_duzy obliczona dla wybranych id wynosi: " avg;
    end;
run;

* II - rozwiązanie z wykorzystaniem polecenia merge;
data tmp_z03_II;
set l08z02_duzy_sort;
  numer = _n_;
run;

data _null_;
retain sum cnt 0;
merge tmp_z03_II(in=d_in) lab8.l08z03_numery(in=n_in) end=eom;
by numer;
if d_in and n_in then do;
  sum + sales;
  cnt + 1;
  output;
end;
if eom then do;
  avg = sum/cnt;
  put "Średnia zmiennej sales ze zbioru L08z02_duzy obliczona dla wybranych id wynosi: " avg;
end;
run;

/*zadanie 4****************************************************************;*/

proc transpose data=lab8.l08z04_kropki out=l08z04_kropki_T;
var z:;
run;

data tmp_z04(keep=non_empty:);
set l08z04_kropki_T;
  retain j 1;
  array cols col:;
  array non_empty{10};
  do i=1 to dim(cols);
    if not(missing(cols(i))) then do;
      non_empty(j) = cols(i);
      j+1;
    end;
    if i = dim(cols) then do;
      output;
      j=1;
    end;
  end;
run;

proc transpose data=tmp_z04 out=out_z04(drop=_name_);
run;

* II sposób za pomocą merge;
data Z1(where=(z1^=.) keep=z1) Z2(where=(z2^=.) keep=z2) Z3(where=(z3^=.) keep=z3) Z4(where=(z4^=.) keep=z4);
set lab8.l08z04_kropki;
run;

data out_z04_merge;
merge Z1 Z2 Z3 Z4;
run;


/*zadanie 5****************************************************************;*/
data l08z05_liczby(keep=x);
do i=1 to 100;
  x = rand('uniform')*1000;
  output;
end;
run;

* przeprowadzenie obliczeń na samodzielnie wygenerowanym zbiorze;
data l08z05_suma(keep=sum);
do i=1 to 95 by 1;
    sum = 0;
    do _n_=i to (i+5) by 1;
      set l08z05_liczby point=_n_;
      sum + x;
    end;
    output;
end;
stop;
run;

* weryfikacja poprawności działania metody na dołączonym zbiorze;
data l08z05_suma(keep=sum);
do i=1 to 95 by 1;
    sum = 0;
    do _n_=i to (i+5) by 1;
      set lab8.l08z05_liczby point=_n_;
      sum + x;
    end;
    output;
end;
stop;
run;


/*zadanie 6****************************************************************;*/

proc sql noprint;
create table L08z06_SQL_to_4GL_fin as
select *, avg(y) as srednia
from lab8.L08z06_SQL_to_4GL
group by x
having count(y) > 5
;
quit;

*średnia z y dla grup zadanych zmienną x 
o liczności >5;
data out_z06(keep=x y srednia);
retain sum cnt first_idx 0;
set lab8.l08z06_sql_to_4gl;
by x;
  if first.x then first_idx = _n_;
  sum+y;
  cnt+1;
  if last.x then do;
    if cnt>5 then do;
      last_idx = first_idx+cnt-1;
      do i=first_idx to last_idx;
        set lab8.l08z06_sql_to_4gl point=i;
        srednia = sum/cnt;
        output;
      end;
    end;
    sum=0;
    cnt=0;
    end;
run;
* rezultat właściwy z dokładnością do permutacji wierszy;

/*zadanie 7****************************************************************;*/
proc contents data=lab8.l08z07_zb1;
run;

data tmp_z07(keep=data);
format data DDMMYY10.;
do i = '01JAN2007'd to '31DEC2007'd;
  data = i;
  output;
end;
run;

data out_z07;
merge tmp_z07 lab8.l08z07_zb1(rename=(x=z1)) lab8.l08z07_zb2(rename=(x=z2)) lab8.l08z07_zb3(rename=(x=z3))
 lab8.l08z07_zb4(rename=(x=z4))  lab8.l08z07_zb5(rename=(x=z5));
 by data;
 total = sum(of z:);
run;

/*zadanie 8****************************************************************;*/
data out_z08;
merge lab8.l08z08_jan(rename=(wynik=wynik1)) lab8.l08z08_feb(rename=(wynik=wynik2))
 lab8.l08z08_mar(rename=(wynik=wynik3)) lab8.l08z08_apr(rename=(wynik=wynik4));
 by osoba;
 najbardziej_aktualny_wynik=coalesce(wynik4,wynik3,wynik2,wynik1);
run;

/*zadanie 9****************************************************************;*/
data _null_;
retain cnt 0;
merge lab8.l08z09_x(rename=(x=x_set)) lab8.l08z09_y(rename=(y=y_set)) lab8.l08z09_xy end=eom;
if x = x_set and y = y_set then cnt+1;
if eom then put "Liczba obserwacji zbioru L08z09_xy, dla których wartości zmiennych x i y są równe wartościom 
zmiennej x ze zbioru L08z09_x i y ze zbioru L08z09_y dla odpowiadających numerów obserwacji wynosi: " cnt;
run;

/*zadanie 10****************************************************************;*/
proc transpose data=lab8.l08z10_drugi out=l08z10_drugi_T name=month;
by year;
var JAN--DEC;
run;

data in_z10(drop=month);
	set l08z10_drugi_T;
	month_num = input(put(input(catt(month,'1960'),monyy.),month.), 8.);
run;

proc contents data=in_z10;
run;

data out_z10;
merge lab8.l08z10_pierwszy(rename=(sales = sales_pierwszy)) in_z10(rename=(col1=sales_drugi month_num=month)) ;
by year month;
if missing(sales_pierwszy) and missing(sales_drugi) then delete;
else if missing(sales_pierwszy) then sales = sales_drugi;
else if missing(sales_drugi) then sales = sales_pierwszy;
else sales = sales_pierwszy+sales_drugi;
run;

* drugi sposób - jeden data step:;
data out_z10;
    retain cur 1;
    merge lab8.l08z10_pierwszy lab8.l08z10_drugi;
    by year;
    array months{12} Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec;
    do i=cur to month;
        if not(missing(months{i})) and i<month then do;
            n_month = i;
            n_sales = months{i};
            output;
            end;
        if month=i then do;
            if not(missing(months{i})) then do;
                n_month = i;
                n_sales = sales+months{i};
                output;
                end;
            else do;
                n_month = i;
                n_sales = sales;
                output;
                end;
            if month<12 and not last.year then do;
                cur = month+1;
                end;
            else do;
                cur = 1;
                end;
            end;
        end;
        keep year n_month n_sales;
run;
