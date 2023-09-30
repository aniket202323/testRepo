CREATE Procedure dbo.spEMEPC_PutPathProducts
@Path_Id int,
@Prod_Id int,
@User_Id int,
@PEPP_Id int = NULL OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_PutPathProducts',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nvarchar(50),@Prod_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@PEPP_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @PEPP_Id is NULL
  Begin
    Insert Into PrdExec_Path_Products (Path_Id, Prod_Id)
      Values (@Path_Id, @Prod_Id)
    Select @PEPP_Id = Scope_Identity()
  End
Else
  Begin
    Delete From PrdExec_Path_Products
      Where PEPP_Id = @PEPP_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
