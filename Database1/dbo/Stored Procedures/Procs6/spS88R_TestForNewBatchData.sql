CREATE procedure [dbo].[spS88R_TestForNewBatchData]
AS
Select Count(*)
  from User_Defined_Events PhaseEvents
  Join Prod_Units BatchUnits ON BatchUnits.Extended_Info = 'Batch:'
  Join Events BatchEvents ON BatchEvents.PU_Id = BatchUnits.PU_Id
  Join Event_Components EC ON EC.Source_Event_Id = BatchEvents.Event_Id
  Join Events UnitProcedureEvents ON UnitProcedureEvents.Event_Id = EC.Event_Id
  Join User_Defined_Events OperationEvents ON OperationEvents.Event_Id = UnitProcedureEvents.Event_Id and OperationEvents.UDE_Id = PhaseEvents.Parent_UDE_ID
