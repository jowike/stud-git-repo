/*
LABORATORIUM NR: 9
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--7
UWAGI:
*/

/*deklaracja bibliotek*/
libname lab8 "/folders/myfolders/Labs/Lab8/lab08";
libname lab9 "/folders/myfolders/Labs/Lab9/lab09";

/*zadanie 1****************************************************************;*/

* Znaleźć wypożyczalnię, w której dokonano największej liczby wypożyczeń między 1 stycznia,
a 6 czerwca 1999 roku;
proc sql;
select NR_MIEJSCA_WYP from(
  select NR_MIEJSCA_WYP, count(*) as cnt from lab9.l09z01_wypozyczenia
  where datepart(input(DATA_WYP, anydtdtm.)) between '01JAN1999'd and '06JUN1999'd
  group by NR_MIEJSCA_WYP)
having cnt = max(cnt)
;
quit;


* Znaleźć nazwiska klientów, którzy korzystali z wypożyczalni więcej niż raz i przynajmniej
raz wypożyczyli Opla.;
proc sql;
select NR_KLIENTA, IMIE, NAZWISKO from lab9.l09z01_klienci
where NR_KLIENTA in(
  select NR_KLIENTA from lab9.l09z01_wypozyczenia
  where NR_KLIENTA in(
    select distinct NR_KLIENTA from lab9.l09z01_wypozyczenia as wypozyczenia 
    join lab9.l09z01_samochody as samochody on samochody.nr_samochodu = wypozyczenia.nr_samochodu
    where MARKA = "OPEL")
  group by NR_KLIENTA
  having count(*) > 1)
;
quit;


* Dla każdej wypożyczalni wybrać te samochody, które były wypożyczone między
1 października, a 31 grudnia 1998 (dla danej wypożyczalni wypisywać samochody w kolejności zależnej
od długości wypożyczenia);
proc sql;
select wypozyczalnie.*, samochody.*, datepart(input(DATA_ODD, anydtdtm.))-datepart(input(DATA_WYP, anydtdtm.)) as CZAS_WYPOZYCZENIA
  from lab9.l09z01_wypozyczenia as wypozyczenia
    join lab9.l09z01_samochody as samochody on wypozyczenia.NR_SAMOCHODU = samochody.NR_SAMOCHODU
    join lab9.l09z01_wypozyczalnie as wypozyczalnie on wypozyczenia.NR_MIEJSCA_WYP = wypozyczalnie.NR_MIEJSCA
  where datepart(input(DATA_WYP, anydtdtm.)) between '01OCT1998'd and '31DEC1998'd
  order by NR_MIEJSCA_WYP, CZAS_WYPOZYCZENIA
;
quit;


* Znaleźć nazwiska klientów, którzy dokonywali wypożyczeń więcej niż raz, ale za każdym razem
wypożyczali samochody innych marek.;
proc sql;
select DISTINCT IMIE, NAZWISKO from lab9.l09z01_wypozyczenia as wypozyczenia
join lab9.l09z01_samochody as samochody on wypozyczenia.NR_SAMOCHODU = samochody.NR_SAMOCHODU
join lab9.l09z01_klienci as klienci on wypozyczenia.NR_KLIENTA = klienci.NR_KLIENTA
group by klienci.NR_KLIENTA
HAVING COUNT(DISTINCT MARKA) = COUNT(*) and COUNT(*) > 1
;
quit;


* Podać listę pracowników, którzy nie dokonali żadnych wypożyczeń między październikiem
1999 roku, a lutym 2000 roku;
proc sql;
select * from lab9.l09z01_pracownicy 
where NR_PRACOWNIKA NOT IN(
  select distinct NR_PRACOW_WYP from lab9.l09z01_wypozyczenia
  where datepart(input(DATA_WYP, anydtdtm.)) between '01OCT1999'd and '01FEB2000'd)
;
quit;


* Dla wypożyczeń, w przypadku których odbiór i oddanie samochodu
odbywały się w różnych wypożyczalniach, znaleźć nazwiska osób wydających i przyjmujących samochody;
proc sql;
select wyp.NR_WYPOZYCZENIA, IMIE_PRACOW_WYP, NAZWISKO_PRACOW_WYP, IMIE_PRACOW_ODD, NAZWISKO_PRACOW_ODD
from (select NR_WYPOZYCZENIA, NR_PRACOW_WYP, IMIE AS IMIE_PRACOW_WYP, NAZWISKO AS NAZWISKO_PRACOW_WYP, NR_MIEJSCA_WYP
	  from lab9.l09z01_wypozyczenia as wypozyczenia
	  join lab9.l09z01_pracownicy as pracownicy on wypozyczenia.NR_PRACOW_WYP = pracownicy.NR_PRACOWNIKA
	  where NR_MIEJSCA_WYP ^= NR_MIEJSCA_ODD) wyp
join (select NR_WYPOZYCZENIA, NR_PRACOW_ODD, IMIE AS IMIE_PRACOW_ODD, NAZWISKO AS NAZWISKO_PRACOW_ODD, NR_MIEJSCA_ODD 
			from lab9.l09z01_wypozyczenia as wypozyczenia
			join lab9.l09z01_pracownicy as pracownicy on wypozyczenia.NR_PRACOW_ODD = pracownicy.NR_PRACOWNIKA
			where NR_MIEJSCA_WYP ^= NR_MIEJSCA_ODD) odd on wyp.NR_WYPOZYCZENIA = odd.NR_WYPOZYCZENIA 
;
run;


* Znaleźć pracownika zatrudnionego przed 1998 rokiem, który w roku 1999 przyniósł
największy dochód firmie.;
proc sql;
select * 
from(
	select distinct pracownicy.*, sum(CENA_JEDN) as DOCHOD
	from lab9.l09z01_wypozyczenia as wypozyczenia
	join lab9.l09z01_pracownicy as pracownicy on wypozyczenia.NR_PRACOW_WYP = pracownicy.NR_PRACOWNIKA
	where datepart(input(DATA_ZATR, anydtdtm.)) < '01JAN1998'd 
		and datepart(input(DATA_WYP, anydtdtm.)) between '01JAN1999'd and '31DEC1999'd
	group by NR_PRACOWNIKA)
HAVING DOCHOD = max(DOCHOD)
;
quit;


* Przedstawić historię wypożyczeń samochodu o kodzie 000006 (data wypożyczenia, data oddania, 
nazwisko wypożyczającego, koszt wypożyczenia).;
proc sql;
select DATA_WYP, DATA_ODD, NAZWISKO, CENA_JEDN 
from lab9.l09z01_wypozyczenia as wypozyczenia
join lab9.l09z01_pracownicy as pracownicy on wypozyczenia.NR_PRACOW_WYP = pracownicy.NR_PRACOWNIKA
where NR_SAMOCHODU = '000006'
order by datepart(input(DATA_WYP, anydtdtm.))
;
quit;


/*zadanie 2****************************************************************;*/

* budowa formatu ze zbioru - wyróżnienie za pomocą formatu wartości występujących 
w małym zbiorze - występujące oflagowujemy jako 1 a wszystkie pozostałe jako 0;
data datasetFmt(drop=i id);
  length fmtname $4 type $1 label $2;
  retain fmtname 'maly' type 'N';
  format START END z6.;
  * wczytuje kolejne obserwacje i ustawiajac start i end za kazdym razem
  dostaje jednoelementowy zakres, ktorego (jedynemu) elementowi nadaje etykiete;
  do i=1 to n; 
    set lab8.l08z02_maly nobs=n;
    label = 'in'; * etykieta wyswietlana dla wartosc z zakresu START i END;
    START = id; * START - poczatkowa wartosc zakresu;
    END = id;   * END - koncowa wartosc zakresu;
    output;
  end;
  
  HLO = 'O';     * O = wskazuje etykiete dla wartosci kategorii other;
  label = 'out'; * etykieta wyswietlana dla wartosci kategorii other;
  output;
run;

proc format library= WORK cntlin=work.datasetFmt; * cntlin - create a format from an input control data set;
run;

data wynik;
  set lab8.l08z02_duzy;
  where put(id, maly.) = 'in' ;
run;

* obliczenie średniej;
proc means data=wynik mean;
var sales;
run;


/*zadanie 3****************************************************************;*/

data L09z03_4GL_to_SQL_fin;
	merge lab9.L09z03_a(in = ina) lab9.L09z03_b(in = inb);
	by a b c;
	if inb;
	if inb and not ina then wskaznik=1;
run;

proc sql;
create table L09z03_4GL_to_SQL as
select B.*, case
			when A.a is null and A.b is null and A.c is null then 1
			else .
			end as wskaznik
from lab9.l09z03_a A
right join lab9.l09z03_b B
on A.a=B.a and A.b=B.b and A.c=B.c
;
quit;


/*zadanie 4****************************************************************;*/

proc sql;
select * 
from(
  select daty.instrument, daty.data, pomiary.data as najblizsza_data, pomiar
  from lab9.l09z04_daty daty
  join lab9.l09z04_pomiary pomiary on pomiary.instrument = daty.instrument
  group by daty.data, daty.instrument
  having abs(daty.data-pomiary.data)=min(abs(daty.data-pomiary.data)))
group by data
having pomiar=max(pomiar)
;
run;


/*zadanie 5****************************************************************;*/

* przynajmniej jeden wspólny przedmiot;
proc sql;
create table out_z05_I as
  select distinct a.id_studenta, b.id_studenta as id_wspoluczestnika 
  from lab9.l09z05_studenci a
  join lab9.l09z05_studenci b on a.id_przedmiotu = b.id_przedmiotu
  where not a.id_studenta = b.id_studenta
  order by a.id_studenta, b.id_studenta
;
run;

* tylko wspólne przedmioty i żadne inne;
* najpierw przez cross join łączę ze sobą parami wszystkich studentów 
  a potem poprzez odpowiednie warunki ograniczam otrzymany zbiór;
  
proc sql;
select student1, student2
from(
  select student1, student2, count(*) as liczba_wspolnych, liczba_przedm_stud1
  from(
    (select id_studenta as student1, id_przedmiotu as przedmioty_stud1, count(*) as liczba_przedm_stud1
     from lab9.l09z05_studenci
     group by id_studenta)
     cross join
    (select id_studenta as student2, id_przedmiotu as przedmioty_stud2, count(*) as liczba_przedm_stud2
     from lab9.l09z05_studenci
     group by id_studenta)
  )
where liczba_przedm_stud1 = liczba_przedm_stud2 and student1 ^= student2 and przedmioty_stud1 = przedmioty_stud2
group by student1, student2, liczba_przedm_stud1)
having liczba_wspolnych = liczba_przedm_stud1
;
quit;

* zbiór przedmiotów jednego studenta są podzbiorem zbioru przedmiotów drugiego;
* tylko wspólne przedmioty i żadne inne;
* analogicznie najpierw przez cross join łączę ze sobą parami wszystkich studentów 
  a potem poprzez odpowiednie warunki ograniczam otrzymany zbiór;
proc sql;
select distinct student1, student2
from(
  select student1, student2, count(*) as liczba_wspolnych, liczba_przedm_stud1
  from(
	(select id_studenta as student1, id_przedmiotu as przedmioty_stud1, count(*) as liczba_przedm_stud1
	from lab9.l09z05_studenci
	group by id_studenta)
	cross join
	(select id_studenta as student2, id_przedmiotu as przedmioty_stud2, count(*) as liczba_przedm_stud2
	from lab9.l09z05_studenci
	group by id_studenta)
  )
where student1 ^= student2 and przedmioty_stud1 = przedmioty_stud2 
group by student1, student2, liczba_przedm_stud1)
having liczba_wspolnych = liczba_przedm_stud1 or liczba_wspolnych = liczba_przedm_stud2
;
quit;


/*zadanie 6****************************************************************;*/

* format wypisujący daty SASowe jako napisy postaci: January 1, 2011; 
* definicja formatu
  picture - creates a template for printing numbers
  Syntax:
  	PICTURE name <(format-options)>
	<value-range-set-1 <(picture-1-options)>
	<value-range-set-2 <(picture-2-options)>> ...>
	
	datatype option - enables the use of directives in the picture as a template to 
					  format date, time, or datetime values.
	default option - specifies the default length of the picture. 
	Best practice:
		If you are using the DATATYPE= option, use the DEFAULT= option to set the 
		default format width to be large enough to format these characters.;
	
proc format;
    picture format_daty (default=20) 
    other='%B %0d, %0Y' (datatype=date language=English)
    ;
run;

* generowanie zbioru;
data random_dates_dataset(keep=date date2);
  mindate='01JAN1999'd;
  maxdate='30DEC2020'd;
  range = maxdate-mindate+1;
  format mindate maxdate date date9.;
  do i = 1 to 100000;
    date = mindate + int(ranuni(12345)*range);
    date2 = put(date, format_daty.);
    output;
  end;
run;

* format wyświetlający bajty w formie ”czytelnej dla człowieka”;

* 1/1024 = 0.0009765625;
* (1/1024)^2 = 9.5367431640625 × 10^-7;
* (1/1024)^3 = 9.31322574615478515625 × 10^-10;
* multiplier - specifies a number to multiply the variable's value by before it is formatted.
  noedit - specifies that numbers are message characters rather than digit selectors.
;

proc format;
picture bytes_format
low -< 0 = 'not supported negative value'
0 -< 1024 = '0000B' 
1024 = '1KB' (noedit)
1024 <-< 1048576 = '0000.000kB' (multiplier=9.765625E-01)
1048576 = '1MB' (noedit)
1048576 <-< 1073741824 = '0000.000MB' (multiplier=9.5367431640625E-04)
1073741824 = '1GB' (noedit)
1073741824 <-< 1099511627776 = '0000.000GB' (multiplier=9.31322574615478515625E-07) 
1099511627776 = '1TB' (noedit)
other = 'value over 1TB' (noedit)
;
run;

* generowanie zbioru;
data bytes_dataset;
 input bytes;
cards;
1
1023
1024
1068.032
1048576
2411724.8 
1073741824
7.025492754432E09
1099511627776
1125899906842624
;
run;

data out_z06_II;
  set bytes_dataset;
  bytes_formatted = put(bytes, bytes_format.);
run;


/*zadanie 7****************************************************************;*/

data format_ulamki(drop=int_part: decimal_part: i j);
  length fmtname $ 10 type $ 1 label $ 35;
  retain fmtname 'ulamki_fmt' TYPE "N";

  array int_part{10} $ ('zero', 'jeden', 'dwa', 'trzy', 'cztery', 'piec', 'szesc', 'siedem', 'osiem', 'dziewiec');
  array decimal_part{9} $22 (' jedna dziesiata', ' dwie dziesiate', ' trzy dziesiate', ' cztery dziesiate', ' piec dziesiatych', ' szesc dziesiatych',' siedem dziesiatych', 'osiem dziesiatych', ' dziewiec dziesiatych');

  * etykiety części całkowitych;
  do i=1 to 10;
    label = int_part(i);
    output;
    start+1;
    end+1;
  end; 
     
  * etykiety części ułamkowych;
  do i=1 to 9;
    label = decimal_part(i);
    start=0.1*i;
    end=0.1*i;
    output;
  end;

  * konkatenacja części ułamkowej i dziesiętnej;
  do i=2 to 10; * rozpoczęcie od 2 umożliwia "nienazywanie" części całkowitej jeśli jest ona 0;
    do j=1 to 9;
      label = trim(int_part(i))||trim(' i ')|| trim(decimal_part(j));
      start=(i-1+0.1*j); * biorąc część całkowitą cofam się o 1 (i-1), aby uwzględnić 1;
      end=(i-1+0.1*j);
      output;
    end;
 end; 

  HLO = 'O';
  label = 'inna'; 
  output;
run;

proc format cntlin = work.format_ulamki; 
run;

data out_z07(keep=var var_formatted);
  var = 3.14159265359;
  var_formatted = put(var, ulamki_fmt.);
  output;
  
  do i=1 to 100000;
    var=round(ranuni(0)*10, 0.1);
    var_formatted = put(var, ulamki_fmt.);
    output;
  end;
run;

/* KONIEC ****************************************************************;*/