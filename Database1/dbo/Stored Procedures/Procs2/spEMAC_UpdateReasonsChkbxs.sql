Create Procedure dbo.spEMAC_UpdateReasonsChkbxs
@AT_Id int,
@Checkbox int,
@Checked bit,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateReasonsChkbxs',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	 Convert(nVarChar(10),@Checkbox) + ','  + 
 	 Convert(nVarChar(10),@Checked) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Checkbox = 1
  begin
    if @Checked = 1
      begin
        update alarm_templates set cause_required = 1 where at_id = @AT_Id
      end
    else
      begin
        update alarm_templates set cause_required = 0 where at_id = @AT_Id 
      end
  end
else if @Checkbox = 2
  begin
    if @Checked = 1
      begin
        update alarm_templates set action_required = 1 where at_id = @AT_Id
      end
    else
      begin
        update alarm_templates set action_required = 0 where at_id = @AT_Id
      end
  end
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
