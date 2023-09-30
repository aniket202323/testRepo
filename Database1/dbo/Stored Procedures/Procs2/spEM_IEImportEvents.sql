CREATE PROCEDURE dbo.spEM_IEImportEvents
@PL_Desc 	  	  	  	 nvarchar(50),
@PU_Desc 	  	  	  	 nvarchar(50),
@ET_Desc 	  	  	  	 nvarchar(50),
@Event_Subtype_Desc 	  	 nvarchar(50),
@EC_Desc 	  	  	  	 nvarchar(255),
@Extended_Info 	  	  	 nvarchar(255),
@Exclusions 	  	  	  	 nvarchar(255),
@Comment_Text 	  	  	 nvarchar(255),
@InputName 	  	  	  	 nVarChar(100),
@ModelNum 	  	  	  	 nVarChar(10),
@EsigLevel 	  	  	  	 nvarchar(50),
@ExternalTZ 	  	  	  	 nvarchar(50),
@MaxRunTime 	  	  	  	 nVarChar(10),
@MoveEndTimeInterval 	 nVarChar(10),
@User_Id 	  	  	  	 int
AS
--delete from local_debug
Declare 	 @PL_Id 	  	  	  	  	 int,
 	  	 @PU_Id 	  	  	  	  	 int,
 	  	 @ET_Id 	  	  	  	  	 int,
 	  	 @Event_Subtype_Id 	  	 int,
 	  	 @Comment_Id 	  	  	  	 int,
 	  	 @EC_Id 	  	  	  	  	 Int,
 	  	 @PEI_Id 	  	  	  	  	 Int,
 	  	 @ED_Model_Id 	  	  	 Int,
 	  	 @InputOrder  	  	  	 Int, 
 	  	 @iESigLevel 	  	  	  	 Int,
 	  	 @iMaxRunTime 	  	  	 Int,
 	  	 @iMoveEndTimeInterval 	 Int,
 	  	 @Allow_Multiple_Active 	 bit
/* Initialize */
Select 	 @ET_Id 	  	 = Null,
 	 @PL_Id 	  	  	 = Null,
 	 @PU_Id 	  	 = Null,
 	 @Event_Subtype_Id 	 = Null,
 	 @Comment_Id 	  	 = Null,
 	 @PEI_Id = Null,
 	 @ED_Model_Id = null
/* Clean Arguments */
Select 	 @ET_Desc 	  	  	  	 = LTrim(RTrim(@ET_Desc)),
 	  	 @Event_Subtype_Desc 	  	 = LTrim(RTrim(@Event_Subtype_Desc)),
 	  	 @PL_Desc 	  	  	  	 = LTrim(RTrim(@PL_Desc)),
 	  	 @PU_Desc 	  	  	  	 = LTrim(RTrim(@PU_Desc)),
 	  	 @Comment_Text 	  	  	 = LTrim(RTrim(@Comment_Text)),
 	  	 @EC_Desc 	  	  	  	 = LTrim(RTrim(@EC_Desc)),
 	  	 @Extended_Info 	  	  	 = LTrim(RTrim(@Extended_Info)),
 	  	 @Exclusions 	  	  	  	 = LTrim(RTrim(@Exclusions)),
 	  	 @EsigLevel 	  	  	  	 = LTrim(RTrim(@EsigLevel)),
 	  	 @ExternalTZ 	  	  	  	 = LTrim(RTrim(@ExternalTZ)),
 	  	 @MaxRunTime 	  	  	  	 = LTrim(RTrim(@MaxRunTime)),
 	  	 @MoveEndTimeInterval 	 = LTrim(RTrim(@MoveEndTimeInterval))
If @EsigLevel = '' 	  	  	  	 Select @EsigLevel = Null
If @ExternalTZ = '' 	  	  	  	 Select @ExternalTZ = Null
If @MaxRunTime = '' 	  	  	  	 Select @MaxRunTime = Null
If @MoveEndTimeInterval = '' 	 Select @MoveEndTimeInterval = Null
If  @EsigLevel Is null
 	 Select @iESigLevel = Null
ELSE
BEGIN
 	 Select @iESigLevel = Case @EsigLevel When 'User Level' Then 1
 	  	  	  	  	  	  	 When 'Approver Level' Then 2
 	  	  	  	  	  	  	 Else Null
 	  	  	  	  	  	  End
END
-- Validate good time zone
if (@ExternalTZ is not null)
 	 if (not Exists(select * from TimeZoneTranslations where TimeZone like @ExternalTZ))
 	  	 Set @ExternalTZ = null
begin try
 	 Set @iMaxRunTime = Case When @MaxRunTime IS null then null else CONVERT(int, @MaxRunTime) end
end try
begin catch
 	 Set @iMaxRunTime = null
end catch
begin try
 	 Set @iMoveEndTimeInterval = Case When @MoveEndTimeInterval IS null then null else CONVERT(int, @MoveEndTimeInterval) end
end try
begin catch
 	 Set @iMoveEndTimeInterval = null
end catch
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Configuration Ids 	  	  	  	  	  	  	 *
******************************************************************************************************************************************************/
If @Comment_Text Is Null 	 Select @Comment_Text = ''
Select @ET_Id = ET_Id
From Event_Types
Where ET_Desc = @ET_Desc
If @ET_Id Is Null
   Begin
     Select 'Failed - Event Type Not Found'
     Return(-100)
   End
If @Event_Subtype_Desc Is Not Null And @Event_Subtype_Desc <> ''
  Begin
     Select @Event_Subtype_Id = Event_Subtype_Id
     From Event_Subtypes
     Where Event_Subtype_Desc = @Event_Subtype_Desc
     If @Event_Subtype_Id Is Null
        Begin
          Select 'Failed - Event Subtype not Found'
          Return (-100)
        End
   End
If @PL_Desc Is Not Null And @PL_Desc <> ''
   Begin
     Select @PL_Id = PL_Id
     From Prod_Lines
     Where PL_Desc = @PL_Desc
     If @PL_Id Is Not Null
       Begin
          If @PU_Desc Is Not Null And @PU_Desc <> ''
            Begin
               Select @PU_Id = PU_Id
               From Prod_Units
               Where PU_Desc = @PU_Desc And PL_Id = @PL_Id
               If @PU_Id Is Null
                 Begin
                    Select 'Failed - Invalid Production Unit'
                    Return (-100)
                 End
            End           
       End
     Else
       Begin
 	  	 Select 'Failed - Invalid Production Line'
 	     Return (-100)
       End
   End 
If @InputName is not null and @InputName <> ''
  Begin
 	 Select @PEI_Id = PEI_Id from Prdexec_inputs Where  Input_Name = @InputName and PU_Id = @PU_Id
 	 If @PEI_Id is null
 	   Begin
 	  	 If @Event_Subtype_Id is Null
 	  	   Begin
 	  	  	 Select 'Failed - Event Subtype is missing'
 	  	  	 Return (-100)
 	  	   End
 	  	 Select @InputOrder = Max(Input_Order) + 1 from Prdexec_inputs Where PU_Id = @PU_Id
 	  	 Select @InputOrder = isnull(@InputOrder,1)
     	  	 Insert  into prdexec_inputs (input_name, input_order, pu_id, event_subtype_id, primary_spec_id, alternate_spec_id, lock_inprogress_input)
       	  	 values(@InputName, @InputOrder, @PU_Id, @Event_Subtype_Id, Null, Null, 1)
 	  	 Select @PEI_Id = PEI_Id from Prdexec_inputs Where  Input_Name = @InputName and PU_Id = @PU_Id
 	   End
  End
If @ModelNum is not null and @ModelNum <> ''
  Begin
 	 Select @ED_Model_Id = ED_Model_Id From Ed_Models where model_Num = @ModelNum
 	 If @ED_Model_Id is null
 	   Begin
 	  	 Select 'Failed - Model Number incorrect'
 	     Return (-100)
 	   End
  End
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Create Input     	  	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
Select @EC_Id = EC_Id, @Allow_Multiple_Active = Allow_Multiple_Active
From Event_Configuration c
Join Event_Types t on t.ET_Id = @ET_Id
Where c.PU_Id = @PU_Id And c.ET_Id = @ET_Id
If @EC_Id Is Null
BEGIN
 	 Execute spEMEC_CreateNewEC @PU_Id,0,@EC_Desc,@ET_Id,@Event_Subtype_Id,@User_Id,@EC_Id  OUTPUT
 	 If @EC_Id is not null
 	   Begin
 	  	 Execute spEMEC_UpdEventConfigAdvanced @EC_Id,@Extended_Info,@Exclusions,@User_Id
 	  	 Execute spEMEC_UpdateAssignModel @EC_Id,@ED_Model_Id,@PU_Id,@User_Id
 	  	 If @ET_Id = 2 or @ET_Id = 3 Execute spEMEC_GetCurrDetESigLevel @EC_Id,2,@iESigLevel,@User_Id
 	  	 Select @Comment_Id = Comment_Id From Event_Configuration where ec_Id = @EC_Id
 	  	 Update comments set comment_Text = @Comment_Text,comment = @Comment_Text Where Comment_Id = @Comment_Id
 	  	 Update Event_Configuration
 	  	   set PEI_ID = @PEI_Id, External_Time_Zone = @ExternalTZ, Max_Run_Time = @iMaxRunTime, Move_EndTime_Interval = @iMoveEndTimeInterval
 	  	   where Ec_Id  = @Ec_Id
 	   End
 	 Else
 	   Begin
 	  	 Select 'Failed - Unable to create event (multiples not allowed)'
 	  	 Return (-100)
 	   End
END
Else If @Allow_Multiple_Active = 1 
 	 Begin
 	  	 SELECT @EC_Id = Null
 	  	 IF @PEI_ID Is Not Null
 	  	 BEGIN
 	  	  	 SELECT @EC_Id = EC_Id
 	  	  	  	 From Event_Configuration ec
 	  	  	  	 Join ed_Models ed on ed.ED_Model_Id =  ec.ED_Model_Id
 	  	  	  	 Where ec.PU_Id = @PU_Id and ec.PEI_ID = @PEI_ID And ec.ET_Id = @ET_Id
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SELECT @EC_Id = EC_Id
 	  	  	  	 From Event_Configuration ec
 	  	  	  	 Join ed_Models ed on ed.ED_Model_Id =  ec.ED_Model_Id
 	  	  	  	 Where ec.PU_Id = @PU_Id And (ec.EC_Desc = @EC_Desc or (ec.EC_Desc Is Null and ed.Model_Desc = @EC_Desc))
 	  	 END
 	  	  	  	 SET @EC_Id = NULL
 	  	 IF @EC_Id Is Null
 	  	 BEGIN
 	  	  	 Execute spEMEC_CreateNewEC @PU_Id,0,@EC_Desc,@ET_Id,@Event_Subtype_Id,@User_Id,@EC_Id  OUTPUT
 	  	  	 If @EC_Id is not null
 	  	  	 BEGIN
 	  	  	  	 Execute spEMEC_UpdEventConfigAdvanced @EC_Id,@Extended_Info,@Exclusions,@User_Id
 	  	  	  	 Execute spEMEC_UpdateAssignModel @EC_Id,@ED_Model_Id,@PU_Id,@User_Id
 	  	  	  	 If @ET_Id = 2 or @ET_Id = 3 Execute spEMEC_GetCurrDetESigLevel @EC_Id,2,@iESigLevel,@User_Id
 	  	  	  	 Select @Comment_Id = Comment_Id From Event_Configuration where ec_Id = @EC_Id
 	  	  	  	 Update comments set comment_Text = @Comment_Text,comment = @Comment_Text Where Comment_Id = @Comment_Id
 	  	  	  	 Update Event_Configuration
 	  	  	  	   set PEI_ID = @PEI_Id, External_Time_Zone = @ExternalTZ, Max_Run_Time = @iMaxRunTime, Move_EndTime_Interval = @iMoveEndTimeInterval
 	  	  	  	   where Ec_Id  = @Ec_Id
 	  	  	  END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to create event (multiples allowed)'
 	  	  	  	 Return (-100)
 	  	  	 END
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 Select 'Failed - Event type with the same Description /Input already exists'
 	  	  	 Return (-100)
 	  	 END
 	 End
Else 
 	 Begin
 	  Select 'Failed - Event of given type already exists'
 	  Return (-100)
 	 End
Return (0)
