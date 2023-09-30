Create Procedure dbo.spEMDT_GetLocations  
@MasterUnit int,
@User_Id int
AS
Select PU_Id as Id, PU_Desc as Units 
  From Prod_Units
  Where (Master_Unit = @MasterUnit or PU_Id = @MasterUnit) and Timed_Event_Association > 0
  order by pu_order
Select Field_Id,Field_Desc from ED_FieldType_ValidValues where ED_Field_Type_Id = 62
