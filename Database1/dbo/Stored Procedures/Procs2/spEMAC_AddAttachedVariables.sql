Create Procedure dbo.spEMAC_AddAttachedVariables 
@AT_Id int,
@Var_Id int,
@EG_Id int,
@User_Id int,
@SamplingSize Int = 0
AS
declare @ExistingRow int,
@Insert_Id int,
@Alarm_Type_Id int,
@ATId int,
@RuleId int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_AddAttachedVariables',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	            Convert(nVarChar(10),@Var_Id) + ','  + 
 	            Convert(nVarChar(10),@EG_Id) + ','  + 
 	            Convert(nVarChar(10),@SamplingSize) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @EG_Id = 0 Select @EG_Id = NULL
select @ExistingRow = (select count(*) from alarm_template_var_data
where at_id = @AT_Id
and var_id = @Var_Id)
if @ExistingRow = 0
Begin
 insert into Alarm_Template_Var_Data (AT_Id, Var_Id, EG_Id,Sampling_Size)  values(@AT_Id, @Var_Id, @EG_Id,@SamplingSize) 
  Select @Alarm_Type_Id = Alarm_Type_Id from Alarm_Templates Where AT_Id = @AT_Id
  If @Alarm_Type_Id = 1 --Variable alarm template
    Begin
 	  	  	 Create Table #Rules (ATVRD_Id int)
 	  	  	 Insert into #Rules
 	  	  	   Select ATVRD_Id from Alarm_Template_Variable_Rule_Data where AT_id = @AT_Id
 	  	  	  	 
 	  	  	 Declare AlarmRuleCursor Cursor For
 	  	  	   Select ATVRD_Id from #Rules for read only
 	  	  	 Open AlarmRuleCursor
 	  	  	 While (0=0) Begin
 	  	  	   Fetch Next
 	  	  	     From AlarmRuleCursor
 	  	  	     Into @RuleId
 	  	  	     If (@@Fetch_Status <> 0) Break
 	  	  	  	  	   Insert into Alarm_Template_Var_Data (AT_Id, Var_Id, EG_Id, ATVRD_Id,Sampling_Size)
 	  	  	  	  	     Select @AT_Id, @Var_Id, @EG_Id, @RuleId,0
 	  	  	 End
 	  	  	 Close AlarmRuleCursor
 	  	  	 Deallocate AlarmRuleCursor
 	  	  	 Drop Table #Rules
    End
  Else
    Begin
 	  	   If @Alarm_Type_Id = 4 --SPC Group alarm template
 	  	     Begin
 	  	  	  	  	 Create Table #Rules2 (ATSRD_Id int, SPC_Group_Variable_Type_Id int)
 	  	  	  	  	 Insert into #Rules2
 	  	  	  	  	   Select ATSRD_Id, SPC_Group_Variable_Type_Id from Alarm_Template_SPC_Rule_Data where AT_id = @AT_Id
 	  	  	  	 
 	  	  	  	   Create Table #Vars (Var_Id int, SPC_Group_Variable_Type_Id int)
 	  	  	  	   Insert into #Vars
 	  	  	  	     Select Var_Id, SPC_Group_Variable_Type_Id from Variables where PVar_Id = @Var_Id
 	  	  	  	   Insert into #Vars
 	  	  	  	     Select Var_Id, SPC_Group_Variable_Type_Id from Variables where Var_Id = @Var_Id
 	  	 
 	  	  	  	  	 --Assign Children variables to appropriate SPC rules
 	  	  	  	   Insert into Alarm_Template_Var_Data (AT_Id, Var_Id, EG_Id, ATSRD_Id,Sampling_Size)
 	  	  	  	     Select @AT_Id, v.Var_Id, @EG_Id, r.ATSRD_Id,@SamplingSize from #Vars v
 	  	  	  	       Join #Rules2 r on r.SPC_Group_Variable_Type_Id = v.SPC_Group_Variable_Type_Id
 	  	  	  	  	 Drop Table #Vars
 	  	  	  	  	 Drop Table #Rules2
 	  	  	  	 End
    End
End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
