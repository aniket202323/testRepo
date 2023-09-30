Create Procedure dbo.spEMAC_UpdateDefaultReasons
@AT_Id int,
@User_Id int,
@Type bit,
@TreeId int,
@Reason1 int = NULL,
@Reason2 int = NULL,
@Reason3 int = NULL,
@Reason4 int = NULL
as
Declare @Insert_Id int,@Event_Reason_Tree_Data_Id Int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMAC_UpdateDefaultReasons',
             Convert(nVarChar(10),@AT_Id) + ','  + 
 	 Convert(nVarChar(10), @Type) + ',' +
 	 Convert(nVarChar(10),@TreeId) + ','  + 
 	 Convert(nVarChar(10),@Reason1) + ','  + 
 	 Convert(nVarChar(10),@Reason2) + ','  + 
 	 Convert(nVarChar(10),@Reason3) + ','  + 
 	 Convert(nVarChar(10),@Reason4) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @TreeId = 0
  select @TreeId = Null
if @Type = 0
  Begin
 	 If @Reason2 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	 Else If @Reason3 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason1 and  Level2_Id = @Reason2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	 Else If @Reason4 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason1 and  Level2_Id = @Reason2 and  Level3_Id = @Reason3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	 Else 
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason1 and  Level2_Id = @Reason2 and  Level3_Id = @Reason3 and Level4_Id  = @Reason4 and Tree_Name_Id = @TreeId
    update alarm_templates set cause_tree_id = @TreeId,
 	  	  	  default_cause1 = @Reason1,
 	  	  	  default_cause2 = @Reason2,
 	  	  	  default_cause3 = @Reason3,
 	  	  	  default_cause4 = @Reason4,
 	  	  	  Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id
      where at_id = @AT_Id   
  End
else if @Type = 1
  Begin
      update alarm_templates set action_tree_id = @TreeId,
 	  	  	  default_action1 = @Reason1,
 	  	  	  default_action2 = @Reason2,
 	  	  	  default_action3 = @Reason3,
 	  	  	  default_action4 = @Reason4
      where at_id = @AT_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
