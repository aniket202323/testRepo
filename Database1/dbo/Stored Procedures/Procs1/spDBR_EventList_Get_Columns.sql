CREATE Procedure dbo.spDBR_EventList_Get_Columns
@UserID int = 0
AS
SET ANSI_WARNINGS off
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
insert into #Columns (ColumnName, Prompt) values('EventNumber',dbo.fnDBTranslate(N'0', 38272,'Event'))
insert into #Columns (ColumnName, Prompt) values('UnitName',dbo.fnDBTranslate(N'0', 38129, 'Unit'))
insert into #Columns (ColumnName, Prompt) values('LocationName',dbo.fnDBTranslate(N'0', 38301,'Location'))
insert into #Columns (ColumnName, Prompt) values('StartTime',dbo.fnDBTranslate(N'0', 38302,'Start'))
insert into #Columns (ColumnName, Prompt) values('EndTime',dbo.fnDBTranslate(N'0', 38303,'End'))
insert into #Columns (ColumnName, Prompt) values('Age',dbo.fnDBTranslate(N'0', 38304,'Age'))
insert into #Columns (ColumnName, Prompt) values('Product',dbo.fnDBTranslate(N'0', 38204,'Product'))
insert into #Columns (ColumnName, Prompt) values('Status',dbo.fnDBTranslate(N'0', 38305,'Status'))
insert into #Columns (ColumnName, Prompt) values('TimeInStatus',dbo.fnDBTranslate(N'0', 38289,'Time'))
insert into #Columns (ColumnName, Prompt) values('DimensionX',dbo.fnDBTranslate(N'0', 38306,'DimensionX'))
insert into #Columns (ColumnName, Prompt) values('DimensionY',dbo.fnDBTranslate(N'0', 38307,'DimensionY'))
insert into #Columns (ColumnName, Prompt) values('DimensionZ',dbo.fnDBTranslate(N'0', 38308,'DimensionZ'))
insert into #Columns (ColumnName, Prompt) values('DimensionA',dbo.fnDBTranslate(N'0', 38309,'DimensionA'))
insert into #Columns (ColumnName, Prompt) values('PercentTested',dbo.fnDBTranslate(N'0', 38310,'% Tested'))
insert into #Columns (ColumnName, Prompt) values('PercentConformance',dbo.fnDBTranslate(N'0', 38276,'% Conf'))
insert into #Columns (ColumnName, Prompt) values('Signoff1',dbo.fnDBTranslate(N'0', 38492,'User'))
insert into #Columns (ColumnName, Prompt) values('Signoff2',dbo.fnDBTranslate(N'0', 38493,'Approver'))
insert into #Columns (ColumnName, Prompt) values('HighAlarmCount',dbo.fnDBTranslate(N'0', 38312,'Alarms'))
select * from #Columns
drop table #Columns
