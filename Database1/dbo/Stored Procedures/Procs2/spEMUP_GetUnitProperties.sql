CREATE Procedure dbo.spEMUP_GetUnitProperties
@PU_Id int,
@User_Id int
AS
Select Unit_Type_Id, UT_Desc, Uses_Production, Uses_Locations
From Unit_Types
Order By UT_Desc ASC
Select Distinct Equipment_Type
From Prod_Units
Order By Equipment_Type ASC
Select s.Sheet_Desc, s.Sheet_Id, Count(sv.Var_Id)
From Sheet_Variables sv
Join Sheets s on s.Sheet_Id = sv.Sheet_Id
Join Variables v on v.Var_Id = sv.Var_Id
Join Prod_Units pu on pu.pu_id = v.pu_id and (pu.pu_id = @PU_Id or pu.master_unit = @PU_Id)
Group By s.Sheet_Desc, s.Sheet_Id
Having Count(sv.Var_Id) > 1
Order By s.Sheet_Desc ASC
Select ERC_Id, ERC_Desc
From Event_Reason_Catagories
Where ERC_Id <> 100
Order By ERC_Desc ASC
Create Table #TimeUnits (TU_Id int, TU_Desc nvarchar(20))
Insert Into #TimeUnits(TU_Id,TU_Desc) Values(0,'Hour')
Insert Into #TimeUnits(TU_Id,TU_Desc) Values(1,'Minute')
Insert Into #TimeUnits(TU_Id,TU_Desc) Values(2,'Second')
Insert Into #TimeUnits(TU_Id,TU_Desc) Values(3,'Day')
Select TU_Id, TU_Desc
From #TimeUnits
Order By TU_Desc ASC
Drop Table #TimeUnits
SELECT Path_Id,Path_Code from prdexec_paths
Select PU.PU_Desc, PU.External_Link, PU.Extended_Info, PU.Unit_Type_Id, PU.Equipment_Type, PL.PL_Id, PL.PL_Desc, PU.Sheet_Id,
       PU.Production_Type, Production_Variable = IsNull(PU.Production_Variable,0),Production_Variable_Desc = IsNull(v.Var_Desc,''), PU.Production_Rate_TimeUnits, PU.Production_Rate_Specification, 
       PU.Production_Alarm_Interval, PU.Production_Alarm_Window,
       PU.Waste_Percent_Specification, PU.Waste_Percent_Alarm_Interval, PU.Waste_Percent_Alarm_Window,
       PU.Downtime_Scheduled_Category, PU.Downtime_External_Category, PU.Downtime_Percent_Specification, 
       PU.Downtime_Percent_Alarm_Interval, PU.Downtime_Percent_Alarm_Window,
       PU.Efficiency_Calculation_Type, Efficiency_Variable = IsNull(PU.Efficiency_Variable,0),Efficiency_Variable_Desc = IsNull(v1.Var_Desc,''), PU.Efficiency_Percent_Specification, 
       PU.Efficiency_Percent_Alarm_Interval, PU.Efficiency_Percent_Alarm_Window, PU.Delete_Child_Events,Default_Path_Id,Performance_Downtime_Category,
       PU.Non_Productive_Category, PU.Non_Productive_Reason_Tree
From Prod_Units PU
Join Prod_Lines PL On PL.PL_Id = PU.PL_Id
Left Join Variables v on v.Var_Id = PU.Production_Variable
Left Join Variables v1 on v1.Var_Id = PU.Efficiency_Variable
Where PU.PU_Id = @PU_Id
Create Table #TableFields(
  TableFieldId int,
  TableFieldDesc nvarchar(50),
  EDFieldTypeId int,
  Value varchar(7000),
  ValueId int,
  FieldTypeDesc nVarChar(100),
  SPLookup tinyint,
  StoreId tinyint
)
-- Insert Into #TableFields
--   Select -1, 'User_Defined1', 1, -1, User_Defined1, 'Text', 0 From Prod_Units Where PU_Id = @PU_Id
-- Insert Into #TableFields
--   Select -2, 'User_Defined2', 1, -2, User_Defined2, 'Text', 0 From Prod_Units Where PU_Id = @PU_Id
-- Insert Into #TableFields
--   Select -3, 'User_Defined3', 1, -3, User_Defined3, 'Text', 0 From Prod_Units Where PU_Id = @PU_Id
Insert Into #TableFields
  Select TF.Table_Field_Id, TF.Table_Field_Desc, TF.ED_Field_Type_Id, 
    Value = Case When EDFT.Store_Id = 0 Then TFV.Value Else NULL End, ValueId = Case When EDFT.Store_Id = 1 Then TFV.Value Else NULL End, 
    EDFT.Field_Type_Desc, EDFT.SP_Lookup, EDFT.Store_Id
    From Table_Fields TF
    Join Table_Fields_Values TFV on TFV.KeyId = @PU_Id and TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = 43
    Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
Select TableFieldDesc As 'Name', Value, ValueId, EDFieldTypeId, FieldTypeDesc, SPLookup, StoreId, TableFieldId From #TableFields
  Order By TableFieldDesc Asc
Drop Table #TableFields
