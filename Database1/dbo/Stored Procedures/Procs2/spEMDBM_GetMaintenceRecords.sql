CREATE PROCEDURE dbo.spEMDBM_GetMaintenceRecords 
  AS
Create Table #GroupTimes(GroupId int,MyRowcount Int,EstTime Int)
Declare @MyRowCount Int,@MyTime Int
Select @MyRowCount =  i.rows from sysindexes i where i.indid < 2 	 and i.id = object_Id('Time_Event_Details')
Select @MyTime = @MyRowCount * 5.0E-6
Insert Into #GroupTimes(GroupId,MyRowcount,EstTime) Values (1,@MyRowCount,@MyTime)
Select @MyRowCount =  i.rows from sysindexes i where i.indid < 2 	 and i.id = object_Id('Test_History')
Select @MyTime = @MyRowCount * 5.0E-6
Insert Into #GroupTimes(GroupId,MyRowcount,EstTime) Values (2,@MyRowCount,@MyTime)
Select @MyRowCount =  i.rows from sysindexes i where i.indid < 2 	 and i.id = object_Id('Crew_Schedule')
Select @MyTime = @MyRowCount * 5.0E-6
Insert Into #GroupTimes(GroupId,MyRowcount,EstTime) Values (3,@MyRowCount,@MyTime)
Select @MyRowCount =  i.rows from sysindexes i where i.indid < 2 	 and i.id = object_Id('Var_Specs')
Select @MyTime = @MyRowCount * 4.49E-6
Insert Into #GroupTimes(GroupId,MyRowcount,EstTime) Values (4,@MyRowCount,@MyTime)
Select @MyRowCount =  i.rows from sysindexes i where i.indid < 2 	 and i.id = object_Id('user_defined_events')
Select @MyTime = @MyRowCount * 5.00E-6
Insert Into #GroupTimes(GroupId,MyRowcount,EstTime) Values (5,@MyRowCount,@MyTime)
Select @MyRowCount =  i.rows from sysindexes i where i.indid < 2 	 and i.id = object_Id('Waste_Event_Details')
Select @MyTime = @MyRowCount * 5.78E-6
Insert Into #GroupTimes(GroupId,MyRowcount,EstTime) Values (6,@MyRowCount,@MyTime)
Select @MyRowCount =  i.rows from sysindexes i where i.indid < 2 	 and i.id = object_Id('Events')
Select @MyTime = @MyRowCount * 3.67E-6
Insert Into #GroupTimes(GroupId,MyRowcount,EstTime) Values (7,@MyRowCount,@MyTime)
Select @MyRowCount =  i.rows from sysindexes i where i.indid < 2 	 and i.id = object_Id('Tests')
Select @MyTime = @MyRowCount * 2.39E-6
Insert Into #GroupTimes(GroupId,MyRowcount,EstTime) Values (8,@MyRowCount,@MyTime)
select DBMC_Id,a.DBMC_Group,DBMC_Group_Order,DBMC_Desc,DBMC_Group_Desc,
 	 DBMC_Group_Desc_Long = '[' + Convert(nVarChar(10),isnull(MyRowcount,0)) + '] Rows' + ' - ' +  	 'Approximately [' + Convert(nVarChar(10),isnull(EstTime,0)) + '] Minutes to apply' + Char(10) + DBMC_Group_Desc_Long
from DB_Maintenance_Commands a
Join DB_Maintenance_Command_Groups b on a.DBMC_Group = b.DBMC_Group
Join #GroupTimes g On a.DBMC_Group = g.GroupId
Where a.Executed_On is null
 Order by a.DBMC_Group,DBMC_Group_Order
Drop Table #GroupTimes
