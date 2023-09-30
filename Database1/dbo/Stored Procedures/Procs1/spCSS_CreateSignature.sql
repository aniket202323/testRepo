CREATE PROCEDURE dbo.spCSS_CreateSignature 
@User_Id int, 
@Node nvarchar(50),
@ESignature_Id int output
AS
DECLARE @UTCNow Datetime,@DbNow Datetime
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
Insert into ESignature (Perform_User_Id, Perform_Node, Perform_Time)
  values (@User_Id, @Node, @DbNow)
Select @ESignature_Id = Scope_Identity()
