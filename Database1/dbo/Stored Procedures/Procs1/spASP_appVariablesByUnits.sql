CREATE procedure [dbo].[spASP_appVariablesByUnits]
@Units nVarChar(1000) = NULL
AS
Create Table #Units (
  ItemOrder int,
  PU_Id int 
)
If @Units = ''
 	 Select @Units = '0'
If @Units Is Not Null
Begin
 	 Insert Into #Units (PU_Id, ItemOrder)
 	  	 execute ('Select Distinct PU_Id, ItemOrder = CharIndex(convert(nvarchar(10),PU_Id),' + '''' + @Units + ''''+ ',1)
 	  	  	  	  	  	  	 From Prod_Units
 	  	  	  	  	  	  	 Where PU_Id in (' + @Units + ')' + ' and pu_id <> 0')
 	  	 Select Distinct v.Var_Id, v.Var_Desc + ' (' + PU_Desc + ')' Var_Desc, SelectedUnits.ItemOrder
 	  	 From Events BatchEvent
 	  	 Join Prod_Units BatchUnit ON BatchUnit.PU_Id = BatchEvent.PU_Id
 	  	 Join #Units SelectedUnits On SelectedUnits.PU_Id = BatchUnit.PU_Id
 	  	 Join Event_Components EC ON EC.Source_Event_Id = BatchEvent.Event_Id
 	  	 Join Events UnitProcedureEvent ON UnitProcedureEvent.Event_Id = EC.Event_Id
 	  	 Join User_Defined_Events OperationEvent ON OperationEvent.Event_Id = UnitProcedureEvent.Event_Id
 	  	 Join User_Defined_Events PhaseEvent ON PhaseEvent.Parent_UDE_Id = OperationEvent.UDE_Id
 	  	 Join Variables v ON 	 v.PU_Id = PhaseEvent.PU_Id
 	  	  	 AND 	 v.Event_Type = 14
 	  	  	 AND 	 v.Event_SubType_Id = PhaseEvent.Event_SubType_Id
 	  	 Order By SelectedUnits.ItemOrder
-- 	 Select v.Var_Id, v.Var_Desc
-- 	 From Variables v
-- 	 Join #Units u On v.PU_Id = u.PU_Id
End
Else
 	 Select Distinct v.Var_Id, v.Var_Desc + ' (' + PU_Desc + ')' Var_Desc
 	 From Events BatchEvent
 	 Join Prod_Units BatchUnit ON BatchUnit.PU_Id = BatchEvent.PU_Id
 	 Join Event_Components EC ON EC.Source_Event_Id = BatchEvent.Event_Id
 	 Join Events UnitProcedureEvent ON UnitProcedureEvent.Event_Id = EC.Event_Id
 	 Join User_Defined_Events OperationEvent ON OperationEvent.Event_Id = UnitProcedureEvent.Event_Id
 	 Join User_Defined_Events PhaseEvent ON PhaseEvent.Parent_UDE_Id = OperationEvent.UDE_Id
 	 Join Variables v ON 	 v.PU_Id = PhaseEvent.PU_Id
 	  	 AND 	 v.Event_Type = 14
 	  	 AND 	 v.Event_SubType_Id = PhaseEvent.Event_SubType_Id
Drop Table #Units
