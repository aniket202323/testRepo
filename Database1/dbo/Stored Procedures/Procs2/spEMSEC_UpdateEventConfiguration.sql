CREATE Procedure dbo.spEMSEC_UpdateEventConfiguration
@ECId 	  	  	 INT,
@EDModelNum 	  	 INT,
@UserId 	  	  	 INT
AS
Declare @AuditId 	  	 INT
DECLARE @EDModelId 	  	 INT
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEMSEC_UpdateEventConfig',
             isnull(Convert(nVarChar(10),@ECId),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@EDModelNum),'Null') + ','  + 
             Convert(nVarChar(10),@UserId), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @AuditId = Scope_Identity()
SELECT @EDModelId = ED_Model_Id From Ed_Models Where Model_Num = @EDModelNum
UPDATE Event_Configuration Set ED_Model_Id = @EDModelId Where EC_Id = @ECId
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @AuditId
