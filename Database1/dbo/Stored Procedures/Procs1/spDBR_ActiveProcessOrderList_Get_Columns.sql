CREATE Procedure dbo.spDBR_ActiveProcessOrderList_Get_Columns
@uid int = 0
AS
SET ANSI_WARNINGS off
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
insert into #Columns (ColumnName, Prompt) values('ResourceName',dbo.fnDBTranslate(N'0', 38295, 'Resource'))
insert into #Columns (ColumnName, Prompt) values('CurrentProcessOrder',dbo.fnDBTranslate(N'0', 38297,'Current Order'))
insert into #Columns (ColumnName, Prompt) values('PlannedAmount',dbo.fnDBTranslate(N'0', 38313, 'Planned'))
insert into #Columns (ColumnName, Prompt) values('ActualAmount',dbo.fnDBTranslate(N'0', 38314, 'Remaining'))
insert into #Columns (ColumnName, Prompt) values('PlannedItems',dbo.fnDBTranslate(N'0', 38315,'Planned Items'))
insert into #Columns (ColumnName, Prompt) values('ActualItems',dbo.fnDBTranslate(N'0', 38316,'Remaining Items'))
/*insert into #Columns (ColumnName, Prompt) values('PercentRate',dbo.fnDBTranslate(N'0', 38275,'% Rate'))
*/
insert into #Columns (ColumnName, Prompt) values('RunTime',dbo.fnDBTranslate(N'0', 38280,'Run Time'))
insert into #Columns (ColumnName, Prompt) values('ScheduledDeviation',dbo.fnDBTranslate(N'0', 38298,'Sched Dev'))
insert into #Columns (ColumnName, Prompt) values('UnitList',dbo.fnDBTranslate(N'0', 38317,'Units'))
insert into #Columns (ColumnName, Prompt) values('NextProcessOrder',dbo.fnDBTranslate(N'0', 38299,'Next Order'))
insert into #Columns (ColumnName, Prompt) values('NextEstimatedStart',dbo.fnDBTranslate(N'0', 38300,'Est Start'))
insert into #Columns (ColumnName, Prompt) values('NextDuration',dbo.fnDBTranslate(N'0', 38318, 'Next Duration'))
select * from #Columns
drop table #Columns
