Create Procedure dbo.spEMAC_UpdateDetailsChkbxs
@AT_Id int,
@Checkbox int,
@Checked bit,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateDetailsChkbxs',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	 Convert(nVarChar(10),@Checkbox) + ','  + 
 	 Convert(nVarChar(10),@Checked) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Checkbox = 1
  update alarm_templates set use_var_desc = @Checked where at_id = @AT_Id
else if @Checkbox = 2
  update alarm_templates set use_at_desc = @Checked where at_id = @AT_Id
else if @Checkbox = 3
   update alarm_templates set use_trigger_desc = @Checked where at_id = @AT_Id
else if @Checkbox = 4
   update alarm_templates set use_Unit_desc = @Checked where at_id = @AT_Id
else if @Checkbox = 5
   update alarm_templates set use_Line_desc = @Checked where at_id = @AT_Id
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
