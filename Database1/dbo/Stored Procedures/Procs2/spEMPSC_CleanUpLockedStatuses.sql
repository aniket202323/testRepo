CREATE PROCEDURE dbo.spEMPSC_CleanUpLockedStatuses
 	 @UserId int 
  AS
DECLARE @Insert_Id integer 
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,StartTime)
 	 VALUES (1,@UserId,'spEMPSC_CleanUpLockedStatuses',dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
DECLARE @LockedStatuses TABLE (LockedStatusId Int)
DECLARE @UnlockedStatuses TABLE (UnlockedStatusId Int)
INSERT INTO @LockedStatuses(LockedStatusId) 
 	 SELECT a.ProdStatus_Id 
 	  	 FROM Production_Status a
 	  	 WHERE a.LockData = 1
INSERT INTO @UnlockedStatuses(UnlockedStatusId) 
 	 SELECT a.ProdStatus_Id 
 	  	 FROM Production_Status a
 	  	 WHERE a.LockData = 0 or a.LockData Is null
DELETE FROM PrdExec_Trans 
 	 WHERE From_ProdStatus_Id in (SELECT LockedStatusId FROM @LockedStatuses) and 
 	  	  	 To_ProdStatus_Id in (SELECT UnlockedStatusId FROM @UnlockedStatuses)
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
 	 WHERE Audit_Trail_Id = @Insert_Id
