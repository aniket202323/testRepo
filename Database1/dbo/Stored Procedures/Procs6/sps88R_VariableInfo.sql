CREATE PROCEDURE [dbo].[sps88R_VariableInfo]
  @VariableId INT
AS
Select Distinct v.Var_Id, v.Var_Desc
From Events BatchEvent
Join Prod_Units BatchUnit ON BatchUnit.PU_Id = BatchEvent.PU_Id
Join Event_Components EC ON EC.Source_Event_Id = BatchEvent.Event_Id
Join Events UnitProcedureEvent ON UnitProcedureEvent.Event_Id = EC.Event_Id
Join User_Defined_Events OperationEvent ON OperationEvent.Event_Id = UnitProcedureEvent.Event_Id
Join User_Defined_Events PhaseEvent ON PhaseEvent.Parent_UDE_Id = OperationEvent.UDE_Id
Join Variables v ON 	 v.PU_Id = PhaseEvent.PU_Id
 	 AND 	 v.Event_Type = 14
 	 AND 	 v.Event_SubType_Id = PhaseEvent.Event_SubType_Id
Where Var_Id = @VariableId
 	 
