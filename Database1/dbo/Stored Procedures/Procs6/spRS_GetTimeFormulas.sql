CREATE PROCEDURE dbo.spRS_GetTimeFormulas
AS
Create Table #t(TimeRange varchar(10), Formula varchar(25))
Insert Into #t(TimeRange, Formula) Values('StartTime', 'Yesterday + 7 Hours')
Insert Into #t(TimeRange, Formula) Values('StartTime', 'Now - 4 Hours')
Insert Into #t(TimeRange, Formula) Values('StartTime', 'Now - 8 Hours')
Insert Into #t(TimeRange, Formula) Values('StartTime', 'Now - 12 Hours')
Insert Into #t(TimeRange, Formula) Values('StartTime', 'Now - 1 Day')
Insert Into #t(TimeRange, Formula) Values('StartTime', 'Now - 2 Days')
Insert Into #t(TimeRange, Formula) Values('StartTime', 'Now - 30 Days')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Now')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Today + 7 Hours')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Yesterday + 7 Hours')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Now - 4 Hours')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Now - 8 Hours')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Now - 12 Hours')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Now - 1 Day')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Now - 2 Days')
Insert Into #t(TimeRange, Formula) Values('EndTime', 'Now - 30 Days')
Select * from #t
Drop Table #t
