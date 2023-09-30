create procedure [dbo].[spASP_appEventAnalysisEvents]
  @UnitId Int = Null,
  @Variables VarChar(8000) = null
AS
create table #VarTable(Id_Order int, Var_Id int)
-- Put the variable Id's into a temp table
If @Variables Is Not Null
  Insert Into #VarTable Exec spRS_MakeOrderedResultSet @Variables
Create Table #EventTypes
(
  [Id] Int,
  [SubId] Int,
  [Description] nVarChar(1000)
)
Insert Into #EventTypes
Select distinct
  [Id] = ec.et_id, SubId = es.event_subtype_id, [Description] = coalesce(es.event_subtype_desc, et.et_desc)  
  From Event_Configuration ec
  Join Event_Types et on et.et_id = ec.et_id
  Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
  Where ec.et_id in (2,3,14) 
  And (PU_Id = @UnitId Or @UnitId Is Null)
--Alarms
Insert Into #EventTypes
Select [Id] = 11, SubId = Null, [Description] = ET_Desc
From Event_Types et
Where et.et_id = 11
--Non-Productive Time
Insert Into #EventTypes
Select [Id] = -2, SubId = Null, [Description] = 'Non-Productive Time'
Select *
From #EventTypes
Order By [Description]
