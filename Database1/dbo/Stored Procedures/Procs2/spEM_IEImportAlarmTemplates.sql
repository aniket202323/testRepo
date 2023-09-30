CREATE PROCEDURE dbo.spEM_IEImportAlarmTemplates
 	 @AT_Desc 	  	 nvarchar(50),
 	 @Custom_Text 	  	 nvarchar(255),
 	 @sUse_Var_Desc 	  	 nVarChar(10),
 	 @sUse_AT_Desc 	  	 nVarChar(10),
 	 @sUse_Trigger_Desc 	 nVarChar(10),
 	 @DQ_PL_Desc 	  	 nvarchar(50),
 	 @DQ_PU_Desc 	  	 nvarchar(50),
 	 @DQ_Var_Desc 	  	 nvarchar(50),
 	 @DQ_Criteria 	  	 nvarchar(50),
 	 @DQ_Value 	  	 nvarchar(50),
 	 @sCause_Required 	 nVarChar(10),
 	 @Cause_Tree_Name 	 nvarchar(50),
 	 @Default_Cause_Name1 	 nVarChar(100),
 	 @Default_Cause_Name2 	 nVarChar(100),
 	 @Default_Cause_Name3 	 nVarChar(100),
 	 @Default_Cause_Name4 	 nVarChar(100),
 	 @sAction_Required 	 nVarChar(10),
 	 @Action_Tree_Name 	 nvarchar(50),
 	 @Default_Action_Name1 	 nVarChar(100),
 	 @Default_Action_Name2 	 nVarChar(100),
 	 @Default_Action_Name3 	 nVarChar(100),
 	 @Default_Action_Name4 	 nVarChar(100),
 	 @Comment_Text 	  	 nvarchar(255),
 	 @AlarmType 	  	 nvarchar(50),
 	 @EsigLevel 	  	 nvarchar(50),
 	 @SpName 	  	  	 nvarchar(50),
 	 @User_Id 	   	 int
AS
Declare @DQ_PL_Id 	  	  	 int,
 	 @DQ_PU_Id 	  	  	 int,
 	 @DQ_PUG_Id 	  	 int,
 	 @DQ_Var_Id 	  	 int,
 	 @DQ_Criteria_Id 	 int,
 	 @Cause_Tree_Id 	  	 int,
 	 @Default_Cause_Id1 	 int,
 	 @Default_Cause_Id2 	 int,
 	 @Default_Cause_Id3 	 int,
 	 @Default_Cause_Id4 	 int,
 	 @Action_Tree_Id 	 int,
 	 @Default_Action_Id1 	 int,
 	 @Default_Action_Id2 	 int,
 	 @Default_Action_Id3 	 int,
 	 @Default_Action_Id4 	 int,
 	 @Comment_Id 	  	 int,
 	 @Reason_Id 	  	 int,
 	 @ERTD_ID  	  	  	 int,
 	 @Reason_Levels 	  	 int,
 	 @Reason_Level 	  	 int,
 	 @Reason_Name 	  	 nVarChar(100),
 	 @Parent_Reason_Id 	 int,
 	 @PERTD_ID 	  	  	 int,
 	 @Use_Var_Desc 	  	 Bit,
 	 @Use_AT_Desc 	  	 Bit,
 	 @Use_Trigger_Desc 	 Bit,
 	 @Cause_Required 	 Bit,
 	 @Action_Required 	 Bit,
 	 @AT_Id  	  	  	 int,
 	 @iAlarmType 	  	 Int,
   	 @iESigLevel 	  	 Int,
 	 @iSpecSetting 	 Int
/* Initialization */
Select 	 @AT_Id 	  	  	 = Null,
 	 @DQ_PL_Id 	  	  	 = Null,
 	 @DQ_PU_Id 	  	  	 = Null,
 	 @DQ_PUG_Id 	  	  	 = Null,
 	 @DQ_Var_Id 	  	  	 = Null,
 	 @DQ_Criteria_Id 	  	 = Null,
 	 @Cause_Tree_Id 	  	 = Null,
 	 @Default_Cause_Id1 	  	 = Null,
 	 @Default_Cause_Id2 	  	 = Null,
 	 @Default_Cause_Id3 	  	 = Null,
 	 @Default_Cause_Id4 	  	 = Null,
 	 @Action_Tree_Id 	  	 = Null,
 	 @Default_Action_Id1 	  	 = Null,
 	 @Default_Action_Id2 	  	 = Null,
 	 @Default_Action_Id3 	  	 = Null,
 	 @Default_Action_Id4 	  	 = Null,
 	 @Parent_Reason_Id 	  	 = Null,
 	 @Reason_Id 	  	  	 = Null,
 	 @ERTD_ID 	 = Null,
 	 @Reason_Levels 	  	 = 4
/* Clean Arguments */
Select 	 @AT_Desc  	  	 = LTrim(RTrim(@AT_Desc)),
 	 @Custom_Text 	   	 = LTrim(RTrim(@Custom_Text)),
 	 @EsigLevel 	   	 = LTrim(RTrim(@EsigLevel)),
 	 @DQ_PL_Desc 	   	 = LTrim(RTrim(@DQ_PL_Desc)),
 	 @DQ_PU_Desc  	  	 = LTrim(RTrim(@DQ_PU_Desc)),
 	 @DQ_Var_Desc  	  	 = LTrim(RTrim(@DQ_Var_Desc)),
 	 @DQ_Criteria 	   	 = LTrim(RTrim(@DQ_Criteria)),
 	 @DQ_Value 	   	 = LTrim(RTrim(@DQ_Value)),
 	 @Cause_Tree_Name 	 = LTrim(RTrim(@Cause_Tree_Name)),
 	 @Default_Cause_Name1 	 = LTrim(RTrim(@Default_Cause_Name1)),
 	 @Default_Cause_Name2 	 = LTrim(RTrim(@Default_Cause_Name2)),
 	 @Default_Cause_Name3 	 = LTrim(RTrim(@Default_Cause_Name3)),
 	 @Default_Cause_Name4 	 = LTrim(RTrim(@Default_Cause_Name4)),
 	 @Action_Tree_Name 	  	 = LTrim(RTrim(@Action_Tree_Name)),
 	 @Default_Action_Name1 	 = LTrim(RTrim(@Default_Action_Name1)),
 	 @Default_Action_Name2 	 = LTrim(RTrim(@Default_Action_Name2)),
 	 @Default_Action_Name3 	 = LTrim(RTrim(@Default_Action_Name3)),
 	 @Default_Action_Name4 	 = LTrim(RTrim(@Default_Action_Name4)),
 	 @AlarmType 	  	  	  	 = LTrim(RTrim(@AlarmType)),
 	 @SpName 	  	  	  	  	 = LTrim(RTrim(@SpName))
IF @SpName = '' Select @SpName = Null 
IF @AlarmType = '' Select @AlarmType = Null 
If @EsigLevel = '' 	  	 Select @EsigLevel = Null
IF @SpName IS NOT NULL 
 	 SELECT @SpName = REPLACE(@SpName,'spLocal_','')
If  @EsigLevel Is null
 	 Select @iESigLevel = 0
ELSE
BEGIN
 	 Select @iESigLevel = Case @EsigLevel When 'User Level' Then 1
 	  	  	  	  	  	  	 When 'Approver Level' Then 2
 	  	  	  	  	  	  	 When 'Undefined' 	 Then 0
 	  	  	  	  	  	  	 Else -2
 	  	  	  	  	  	  End
 	 If @iESigLevel = -2 
 	 BEGIN
 	  	 Select 'Failed - Event ESignature is not correct'
 	  	 RETURN (-100)
 	 END
END
 	 If @sUse_Var_Desc = '1'
 	      Select @Use_Var_Desc = 1
 	 Else If @sUse_Var_Desc = '0' Or @sUse_Var_Desc Is Null
 	      Select @Use_Var_Desc = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid use var desc'
 	     Return(-100)
 	  End
 	 If @sUse_AT_Desc = '1'
 	      Select @Use_AT_Desc = 1
 	 Else If @sUse_AT_Desc = '0' Or @sUse_AT_Desc Is Null
 	      Select @Use_AT_Desc = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid Use template desc'
 	     Return(-100)
 	  End
 	 If @sUse_Trigger_Desc = '1'
 	      Select @Use_Trigger_Desc = 1
 	 Else If @sUse_Trigger_Desc = '0' Or @sUse_Trigger_Desc Is Null
 	      Select @Use_Trigger_Desc = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid Use trigger desc'
 	     Return(-100)
 	  End
 	 If @sCause_Required = '1'
 	      Select @Cause_Required = 1
 	 Else If @sCause_Required = '0' Or @sCause_Required Is Null
 	      Select @Cause_Required = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid Cause Required'
 	     Return(-100)
 	  End
 	 If @sAction_Required = '1'
 	      Select @Action_Required = 1
 	 Else If @sAction_Required = '0' Or @sAction_Required Is Null
 	      Select @Action_Required = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid Action Required'
 	     Return(-100)
 	  End
 	 If @DQ_Criteria Is Not Null
 	 BEGIN
 	  	 Select @DQ_Criteria_Id = Comparison_Operator_Id
 	  	 From Comparison_Operators
 	  	 Where Comparison_Operator_Value = @DQ_Criteria
 	  	 If @DQ_Criteria_Id Is Null
 	  	 BEGIN
 	  	  	 Select 'Error: Invalid data quality criteria'
 	  	  	 Return (-100)
 	  	 END
 	 END
/* Get Alarm Type */
If @AlarmType Is Not Null 
Begin
 	 Select @iAlarmType = Alarm_Type_Id
 	  	 From Alarm_Types
 	  	 Where Alarm_Type_Desc = @AlarmType
     If @iAlarmType is Null
 	  BEGIN
 	  	 IF @AlarmType = 'Variable Limits String - (Equal Spec)'
 	  	 BEGIN
 	  	  	 SET @iAlarmType = 1
 	  	  	 SET @iSpecSetting = 0
 	  	 END
 	  	 IF @AlarmType = 'Variable Limits String - (Not Equal Spec)'
 	  	 BEGIN
 	  	  	 SET @iAlarmType = 1
 	  	  	 SET @iSpecSetting = 1
 	  	 END
 	  	 IF @AlarmType = 'Variable Limits String - (Use Phrase Order)'
 	  	 BEGIN
 	  	  	 SET @iAlarmType = 1
 	  	  	 SET @iSpecSetting = 2
 	  	 END
 	  END
     If @iAlarmType is Null
       Begin
          Select 'Failed -  Invalid alarm type'
          Return (-100)
       End
     If @iAlarmType != 1 and @iAlarmType != 2 and @iAlarmType != 4
       Begin
          Select 'Failed -  Invalid alarm type'
          Return (-100)
       End
End
Else
Begin
 	 Select 'Failed - Invalid alarm type'
 	 Return (-100)
End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Data Quality Tag  	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
If @DQ_PL_Desc Is Not Null And @DQ_PL_Desc <> ''
  Begin
 	 Select @DQ_PL_Id = PL_Id From Prod_Lines Where PL_Desc = @DQ_PL_Desc
 	 If @DQ_PL_Id Is Not Null
 	   Begin
 	     If @DQ_PU_Desc Is Not Null And @DQ_PU_Desc <> ''
 	  	    Begin
 	  	  	 Select @DQ_PU_Id = PU_Id From Prod_Units Where PU_Desc = @DQ_PU_Desc and PL_Id = @DQ_PL_Id
 	  	  	 If @DQ_PU_Id Is Not Null
 	  	  	   Begin          
 	  	  	  	 If @DQ_Var_Desc Is Not Null And @DQ_Var_Desc <> ''
 	  	  	  	   Begin
 	  	  	  	  	 Select @DQ_Var_Id = Var_Id From Variables Where Var_Desc = @DQ_Var_Desc and PU_Id = @DQ_PU_Id
 	  	  	  	  	 If @DQ_Var_Id Is Null
 	  	  	  	  	   Begin
 	  	  	  	  	  	 Select 'Failed - Data Quality Variable not Found.'
 	  	  	  	  	  	 Return (-100)
 	  	  	  	  	   End
 	  	  	       End           
 	  	  	  	 End
 	  	    End
 	     Else
 	  	   Begin
 	  	  	 Select 'Failed - Invalid Production Unit'
 	  	  	 Return (-100)
 	  	   End
 	    End           
 	 Else
 	   Begin
 	  	 Select 'Failed - Invalid Production Line'
 	  	 Return (-100)
 	   End
   End 
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Cause Tree Data  	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
If @Cause_Required = 1 And @Cause_Tree_Name Is Not Null And @Cause_Tree_Name <> ''
  Begin
     Select @Cause_Tree_Id = Tree_Name_Id
     From Event_Reason_Tree
     Where Tree_Name = @Cause_Tree_Name
     If @Cause_Tree_Id Is Not Null
       Begin
          Select @Parent_Reason_Id  	  	 = Null,
 	         @PERTD_ID  	 = Null,
 	         @Reason_Level 	  	  	 = 1
          While @Reason_Level <= @Reason_Levels
            Begin
               Select @Reason_Id  	  	  	 = Null,
                          @ERTD_ID  	 = Null
               /* Get Reason Names */
               Select @Reason_Name = Case @Reason_Level
 	  	  	  	  	 When 1 Then @Default_Cause_Name1
 	  	  	  	  	 When 2 Then @Default_Cause_Name2
 	  	  	  	  	 When 3 Then @Default_Cause_Name3
 	  	  	  	  	 When 4 Then @Default_Cause_Name4
 	  	  	  	  	 Else Null
 	  	  	 End
               /* Get Reason Id  */
               If @Reason_Name Is Not Null And @Reason_Name <> ''
                 Begin
                    Select @Reason_Id = Event_Reason_Id
                    From Event_Reasons
                    Where Event_Reason_Name = @Reason_Name
                    If @Reason_Id Is Not Null
                         Begin
                         /* Validate Tree Structure */
                         Select @ERTD_ID = Event_Reason_Tree_Data_Id
                         From Event_Reason_Tree_Data
                         Where Tree_Name_Id = @Cause_Tree_Id And Event_Reason_Id = @Reason_Id And
 	  	          ((Event_Reason_Level = 1 And Parent_Event_Reason_Id Is Null And Parent_Event_R_Tree_Data_Id Is Null) Or
                                    (Event_Reason_Level = @Reason_Level And Parent_Event_Reason_Id = @Parent_Reason_Id And Parent_Event_R_Tree_Data_Id = @PERTD_ID))
                         If @ERTD_ID Is Null
                           Begin
                              Select 'Failed - Invalid cause tree structure'
                              Return (-100)
                           End
                         Select @Parent_Reason_Id = @Reason_Id,@PERTD_ID = @ERTD_ID
                      End
                    Else
                      Begin
                         Select 'Failed - cause tree reason not found'
                         Return (-100)
                      End
                 End
               Else
                 Break
               /* Assign Reason Id */
               If @Reason_Level = 1
                    Select @Default_Cause_Id1 = @Reason_Id
               Else If @Reason_Level = 2
                    Select @Default_Cause_Id2 = @Reason_Id
               Else If @Reason_Level = 3
                    Select @Default_Cause_Id3 = @Reason_Id
               Else If @Reason_Level = 4
                    Select @Default_Cause_Id4 = @Reason_Id
               Select @Reason_Level = @Reason_Level + 1
            End
       End
     Else
       Begin
 	  	 Select 'Failed - Cause tree not found'
 	  	 Return (-100)
       End
     End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Action Tree Data  	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
If @Action_Required = 1 And @Action_Tree_Name Is Not Null And @Action_Tree_Name <> ''
  Begin
     Select @Action_Tree_Id = Tree_Name_Id
     From Event_Reason_Tree
     Where Tree_Name = @Action_Tree_Name
     If @Action_Tree_Id Is Not Null
       Begin
          Select @Parent_Reason_Id  	  	 = Null,
                     @PERTD_ID  	 = Null,
                     @Reason_Level 	  	  	 = 1
          While @Reason_Level <= @Reason_Levels
            Begin
               Select @Reason_Id = Null,@ERTD_ID = Null
               /* Get Reason Names */
               Select @Reason_Name = Case @Reason_Level
 	  	  	  	  	 When 1 Then @Default_Action_Name1
 	  	  	  	  	 When 2 Then @Default_Action_Name2
 	  	  	  	  	 When 3 Then @Default_Action_Name3
 	  	  	  	  	 When 4 Then @Default_Action_Name4
 	  	  	  	  	 Else Null
 	  	  	  	  	 End
               /* Get Reason Id  */
               If @Reason_Name Is Not Null And @Reason_Name <> ''
                 Begin
                    Select @Reason_Id = Event_Reason_Id
                    From Event_Reasons
                    Where Event_Reason_Name = @Reason_Name
                    If @Reason_Id Is Not Null
                      Begin
                         /* Validate Tree Structure */
                         Select @ERTD_ID = Event_Reason_Tree_Data_Id
                         From Event_Reason_Tree_Data
                         Where Tree_Name_Id = @Action_Tree_Id And Event_Reason_Id = @Reason_Id And
 	  	          ((Event_Reason_Level = 1 And Parent_Event_Reason_Id Is Null And Parent_Event_R_Tree_Data_Id Is Null) Or
                                    (Event_Reason_Level = @Reason_Level And Parent_Event_Reason_Id = @Parent_Reason_Id And Parent_Event_R_Tree_Data_Id = @PERTD_ID))
                         If @ERTD_ID Is Null
                           Begin
                              Select 'Failed - Invalid action tree structure'
                              Return (-100)
                           End
                         Select @Parent_Reason_Id = @Reason_Id,@PERTD_ID = @ERTD_ID
                      End
                    Else
                      Begin
                        Select 'Failed - Action tree reason not found'
                        Return (-100)
                      End
                 End
               Else
                    Break
               /* Assign Reason Id */
               If @Reason_Level = 1
                    Select @Default_Action_Id1 = @Reason_Id
               Else If @Reason_Level = 2
                    Select @Default_Action_Id2 = @Reason_Id
               Else If @Reason_Level = 3
                    Select @Default_Action_Id3 = @Reason_Id
               Else If @Reason_Level = 4
                    Select @Default_Action_Id4 = @Reason_Id
               Select @Reason_Level = @Reason_Level + 1
            End
       End
     Else
       Begin
 	  	 Select 'Failed - Action tree not found'
 	  	 Return (-100)
       End
     End
/******************************************************************************************************************************************************
*  	  	  	  	  	 Insert/Update Alarm Template  	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
If @AT_Desc Is Not Null And @AT_Desc <> ''
  Begin
     /* Check for existing tempate */
 	 Select @Comment_Id = Null
 	 Select @AT_Id = AT_Id,@Comment_Id = Comment_Id From Alarm_Templates
    Where AT_Desc = @AT_Desc
 	 If @AT_Id Is Null
 	   Begin
 	  	 Insert into Alarm_Templates(AT_Desc, AP_Id) values (@AT_Desc, 1)
 	  	 Select @AT_Id = AT_Id From Alarm_Templates
 	      	   Where AT_Desc = @AT_Desc
 	  	 If @AT_Id is Null
 	  	   Begin
 	  	  	 Select 'Failed - Unable to create new Alarm Template'
 	  	  	 return (-100)
 	  	   End
 	   End
 	 Update Alarm_Templates
 	  	  	  Set Custom_Text 	 = @Custom_Text,Use_Var_Desc = @Use_Var_Desc,
 	  	  	  	  Use_AT_Desc = @Use_AT_Desc, Use_Trigger_Desc = @Use_Trigger_Desc,DQ_Var_Id 	 = @DQ_Var_Id,
 	  	  	  	  DQ_Criteria = @DQ_Criteria_Id, DQ_Value = @DQ_Value,Cause_Required 	 = @Cause_Required,
 	  	  	      Cause_Tree_Id = @Cause_Tree_Id, Default_Cause1 	 = @Default_Cause_Id1,Default_Cause2 	 = @Default_Cause_Id2,
 	  	  	  	  Default_Cause3 	 = @Default_Cause_Id3,Default_Cause4 	 = @Default_Cause_Id4,Action_Required= @Action_Required,
 	  	  	  	  Action_Tree_Id 	 = @Action_Tree_Id,Default_Action1 = @Default_Action_Id1,Default_Action2 	 = @Default_Action_Id2,
 	  	  	  	  Default_Action3 = @Default_Action_Id3,Default_Action4 = @Default_Action_Id4,Alarm_Type_Id = @iAlarmType, 
 	  	  	  	  ESignature_Level = @iEsigLevel,sp_Name = @SpName, String_Specification_Setting= @iSpecSetting
           Where AT_Id = @AT_Id
 	 If @Comment_Text <> '' and @Comment_Text is not null
 	   Begin
 	  	 If @Comment_Id is null
 	  	   Begin
 	  	  	 Insert into comments(Comment,User_Id,CS_Id,Modified_On) 
 	  	  	  	 Select '',@User_Id,1,dbo.fnServer_CmnGetDate(getUTCdate())
 	  	  	 Select @Comment_Id = Scope_Identity()
 	  	  	 If @Comment_Id is Not null
 	  	  	    Update Alarm_Templates set comment_Id = @Comment_Id Where AT_Id = @AT_Id
 	  	   End
 	  	 If @Comment_Id Is not Null
 	  	   Update Comments set comment_text = @Comment_Text,Comment = @Comment_Text  Where Comment_Id = @Comment_Id 
 	   End 
  End
Else
  Begin
 	 Select 'Failed- Template Description Missing '
 	 Return (-100)
  End
RETURN(0)
