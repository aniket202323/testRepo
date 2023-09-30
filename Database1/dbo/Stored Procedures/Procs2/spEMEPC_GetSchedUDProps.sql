CREATE Procedure dbo.spEMEPC_GetSchedUDProps
@Path_Id int,
@TableId int,
@User_Id int
AS
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
Insert Into #TableFields
  Select TF.Table_Field_Id, TF.Table_Field_Desc, TF.ED_Field_Type_Id, 
    Value = Case When EDFT.Store_Id = 0 Then TFV.Value Else NULL End, ValueId = Case When EDFT.Store_Id = 1 Then TFV.Value Else NULL End, 
    EDFT.Field_Type_Desc, EDFT.SP_Lookup, EDFT.Store_Id
    From Table_Fields TF
    Join Table_Fields_Values TFV on TFV.KeyId = @Path_Id and TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = @TableId
    Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
Select TableFieldDesc As 'Name', Value, ValueId, EDFieldTypeId, FieldTypeDesc, SPLookup, StoreId, TableFieldId From #TableFields
  Order By TableFieldDesc Asc
Drop Table #TableFields
