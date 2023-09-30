create procedure [dbo].[spS88R_CurrentUnitBatch]
--Declare
@Unit INT
AS
Declare @Timestamp datetime
Declare @Event_Id INT
/*******
-- Testing
spS88R_CurrentUnitBatch 35
--*******
Select @Unit = 52
--*******/
Declare @UnitName nVarChar(100)
Declare @UnitProcedureName nVarChar(100)
Declare @UnitProcedureId int
Declare @OperationName nVarChar(100)
Declare @OperationId int
Declare @PhaseName nVarChar(100)
Declare @PhaseId int
Select @UnitName = PU_Desc From Prod_Units Where PU_Id = @Unit
Select @Timestamp = max(timestamp)
from events
where pu_id = @Unit
SELECT @Event_id = Event_Id
From events
where pu_id = @Unit and timestamp = @Timestamp
Select @Timestamp = max(e.timestamp)
from Events E
 	 Join Event_Components EC ON EC.Event_Id = E.Event_Id
where EC.Source_Event_Id = @Event_Id
Select @UnitProcedureName = PU.PU_Desc, @UnitProcedureId = E.Event_Id
 	 From Events E
 	  	 Join Prod_Units PU on PU.Pu_Id = E.PU_Id
 	  	 Join Event_Components EC ON EC.Event_Id = E.Event_Id
 	 Where EC.Source_Event_Id = @Event_Id And E.TimeStamp = @TimeStamp
Select Top 1 @OperationName = UDE.UDE_Desc, @OperationId = UDE.UDE_Id
 	 From User_Defined_Events UDE
 	 Where UDE.Event_Id = @UnitProcedureId
 	 Order By End_Time Desc
Select Top 1 @PhaseName = UDE_Desc, @PhaseId = UDE_Id
 	 From User_Defined_Events
 	 Where Parent_UDE_Id = @OperationId
 	 Order By End_Time Desc
SELECT EventId = @Event_Id, UnitProcedureName = @UnitProcedureName, OperationName = @OperationName, PhaseName = @PhaseName
RETURN @Event_Id
