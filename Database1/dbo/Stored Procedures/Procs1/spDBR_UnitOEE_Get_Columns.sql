CREATE Procedure dbo.spDBR_UnitOEE_Get_Columns
@UserID int = 0 
AS
SET ANSI_WARNINGS off
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
/*TODO:
--Probably just want to add new prompts for these!
Update Prompt #38273 in database (from Production to Net Production)
Update Prompt #38274 in database (from Speed to Actual Speed)
Add Prompt for Ideal Speed, Performance Rate %, Quality Rate %, Loading Time, Available Rate %, 
update OEE % in prompts
*/
insert into #Columns (ColumnName, Prompt) values('UnitName',dbo.fnDBTranslate(N'0', 38129, 'Unit') )
insert into #Columns (ColumnName, Prompt) values('ProductionAmount',dbo.fnDBTranslate(N'0', 38466,'Net Production'))
insert into #Columns (ColumnName, Prompt) values('ActualSpeed',dbo.fnDBTranslate(N'0', 38467,'Actual Speed'))
insert into #Columns (ColumnName, Prompt) values('IdealProductionAmount',dbo.fnDBTranslate(N'0', 36334,'Ideal Production'))
insert into #Columns (ColumnName, Prompt) values('PerformanceRate',dbo.fnDBTranslate(N'0', 38469,'Performance Rate %'))
insert into #Columns (ColumnName, Prompt) values('WasteAmount',dbo.fnDBTranslate(N'0', 38278,'Waste'))
insert into #Columns (ColumnName, Prompt) values('QualityRate',dbo.fnDBTranslate(N'0', 38470,'Quality Rate %'))
insert into #Columns (ColumnName, Prompt) values('PerformanceTime',dbo.fnDBTranslate(N'0', 36335,'Performance Time'))
insert into #Columns (ColumnName, Prompt) values('RunTime',dbo.fnDBTranslate(N'0', 38280,'Run Time'))
insert into #Columns (ColumnName, Prompt) values('LoadingTime',dbo.fnDBTranslate(N'0', 38471,'Loading Time'))
insert into #Columns (ColumnName, Prompt) values('AvailableRate',dbo.fnDBTranslate(N'0', 38472,'Available Rate %'))
insert into #Columns (ColumnName, Prompt) values('PercentOEE',dbo.fnDBTranslate(N'0', 38277,'OEE %'))
insert into #Columns (ColumnName, Prompt) values('HighAlarmCount',dbo.fnDBTranslate(N'0', 38284,'Alarms'))
insert into #Columns (ColumnName, Prompt) values('IdealSpeed',dbo.fnDBTranslate(N'0', 38468,'Ideal Speed'))
select * from #Columns
drop table #Columns
