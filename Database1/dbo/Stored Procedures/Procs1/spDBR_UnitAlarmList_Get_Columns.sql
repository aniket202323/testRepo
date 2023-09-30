CREATE Procedure dbo.spDBR_UnitAlarmList_Get_Columns
@UserID int = 0
AS
SET ANSI_WARNINGS off
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
insert into #Columns (ColumnName, Prompt) values('Origin',dbo.fnDBTranslate(N'0', 38285,'Origin'))
insert into #Columns (ColumnName, Prompt) values('Type',dbo.fnDBTranslate(N'0', 38286,'Type'))
insert into #Columns (ColumnName, Prompt) values('Message',dbo.fnDBTranslate(N'0', 38287,'Message'))
insert into #Columns (ColumnName, Prompt) values('Value',dbo.fnDBTranslate(N'0', 38288,'Value'))
insert into #Columns (ColumnName, Prompt) values('Event',dbo.fnDBTranslate(N'0', 38272,'Event'))
insert into #Columns (ColumnName, Prompt) values('Product',dbo.fnDBTranslate(N'0', 38204,'Product'))
insert into #Columns (ColumnName, Prompt) values('StartTime',dbo.fnDBTranslate(N'0', 38289,'Time'))
insert into #Columns (ColumnName, Prompt) values('Cause',dbo.fnDBTranslate(N'0', 38291,'Cause'))
insert into #Columns (ColumnName, Prompt) values('Action',dbo.fnDBTranslate(N'0', 38292,'Action'))
insert into #Columns (ColumnName, Prompt) values('Signoff1',dbo.fnDBTranslate(N'0', 38492,'User'))
insert into #Columns (ColumnName, Prompt) values('Signoff2',dbo.fnDBTranslate(N'0', 38493,'Approver'))
select * from #Columns
drop table #Columns
