CREATE Procedure dbo.spDBR_ProductProduction_Get_Columns
@UserID int = 0
AS
SET ANSI_WARNINGS off
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
insert into #Columns (ColumnName, Prompt) values('ProductCode',dbo.fnDBTranslate(N'0', 38204,'Product'))
insert into #Columns (ColumnName, Prompt) values('ProductionItems',dbo.fnDBTranslate(N'0', 38293,'#Items'))
insert into #Columns (ColumnName, Prompt) values('ProductionAmount',dbo.fnDBTranslate(N'0', 38294,'Amount'))
insert into #Columns (ColumnName, Prompt) values('ConformancePercent',dbo.fnDBTranslate(N'0', 38276,'% Conf'))
insert into #Columns (ColumnName, Prompt) values('RatePercent',dbo.fnDBTranslate(N'0', 38275,'% Rate'))
insert into #Columns (ColumnName, Prompt) values('RunTime',dbo.fnDBTranslate(N'0', 38280,'Run Time'))
insert into #Columns (ColumnName, Prompt) values('DowntimePercent',dbo.fnDBTranslate(N'0', 38282,'% Downtime'))
insert into #Columns (ColumnName, Prompt) values('WastePercent',dbo.fnDBTranslate(N'0', 38279,'% Waste'))
select * from #Columns
drop table #Columns
