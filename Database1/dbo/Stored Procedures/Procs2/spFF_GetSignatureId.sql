Create Procedure dbo.spFF_GetSignatureId 
@Type_Id int,
@Key_Id BigInt,
@Signature_Id int OUTPUT
AS
Select @Signature_Id = Null
If @Type_Id = 1
  Begin
    Select @Signature_Id = Signature_Id From Events Where Event_Id = @Key_Id
  End
else if @Type_Id = 2
  Begin
    Select @Signature_Id = Signature_Id From Tests Where Test_Id = @Key_Id
  End
Return(100)
