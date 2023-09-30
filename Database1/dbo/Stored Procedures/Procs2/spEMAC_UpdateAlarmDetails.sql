Create Procedure dbo.spEMAC_UpdateAlarmDetails
 	 @IntValue 	 Int,
 	 @AT_Id 	  	 Int,
 	 @TransNum 	 Int,
 	 @User_Id 	 Int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateAlarmDetails',
 	  	  	  Convert(nVarChar(10),@IntValue)  + ',' +
             Convert(nVarChar(10),@AT_Id) + ','  + 
             Convert(nVarChar(10),@TransNum) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
IF @TransNum = 1
BEGIN
 	 IF @IntValue = -1 SET @IntValue = Null
 	 UPDATE alarm_templates set Email_Table_Id = @IntValue where at_id = @AT_Id
END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
