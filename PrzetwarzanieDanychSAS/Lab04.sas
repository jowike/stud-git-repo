/*
LABORATORIUM NR: 4
IMIE I NAZWISKO: Elżbieta Jowik
NUMER ALBUMU: 298821
NUMERY ROZWIAZANYCH ZADAN: 1--11
UWAGI:
*/

/*deklaracja bibliotek*/
libname lab4 "/folders/myfolders/Labs/Lab4/lab04";


/*zadanie 1****************************************************************;*/
* a);
data out_z01a;
	set lab4.l04z01;
	array vars{*} pytanie_1-pytanie_41;
	array varlist A_cnt B_cnt C_cnt D_cnt;
	
	do i=1 to dim(varlist);
  		varlist(i)=0;
	end;
	
	do i = 1 to dim(vars);
		if (vars{i})="A" then A_cnt + 1;
		else if (vars{i})="B" then B_cnt + 1;
		else if (vars{i})="C" then C_cnt + 1;
		else if (vars{i})="D" then D_cnt + 1;
	end;
	output;
	keep id A_cnt B_cnt C_cnt D_cnt;
run;

* b);
proc summary data=out_z01a;
var A_cnt B_cnt C_cnt D_cnt;
output out=out_z01b(drop= _TYPE_ _FREQ_) sum=;
run;

* c);
proc transpose data=lab4.l04z01 out=in_z01c(drop= _NAME_ _LABEL_) prefix = id_;
var pytanie_1-pytanie_41;
run;

data out_z01c;
	set in_z01c end=eof;
	array vars{*} id_1-id_1622;
	array varlist A_cnt B_cnt C_cnt D_cnt;
	do i=1 to dim(varlist);
  		varlist(i)=0;
	end;
	
	do i = 1 to dim(vars);
		if (vars{i})="A" then A_cnt + 1;
		else if (vars{i})="B" then B_cnt + 1;
		else if (vars{i})="C" then C_cnt + 1;
		else if (vars{i})="D" then D_cnt + 1;
	end;
	keep A_cnt B_cnt C_cnt D_cnt;
run;
* numer wiersza odpowiada numerowi pytania;

* d);
data _null_;
	set lab4.l04z01 end=eof;
	retain cnt 0;
	array vars{*} pytanie_1-pytanie_41;
	miss_cnt = 0;
	do i = 1 to dim(vars);
		if missing(vars{i}) then miss_cnt + 1;
		if miss_cnt > 1 then 
		do;
			cnt + 1;
			leave;
		end;
	end;
	if eof then put "Na więcej niż jedno pytanie nie odpowiedziało " cnt " respondentów.";
run;

	
/*zadanie 2****************************************************************;*/

* ze zwracaniem;

data _null_; 
  set lab4.l04z02;
  array vars{*} z1-z32;
  do i = 1 to m;
  	idx = rand("Integer", l, u);
  	elem = vars(idx);
    put elem;
  end;
run;

* bez zwracania;

data _null_; 
  set lab4.l04z02;
  array vars{*} z1-z32;
  array tmp{27}; *max(m) = 27;
  
  i = 1;
  do while (i <= m);
  	rnd = rand("Integer", l, u);
  	if not (rnd in tmp) then 
  	do; 
  		tmp(i)=rnd;
  		i = i+1;
  		put vars(rnd);
  	end;
  end;
  call stdize('replace','mult=',0,of tmp(*),_N_);
run;


/*zadanie 3****************************************************************;*/
proc iml;
start PascalTriangle(n);
   * matrix with all zeros;
   matrix = j(n,n,0);  
   
   * fill nonzero elements;
   do k = 1 to n;
	   /* compute subsequent numbers
	   of combinations of k-1 elements
	   taken 0:k-1 at a time*/
      matrix[k,1:k] = comb(k-1, 0:k-1);
   end;
   
   return(matrix);
finish;
 
pt_10 = PascalTriangle(11);
print pt_10[F=3. L="Pascal's Triangle" r=("n=0":"n=10")];

/*zadanie 4****************************************************************;*/
data L04Z04;
    array z_(1600);
    do i=1 to dim(z_);
        z_(i) = rand('uniform', -1, 1);
    end;
    output;
    drop i;
run;

data L04Z04_kwadrat;
	set L04Z04;
	array vars{1600} z_1-z_1600;
	array col_{40};
	do r=1 to 40;
		do c=1 to 40;
			col_(c) = vars(40*(r-1)+c);
		end;
		output;
		keep col_1-col_40;
	end;
run;
	

data out_z04;
	retain cnt 0;
	set L04Z04_kwadrat;
	array tmp {*} col_1-col_40;
	if cnt < 72 then do;
		do i = 1 to dim(tmp);
			if rand("Bern", 0.055) then do;
				tmp(i)=.;
				cnt = cnt+1;
				if cnt = 72 then leave;
			end;
		end;
	end;
	drop cnt i;
run;

proc print;
run;

data _null_;
	retain missnum 0;
	set out_z04 end=eof;
	missnum + nmiss(of col_1--col_40);
	if eof then put "Number of missings: " missnum;
run;

/*zadanie 5****************************************************************;*/

data L04Z05_ord;
	set lab4.l04z02;
	array vars{*} z1-z32;
	call sortn (of vars(*));
	output;
run;

proc contents data=lab4.l04z02;
run;

/*zadanie 6****************************************************************;*/

data out_z06;
   set lab4.l04z06;
      
   *dekodowanie liczby;
   array chars{2} $;
   do i = 1 to dim(chars);
      chars(i) = scan(kod, i,',','M');
   end;
   call sortn (of chars(*));

   P_code = compress(chars(1),"","kd");
   W_code = compress(chars(2),"","kd");
   
   tmp = tranwrd(liczba, "P", trim(P_code));
   decode = tranwrd(tmp, "W", trim(W_code));
   liczba_num = input(decode, best16.);
   
   * zmiana formatu daty;
   month = scan(data,1,'.');
   year = scan(data,2,'.');
   day = scan(data,3,'.');
   data_sas =  mdy(month, day, year);
   format data_sas date9.;
   
   keep data liczba kod data_sas liczba_num;
run;

proc contents data=out_z06;
run;


/*zadanie 7****************************************************************;*/

data _null_;
	retain val 0;
	set lab4.l04z07;
	array vars{*} b0-b10;
	do i=1 to dim(vars);
		val + vars(i) * 2**(i-1);
	end;
	put val;
	val = 0;
run;

/*zadanie 8****************************************************************;*/
/* rozciągnięcie zbioru */
data in_z08;
	set lab4.l04z08;
	array grps{*} a1-a5;
	array vars{*} x1-x5;
	do i=1 to 5;
		gr = grps[i];
		var = trim(vname(vars[i]));
		val = vars[i];
		output; 
	end;
	keep gr var val;
run;

/* sortowanie do grupowania */
proc sort data=in_z08 out=sort_z08;
	by gr var;
run;

/* średnie wzgledem 2 grup, struktura wynikowa zachowana z dokładnością do kolejności */
data out_z08;

	array avgx{5} avgx_1-avgx_5;
	retain avgx_1-avgx_5 0;
	retain sum n 0;
	retain i 1;
	
	set sort_z08;
	by gr var;
	if not last.gr and not last.var then
	do;
		sum = sum + val;
		n = n+1;
	end;
	else if not last.gr and last.var then
	do;
		sum = sum + val;
		n = n+1;
		avgx(i) = sum/n;
		sum = 0;
		n = 0;
		i = i+1;
	end;
	else 
	do;
		sum = sum + val;
		n = n+1;
		avgx(i) = sum/n;
		sum = 0;
		n = 0;
		i = 1;
		output;
	end;
	keep gr avgx_1-avgx_5;
run;

data out_z08;
	set out_z08;
	format avgx_1 avgx_2 avgx_3 avgx_4 avgx_5 6.1;
run;


/*zadanie 9****************************************************************;*/
data out_z09;
	set lab4.l04z02;
	array row{*} z1-z32;
	avg = (row(l) + row(m) + row(u))/3;
	format avg commax6.;
	keep avg;
run;


/*zadanie 10****************************************************************;*/

data out_z10;
	set lab4.l04z10;
	array arr{*} r1-r5;
	do i=1 to dim(arr);
		if missing(arr(i)) then
		do;
			row = _n_;
			col = i;
			output;
		end;
	end;
	keep row col;
run;
	


/*zadanie 11***************************************************************;*/

* a);
data _null_;
	*liczniki dla całej serwerowni;
	retain all_v all_x all_o 0; 
	*liczniki dla poszczególnuch serwerów;
	v_serv = 0;
	x_serv = 0;
	o_serv = 0;
	set lab4.l04z11 end=eof;
	array switches{31} switch1-switch31;	
	do i=1 to dim(switches);
		v_serv + lengthn(compress(switches{i},'v','k'));
		x_serv + lengthn(compress(switches{i},'x','k'));
		o_serv + lengthn(compress(switches{i},'o','k'));
	end;
	all_v + v_serv;
	all_x + x_serv;
	all_o + o_serv;
	if eof then put "Liczby sprawnych, nieczynnych oraz nieużywanych portów
	w całej serwerowni wynoszą odpowiednio: " all_v all_x all_o;
run;

* b);
data out_z11b;
	set lab4.l04z11;
	array switches{31} switch1-switch31;
	v_cnt = 0;
	x_cnt = 0;
	o_cnt = 0;
	do i = 1 to 31;
		v_cnt + lengthn(compress(switches{i},'v','k'));
		x_cnt + lengthn(compress(switches{i},'x','k'));
		o_cnt + lengthn(compress(switches{i},'o','k'));
	end;
	output;
	keep server_name v_cnt x_cnt o_cnt;
run;

* c);
data _null_;
	set out_z11b end=eof;
	retain argmin argmax;
	retain v_min v_max 0;
	if _n_ = 1 then	
		do;
			v_min = v_cnt;
			argmin = server_name;
			v_max = v_cnt;
			argmax = server_name;
		end;
	if v_cnt < v_min then 
		do;
			argmin = server_name;
			v_min = v_vnt;
		end;
	if v_cnt > v_max then
		do;
			argmax = server_name;
			v_max = v_cnt;
		end;
	if eof then put "Serwerami o największej i najmniejszej sprawności są odpowiednio: " argmax argmin;
run;


* d);
data _null_;
	set lab4.l04z11 end=eof;
	array switches{31} switch1-switch31;
	array vars{31} v1-v31;
	
	do i = 1 to 31;
		vars(i) + lengthn(compress(switches(i),'v','k'));
	end;
	
	if eof then 
	do;
		do i = 1 to 31;
			if i = 1 then
				do;
					v_min = vars(i);
					argmin = i;
					v_max = vars(i);
					argmax = i;
					
				end;
			if vars(i) > v_max then 
				do;
					v_max = vars(i);
					argmax = i;
				end;
			if vars(i) < v_min then 
				do;
					v_min = vars(i);
					argmin = i;
				end;
		end;
		put "Najrzadziej i najczęściej używanymi typami przełączników są odpowienio switch" argmin
		"i switch" argmax;
	end;
run;


/*KONIEC*******************************************************************;*/
