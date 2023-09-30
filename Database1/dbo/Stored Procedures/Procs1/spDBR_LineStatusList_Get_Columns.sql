CREATE Procedure dbo.spDBR_LineStatusList_Get_Columns
@userid int = 0
AS
SET ANSI_WARNINGS off
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
insert into #Columns (ColumnName, Prompt) values('ResourceName',dbo.fnDBTranslate(N'0', 38295, 'Resource'))
insert into #Columns (ColumnName, Prompt) values('ProductionAmount',dbo.fnDBTranslate(N'0', 38273,'Production'))
insert into #Columns (ColumnName, Prompt) values('ProductionItems',dbo.fnDBTranslate(N'0', 38294,'Amount'))
insert into #Columns (ColumnName, Prompt) values('PercentOEE',dbo.fnDBTranslate(N'0', 38277,'% OEE'))
insert into #Columns (ColumnName, Prompt) values('PercentRate',dbo.fnDBTranslate(N'0', 38275,'% Rate'))
insert into #Columns (ColumnName, Prompt) values('RunTime',dbo.fnDBTranslate(N'0', 38296, 'Run / Sched'))
insert into #Columns (ColumnName, Prompt) values('PercentDowntime',dbo.fnDBTranslate(N'0', 38282,'% Downtime'))
insert into #Columns (ColumnName, Prompt) values('PercentWaste', dbo.fnDBTranslate(N'0', 38279,'% Waste'))
insert into #Columns (ColumnName, Prompt) values('CurrentProcessOrder',dbo.fnDBTranslate(N'0', 38297,'Current Order'))
insert into #Columns (ColumnName, Prompt) values('ScheduledDeviation',dbo.fnDBTranslate(N'0', 38298,'Sched Dev'))
insert into #Columns (ColumnName, Prompt) values('NextProcessOrder',dbo.fnDBTranslate(N'0', 38299,'Next Order'))
insert into #Columns (ColumnName, Prompt) values('NextEstimatedStart',dbo.fnDBTranslate(N'0', 38300,'Est Start'))
select * from #Columns
drop table #Columns
