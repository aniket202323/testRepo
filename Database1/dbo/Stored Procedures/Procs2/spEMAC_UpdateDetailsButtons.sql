Create Procedure dbo.spEMAC_UpdateDetailsButtons
@AT_Id int,
@Button int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateDetailsButtons',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	 Convert(nVarChar(10),@Button) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Button = 3
  begin
    update alarm_templates set AP_Id = 3 where at_id = @AT_Id
  end
else if @Button = 2
  begin
    update alarm_templates set AP_Id = 2 where at_id = @AT_Id
  end
else
  begin
    update alarm_templates set AP_Id = 1 where at_id = @AT_Id
  end
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
