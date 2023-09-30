Create Procedure dbo.spEMEV_GetInputs
@ECId int,
@User_Id int
AS
Declare @Insert_Id int
Select Alias, SUBSTRING(Value,COALESCE(DATALENGTH(t.Prefix),0) + 1,255) as Input
  From Event_Configuration_Data d
  Join Event_Configuration_Values v on d.ECV_Id = v.ECV_Id 
  Join ED_Fields f on d.ED_Field_Id = f.ED_Field_Id and f.ED_Field_Type_Id = 3 
  Join ED_FieldTypes t on t.ED_Field_Type_Id = f.ED_Field_Type_Id
  Where d.EC_Id = @ECId
