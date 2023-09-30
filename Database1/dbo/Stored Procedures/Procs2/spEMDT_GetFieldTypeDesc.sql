Create Procedure dbo.spEMDT_GetFieldTypeDesc
@ED_Field_Type_Id int,
@ECId int, 
@User_Id int,
@Field_Type_Desc nVarChar(100) OUTPUT,
@NumofInputs int OUTPUT
AS
select @Field_Type_Desc = ltrim(rtrim(substring(field_type_desc, 1, charindex(' ',field_type_desc))))
from ed_fieldtypes
where ed_field_type_id = @ED_Field_Type_Id
Select @NumofInputs = count(*) 
  From Event_Configuration_data c
  Join ED_Fields f on f.ED_Field_Id = c.ED_Field_Id and f.ED_Field_Type_Id = 3
  Where EC_Id = @ECId
