CREATE Procedure dbo.spEMEPC_PutInputSources
@Path_Id int,
@PEI_Id int,
@PU_Id int,
@User_Id int,
@PEPIS_Id int = NULL OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_PutInputSources',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nvarchar(50),@PEI_Id) + ','  + 
             Convert(nvarchar(50),@PU_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@PEPIS_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @PEPIS_Id is NULL
  Begin
    Insert Into PrdExec_Path_Input_Sources (Path_Id, PEI_Id, PU_Id)
      Values (@Path_Id, @PEI_Id, @PU_Id)
    Select @PEPIS_Id = Scope_Identity()
  End
Else
  Begin
    Delete From PrdExec_Path_Input_Source_Data
      Where PEPIS_Id = @PEPIS_Id
    Delete From PrdExec_Path_Input_Sources
      Where PEPIS_Id = @PEPIS_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
