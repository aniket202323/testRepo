CREATE Procedure dbo.spSV_GetBOMDetails
@BOM_Formulation_Id int,
@Language_Id int = 0
AS
Declare @Col1 nvarchar(50),
        @Col2 nvarchar(50),
        @Col3 nvarchar(50),
        @SQL nvarchar(2000)
Create Table #TableFields(
  TableFieldId int,
  TableFieldDesc nvarchar(50),
  EDFieldTypeId int,
  Value varchar(7000),
  ValueId int,
  FieldTypeDesc nvarchar(100),
  SPLookup tinyint,
  StoreId tinyint,
 	 BOM_Formulation_Desc nvarchar(50)
)
Insert Into #TableFields
  Select TF.Table_Field_Id, TF.Table_Field_Desc, TF.ED_Field_Type_Id, 
    Value = Case When EDFT.Store_Id = 0 Then TFV_BOM.Value Else NULL End, ValueId = Case When EDFT.Store_Id = 1 Then TFV_BOM.Value Else NULL End, 
    EDFT.Field_Type_Desc, EDFT.SP_Lookup, EDFT.Store_Id, BOMF.BOM_Formulation_Desc
    From Table_Fields TF
    Join Table_Fields_Values TFV_BOM on TFV_BOM.KeyId = @BOM_Formulation_Id and TFV_BOM.Table_Field_Id = TF.Table_Field_Id and TFV_BOM.TableId = 26 --Bill_Of_Material_Formulation
    Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
 	  	 Left Outer Join Bill_Of_Material_Formulation BOMF on BOMF.BOM_Formulation_Id = TFV_BOM.KeyId
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20466 --BOM Formulation Description
    Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20490 --Property Name
    Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 20312 --Value
Select @SQL = 'Select BOM_Formulation_Desc as [' + @Col1 + '], TableFieldDesc As [' + @Col2 + '], Value As [' + @Col3 + '], ValueId, EDFieldTypeId, FieldTypeDesc, SPLookup, StoreId, TableFieldId From #TableFields
  Order By TableFieldDesc Asc'
    exec (@SQL)
Drop Table #TableFields
