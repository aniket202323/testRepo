Create Procedure dbo.spALM_SheetInformation 
@SheetDesc nvarchar(50) = NULL,
@Unit_Id int = NULL,
@Event_Id int = NULL
AS
if @SheetDesc is NOT NULL and @SheetDesc <> ''
Select 
  Sheet_Id,
  Sheet_Desc,
  Is_Active,
  Event_Type,
  Master_Unit,
  Interval,
  Offset,
  Initial_Count,
  Maximum_Count,
  Row_Headers,
  Column_Headers,
  Row_Numbering,
  Column_Numbering,
  Display_Event,
  Display_Date,
  Display_Time,
  Display_Grade,
  Display_Var_Order,
  Display_Data_Type,
  Display_Data_Source,
  Display_Spec,
  Display_Prod_Line,
  Display_Prod_Unit,
  Display_Description,
  Display_EngU,
  Group_Id = Coalesce(s.Group_Id, s1.Group_Id),
  Display_Spec_Win,
  Comment_Id,
  Sheet_Type,
  External_Link,
  Display_Comment_Win,
  Dynamic_Rows,
  Max_Edit_Hours,
  Wrap_Product,
  Max_Inventory_Days,
  s.Sheet_Group_Id,
  Auto_Label_Status,
  Display_Spec_Column,
  PL_Id,
  PEI_Id 
 from sheets s -- (index=Sheets_By_Description) 
    Left Outer Join Sheet_Groups s1 on s1.Sheet_Group_Id = s.Sheet_Group_Id
    where sheet_desc = @SheetDesc
if @Unit_Id is NULL or @Unit_id = 0
  select @Unit_Id = PU_Id from events where event_Id = @event_Id
Create Table #Keys(KeyId int, VarId int, CauseTree int NULL, ActionTree int NULL, SPCGroupVariableTypeId int NULL, SPCCalculationTypeId int NULL)
if @SheetDesc is NOT NULL and @SheetDesc <> ''
  Begin
    Insert Into #Keys
     Select distinct d.ATD_Id, v.Var_Id, CauseTree= COALESCE(d.Override_Cause_Tree_Id, t.Cause_tree_Id), ActionTree =COALESCE(d.Override_Action_Tree_Id, t.Action_Tree_Id), SPCGroupVariableTypeId = COALESCE(v.SPC_Group_Variable_Type_Id, 0), SPCCalculationTypeId = COALESCE(v.SPC_Calculation_Type_Id, 0)
      From Variables v
      Join Sheet_Variables sv on sv.Var_Id = v.Var_Id
      Join Sheets s on s.Sheet_Id = sv.Sheet_Id and Sheet_Desc = @SheetDesc
      Join Alarm_Template_Var_Data d on d.Var_Id = v.Var_Id
      Join Alarm_Templates t on t.AT_Id = d.AT_Id
    Insert Into #Keys
     Select distinct d.ATD_Id, v.Var_Id, CauseTree= COALESCE(d.Override_Cause_Tree_Id, t.Cause_tree_Id), ActionTree =COALESCE(d.Override_Action_Tree_Id, t.Action_Tree_Id), SPCGroupVariableTypeId = COALESCE(v.SPC_Group_Variable_Type_Id, 0), SPCCalculationTypeId = COALESCE(v.SPC_Calculation_Type_Id, 0)
      From Sheets s 
      Join Sheet_Unit su on su.Sheet_Id = s.Sheet_Id
      Join Prod_Units pu on pu.PU_Id = su.PU_Id
      Join Variables v on v.PU_Id = pu.PU_Id
      Join Alarm_Template_Var_Data d on d.Var_Id = v.Var_Id
      Join Alarm_Templates t on t.AT_Id = d.AT_Id
 	  	  	  Where s.Sheet_Id = su.Sheet_Id and Sheet_Desc = @SheetDesc and v.System = 1
  End
else
  Begin
    Insert Into #Keys
     Select distinct d.ATD_Id, v.Var_Id, CauseTree= COALESCE(d.Override_Cause_Tree_Id, t.Cause_tree_Id), ActionTree =COALESCE(d.Override_Action_Tree_Id, t.Action_Tree_Id), SPCGroupVariableTypeId = COALESCE(v.SPC_Group_Variable_Type_Id, 0), SPCCalculationTypeId = COALESCE(v.SPC_Calculation_Type_Id, 0)
      From Variables v
      Join Alarm_Template_Var_Data d on d.Var_Id = v.Var_Id
      Join Alarm_Templates t on t.AT_Id = d.AT_Id
      Join Prod_Units pu on v.PU_Id = pu.PU_Id and pu.PU_Id = @Unit_Id
  End
Select KeyId, VarId, CauseTree, ActionTree, SPCGroupVariableTypeId, SPCCalculationTypeId
  From #Keys
If @SheetDesc is NOT NULL and @SheetDesc <> ''
  Begin
 	  	 Select su.PU_Id 
 	  	   from Sheet_Unit su
 	  	   Join Sheets s on s.Sheet_Id = su.Sheet_Id and Sheet_Desc = @SheetDesc
  end
Else
  Select PU_Id = @Unit_Id --Use PU_Id passed into stored procedure
Drop Table #Keys
