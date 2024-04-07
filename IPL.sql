select * from dbo.ipl_matches_2008_2022
  
select * from dbo.ipl_ball_by_ball_2008_2022



-- Winning team each season
select season, winning_team
from dbo.ipl_matches_2008_2022
where match_number = 'final'



-- Orange Cap
with ranked_runs as
(
	select 
		T2.season, 
		T1.batter, 
		sum(batsman_run) as Total_Runs_in_season,
		ROW_NUMBER() over(partition by season order by sum(batsman_run) desc) as run_rank
	from dbo.ipl_ball_by_ball_2008_2022 T1
	join dbo.ipl_matches_2008_2022 T2
	on T1.id = T2.id
	group by season, batter
)
select season, batter, Total_Runs_in_season as Orange_Cap
from ranked_runs
where run_rank = 1




-- Purple Cap
with Best_Bowler as 
(
	select 
		T2.season, 
		bowler, 
		sum(iswicket_delivery) as Number_of_kills,
		ROW_NUMBER() over(partition by season order by sum(iswicket_delivery) desc) as rank
	from dbo.ipl_ball_by_ball_2008_2022 T1
	join dbo.ipl_matches_2008_2022 T2
	on T1.id = T2.id
	and dismisal_kind in ('caught', 'caught and bowled', 'bowled', 'hit wicket', 'lbw', 'stumped')
	group by bowler, T2.season
)
select season, bowler, Number_of_kills
from Best_Bowler
where rank = 1




-- Tournament 6's
with Tournament_6s as (
	select 
		season, 
		count(batsman_run) as Total_Run_6
	from dbo.ipl_ball_by_ball_2008_2022 T1
	join dbo.ipl_matches_2008_2022 T2
	on T1.id = T2.id
	where batsman_run = 6 and non_boundary = 0
	group by season
) 
select sum(Total_Run_6)
from Tournament_6s




-- Tournament 4's
with Tournament_4s as (
	select 
		season, 
		count(batsman_run) as Total_4_Runs
	from dbo.ipl_ball_by_ball_2008_2022 T1
	join dbo.ipl_matches_2008_2022 T2
	on T1.id = T2.id
	where batsman_run = 4 and non_boundary = 0
	group by season
)
select sum(Total_4_Runs) as Total
from Tournament_4s




-- IPL BATTING STATS
select 
	season, 
	batter, 
	count(ball_number) as Numbers_Of_Ball,
	sum(batsman_run) as Total_Run, 
	sum(case when batsman_run = 4 and non_boundary = 0 then 1 else 0 end) as Tournament_4s,
	sum(case when batsman_run = 6 and non_boundary = 0 then 1 else 0 end) as Tournament_6s,
	convert(float, sum(batsman_run)) / count(ball_number) as Strike_Rate
from dbo.ipl_ball_by_ball_2008_2022 T1
join dbo.ipl_matches_2008_2022 T2
on T1.id = T2.id
group by season, batter
order by 1




-- IPL BOWLING STATS
-- Wickets
create view Wickets as (
select 
	season, 
	bowler,
	sum(iswicket_delivery) as Total_Wickets
from dbo.ipl_matches_2008_2022 T1
join dbo.ipl_ball_by_ball_2008_2022 T2
on T1.id = T2.id
where dismisal_kind in ('caught', 'caught and bowled', 'bowled', 'hit wicket', 'lbw', 'stumped')
group by season, bowler
)
	


-- Economy Rate for bowlers
with Economy_Rate_for_Bowlers as (
	select 
		season,
		bowler,
		count(distinct overs) as Overs_Bowled,
		sum(batsman_run) as Run_Conceded
	from dbo.ipl_ball_by_ball_2008_2022 T1
	join dbo.ipl_matches_2008_2022 T2
	on T1.id = T2.id
	group by season, bowler
)
select *, cast(Run_Conceded as float) / nullif(Overs_Bowled, 0) as Economy_Rate
from Economy_Rate_for_Bowlers
order by season


	
-- Average Bowlers
create view Runs as (
select 
	season, 
	bowler,
	sum(batsman_run) as Total_Runs
from dbo.ipl_matches_2008_2022 T1
join dbo.ipl_ball_by_ball_2008_2022 T2
on T1.id = T2.id
group by season, bowler
)
select W.season, W.bowler, Total_Wickets, Total_Runs, cast(Total_Runs as float) / nullif(Total_Wickets, 0) as AVG_Bowler
from Wickets W
join Runs R
on W.season = R.season and W.bowler = R.bowler
order by 1


	
-- Strike Rate of Bowlers
create view Num_of_Balls as (
	select 
		season, 
		bowler, 
		count(ball_number) as Ball_Bowled
	from dbo.ipl_ball_by_ball_2008_2022 T1
	join dbo.ipl_matches_2008_2022 T2
	on T1.id = T2.id
	group by season, bowler
)
select W.season, W.bowler, Ball_Bowled, Total_Wickets, cast(Ball_Bowled as float) / nullif(Total_Wickets, 0) as Bowler_RS
from Wickets W
join Num_of_Balls NB
on W.season = NB.season and W.bowler = NB.bowler
order by 1




-- Winning Percentage based on toss decision
with winning_team_based_on_toss_decison as (
	select 
		season, 
		toss_winner, 
		winning_team, 
		count(toss_decision) as Toss_Decision,
		sum(case when toss_decision = 'field' then 1 else 0 end) as Field,
		sum(case when toss_decision = 'bat' then 1 else 0 end) as Bat
	from dbo.ipl_matches_2008_2022
	where winning_team = toss_winner
	group by season, winning_team, toss_winner
)
select *, cast(Field as float) / Toss_Decision * 100 as PCT_Field, cast(Bat as float) / Toss_Decision * 100 as PCT_Bat
from winning_team_based_on_toss_decison
order by 1



-- Matches Win by Result Type
drop view if exists matches_win_by_result_type

create view matches_win_by_result_type as (
	select
		season,
		winning_team,
		count(won_by) as Number_of_Matches_Win_by_ResType,
		sum(case when won_by = 'Runs' then 1 else 0 end) as Win_by_Runs,
		sum(case when won_by = 'Wickets' then 1 else 0 end) as Win_by_Wickets,
		sum(case when won_by = 'SuperOvers' then 1 else 0 end) as Win_by_SuperOvers,
		sum(case when won_by = 'NoResults' then 1 else 0 end) as Win_by_NoResults
	from dbo.ipl_matches_2008_2022
	group by season, winning_team
)
select 
	season,
	sum(Win_by_Runs) / convert(float, sum(Number_of_Matches_Win_by_ResType)) * 100 as Win_PCT_by_Runs,
	sum(Win_by_Wickets) / convert(float, sum(Number_of_Matches_Win_by_ResType)) * 100 as Win_PCT_by_Wickets,
	sum(Win_by_SuperOvers) / convert(float, sum(Number_of_Matches_Win_by_ResType)) * 100 as Win_PCT_by_SuperOvers,
	sum(Win_by_NoResults) / convert(float, sum(Number_of_Matches_Win_by_ResType)) * 100 as Win_PCT_by_NoResults
from matches_win_by_result_type
group by season
order by 1



-- Matches Win by Venue
select 
	season,
	venue,
	count(won_by) as Num_of_Matches_Win_by_Venues,
	sum(case when won_by = 'Runs' then 1 else 0 end) as Runs_ResultType,
	sum(case when won_by = 'Wickets' then 1 else 0 end) as Wickets_ResultType,
	sum(case when won_by = 'SuperOvers' then 1 else 0 end) as SuperOvers_ResultType,
	sum(case when won_by = 'NoResults' then 1 else 0 end) as NoResults_ResultType
from dbo.ipl_matches_2008_2022
group by season, venue
order by 1 asc, 3 desc



-- Matches Win by Season
select 
	season,
	sum(Number_of_Matches_Win_by_ResType) as Total_Matches_Win_for_Season,
	sum(Win_by_Runs) as Total_Matches_Win_by_Runs,
	sum(Win_by_Wickets) as Total_Matches_Win_by_Wicket,
	sum(Win_by_SuperOvers) as Total_Matches_Win_by_SuperOvers,
	sum(Win_by_NoResults) as Total_Matches_Win_by_NoResults
from dbo.matches_win_by_result_type
group by season
