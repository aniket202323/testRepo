CREATE PROCEDURE dbo.spEM_IEImportEventSubTypes
@ET_Desc 	  	  	  	  	 nvarchar(50),
@Event_Subtype_Desc 	  	  	 nvarchar(50),
@Event_Mask 	  	  	  	  	 nvarchar(50),
@Dimension_X_Name 	  	  	 nvarchar(50),
@Dimension_X_Eng_Units 	  	 nvarchar(50),
@Dimension_Y_Enabled_Str 	 nvarchar(50),
@Dimension_Y_Name 	  	  	 nvarchar(50),
@Dimension_Y_Eng_Units 	  	 nvarchar(50),
@Dimension_Z_Enabled_Str 	 nvarchar(50),
@Dimension_Z_Name 	  	  	 nvarchar(50),
@Dimension_Z_Eng_Units 	  	 nvarchar(50),
@Dimension_A_Enabled_Str 	 nvarchar(50),
@Dimension_A_Name 	  	  	 nvarchar(50),
@Dimension_A_Eng_Units 	  	 nvarchar(50),
@Ack_Required_Str 	  	  	 nvarchar(50),
@Duration_Required_Str 	  	 nvarchar(50),
@Cause_Required_Str 	  	  	 nvarchar(50),
@Cause_Tree_Name 	  	  	 nvarchar(50),
@Default_Cause1 	  	  	  	 nvarchar(50),
@Default_Cause2 	  	  	  	 nvarchar(50),
@Default_Cause3 	  	  	  	 nvarchar(50),
@Default_Cause4 	  	  	  	 nvarchar(50),
@Action_Required_Str 	  	 nvarchar(50),
@Action_Tree_Name 	  	  	 nvarchar(50),
@Default_Action1 	  	  	 nvarchar(50),
@Default_Action2 	  	  	 nvarchar(50),
@Default_Action3 	  	  	 nvarchar(50),
@Default_Action4 	  	  	 nvarchar(50),
@Icon_Desc 	  	  	  	  	 nvarchar(50),
@Comment_Text 	  	  	  	 nvarchar(255),
@EsigLevel 	  	  	  	  	 nvarchar(50),
@UserId 	  	  	  	  	  	 int
AS
Declare 	 @ET_Id 	  	  	  	 int,
 	 @Comment_Id 	  	  	  	 int,
 	 @Dimension_Y_Enabled 	 bit,
 	 @Dimension_Z_Enabled 	 bit,
 	 @Dimension_A_Enabled 	 bit,
 	 @Ack_Required 	  	  	 bit,
 	 @Duration_Required 	  	 bit,
 	 @Cause_Required 	  	  	 bit,
 	 @Cause_Tree_Id 	  	  	 Int,
 	 @Id1 	  	  	  	  	 int,
 	 @Id2 	  	  	  	  	 int,
 	 @Id3 	  	  	  	  	 int,
 	 @Id4 	  	  	  	  	 int,
 	 @Action_Required 	  	 bit,
 	 @Action_Tree_Id 	  	  	 int,
 	 @Icon_Id 	  	  	  	 int,
 	 @Event_Subtype_Id 	  	 int,
 	 @TreeCheck 	  	  	  	 Int,
 	 @Subtypes_Apply 	  	 Int,
 	 @Dimension_X_Id 	  	 Int,
 	 @Dimension_Y_Id 	  	 Int,
 	 @Dimension_Z_Id 	  	 Int,
 	 @Dimension_A_Id 	  	 Int,
 	 @iEsigLevel 	  	  	 Int
/* Initialize */
Select 	 @ET_Id 	  	  	  	 = Null,
 	 @Comment_Id 	  	  	  	 = Null,
 	 @Dimension_Y_Enabled 	 = Null,
 	 @Dimension_Z_Enabled 	 = Null,
 	 @Dimension_A_Enabled 	 = Null,
 	 @Ack_Required 	  	  	 = Null,
 	 @Duration_Required 	  	 = Null,
 	 @Cause_Required 	  	  	 = Null,
 	 @Cause_Tree_Id 	  	  	 = Null,
 	 @Id1 	  	 = Null,
 	 @Id2 	  	 = Null,
 	 @Id3 	  	 = Null,
 	 @Id4 	  	 = Null,
 	 @Action_Required 	  	 = Null,
 	 @Action_Tree_Id 	  	  	 = Null,
 	 @Icon_Id 	  	  	  	 = Null
/* Clean Arguments */
Select 	 @ET_Desc 	  	  	 = LTrim(RTrim(@ET_Desc)),
 	 @Event_Subtype_Desc 	  	 = LTrim(RTrim(@Event_Subtype_Desc)),
 	 @Event_Mask 	  	  	  	 = LTrim(RTrim(@Event_Mask)),
 	 @Comment_Text 	  	  	 = LTrim(RTrim(@Comment_Text)),
 	 @Dimension_X_Name 	  	 = LTrim(RTrim(@Dimension_X_Name)),
 	 @Dimension_X_Eng_Units 	 = LTrim(RTrim(@Dimension_X_Eng_Units)),
 	 @Dimension_Y_Enabled_Str= LTrim(RTrim(@Dimension_Y_Enabled_Str)),
 	 @Dimension_Y_Name 	  	 = LTrim(RTrim(@Dimension_Y_Name)),
 	 @Dimension_Y_Eng_Units 	 = LTrim(RTrim(@Dimension_Y_Eng_Units)),
 	 @Dimension_Z_Enabled_Str= LTrim(RTrim(@Dimension_Z_Enabled_Str)),
 	 @Dimension_Z_Name 	  	 = LTrim(RTrim(@Dimension_Z_Name)),
 	 @Dimension_Z_Eng_Units 	 = LTrim(RTrim(@Dimension_Z_Eng_Units)),
 	 @Dimension_A_Enabled_Str= LTrim(RTrim(@Dimension_A_Enabled_Str)),
 	 @Dimension_A_Name 	  	 = LTrim(RTrim(@Dimension_A_Name)),
 	 @Dimension_A_Eng_Units 	 = LTrim(RTrim(@Dimension_A_Eng_Units)),
 	 @Ack_Required_Str 	  	 = LTrim(RTrim(@Ack_Required_Str)),
 	 @Duration_Required_Str 	 = LTrim(RTrim(@Duration_Required_Str)),
 	 @Cause_Required_Str 	  	 = LTrim(RTrim(@Cause_Required_Str)),
 	 @Cause_Tree_Name 	  	 = LTrim(RTrim(@Cause_Tree_Name)),
 	 @Default_Cause1 	  	  	 = LTrim(RTrim(@Default_Cause1)),
 	 @Default_Cause2 	  	  	 = LTrim(RTrim(@Default_Cause2)),
 	 @Default_Cause3 	  	  	 = LTrim(RTrim(@Default_Cause3)),
 	 @Default_Cause4 	  	  	 = LTrim(RTrim(@Default_Cause4)),
 	 @Action_Required_Str 	 = LTrim(RTrim(@Action_Required_Str)),
 	 @Action_Tree_Name 	  	 = LTrim(RTrim(@Action_Tree_Name)),
 	 @Default_Action1 	  	 = LTrim(RTrim(@Default_Action1)),
 	 @Default_Action2 	  	 = LTrim(RTrim(@Default_Action2)),
 	 @Default_Action3 	  	 = LTrim(RTrim(@Default_Action3)),
 	 @Default_Action4 	  	 = LTrim(RTrim(@Default_Action4)),
 	 @EsigLevel 	  	  	  	 = LTrim(RTrim(@EsigLevel)),
 	 @Icon_Desc 	  	  	  	 = LTrim(RTrim(@Icon_Desc))
Select @Dimension_X_Id = Null
Select @Dimension_Y_Id = Null
Select @Dimension_Z_Id = Null
Select @Dimension_A_Id = Null
IF @EsigLevel = '' SELECT @EsigLevel = Null
IF @Icon_Desc = '' SELECT @Icon_Desc = Null
IF @Icon_Desc Is Not NULL
BEGIN
 	 SELECT @Icon_Id = Icon_Id From Icons WHERE Icon_Desc = @Icon_Desc
 	 IF @Icon_Id Is Null
 	 BEGIN
 	  	 Select 'Failed - Icon Not Found'
 	  	 Return(-100)
 	 END
END
If  @EsigLevel Is null
 	 Select @iEsigLevel = Null
ELSE
BEGIN
 	 Select @iEsigLevel = Case @EsigLevel When 'User Level' Then 1
 	  	  	  	  	  	  	 When 'Approver Level' Then 2
 	  	  	  	  	  	  	 When 'Undefined' 	 Then 0
 	  	  	  	  	  	  	 Else -2
 	  	  	  	  	  	  End
 	 If @iEsigLevel = -2 
 	 BEGIN
 	  	 Select 'Failed - ESignature is not correct'
 	  	 RETURN (-100)
 	 END
END
If @Dimension_X_Eng_Units Is Not Null
  Begin
 	 Select @Dimension_X_Id = Eng_Unit_Id From engineering_Unit Where Eng_Unit_Code = @Dimension_X_Eng_Units
 	 If @Dimension_X_Id Is null
 	  	 Execute spEM_EUCreate  @Dimension_X_Eng_Units,@Dimension_X_Eng_Units,@UserId,@Dimension_X_Id OUTPUT
  End
If @Dimension_Y_Eng_Units Is Not Null
  Begin
 	 Select @Dimension_Y_Id = Eng_Unit_Id From engineering_Unit Where Eng_Unit_Code = @Dimension_Y_Eng_Units
 	 If @Dimension_Y_Id Is null
 	  	 Execute spEM_EUCreate  @Dimension_Y_Eng_Units,@Dimension_Y_Eng_Units,@UserId,@Dimension_Y_Id OUTPUT
  End
If @Dimension_Z_Eng_Units Is Not Null
  Begin
 	 Select @Dimension_Z_Id = Eng_Unit_Id From engineering_Unit Where Eng_Unit_Code = @Dimension_Z_Eng_Units
 	 If @Dimension_Z_Id Is null
 	  	 Execute spEM_EUCreate  @Dimension_Z_Eng_Units,@Dimension_Z_Eng_Units,@UserId,@Dimension_Z_Id OUTPUT
  End
If @Dimension_A_Eng_Units Is Not Null
  Begin
 	 Select @Dimension_A_Id = Eng_Unit_Id From engineering_Unit Where Eng_Unit_Code = @Dimension_A_Eng_Units
 	 If @Dimension_A_Id Is null
 	  	 Execute spEM_EUCreate  @Dimension_A_Eng_Units,@Dimension_A_Eng_Units,@UserId,@Dimension_A_Id OUTPUT
  End
/* Get Configuration Data */
Select @ET_Id = ET_Id,@Subtypes_Apply = Subtypes_Apply
From Event_Types
Where ET_Desc = @ET_Desc
Select @Event_Subtype_Id = Event_Subtype_Id,@Comment_Id = Comment_Id
From Event_Subtypes
Where Event_Subtype_Desc = @Event_Subtype_Desc
If @ET_Id Is Null or @Subtypes_Apply = 0
  Begin
    Select 'Failed - invalid event type'
    Return(-100)
  End
If @ET_Id = 14 -- User defined
  Begin
 	 If @Ack_Required_Str = '1'
 	      Select @Ack_Required = 1
 	 Else If @Ack_Required_Str = '0' Or @Ack_Required_Str Is Null
 	      Select @Ack_Required = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid Action Required'
 	     Return(-100)
 	  End
 	 If @Duration_Required_Str = '1'
 	      Select @Duration_Required = 1
 	 Else If @Duration_Required_Str = '0' Or @Duration_Required_Str Is Null
 	      Select @Duration_Required = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid Duration Required'
 	     Return(-100)
 	  End
 	 If @Cause_Required_Str = '1'
 	      Select @Cause_Required = 1
 	 Else If @Cause_Required_Str = '0' Or @Cause_Required_Str Is Null
 	      Select @Cause_Required = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid Cause Required'
 	     Return(-100)
 	  End
 	 
 	 If @Action_Required_Str = '1'
 	      Select @Action_Required = 1
 	 Else If @Action_Required_Str = '0' Or @Action_Required_Str Is Null
 	      Select @Action_Required = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid Action Required'
 	     Return(-100)
 	  End
 	 Execute spEMEC_UpdateUDEEvent @Event_Subtype_Id,@Event_Subtype_Desc,@Icon_Id,@Duration_Required,
 	  	 @Cause_Required,@Action_Required,@Ack_Required,@iEsigLevel,@UserId,@Event_Subtype_Id OUTPUT
 	 If @Cause_Required = 1 and @Cause_Tree_Name is not null  and @Cause_Tree_Name <> ''
 	   Begin
 	  	  SELECT @Id1 = Null,@Id2 = Null,@Id3 = Null,@Id4 = Null, 	 @TreeCheck = Null
 	  	  EXECUTE spEM_IEFindERTDataId @Cause_Tree_Name,@Default_Cause1,@Default_Cause2,@Default_Cause3,@Default_Cause4,
 	  	  	  	  	  	  	 @Id1  Output,@Id2  Output,@Id3  Output,@Id4  Output,@Cause_Tree_Id Output,@TreeCheck  Output
 	  	 If @Cause_Tree_Id is null
 	  	  Begin
 	  	     Select 'Failed - invalid cause tree'
 	  	     Return(-100)
 	  	  End
 	  	  IF @Default_Cause1 Is Not Null and @Id1 Is Null
 	  	  BEGIN
 	  	  	 Select 'Failed - invalid Cause reason level 1'
 	  	  	 Return(-100) 	  	   
 	  	  END
 	  	  IF @Default_Cause2 Is Not Null and @Id2 Is Null
 	  	  BEGIN
 	  	  	 Select 'Failed - invalid Cause reason level 2'
 	  	  	 Return(-100) 	  	   
 	  	  END
 	  	  IF @Default_Cause3 Is Not Null and @Id3 Is Null
 	  	  BEGIN
 	  	  	 Select 'Failed - invalid Cause reason level 3'
 	  	  	 Return(-100) 	  	   
 	  	  END
 	  	  IF @Default_Cause4 Is Not Null and @Id4 Is Null
 	  	  BEGIN
 	  	  	 Select 'Failed - invalid Cause reason level 4'
 	  	  	 Return(-100) 	  	   
 	  	  END
 	  	 Execute spEMEC_UpdateDefaultReasons @Event_Subtype_Id,@UserId, 0,@Cause_Tree_Id,@Id1,@Id2,@Id3,@Id4
 	   End
 	 If @Action_Required = 1 and @Action_Tree_Name is not null  and @Action_Tree_Name <> ''
 	 Begin
 	  	 SELECT @Id1 = Null,@Id2 = Null,@Id3 = Null,@Id4 = Null, 	 @TreeCheck = Null
 	  	 EXECUTE spEM_IEFindERTDataId @Action_Tree_Name,@Default_Action1,@Default_Action2,@Default_Action3,@Default_Action4,
 	  	  	  	  	  	  	 @Id1  Output,@Id2  Output,@Id3  Output,@Id4  Output,@Action_Tree_Id Output,@TreeCheck  Output
 	  	 If @Action_Tree_Id is null
 	  	  Begin
 	  	     Select 'Failed - invalid action tree'
 	  	     Return(-100)
 	  	  End
 	  	  IF @Default_Action1 Is Not Null and @Id1 Is Null
 	  	  BEGIN
 	  	  	 Select 'Failed - invalid Action reason level 1'
 	  	  	 Return(-100) 	  	   
 	  	  END
 	  	  IF @Default_Action2 Is Not Null and @Id2 Is Null
 	  	  BEGIN
 	  	  	 Select 'Failed - invalid Action reason level 2'
 	  	  	 Return(-100) 	  	   
 	  	  END
 	  	  IF @Default_Action3 Is Not Null and @Id3 Is Null
 	  	  BEGIN
 	  	  	 Select 'Failed - invalid Action reason level 3'
 	  	  	 Return(-100) 	  	   
 	  	  END
 	  	  IF @Default_Action4 Is Not Null and @Id4 Is Null
 	  	  BEGIN
 	  	  	 Select 'Failed - invalid Action reason level 4'
 	  	  	 Return(-100) 	  	   
 	  	  END
 	  	 Execute spEMEC_UpdateDefaultReasons @Event_Subtype_Id,@UserId,1,@Action_Tree_Id,@Id1,@Id2,@Id3,@Id4
 	   End
  End
Else
  Begin
    If @Dimension_Y_Enabled_Str = '1'
     Select @Dimension_Y_Enabled = 1
 	 Else If @Dimension_Y_Enabled_Str = '0'  Or @Dimension_Y_Enabled_Str Is Null
     Select @Dimension_Y_Enabled = 0
 	 Else
  	 Begin
      Select 'Failed - invalid dimension Y enabled'
      Return(-100)
  	 End
 	 If @Dimension_Z_Enabled_Str = '1'
 	      Select @Dimension_Z_Enabled = 1
 	 Else If @Dimension_Z_Enabled_Str = '0'  Or @Dimension_Z_Enabled_Str Is Null
 	      Select @Dimension_Z_Enabled = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid dimension Z enabled'
 	     Return(-100)
 	  End
 	 If @Dimension_A_Enabled_Str = '1'
 	      Select @Dimension_A_Enabled = 1
 	 Else If @Dimension_A_Enabled_Str = '0'  Or @Dimension_A_Enabled_Str Is Null
 	      Select @Dimension_A_Enabled = 0
 	 Else
 	  Begin
 	     Select 'Failed - invalid dimension A enabled'
 	     Return(-100)
 	  End
  Execute spEMEC_UpdateProdEvent @Event_Subtype_Id,@Event_Subtype_Desc,@Event_Mask,@Dimension_A_Enabled,@Dimension_A_Name,
 	 @Dimension_A_Id,@Dimension_X_Name, @Dimension_X_Id,@Dimension_Y_Enabled, @Dimension_Y_Name, @Dimension_Y_Id,
 	 @Dimension_Z_Enabled, @Dimension_Z_Name, @Dimension_Z_Id,@UserId,@Event_Subtype_Id OUTPUT
End
If @Event_Subtype_Id Is Null
  Begin
     Select 'Failed - could not create event subtype'
     Return (-100) 
  End
If @Comment_Text is Not Null
Begin
 	 If @Comment_Id is null
 	 Begin
 	  	 INSERT INTO Comments (Comment,  User_Id, Modified_On, CS_Id) 
 	  	  	  	 SELECT @Comment_Text, @UserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
 	  	 SELECT @Comment_Id = Scope_Identity()
 	  	 If @Comment_Id is Not null
 	  	  	 Update Event_Subtypes set comment_Id = @Comment_Id Where Event_Subtype_Id = @Event_Subtype_Id
 	 End
 	 If @Comment_Id Is not Null
 	  	 Update Comments set comment_text = @Comment_Text,Comment = @Comment_Text  Where Comment_Id = @Comment_Id 
End 
Return (0)
SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON 
