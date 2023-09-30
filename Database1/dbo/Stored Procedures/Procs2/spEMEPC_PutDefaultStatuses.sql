CREATE Procedure dbo.spEMEPC_PutDefaultStatuses
@PU_Id int,
@PEPIS_Id int,
@Previous_PEPIS_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_PutDefaultStatuses',
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nvarchar(50),@PEPIS_Id) + ','  + 
             Convert(nvarchar(50),@Previous_PEPIS_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @Previous_PEPIS_Id = 0
  Begin
    Insert Into PrdExec_Path_Input_Source_Data (PEPIS_Id, Valid_Status)
      Select @PEPIS_Id, pps.valid_status 
      From prdexec_status pps
      Join production_status ps on ps.ProdStatus_Id = pps.valid_status
      Where pps.pu_id = @PU_Id
      And ps.status_valid_for_input = 1
  End
Else
  Begin
    Insert Into PrdExec_Path_Input_Source_Data (PEPIS_Id, Valid_Status)
      Select @PEPIS_Id, ppisd.valid_status 
      From PrdExec_Path_Input_Source_Data ppisd
      Join prdexec_status pps on pps.valid_status = ppisd.valid_status
      Where PEPIS_Id = @Previous_PEPIS_Id
      And pps.pu_id = @PU_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
