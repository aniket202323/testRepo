CREATE PROCEDURE dbo.spEM_IEImportEventReasonTree
@Reason_Tree_Name 	  	 nVarchar (100),
@Reason_Level_1 	  	  	 nVarchar (100),
@Reason_Level_2 	  	  	 nVarchar (100),
@Reason_Level_3 	  	  	 nVarchar (100),
@Reason_Level_4 	  	  	 nVarchar (100),
@Add_Reasons 	  	  	 nvarchar(50),
@User_Id 	  	  	  	 Int
As
SET NOCOUNT ON
Declare 	 @Event_Reason_Id 	  	 int,
 	  	 @iAddReason 	  	  	  	 int,
 	  	 @Tree_Id 	  	  	  	 Int,
 	  	 @Ecrd_Id 	  	  	  	 Int,
 	  	 @NextEcrd_Id 	  	  	 Int
/* Initialization */
Select  	 @Event_Reason_Id  	 = Null,
 	  	 @Tree_Id 	  	  	 = Null
/* Clean arguments */
Select  	 @Reason_Tree_Name  	 = RTrim(LTrim(@Reason_Tree_Name)),
 	  	 @Reason_Level_1  	 = RTrim(LTrim(@Reason_Level_1)),
 	  	 @Reason_Level_2  	 = RTrim(LTrim(@Reason_Level_2)),
 	  	 @Reason_Level_3  	 = RTrim(LTrim(@Reason_Level_3)),
 	  	 @Reason_Level_4 	  	 = RTrim(LTrim(@Reason_Level_4)),
 	  	 @Add_Reasons 	  	 = RTrim(LTrim(@Add_Reasons))
If @Add_Reasons = '0'
 	 Select @iAddReason = 0
Else If  @Add_Reasons = '1'
 	 Select @iAddReason = 1
Else
  Begin
 	 Select 'Failed - Add Reasons must be True / False'
 	 Return (-100)
  End
If @Reason_Tree_Name = '' or @Reason_Tree_Name Is Null
  Begin
 	 Select 'Failed - Reason Tree Name must be defined'
 	 Return (-100)
  End
If @Reason_Level_1 = '' or @Reason_Level_1 Is Null
  Begin
 	 Select 'Failed - Reason Level 1 must be defined'
 	 Return (-100)
  End
 	 
 /* Check for existing tree */
 Select @Tree_Id = Tree_Name_Id
 From Event_Reason_Tree
 Where Tree_Name = @Reason_Tree_Name
 If @Tree_Id is null
  Begin
 	 Select 'Failed - Reason Tree Name not found'
 	 Return (-100)
  End
 /* Check for existing reason Level 1*/
 Select @Event_Reason_Id = Event_Reason_Id
 From Event_Reasons
 Where Event_Reason_Name = @Reason_Level_1
If @Event_Reason_Id is Null
  Begin
 	 if @iAddReason = 0
 	   Begin
 	  	 Select 'Failed - Reason Level 1 not found'
 	  	 Return (-100)
 	   End
 	 Else
 	   Begin
 	  	 Execute spEM_CreateEventReason  @Reason_Level_1, Null, 0,  @User_Id ,  @Event_Reason_Id  OUTPUT
 	  	 If @Event_Reason_Id is Null
 	  	   Begin
 	  	  	 Select 'Failed - Unable to create Reason Level 1'
 	  	  	 Return (-100)
 	  	   End
 	   End
  End
/* See if level 1 exists */
 Select @Ecrd_Id = Null
 Select @Ecrd_Id = Event_Reason_Tree_Data_Id 
 	 From Event_Reason_Tree_Data
 	 Where Tree_Name_Id = @Tree_Id and Event_Reason_Level = 1 and Event_Reason_Id = @Event_Reason_Id
 If @Ecrd_Id Is Null
 	 Begin
 	   Execute spEM_CreateEventReasonData   @Tree_Id,  @Event_Reason_Id, Null, 1, @User_Id,  @Ecrd_Id  OUTPUT
 	   If @Ecrd_Id is Null
 	  	 Begin
 	  	   Select 'Failed - Unable to attach Reason Level 1'
 	  	   Return (-100)
 	  	 End
 	 End
/**Level 2**/
If @Reason_Level_2 = '' or @Reason_Level_2 Is Null
 	 Return(0)   --Done
 /* Check for existing reason Level 2*/
 Select 	 @Event_Reason_Id  	 = Null
 Select @Event_Reason_Id = Event_Reason_Id
 From Event_Reasons
 Where Event_Reason_Name = @Reason_Level_2
If @Event_Reason_Id is Null
  Begin
 	 if @iAddReason = 0
 	   Begin
 	  	 Select 'Failed - Reason Level 2 not found'
 	  	 Return (-100)
 	   End
 	 Else
 	   Begin
 	  	 Execute spEM_CreateEventReason  @Reason_Level_2, Null, 0,  @User_Id ,  @Event_Reason_Id  OUTPUT
 	  	 If @Event_Reason_Id is Null
 	  	   Begin
 	  	  	 Select 'Failed - Unable to create Reason Level 2'
 	  	  	 Return (-100)
 	  	   End
 	   End
  End
/* See if level 2 exists */
 Select @NextEcrd_Id = Null
 Select @NextEcrd_Id = Event_Reason_Tree_Data_Id 
 	 From Event_Reason_Tree_Data
 	 Where Tree_Name_Id = @Tree_Id and Event_Reason_Level = 2 and Event_Reason_Id = @Event_Reason_Id and Parent_Event_R_Tree_Data_Id = @Ecrd_Id
 If @NextEcrd_Id Is Null
 	 Begin
 	   Execute spEM_CreateEventReasonData  @Tree_Id,  @Event_Reason_Id, @Ecrd_Id, 2, @User_Id,  @NextEcrd_Id  OUTPUT
 	   If @NextEcrd_Id is Null
 	  	 Begin
 	  	   Select 'Failed - Unable to attach Reason Level 2'
 	  	   Return (-100)
 	  	 End
 	 End
  Select  @Ecrd_Id = @NextEcrd_Id
/**Level 3**/
If @Reason_Level_3 = '' or @Reason_Level_3 Is Null
 	 Return(0)   --Done
 /* Check for existing reason Level 3*/
 Select 	 @Event_Reason_Id  	 = Null
 Select @Event_Reason_Id = Event_Reason_Id
 From Event_Reasons
 Where Event_Reason_Name = @Reason_Level_3
If @Event_Reason_Id is Null
  Begin
 	 if @iAddReason = 0
 	   Begin
 	  	 Select 'Failed - Reason Level 3 not found'
 	  	 Return (-100)
 	   End
 	 Else
 	   Begin
 	  	 Execute spEM_CreateEventReason  @Reason_Level_3, Null, 0,  @User_Id ,  @Event_Reason_Id  OUTPUT
 	  	 If @Event_Reason_Id is Null
 	  	   Begin
 	  	  	 Select 'Failed - Unable to create Reason Level 3'
 	  	  	 Return (-100)
 	  	   End
 	   End
  End
/* See if level 3 exists */
 Select @NextEcrd_Id = Null
 Select @NextEcrd_Id = Event_Reason_Tree_Data_Id 
 	 From Event_Reason_Tree_Data
 	 Where Tree_Name_Id = @Tree_Id and Event_Reason_Level = 3 and Event_Reason_Id = @Event_Reason_Id and Parent_Event_R_Tree_Data_Id = @Ecrd_Id
 If @NextEcrd_Id Is Null
 	 Begin
 	   Execute spEM_CreateEventReasonData  @Tree_Id,  @Event_Reason_Id, @Ecrd_Id, 3, @User_Id,  @NextEcrd_Id  OUTPUT
 	   If @NextEcrd_Id is Null
 	  	 Begin
 	  	   Select 'Failed - Unable to attach Reason Level 3'
 	  	   Return (-100)
 	  	 End
 	 End
 	 Select  @Ecrd_Id = @NextEcrd_Id
/**Level 4**/
If @Reason_Level_4 = '' or @Reason_Level_4 Is Null
 	 Return(0)   --Done
 /* Check for existing reason Level 4*/
 Select 	 @Event_Reason_Id  	 = Null
 Select @Event_Reason_Id = Event_Reason_Id
 From Event_Reasons
 Where Event_Reason_Name = @Reason_Level_4
If @Event_Reason_Id is Null
  Begin
 	 if @iAddReason = 0
 	   Begin
 	  	 Select 'Failed - Reason Level 4 not found'
 	  	 Return (-100)
 	   End
 	 Else
 	   Begin
 	  	 Execute spEM_CreateEventReason  @Reason_Level_4, Null, 0,  @User_Id ,  @Event_Reason_Id  OUTPUT
 	  	 If @Event_Reason_Id is Null
 	  	   Begin
 	  	  	 Select 'Failed - Unable to create Reason Level 4'
 	  	  	 Return (-100)
 	  	   End
 	   End
  End
/* See if level 4 exists */
 Select @NextEcrd_Id = Null
 Select @NextEcrd_Id = Event_Reason_Tree_Data_Id 
 	 From Event_Reason_Tree_Data
 	 Where Tree_Name_Id = @Tree_Id and Event_Reason_Level = 4 and Event_Reason_Id = @Event_Reason_Id and Parent_Event_R_Tree_Data_Id = @Ecrd_Id
 If @NextEcrd_Id Is Null
 	 Begin
 	   Execute spEM_CreateEventReasonData  @Tree_Id,  @Event_Reason_Id, @Ecrd_Id, 4, @User_Id,  @NextEcrd_Id  OUTPUT
 	   If @NextEcrd_Id is Null
 	  	 Begin
 	  	   Select 'Failed - Unable to attach Reason Level 4'
 	  	   Return (-100)
 	  	 End
 	 End
RETURN(0)
