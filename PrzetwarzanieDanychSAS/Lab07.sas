/*
LABORATORIUM NR: 7
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--7
UWAGI:
*/

/*deklaracja bibliotek*/
libname lab7 "/folders/myfolders/Labs/Lab7/lab07";


/*zadanie 1****************************************************************;*/

*Utworzyć zbiór zawierający maksima, 
odchylenia standardowe i średnie zmiennych
w kolejnych obserwacjach.;

proc sql;
	create table out_z01a as
	select max(x,y,z,t) as maximum, std(x,y,z,t) as standard_deviation, mean(x,y,z,t) as average
	from lab7.l07z01;
quit;


proc sql;
	*Liczba braków danych zmiennej x;
	select count(*) as miss_cnt
	from lab7.l07z01
	where x <= .z; *obsługuje wszystkie rodzaje missingów w sasie;
	
	*Ile razy zmienna z przyjmuje wartości większe niż 60?;
	select count(*) as over_60
	from lab7.l07z01
	where z > 60;
quit;

* Ile razy suma wszystkich zmiennych (z brakującymi
 wartościami traktowanymi jako −1) przekracza 30?;
 
proc sql;
	select count(*)
	from lab7.l07z01
	where sum(coalesce(x,-1), coalesce(y,-1), coalesce(z,-1), coalesce(t,-1)) > 30;
quit;


*Jednym zapytaniem wyznaczyć średnie zmiennej t dla: parzystych t,
dla t będących wielokrotnościami 5 i dla t większych od 50 w grupach
wyznaczonych przez reszty z dzielenia zmiennej y przez 3;

proc sql;
select avg(t1) as avg1, avg(t2) as avg2, avg(t3) as avg3
from(select 
		case when mod(t, 2)=0 then t end as t1,
		case when mod(t, 5)=0 then t end as t2,
		case when t>50 then t end as t3,
		y
		from lab7.l07z01)
group by mod(y, 3); 
quit;


/*zadanie 2****************************************************************;*/

*SQL;

proc sql;
* 1. Podać średnią z wyników osób A i E.;
	select avg(w) as średnia_z_wyników
	from lab7.l07z02
	where o="A" or o='E';
	
* 2. Podać najlepszy wynik osoby C w drugiej połowie roku.;
	select max(w) as najlepszy_wynik
	from lab7.l07z02
	where o="C" and (k='III' or k='IV');
quit;	


proc sql number;
* 3. Sklasyfikować osoby względem średniego wyniku.;
	select o, avg(w) as średnia_z_wyników
	from lab7.l07z02
	group by o
	order by średnia_z_wyników desc;
quit;

proc sql;
* 4. Wybrać kwartały, w których choć jedna osoba osiągnęła 
	 swój najlepszy rezultat;

select r, k
from lab7.l07z02 as outer
inner join (select o, max(w) as m
			from lab7.l07z02
			group by o) as inner
on inner.o = outer.o and outer.w = inner.m
group by r, k
having count(*)>0;

* 5. Wybrać osoby, które swój najlepszy rezultat osiągnęły 
	 w pierwszej połowie roku.;
select distinct outer.o
from lab7.l07z02 as outer
inner join (select o, max(w) as m
			from lab7.l07z02
			group by o) as inner
on inner.o = outer.o and outer.w = inner.m
where k in ('I', 'II');

* 6. Wybrać najlepsze osoby w poszczególnych kwartałach
     poszczególnych lat;
     
select outer.r, outer.k, outer.o
from lab7.l07z02 as outer
inner join (     
		select r, k, max(w) as m
		from lab7.l07z02 
		group by k, r) as inner
on inner.r = outer.r and inner.k = outer.k and inner.m = outer.w;

* 7. Ile wyników osoby A jest lepszych niż najgorszy wynik osoby B?;

select count(*)
from lab7.l07z02 
where o="A" and w < (select min(w) from lab7.l07z02 where o="B");

* 8. Znaleźć osobę, dla której różnica między najlepszym 
	 i najgorszym wynikiem jest największa?;

create table temp_z01h as
select o, max(w)-min(w) as max_diff 
from lab7.l07z02
group by o;

select o, max_diff
from temp_z01h
where max_diff in (select max(max_diff) from temp_z01h);

* 9. Wybrać te kwartały, w których więcej 
niż jedna osoba osiągnęła swój najlepszy rezultat.;

select distinct r, k
from lab7.l07z02 as outer
inner join (select o, max(w) as m
			from lab7.l07z02
			group by o) as inner
on inner.o = outer.o and outer.w = inner.m
group by r, k
having count(*)>1;

* 10. Wybrać te wyniki osoby C, dla których w kwartale ich uzyskania 
osoba D miała wynik gorszy lub nie startowała.;


select outer.r, outer.k, outer.o, w from lab7.l07z02 as outer 
inner join(
	select r, k from lab7.l07z02 where o = "C"
	except
	select r, k from lab7.l07z02 where o = "D") as inner
	on outer.r = inner.r and outer.k = inner.k
where o = "C"
union
select outer.r, outer.k, outer.o, outer.w
from lab7.l07z02 as outer
inner join(
	select * 
	from lab7.l07z02 
	where o = "D") as inner
on inner.r = outer.r and inner.k = outer.k
where outer.o = "C" and inner.w < outer.w;


* 11. Wybrać te wyniki osoby C, dla których w kwartale ich uzyskania 
	  osoba D miała wynik gorszy;

select outer.r, outer.k, outer.o, outer.w
from lab7.l07z02 as outer
inner join(
	select * 
	from lab7.l07z02 
	where o = "D") as inner
on inner.r = outer.r and inner.k = outer.k
where outer.o = "C" and inner.w < outer.w;

quit;

* 4GL;
* 1. Podać średnią z wyników osób A i E.;

data out_z02a;
	set lab7.l07z02 end=eof;
	retain sum cnt 0;
	if o = "A" or o = "E" then 
		do;
			sum + w;
			cnt + 1;
		end;
	if eof then
		do;
			mean = sum/cnt;
			output;
		end;
	keep mean;
run;


* 2. Podać najlepszy wynik osoby C w drugiej połowie roku.;

data out_z02b;
	set lab7.l07z02 end=eof;
	retain max 0;
	if o = "C" and (k = "III" or k = "IV") then 
		do;
			if w > max then max = w;
		end;
	if eof then output;
	keep max;
run;


* 3. Sklasyfikować osoby względem średniego wyniku.;

proc sort data=lab7.l07z02 out=l07z02;
by descending o;
run;

proc means data=l07z02 mean;
var w;
by descending o;
output out=l07z02(drop=_type_ _freq_) mean= / autoname;
run;

proc sort data=l07z02 out=l07z02;
by descending w_Mean;
run;

data out_z02c;
set l07z02;
by descending w_Mean;
retain rank;
if first.w_Mean then rank+1;
run;


* 4 i 9. Wybrać kwartały, w których choć jedna osoba osiągnęła 
	 swój najlepszy rezultaw w których więcej niż jedna osoba
	 osiągnęła swój najlepszy rezultat i te v;

proc sort data=lab7.l07z02 out=l07z02;
by descending w;
run;

data tmp_z02d;
  array cnt{5};
  set l07z02;
  put _all_;
  if cnt(rank(o)-64)=. then cnt(rank(o)-64)=w;  
  if w = cnt(rank(o)-64) then output;
  retain cnt;
  keep r k;
run;

proc sort data=tmp_z02d out=out_z02d nodupkey dupout=out_z02h;
	by _all_;
run;
	 
* 5. Wybrać osoby, które swój najlepszy rezultat osiągnęły 
	 w pierwszej połowie roku.;
	 
proc sort data=lab7.l07z02 out=l07z02;
by o descending w;
run;	 
	
data tmp_z02e;
  array max_res{5};
  set l07z02;
  by o;
  if first.o then do;
	  max_res(rank(o)-64)=w;
  end;
  if w=max_res(rank(o)-64) then output;
  retain max_res;
run;

data out_z02e;
	set tmp_z02e;
	if (k = "I" or k = "II") then output;
	keep o;
run;
	 
* 6. Wybrać najlepsze osoby w poszczególnych kwartałach
     poszczególnych lat;
     
proc sort data=lab7.l07z02 out=l07z02;
  by r k descending w;
run;

data out_z02f;
  set l07z02;
  by r k;
  if first.k then do;
	  max_res=w;
  end;
  if w=max_res then output;
  retain max_res;
run;
     
     
* 7. Ile wyników osoby A jest lepszych niż najgorszy wynik osoby B?;
proc sort data=lab7.l07z02 out=l07z02;
  by descending o w;
run;


data out_z02g;
  set l07z02;
  by descending o;
  if o="B" and first.o then 
  do; 
  	min_B = w;
  end;
  if o="A" and w > min_B then output;
  retain min_B;
run;


* 8. Znaleźć osobę, dla której różnica między najlepszym 
	 i najgorszym wynikiem jest największa?;
	 
proc sort data=lab7.l07z02 out=l07z02;
  by o descending w;
run;

data tmp_z02h;
  set l07z02;
  by o;
  if first.o then max_res=w;
  if last.o then do;
    res_rng = max_res-w;
    output;
  end;
  retain max_res;
run;

proc sort data=tmp_z02h out=tmp_z02h;
  by descending res_rng;
run;	 

data out_z02h;
  set tmp_z02h;
  if _n_=1 then max_rng=res_rng;
  if res_rng = max_rng then output;
  retain max_rng;
  keep o max_rng;
run;

* 10. Wybrać te wyniki osoby C, dla których w kwartale ich uzyskania 
	  osoba D miała wynik gorszy lub nie startowała.;

proc sort data=lab7.l07z02 out=l07z02;
  by r k descending o;
run;


data out_z02g;
  set l07z02;
  by r k descending o;
  prev_o = lag(o);
  prev_w = lag(w);
  if o = "C" then 
  do;
    if first.k=0 then 
    do;
      if prev_o^="D" then output;
      else if w > prev_w then output;
    end;
    else output;
  end;
run;

	  
* 11. Wybrać te wyniki osoby C, dla których w kwartale ich uzyskania 
	  osoba D miała wynik gorszy;

proc sort data=lab7.l07z02 out=l07z02;
  by r k descending o;
run;


data out_z02g;
  set l07z02;
  by r k descending o;
  prev_o = lag(o);
  prev_w = lag(w);
  if first.k=0 and o="C" and lag(o)="D" and w > lag(w) then output;
  put _all_;
run;


/*zadanie 3****************************************************************;*/

proc sql;
* 1. Dla każdej wartości zmiennej x znaleźć najczęściej występujące wartości 
zmiennej y (nie dbając o ewentualne sytuacje remisowe, tj. wybierając 
wtedy dowolną z najczęstszych wartości y);

select * 
from(
	select *
		from(select x, y, count(*) as y_count, monotonic() as row
			 from temp 
			 group by x, y)
		group by x
		having y_count = max(y_count))
group by x
having row = min(row);


* 2. Dla każdej wartości zmiennej x znaleźć wszystkie najczęściej występujące
 wartości zmiennej y;
 
select x, y
from(select x, y, count(*) as y_count 
	 from lab7.l07z03 
	 group by x, y)
group by x
having y_count = max(y_count);


* 3. Znaleźć te wartości zmiennej x, dla których istnieje dokładnie 
     jeden najmniejszy y;
     
select x
from(select x, y, min(y) 
	 from lab7.l07z03 
	 group by x 
	 having y = min(y))
group by x
having count(*) = 1;

	
* 4. Znaleźć te wartości zmiennej x, którym nie odpowiadają 
	 powtarzające się y;

select x 
from lab7.l07z03
except(
	select distinct x
	from lab7.l07z03
	group by x,y
	having count(y)>1);
	
	
* 5. Znaleźć te wartości zmiennej x, którym odpowiada największa
	 liczba różnych wartości zmiennej y.;
	 
select x 
from(select x, count(distinct y) as y_count
	 from lab7.l07z03
	 group by x) 
where monotonic() = 1
order by y_count;	 

	 
* 6. Wybrać te wartości zmiennej x, dla których wartości zmiennej
     y tworzą zbiór {1,...,n} dla pewnego n;
     
select distinct x 
from lab7.l07z03
except(
	select distinct base.x
	from(
	  select base.x, base.y, prev.x as prev_x, prev.y as prev_y, base.y-prev.y as diff, min(base.y) as min_y
	  from    (select *, monotonic() as idx from lab7.l07z03) base
	  left join (select *, monotonic() as idx from lab7.l07z03) prev
	  on      base.x=prev.x
	  and     base.idx=prev.idx+1
	  group by base.x)
	  where diff>1 or min_y <> 1);

* 7. Wybrać te wartości zmiennej x, dla których różne wartości 
	 zmiennej y tworzą zbiór {1,...,n} dla pewnego n;
	 
select * 
from(
	select x
	from lab7.l07z03
	except(
		select distinct base.x
		from(
		  select base.x, base.y, prev.x as prev_x, prev.y as prev_y, base.y-prev.y as diff, min(base.y) as min_y
		  from    (select *, monotonic() as idx from lab7.l07z03) base
		  left join (select *, monotonic() as idx from lab7.l07z03) prev
		  on      base.x=prev.x
		  and     base.idx=prev.idx+1
		  group by base.x)
		  where diff>1 or min_y <> 1))
group by x
having count(*)>1;
	 
* 8.  Znaleźć te wartości zmiennej y, które przypisane są co 
      najmniej połowie wartości zmiennej x występujących
      w zbiorze L07z03.;
      
select y, count(x) as x_count
from lab7.l07z03
group by y
having x_count >= (select count(distinct x) from lab7.l07z03)/2;
quit;



/*zadanie 4****************************************************************;*/

*1. Znaleźć wartości zmiennej id, które nie występowały przed 2003 rokiem.;
proc sql;
	select id
	from lab7.l07z04
	group by id
	having min(year) >= 2003;
quit;

*2. Znaleźć wartości zmiennej id, które występowały w pierwszym i ostatnim roku.;
proc sql;
	select id
	from(select id, year, min(year) as min_year, max(year) as max_year from lab7.l07z04)
	group by id
	having min(year) = min_year and max(year) = max_year;
quit;

* 3. Znaleźć wartości zmiennej id, które występowały dla każdego roku.;
proc sql;
	select id
	from(select id, year, max(year) - min(year) + 1 as range from lab7.l07z04)
	group by id
	having count(*) >= range;
quit;


/*zadanie 5****************************************************************;*/


proc sql;
* 1. ilość różych wartości zmiennej x, które znajdują się tylko w pierwszym zbiorze;
select count(*) 
from(
	select distinct x from lab7.l07z05t1
	except
	select distinct x from lab7.l07z05t2);

* 2. ilość różych wartości zmiennej x, które znajdują się tylko w drugim zbiorze;
select count(*) 
from(
	select distinct x from lab7.l07z05t2
	except
	select distinct x from lab7.l07z05t1);	
	
* 3. ilość różych wartości zmiennej x, które znajdują się w obydwu zbiorach;
select count(*) 
from(
	select x from lab7.l07z05t2
	intersect
	select x from lab7.l07z05t1);	
	
	
* 4. ilość różych wartości zmiennej x, które nie występują w obydwu zbiorach jednocześnie;
select count(*) 
from(
	(select * from lab7.l07z05t2
	union 
	select * from lab7.l07z05t1)
	except(
	select x from lab7.l07z05t2
	intersect
	select x from lab7.l07z05t1));
quit;

/*zadanie 6****************************************************************;*/
* 1. Traktując zmienne a1 i a2 jako zmienne grupujące, wybrać dla każdej 
grupy wyznaczonej przez a1 te wartości x1, które znajdują się między 
minimalną i maksymalną wartością zmiennej x2 w tej samej grupie 
wyznaczonej przez a2;
proc sql;

select distinct a1, x1 
from lab7.l07z06 as outer
left join(
	select a2, min(x2) as min_x2, max(x2) as max_x2
	from lab7.l07z06
	group by a2) as inner
on outer.a1 = inner.a2
where x1 >= min_x2 and x1 <= max_x2;
quit;

* 2. Znaleźć nazwę grupy, która najczęściej występuje w całym zbiorze L07z06.;

proc sql;
select grp 
	from(
		select grp, sum(cnt) as counter
			from(
				select a1 as grp, count(*) as cnt 
					from lab7.l07z06 
					group by a1
				union
				select a2 as grp, count(*) as cnt 
					from lab7.l07z06 
					group by a2)
		group by grp)
	having counter = max(counter);
quit;



/*zadanie 7****************************************************************;*/
* 1. dla zmiennej r2 znaleźć miesiąc, w którym miała ona najwięcej braków;
proc sql;
select miesiac 
from(
	select distinct month(dzien) as miesiac, count(*) as r2_mcnt
		from lab7.l07z07 
		where r2 is null 
		group by miesiac)
having r2_mcnt = max(r2_mcnt);			
quit;

* 2.  dla zmiennej r1 znaleźć miesiąc, w którym jej wartości 
	są najbardziej rozproszone;
	
proc sql;
select miesiac 
from(
	select distinct month(dzien) as miesiac, max(r1)-min(r1) as r1_rng
		from lab7.l07z07 
		group by miesiac)
having r1_rng = max(r1_rng);			


/*KONIEC*******************************************************************;*/
