CREATE PROCEDURE dbo.spRS_WWW_VariableFilter
@CallType int,
@DataTypeId int = Null
AS
If @CallType = 1
  Begin
    Select * from Data_Type
    Where User_Defined = 1
  End
If @CallType = 2
  Begin
    Select * from Phrase
    Where Data_Type_Id = @DataTypeId
  End
