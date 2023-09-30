CREATE PROCEDURE dbo.[spEM_IEImportModels_Bak_177]
 	 @ModelDesc 	  	 nvarchar(255),
 	 @ModelNum 	  	  	 nvarchar(50),
 	 @Derivedfrom  	  	 nvarchar(50),
 	 @Version  	  	  	 nvarchar(50),
 	 @IntervalBased  	 nvarchar(50),
 	 @Locked  	  	  	 nvarchar(50),
 	 @ETDesc 	  	  	 nvarchar(50), 
 	 @CommentText  	  	 nvarchar(255),
 	 @UserId Int
AS
Declare
 	 @ModelId 	  	  	 Int,
 	 @DerivedFromId  	 Int,
 	 @IntervalBasedBit  	 TinyInt,
 	 @LockedBit  	  	 TinyInt,
 	 @ETId  	  	  	 Int,
 	 @CommentId  	  	 Int,
 	 @iModelNum 	  	 Int
/* Clean arguments */
Select  	 @ModelDesc  	 = nullif(RTrim(LTrim(@ModelDesc)),''),
 	   	 @ModelNum  	 = nullif(RTrim(LTrim(@ModelNum)),''),
 	  	 @Derivedfrom 	 = nullif(RTrim(Ltrim(@Derivedfrom)),''),
 	  	 @Version 	 = nullif(RTrim(Ltrim(@Version)),''),
 	  	 @IntervalBased 	 = nullif(RTrim(Ltrim(@IntervalBased)),''),
 	  	 @Locked 	  	 = nullif(RTrim(Ltrim(@Locked)),''),
 	  	 @ETDesc 	  	 = nullif(RTrim(Ltrim(@ETDesc)),''),
 	  	 @CommentText 	 = nullif(RTrim(Ltrim(@CommentText)),'')
/* Take care of nonNullable fields  sp_Help ED_Models*/
     If @IntervalBased Is Null
 	    Begin
 	  	 Select 'Failed - Interval Based Not Found'
 	  	 Return(-100)
 	    End
     If @Locked Is Null
 	    Begin
 	  	 Select 'Failed - Is Locked Not Found'
 	  	 Return(-100)
 	    End
     If @ETDesc Is Null
 	    Begin
 	  	 Select 'Failed - Event Type Not Found'
 	  	 Return(-100)
 	    End
     If @ModelDesc Is Null
 	    Begin
 	  	 Select 'Failed - Model Description Not Found'
 	  	 Return(-100)
 	    End
 	 If @ModelNum is Null
 	    Begin
 	  	 Select 'Failed - Model Number Not Found'
 	  	 Return(-100)
 	    End
/* Check to see if already exists */
 	 Select @ModelId = ed_Model_Id from ed_Models where Model_Desc = @ModelDesc
     If @ModelId Is Not Null
 	    Begin
 	  	 Select 'Failed - Model Description already exists'
 	  	 Return(-100)
 	    End
 	 If isnumeric(@ModelNum) = 0
 	    Begin
 	  	 Select 'Failed - Model number incorrect'
 	  	 Return(-100)
 	    End
 	 If @ModelNum < 50000
 	    Begin
 	  	 Select 'Failed - Model number incorrect (user defined > 50000)'
 	  	 Return(-100)
 	    End
 	 Select @iModelNum = ModelNum from ed_Models where ModelNum = @ModelNum
     If @iModelNum Is Not Null
 	    Begin
 	  	 Select 'Failed - Model number already exists'
 	  	 Return(-100)
 	    End
 	 Select @DerivedFromId = ed_Model_Id from ed_Models where Model_Num = @Derivedfrom and Allow_Derived = 1
     If @DerivedFromId Is Null
 	    Begin
 	  	 Select 'Failed - Unable to find derived model or derived model not allowed for this model'
 	  	 Return(-100)
 	    End
 	 If isnumeric(@IntervalBased) = 0 or (@IntervalBased <> '1' and @IntervalBased <> '0')
 	   Begin
 	  	 Select 'Failed - Interval based not correct '
 	  	 Return(-100)
 	   End 
 	 Select @IntervalBasedBit = Convert(bit,@IntervalBased)
 	 If isnumeric(@Locked) = 0 or (@Locked <> '1' and @Locked <> '0')
 	   Begin
 	  	 Select 'Failed - Interval based not correct '
 	  	 Return(-100)
 	   End 
 	 Select @LockedBit = Convert(bit,@Locked)
 	 Select @ETId = ET_Id from Event_Types where ET_Desc = @ETDesc
 	 If @ETId IS NULL 
 	     BEGIN
 	       Select 'Failed - invalid event type'
 	       Return(-100)
 	     END
 	 Select @CommentId = Null
 	 If @CommentText is not null 
 	   Begin
     	  	 Insert into Comments (Comment, User_Id, Modified_On, CS_Id) 
 	  	  	 Select @CommentText,@UserId,dbo.fnServer_CmnGetDate(getUTCdate()),1
 	  	 Select @CommentId = SCOPE_IDENTITY()
 	  	 If @CommentId IS NULL
 	  	  	 Select 'Warning - Unable to create comment'
 	   End
 	  	 
Insert Into ED_Models(Model_Num,ModelNum, Model_Desc, Derived_from, Installed_On, Server_Version,Model_Version, Interval_Based, Locked, User_Defined, ET_Id, Comment_Id, Num_Of_Fields, ModelDesc)
 	 Select @ModelNum,@ModelNum, @ModelDesc, @Derivedfrom, dbo.fnServer_CmnGetDate(getUTCdate()), Null,@Version, @IntervalBasedBit, @LockedBit, 0, @ETId, @CommentId, 0,@ModelDesc
