CREATE Procedure dbo.spEMEPC_PutInputStatuses
@Valid_Status int,
@Path_Id int,
@PEI_Id int,
@PU_Id int,
@PEIS_Id int,
@User_Id int,
@PEPIS_Id int OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_PutInputStatuses',
             Convert(nvarchar(50),@Valid_Status) + ','  + 
             Convert(nvarchar(50),@Path_Id) + ','  + 
             Convert(nvarchar(50),@PEI_Id) + ','  + 
             Convert(nvarchar(50),@PU_Id) + ','  + 
             Convert(nvarchar(50),@PEIS_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@PEPIS_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @PEPIS_Id is NULL
  Begin
    Exec spEMEPC_PutInputSources @Path_Id, @PEI_Id, @PU_Id, @User_Id, @PEPIS_Id OUTPUT
    Insert Into PrdExec_Path_Input_Source_Data (PEPIS_Id, Valid_Status)
      Select @PEPIS_Id, pisd.valid_status 
      From PrdExec_Input_Source_Data pisd
      Join prdexec_status ps on ps.valid_status = pisd.valid_status
      Where PEIS_Id = @PEIS_Id
      And ps.pu_id = @PU_Id
  End
If (Select Count(*) From PrdExec_Path_Input_Source_Data Where PEPIS_Id = @PEPIS_Id and Valid_Status = @Valid_Status) = 0
  Begin
    Insert Into PrdExec_Path_Input_Source_Data (PEPIS_Id, Valid_Status)
      Values (@PEPIS_Id, @Valid_Status)
  End
Else
  Begin
    Delete From PrdExec_Path_Input_Source_Data
      Where PEPIS_Id = @PEPIS_Id and Valid_Status = @Valid_Status
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
