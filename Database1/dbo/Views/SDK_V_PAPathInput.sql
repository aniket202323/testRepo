CREATE view SDK_V_PAPathInput
as
select
PrdExec_Inputs.PEI_Id as Id,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
PrdExec_Inputs.Input_Name as PathInput,
Event_Subtypes.Event_Subtype_Desc as EventSubType,
Prod_Units_Base.PL_Id as ProductionLineId,
PrdExec_Inputs.PU_Id as ProductionUnitId,
PrdExec_Inputs.Event_Subtype_Id as EventSubTypeId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PU_Order as ProductionUnitOrder,
PrdExec_Inputs.Input_Order as InputOrder,
prdexec_inputs.Def_Event_Comp_Sheet_Id as DefEventCompSheetId,
prdexec_inputs.Lock_Inprogress_Input as LockInprogressInput,
prdexec_inputs.Alternate_Spec_Id as AlternateSpecId,
AlternateSpec_Src.Spec_Desc as AlternateSpec,
prdexec_inputs.Primary_Spec_Id as PrimarySpecId,
PrimarySpec_Src.Spec_Desc as PrimarySpec
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 JOIN PrdExec_Inputs ON Prod_Units_Base.PU_Id = PrdExec_Inputs.PU_Id
 JOIN Event_SubTypes ON PrdExec_Inputs.Event_Subtype_Id = Event_Subtypes.Event_SubType_Id
 Left Join Specifications AlternateSpec_Src on AlternateSpec_Src.Spec_Id = prdexec_inputs.Alternate_Spec_Id 
 Left Join Specifications PrimarySpec_Src on PrimarySpec_Src.Spec_Id = prdexec_inputs.Primary_Spec_Id 
