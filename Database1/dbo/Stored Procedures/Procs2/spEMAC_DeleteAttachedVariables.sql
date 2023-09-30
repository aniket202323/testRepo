CREATE PROCEDURE dbo.spEMAC_DeleteAttachedVariables 
@AT_Id int,
@Var_Id int = NULL,
@User_Id int
AS
declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_DeleteAttachedVariables',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	 Convert(nVarChar(10),@Var_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
declare @ATD_Id int,
@Alarm_Id int,
@Comment_Id int,
@Cause_Comment_Id int,
@Action_Comment_Id int,
@Research_Comment_Id int,
@Alarm_Type_Id int
if @Var_Id is NULL
  begin
    Declare Alarms Cursor For
    Select a.Alarm_Id, a.ATD_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id from Alarms a
    join alarm_template_var_data atvd on atvd.atd_id = a.atd_id
    where atvd.at_id = @AT_Id for read only
    Open Alarms
    While (0=0) Begin
      Fetch Next
        From Alarms
        Into @Alarm_Id, @ATD_ID, @Cause_Comment_Id, @Action_Comment_Id, @Research_Comment_Id
      If (@@Fetch_Status <> 0) Break
      if @Cause_Comment_Id is not null
        exec spCSS_InsertDeleteComment @Alarm_Id, 13, 1, 1, null, @Cause_Comment_Id
      if @Action_Comment_Id is not null
        exec spCSS_InsertDeleteComment @Alarm_Id, 14, 1, 1, null, @Action_Comment_Id
      if @Research_Comment_Id is not null
        exec spCSS_InsertDeleteComment @Alarm_Id, 15, 1, 1, null, @Research_Comment_Id
      delete from alarms where alarm_id = @Alarm_Id
    End
    Close Alarms
    Deallocate Alarms
    Declare AlarmTemplateVarData Cursor For
    Select atvd.atd_id, atvd.comment_id from Alarm_Template_Var_Data atvd
    join alarm_templates at on at.at_id = atvd.at_id
    where at.at_id = @AT_Id for read only
    Open AlarmTemplateVarData
    While (0=0) Begin
      Fetch Next
        From AlarmTemplateVarData
        Into @ATD_ID, @Comment_Id
      If (@@Fetch_Status <> 0) Break
      if @Comment_Id is not null
        exec spCSS_InsertDeleteComment @ATD_Id, 7, 1, 1, null, @Comment_Id
      delete from alarm_template_var_data where atd_id = @ATD_Id 
    End
    Close AlarmTemplateVarData
    Deallocate AlarmTemplateVarData
  end
else
  begin
    Create Table #Vars (VarId int)
    Select @Alarm_Type_Id = Alarm_Type_Id from Alarm_Templates Where AT_Id = @AT_Id
    If @Alarm_Type_Id = 4 --Must detach all Children variables from Rules for SPC Group Template type
      Begin
 	  	     Insert into #Vars (VarId)
 	  	       Select Var_Id from Variables Where PVar_Id = @Var_Id
      End
    Insert into #Vars (VarId) values (@Var_Id)
    Declare Alarms Cursor For
    Select a.Alarm_Id, a.ATD_Id, Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id from Alarms a
    join alarm_template_var_data atvd on atvd.atd_id = a.atd_id
    join #Vars v on v.VarId = a.Key_Id
    where atvd.at_id = @AT_Id for read only
    Open Alarms
    While (0=0) Begin
      Fetch Next
        From Alarms
        Into @Alarm_Id, @ATD_ID, @Cause_Comment_Id, @Action_Comment_Id, @Research_Comment_Id
      If (@@Fetch_Status <> 0) Break
      if @Cause_Comment_Id is not null
        exec spCSS_InsertDeleteComment @Alarm_Id, 13, 1, 1, null, @Cause_Comment_Id
      if @Action_Comment_Id is not null
        exec spCSS_InsertDeleteComment @Alarm_Id, 14, 1, 1, null, @Action_Comment_Id
      if @Research_Comment_Id is not null
        exec spCSS_InsertDeleteComment @Alarm_Id, 15, 1, 1, null, @Research_Comment_Id
      delete from alarms where alarm_id = @Alarm_Id
    End
    Close Alarms
    Deallocate Alarms
    select @ATD_Id = atd_id, @Comment_Id = comment_id
    from alarm_template_var_data
    where at_id = @AT_Id and var_id in (Select VarId from #Vars)
    if @Comment_Id is not null
      exec spCSS_InsertDeleteComment @ATD_Id, 7, 1, 1, null, @Comment_Id
    delete from alarm_template_var_data 
    where at_id = @AT_Id 
    and var_id in (Select VarId from #Vars)
    drop table #Vars
  end
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
