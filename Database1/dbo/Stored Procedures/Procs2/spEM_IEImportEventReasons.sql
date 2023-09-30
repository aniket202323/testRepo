CREATE PROCEDURE dbo.spEM_IEImportEventReasons
@Old_Event_Reason_Name 	 nVarchar (100),
@New_Event_Reason_Name 	 nVarchar (100),
@Comment_Required 	  	 nVarChar(10),
@Event_Reason_Code 	  	 Varchar (10),
@Group_Desc 	  	  	 nvarchar(50),
@ExternalLink 	  	  	 nvarchar(255),
@User_Id 	  	  	  	 Int
As
Declare 	 @Group_Id 	 int,
 	  	 @Event_Reason_Id 	  	 int,
 	  	 @New_Event_Reason_Id 	  	 int,
 	  	 @iCommentRequired 	 TinyInt
/* Initialization */
Select  	 @Group_Id  	  	 = Null,
 	 @Event_Reason_Id  	 = Null,
 	 @New_Event_Reason_Id = Null
/* Clean arguments */
Select  	 @Old_Event_Reason_Name  	 = RTrim(LTrim(@Old_Event_Reason_Name)),
 	 @New_Event_Reason_Name  	 = RTrim(LTrim(@New_Event_Reason_Name)),
 	 @Event_Reason_Code  	  	 = RTrim(LTrim(@Event_Reason_Code)),
 	 @Group_Desc  	  	  	 = RTrim(LTrim(@Group_Desc)),
 	 @Comment_Required 	  	 = RTrim(LTrim(@Comment_Required)),
 	 @ExternalLink 	  	  	 = RTrim(LTrim(@ExternalLink))
If @Comment_Required = '0'
 	 Select @iCommentRequired = 0
Else If  @Comment_Required = '1'
 	 Select @iCommentRequired = 1
Else
  Begin
 	 Select 'Failed - Comment required must be True / False'
 	 Return (-100)
  End
If @Old_Event_Reason_Name = '' or @Old_Event_Reason_Name Is Null
  Begin
 	 Select 'Failed - Reason Names must be defined'
 	 Return (-100)
  End
If @New_Event_Reason_Name = '' or @New_Event_Reason_Name Is Null
  Begin
 	 Select 'Failed - Reason Names must be defined'
 	 Return (-100)
  End
 	 
/* Get the Group_Id */
If @Group_Desc Is Not Null
  Begin
 	 Select @Group_Id = Group_Id From Security_Groups
 	    Where Group_Desc = @Group_Desc
 	 If @Group_Id is null
 	  Begin
 	  	 Select 'Failed - Security Group not found'
 	  	 Return (-100)
 	  End
  End
 /* Check for existing reason */
 Select @Event_Reason_Id = Event_Reason_Id
 From Event_Reasons
 Where Event_Reason_Name = @Old_Event_Reason_Name
 /* If exists then update data */
 If @Event_Reason_Id Is Null
   Begin
 	 If @New_Event_Reason_Name <> @Old_Event_Reason_Name
 	   Begin
 	  	 Select 'Failed - New Name = Old Name (for new reasons)'
 	  	 Return (-100)
 	   End
 	   Execute spEM_CreateEventReason  @New_Event_Reason_Name,@Event_Reason_Code,@iCommentRequired,@User_Id,@Event_Reason_Id Output
 	   If @Event_Reason_Id is null
 	     Begin
 	  	  Select 'Failed - Unable to create new reason'
 	  	  Return (-100)
 	     End
   End
 Else
  Begin
 	 If @New_Event_Reason_Name <> @Old_Event_Reason_Name
 	   Begin
 	  	 Select @New_Event_Reason_Id = Event_Reason_Id From Event_Reasons
 	   	    Where Event_Reason_Name = @New_Event_Reason_Name
 	    	 If @New_Event_Reason_Id is Not Null
 	      Begin
 	  	   Select 'Failed - Unable to Update Reason (New Name already exists)'
 	  	   Return (-100)
 	      End
 	   End
    Execute spEM_UpdateEventReason  @Event_Reason_Id,@New_Event_Reason_Name,@Event_Reason_Code,@iCommentRequired,@User_Id
  End
 Execute spEM_PutSecurityReason  @Event_Reason_Id,@Group_Id,@User_Id
 Execute spEM_PutExtLink  @Event_Reason_Id,'by',@ExternalLink,Null,Null,@User_Id
RETURN(0)
