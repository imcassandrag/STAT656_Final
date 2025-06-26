/* Final: By Cassandra Gayer and Sarang Solhdoost
06/24/2024
Edited: 06/27/2024
Data needed: 
*/

/* start rtf file */
ods rtf startpage = never file = '/home/u63892903/Assignments/FinalSAS.rtf';

/* SF Annual Park Score dataset */
proc import datafile="/home/u63892903/Imported/annual_park_scores_2023.csv" 
    out=park_scores 
    dbms=csv 
    replace;
    getnames=yes;
run;

data park_scores;
set park_scores;
rename
	'Analysis Neighborhood'n = park_neighborhood;
run;

/* SF Police Department dataset, and renaming necessary variables.*/
proc import datafile="/home/u63892903/Imported/police_department_incidents_2023.csv" 
    out=police_reports 
    dbms=csv 
    replace;
    getnames=yes;
run;

data police_reports;
set police_reports;
rename
	'Incident Time'n = crime_time
	'Incident Day of Week'n = day
	'Incident Category'n = crime_type
	'Incident Year'n = crime_year
	'Analysis Neighborhood'n = neighborhood;
run;

/* Combining the datasets */
proc sql;
create table combined as
select 
	ps.park_neighborhood, 
    ps.park_score, 
    pr.neighborhood, 
    pr.crime_type, 
    pr.crime_time, 
    pr.day, 
    pr.crime_year
from park_scores ps
left join police_reports pr 
on ps.park_neighborhood = pr.neighborhood;
quit;

/*------------------------------------------------------------------------------------------------------------------------------*/

/* Analysis for Park Scores */

/* Summary Statistics for park scores*/
title "Average Park Score by Type";
proc means data = park_scores;
class park_type;
var park_score;
run;

/* Identifing parks with top highest and lowest scores */
proc sort data = park_scores;
by descending park_score;
run;

title "Top 10 Parks with Highest Scores";
proc print data = park_scores (obs = 10);
var park park_neighborhood park_type park_score;
run;

proc sort data = park_scores;
by park_score;
run;

title "Top 10 Parks with Lowest Scores";
proc print data = park_scores (obs = 10);
var park park_neighborhood park_type park_score;
run;

/* How do park types affect scores? */
title "Influence of Park Types on Park Scores";
proc glm data = park_scores;
class park_type;
model park_score = park_type / solution;
run;

/* How do neighborhoods affect scores? */
title "Influence of Neighborhoods on Park Scores";
proc glm data = park_scores;
class park_neighborhood;
model park_score = park_neighborhood / solution;
run;


/*------------------------------------------------------------------------------------------------------------------------------*/

/* Analysis for Police Reports dataset */

/* Frequency of crime types */
proc freq data = police_reports order=freq;
table crime_type;
run;

/* filtering crime_type data based on type of crime believed to happen in/around parks (Assult/Mischief) */
data filtered_data_assault;
set police_reports;
where crime_type in ('Assault', 'Malicious Mischief');
run;

/* filtering crime_type data based on type of crime believed to happen in/around parks (Motor/Personal Theft)*/
data filtered_data_theft;
set police_reports;
where crime_type in ('Larceny Theft', 'Motor Vehicle Theft');
run;

title "Assault and Malicious Mischief Frequency by Neighborhood";
proc freq data = filtered_data_assault order=freq;
tables neighborhood;
run;

title "Larceny and Motor Vehicle Theft Frequency by Neighborhood";
proc freq data = filtered_data_theft order=freq;
tables neighborhood;
run;

/* Box Plot */
title "Box Plot: Crime Times by Day of the Week";
proc sgplot data = filtered_data;
vbox crime_time / category = day;
xaxis label="Day of the Week";
yaxis label="Time of Crime";
run;

/* Bar Chart */
title "Bar Chart: Assault and Malicious Mischief by Neighborhood";
proc sgplot data = filtered_data_assault;
hbar neighborhood / group = crime_type groupdisplay = cluster stat = freq;
xaxis label="Neighborhood";
yaxis label="Crime Frequency";
run;

/* Bar Chart */
title "Bar Chart: Larceny and Motor Vehicle Theft by Neighborhood";
proc sgplot data = filtered_data_theft;
hbar neighborhood / group = crime_type groupdisplay = cluster stat = freq;
xaxis label="Neighborhood";
yaxis label="Crime Frequency";
run;

/*------------------------------------------------------------------------------------------------------------------------------*/

/* Linear Regression Model to see correlation between crime rates and park scores */

/* Counting crime data incidents and grouping by neighborhood */
proc sql;
create table crime_count as
select neighborhood, count(*) as crime_count
from combined
group by neighborhood;
quit;

/* Combining counting data with park_score dataset */
proc sql;
create table final as
select 
	ps.park_neighborhood,
	ps.park_score,
    cc.crime_count
from park_scores ps
left join crime_count cc 
on ps.park_neighborhood = cc.neighborhood;
quit;

/* Fit a linear regression model */
title "Linear Regression Model: Are Park Scores Based on Crime Rate?";
proc reg data = final;
model park_score = crime_count;
run;

/* close rtf file */
ods rtf close;
