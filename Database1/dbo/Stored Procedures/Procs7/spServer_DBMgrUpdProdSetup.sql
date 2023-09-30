CREATE PROCEDURE dbo.spServer_DBMgrUpdProdSetup
@PPSetupId int OUTPUT,
@TransType int,
@TransNum int,
@UserId int,
@PPId int,
@ImpliedSequence int OUTPUT,
@PPStatusId int,
@PatternRepititions int,
@CommentId int,
@ForecastQuantity float, 
@BaseDimensionX real, 
@BaseDimensionY real, 
@BaseDimensionZ real, 
@BaseDimensionA real, 
@BaseGeneral1 real, 
@BaseGeneral2 real, 
@BaseGeneral3 real, 
@BaseGeneral4 real, 
@Shrinkage real,
@PatternCode nVarChar(25),
@PathId int, 
@EntryOn datetime OUTPUT,
@TransactionTime datetime = Null,
@ParentPPSetupId int,
@Unused int = 0 --Formally @TransactionOpen, removed to reduce complexity. This was only used by Server side procs so it can be reused.
AS
Declare @DebugFlag tinyint,
       	 @ID int,
 	       @MyOwnTrans 	 Int
If @@Trancount = 0
 	 Select @MyOwnTrans = 1
Else
 	 Select @MyOwnTrans = 0
/*
Insert Into User_Parameters (Parm_Id, User_Id, Value, HostName) Values(100, 6, 1, '')
update User_Parameters set value = 1 where Parm_Id = 100 and User_Id = 6
*/
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
--Select @DebugFlag = 1
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdProdSetup /PPSetupId: ' + ISNULL(convert(nvarchar(10),@PPSetupId),'NULL') + ' /TransType: ' + ISNULL(convert(nVarChar(4),@TransType),'NULL') + 
 	 ' /TransNum: ' + ISNULL(convert(nVarChar(4),@TransNum),'NULL') + ' /UserId: ' + ISNULL(convert(nVarChar(4),@UserId),'NULL') + 
 	 ' /PPId: ' + ISNULL(convert(nvarchar(10),@PPId),'NULL') + ' /ImpliedSequence: ' + ISNULL(convert(nvarchar(10),@ImpliedSequence),'NULL') + 
 	 ' /PPStatusId: ' + ISNULL(convert(nVarChar(4),@PPStatusId),'NULL') + ' /PatternRepititions: ' + ISNULL(convert(nVarChar(4),@PatternRepititions),'NULL') + 
 	 ' /CommentId: ' + ISNULL(convert(nvarchar(10),@CommentId),'NULL') + ' /ForecastQuantity: ' + ISNULL(convert(nvarchar(10),@ForecastQuantity),'NULL') + 
 	 ' /BaseDimensionX: ' + ISNULL(convert(nvarchar(10),@BaseDimensionX),'NULL') + ' /BaseDimensionY: ' + ISNULL(convert(nvarchar(10),@BaseDimensionY),'NULL') + 
 	 ' /BaseDimensionZ ' + ISNULL(convert(nvarchar(10),@BaseDimensionZ),'NULL') + ' /BaseDimensionA: ' + ISNULL(convert(nvarchar(10),@BaseDimensionA),'NULL') + 
 	 ' /BaseGeneral1: ' + ISNULL(convert(nvarchar(10),@BaseGeneral1),'NULL') + ' /BaseGeneral2 ' + ISNULL(convert(nvarchar(10),@BaseGeneral2),'NULL') +  
 	 ' /BaseGeneral3: ' + ISNULL(convert(nvarchar(10),@BaseGeneral3),'NULL') + ' /BaseGeneral4: ' + ISNULL(convert(nvarchar(10),@BaseGeneral4),'NULL') +
 	 ' /Shrinkage: ' + ISNULL(convert(nvarchar(10),@Shrinkage),'NULL') + ' /PatternCode: ' + ISNULL(convert(nVarChar(25),@PatternCode),'NULL') + 
 	 ' /PathId: ' + ISNULL(convert(nvarchar(10),@PathId),'NULL') + ' /EntryOn: ' + ISNULL(convert(nVarChar(25),@EntryOn),'NULL') + 
  ' /TransactionTime: ' + ISNULL(convert(nVarChar(25),@TransactionTime),'NULL') + ' /ParentPPSetupId: ' + ISNULL(convert(nvarchar(10),@ParentPPSetupId),'NULL'))
  End
Declare @Check int
Declare @Sequence int
Declare @Max_Sequence int
Declare @This_Movable bit
Declare @This_Sequence int
Declare @This_Sort_Order tinyint
Declare @Adjacent_Sequence int
Declare @Adjacent_PP_Setup_Id int
Declare @Adjacent_Movable bit
Declare @Adjacent_Sort_Order tinyint
Declare @How_Many int ---tinyint to int
Declare @AutoPromoteFrom_PPStatusId int
Declare @AutoPromoteTo_PPStatusId int
Declare @CurrentCount int
Declare @Min_ImpliedSequence int
Declare @PromotedFrom_PPStatusId int
Declare @Next_PPSetupId int
Declare 
@UserGeneral1 nVarChar(255), 
@UserGeneral2 nVarChar(255), 
@UserGeneral3 nVarChar(255), 
@ExtendedInfo nVarChar(255)
Declare 
@SourceComment_Id int,
@DestComment_Id int,
@SourcePtrComment varbinary(16),
@DestPtrComment varbinary(16),
@SourcePtrCommentValid int,
@SourcePtrCommentText varbinary(16),
@DestPtrCommentText varbinary(16),
@SourcePtrCommentTextValid int
Declare @x int,
@xID int
Create Table #ProductionSetupResultSet
(
Result tinyint,
PreDB tinyint,
TransType int,
TransNum int,
PathId int, 
PPSetupId int,
PPId int,
ImpliedSequence int,
PPStatusId int,
PatternRepititions int,
CommentId int,
ForecastQuantity float,  
BaseDimensionX real, 
BaseDimensionY real, 
BaseDimensionZ real, 
BaseDimensionA real, 
BaseGeneral1 real, 
BaseGeneral2 real, 
BaseGeneral3 real, 
BaseGeneral4 real, 
Shrinkage real,
PatternCode nVarChar(25),
UserId int, 
EntryOn datetime, 
TransactionTime datetime,
ParentPPSetupId int
)
/****************************************************/
/********Copyright 1998 Mountain Systems Inc.********/
/****************************************************/
  --
  -- Transaction Types
  -- 1  - Insert
  -- 2  - Update
  -- 3  - Delete
  --
  -- Transaction Numbers
  -- 00 - Coalesce
  -- 01 - Comment Update
  -- 02 - No Coalesce
  -- 91 - Return To Parent Sequence
  -- 92 - Create Child Sequence
  -- 97 - Status Transition
  -- 98 - Move Sequence Back
  -- 99 - Move Sequence Forward
  --1000 - update Comment
  --
  -- Return Values:
  --
  --   (-100)  Error.  11/08/04 (BJO) - Errors will now be specific to error so we can pass this back to the calling SP.
  --   (   1)  Success: New record added.
  --   (   2)  Success: Existing record modified.
  --   (   3)  Success: Existing record deleted.
  --   (   4)  Success: No action taken.
  --
If (@TransNum is NULL)
  select @TransNum = 0
If (@TransNum =1010) -- Transaction From WebUI
 	 SELECT @TransNum = 2
If @TransNum Not In(0,1,2,91,92,97,98,99,1000)
  Begin
    Drop Table #ProductionSetupResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Invalid TransNum') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-1000)
  End
SET @TransactionTime = Coalesce(@TransactionTime, dbo.fnServer_CmnGetDate(getUTCdate()))
SET @EntryOn = Coalesce(@EntryOn,@TransactionTime)
 	 IF @TransNum = 1000 /* Update Comment*/
 	 BEGIN
 	  	 IF @PPSetupId is Null or @UserId Is Null -- Check required fields
 	  	  	 RETURN(4)
 	  	 SET @Check  = NULL
 	  	 SELECT  @Check = pp_setup_id FROM Production_Setup WHERE pp_setup_id = @PPSetupId
 	  	 IF @Check is Null RETURN(4)-- Not Found
 	  	 UPDATE Production_Setup SET Comment_id = @CommentId,User_Id  = @UserId, Entry_On = @EntryOn  
 	  	  	  	 WHERE pp_setup_id  = @PPSetupId
 	  	 RETURN(2)
 	 END
If @TransType = 2 and (@TransNum = 0 or @TransNum = 2)
  Begin
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ImpliedSequence = ' + Convert(nvarchar(10), @ImpliedSequence)) 
    if @ImpliedSequence is NULL
      Begin
        select @ImpliedSequence = Implied_Sequence from Production_Setup Where PP_Setup_Id = @PPSetupId
      End
    select @Sequence = @ImpliedSequence
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Sequence = ' + Convert(nvarchar(10), @Sequence)) 
  End
Select @Check = NULL
If @ImpliedSequence = 0
  Select @ImpliedSequence = NULL
--Check For Unique Pattern Code On This Sequence
Select @Check = count(PP_Setup_Id) From Production_Setup Where PP_Id = @PPId and Pattern_Code = @PatternCode and PP_Setup_Id <> @PPSetupId
If @Check > 0
  Begin
    Drop Table #ProductionSetupResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Duplicate Pattern_Code') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-1010)
  End
If Not (@TransType = 2 and @TransNum = 1)
  If @MyOwnTrans = 1 
 	  	 Begin
 	  	  	 BEGIN TRANSACTION
      DECLARE @XLock BIT SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	  	 End
If @TransType = 1
  Begin
    If (@TransNum = 0) OR (@TransNum = 2)
      Begin
      Select @Max_Sequence = max(Implied_Sequence) From Production_Setup Where PP_Id = @PPId
      if @Max_Sequence is NULL
        Select @Sequence = 1
      else
        Select @Sequence = @Max_Sequence + 1
      If @PatternCode is NULL or LTrim(RTrim(@PatternCode)) = ''
        Begin
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Pattern Code is NULL...Create One')
          Select @PatternCode = Convert(nVarChar(30),dbo.fnServer_CmnGetDate(getUTCdate()),21)
        End
      Insert Into Production_Setup (
        PP_Id,
        Implied_Sequence,
        PP_Status_Id,
        Pattern_Repititions,     
        Comment_Id,
        Forecast_Quantity,
        Base_Dimension_X,
        Base_Dimension_Y,
        Base_Dimension_Z,
        Base_Dimension_A,
        Base_General_1, 
        Base_General_2, 
        Base_General_3, 
        Base_General_4, 
        Shrinkage,
        Pattern_Code,
        User_Id,
        Entry_On,
        Parent_PP_Setup_Id)
      Values (
        @PPId,
        @Sequence,
        @PPStatusId,
        @PatternRepititions,
        @CommentId,     
        @ForecastQuantity,
        @BaseDimensionX,
        @BaseDimensionY,
        @BaseDimensionZ,
        @BaseDimensionA,
        @BaseGeneral1,
        @BaseGeneral2,
        @BaseGeneral3, 
        @BaseGeneral4, 
        @Shrinkage, 
        @PatternCode, 
        @UserId, 
        @EntryOn,
        @ParentPPSetupId)
      if @@ERROR <> 0  
        Begin
          -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
          Drop Table #ProductionSetupResultSet
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Failed')
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
         	 Return (-1020)
        End
      else 
        Begin
          Insert Into #ProductionSetupResultSet
            Select 16, 0, @TransType, @TransNum, @PathId, @PPSetupId, @PPId, @Sequence, @PPStatusId, @PatternRepititions, @CommentId, 
            @ForecastQuantity, @BaseDimensionX, @BaseDimensionY, @BaseDimensionZ, @BaseDimensionA, @BaseGeneral1, @BaseGeneral2, 
            @BaseGeneral3, @BaseGeneral4, @Shrinkage, @PatternCode, @UserId, @EntryOn, @TransactionTime, @ParentPPSetupId
 	  	  	  	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
          Select @ImpliedSequence = @Sequence
          Select @PPSetupId = PP_Setup_Id From Production_Setup Where PP_Id = @PPId and Pattern_Code = @PatternCode
          Update #ProductionSetupResultSet Set PPSetupId = @PPSetupId Where PPSetupId is NULL or PPSetupId = 0
          Select Result, PreDB, TransType, TransNum, PathId, PPSetupId, PPId, ImpliedSequence, PPStatusId, PatternRepititions, CommentId, ForecastQuantity, 
          BaseDimensionX, BaseDimensionY, BaseDimensionZ, BaseDimensionA, BaseGeneral1, BaseGeneral2, BaseGeneral3, BaseGeneral4, Shrinkage, PatternCode, UserId, EntryOn, TransactionTime, ParentPPSetupId
            From #ProductionSetupResultSet
          Drop Table #ProductionSetupResultSet
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Sequence Successful')
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
         	 Return (1)
        End
     End
    Else If @TransNum = 92
      Begin  
        Select @Max_Sequence = max(Implied_Sequence) From Production_Setup Where PP_Id = @PPId
        if @Max_Sequence is NULL
          Select @Sequence = 1
        else
          Select @Sequence = @Max_Sequence + 1
        If @PatternCode is NULL or LTrim(RTrim(@PatternCode)) = ''
          Begin
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Pattern_Code is NULL...Create One') 
            Select @PatternCode = Pattern_Code + '-C' From Production_Setup Where PP_Setup_Id = @ParentPPSetupId
            Select @Check = count(PP_Setup_Id) From Production_Setup Where PP_Id = @PPId and Pattern_Code = @PatternCode
            If @Check > 0
              Begin
                Select @PatternCode = Convert(nVarChar(30),dbo.fnServer_CmnGetDate(getUTCdate()),21)
                Select @x = 0
                NextAvailChildDesc:
                Select @x = @x + 1
                Select @xID = Null
                Select @xID = PP_Setup_Id From Production_Setup
                Where Pattern_Code = @PatternCode + Convert(nvarchar(10), @x)
                If @xID is Null
                  Begin
                    Select @PatternCode = @PatternCode + Convert(nvarchar(10), @x)
                  End
                Else
                  Begin
                    Goto NextAvailChildDesc
                  End
              End
          End
        Select 
          @PPStatusId = 1,
          @PatternRepititions = Pattern_Repititions,
          @BaseDimensionX = Base_Dimension_X,
          @BaseDimensionY = Base_Dimension_Y,
          @BaseDimensionZ = Base_Dimension_Z,
          @BaseDimensionA = Base_Dimension_A,
          @BaseGeneral1 = Base_General_1,
          @BaseGeneral2 = Base_General_2,
          @BaseGeneral3 = Base_General_3,
          @BaseGeneral4 = Base_General_4,
          @Shrinkage = Shrinkage
          From Production_Setup
          Where PP_Setup_Id = @ParentPPSetupId
        Insert Into Production_Setup (
          PP_Id,
          Implied_Sequence,
          PP_Status_Id,
          Pattern_Repititions,     
          Comment_Id,
          Forecast_Quantity,
          Base_Dimension_X,
          Base_Dimension_Y,
          Base_Dimension_Z,
          Base_Dimension_A,
          Base_General_1, 
          Base_General_2, 
          Base_General_3, 
          Base_General_4, 
          Shrinkage,
          Pattern_Code,
          User_Id,
          Entry_On,
          Parent_PP_Setup_Id)
        Values (
          @PPId,
          @Sequence,
          @PPStatusId,
          @PatternRepititions,
          @CommentId,     
          @ForecastQuantity,
          @BaseDimensionX,
          @BaseDimensionY,
          @BaseDimensionZ,
          @BaseDimensionA,
          @BaseGeneral1,
          @BaseGeneral2,
          @BaseGeneral3, 
          @BaseGeneral4, 
          @Shrinkage, 
          @PatternCode, 
          @UserId, 
          @EntryOn,
          @ParentPPSetupId)
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
            Drop Table #ProductionSetupResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Failed')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
           	 Return (-1030)
          End
        else 
          Begin
            --Refreshes Parent in the Client
            Insert Into #ProductionSetupResultSet
              Select 16, 0, 2, 0, @PathId, PP_Setup_Id, PP_Id, Implied_Sequence, PP_Status_Id, Pattern_Repititions, Comment_Id, 
              Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
              Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
                From Production_Setup
                Where PP_Setup_Id = @ParentPPSetupId
            Insert Into #ProductionSetupResultSet
              Select 16, 0, @TransType, @TransNum, @PathId, @PPSetupId, @PPId, @Sequence, @PPStatusId, @PatternRepititions, @CommentId, 
              @ForecastQuantity, @BaseDimensionX, @BaseDimensionY, @BaseDimensionZ, @BaseDimensionA, @BaseGeneral1, @BaseGeneral2, 
              @BaseGeneral3, @BaseGeneral4, @Shrinkage, @PatternCode, @UserId, @EntryOn, @TransactionTime, @ParentPPSetupId
 	  	  	  	  	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
            Select @ImpliedSequence = @Sequence
            Select @PPSetupId = PP_Setup_Id From Production_Setup Where PP_Id = @PPId and Pattern_Code = @PatternCode
            Select @UserGeneral1 = User_General_1, @UserGeneral2 = User_General_2, @UserGeneral3 = User_General_3, @ExtendedInfo = Extended_Info From Production_Setup Where PP_Setup_Id = @ParentPPSetupId
            Update Production_Setup Set User_General_1 = @UserGeneral1, User_General_2 = @UserGeneral2, User_General_3 = @UserGeneral3, Extended_Info = @ExtendedInfo Where PP_Setup_Id = @PPSetupId
            Select @SourceComment_Id = comment_id
              From Production_Setup
              Where PP_Setup_Id = @ParentPPSetupId
            if @SourceComment_Id > 0
              Begin
                insert into comments(Comment, Comment_Text, CS_Id, Modified_On, User_Id, Entry_On) values ('', '', 2, dbo.fnServer_CmnGetDate(getUTCdate()), @UserId, dbo.fnServer_CmnGetDate(getUTCdate()))
                select @DestComment_Id = Scope_Identity()
                update comments set TopOfChain_Id = @DestComment_Id where comment_id = @DestComment_Id
                update Production_Setup set comment_id = @DestComment_Id Where PP_Setup_Id = @PPSetupId
                select @SourcePtrComment = TEXTPTR(comment) from comments where comment_id = @SourceComment_Id
                select @SourcePtrCommentValid = TEXTVALID ('comments.comment', @SourcePtrComment)
                if @SourcePtrCommentValid = 1
                  Begin
                    select @DestPtrComment = TEXTPTR(comment) from comments where comment_id = @DestComment_Id
                    UPDATETEXT comments.comment @DestPtrComment 0 0 WITH LOG comments.comment @SourcePtrComment
                  End
                select @SourcePtrCommentText = TEXTPTR(comment_text) from comments where comment_id = @SourceComment_Id
                select @SourcePtrCommentTextValid = TEXTVALID ('comments.comment_text', @SourcePtrCommentText)
                if @SourcePtrCommentTextValid = 1
                  Begin
                    select @DestPtrCommentText = TEXTPTR(comment_text) from comments where comment_id = @DestComment_Id
                    UPDATETEXT comments.comment_text @DestPtrCommentText 0 0 WITH LOG comments.comment_text @SourcePtrCommentText
                  End
              End
            Update #ProductionSetupResultSet Set PPSetupId = @PPSetupId Where PPSetupId is NULL or PPSetupId = 0
            Update #ProductionSetupResultSet Set CommentId = @DestComment_Id Where PPSetupId = @PPSetupId
            Select Result, PreDB, TransType, TransNum, PathId, PPSetupId, PPId, ImpliedSequence, PPStatusId, PatternRepititions, CommentId, ForecastQuantity, 
            BaseDimensionX, BaseDimensionY, BaseDimensionZ, BaseDimensionA, BaseGeneral1, BaseGeneral2, BaseGeneral3, BaseGeneral4, Shrinkage, PatternCode, UserId, EntryOn, TransactionTime, ParentPPSetupId
              From #ProductionSetupResultSet
            Drop Table #ProductionSetupResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 92 (Create Child Sequence)')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
           	 Return (1)
          End
      End
  End
Else If @TransType = 2
  Begin
    If @TransNum = 1
      Begin
        Insert Into #ProductionSetupResultSet
          Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, @This_Sequence, PP_Status_Id, Pattern_Repititions, Comment_Id, 
          Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
          Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
            From Production_Setup
            Where PP_Setup_Id = @PPSetupId
        Select Result, PreDB, TransType, TransNum, PathId, PPSetupId, PPId, ImpliedSequence, PPStatusId, PatternRepititions, CommentId, ForecastQuantity, 
        BaseDimensionX, BaseDimensionY, BaseDimensionZ, BaseDimensionA, BaseGeneral1, BaseGeneral2, BaseGeneral3, BaseGeneral4, Shrinkage, PatternCode, UserId, EntryOn, TransactionTime, ParentPPSetupId
          From #ProductionSetupResultSet
        Drop Table #ProductionSetupResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 1') 
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        	 Return (2)
      End
    Else If @TransNum = 91
      Begin
        Update Production_Setup Set Forecast_Quantity = Actual_Good_Quantity, User_Id = @UserId, Entry_On = @EntryOn
          Where PP_Setup_Id = @PPSetupId
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
            Drop Table #ProductionSetupResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (-1040)
          End
        Insert Into #ProductionSetupResultSet
          Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, @This_Sequence, PP_Status_Id, Pattern_Repititions, Comment_Id, 
          Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
          Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
            From Production_Setup
            Where PP_Setup_Id = @PPSetupId
 	  	  	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
        Select Result, PreDB, TransType, TransNum, PathId, PPSetupId, PPId, ImpliedSequence, PPStatusId, PatternRepititions, CommentId, ForecastQuantity, 
        BaseDimensionX, BaseDimensionY, BaseDimensionZ, BaseDimensionA, BaseGeneral1, BaseGeneral2, BaseGeneral3, BaseGeneral4, Shrinkage, PatternCode, UserId, EntryOn, TransactionTime, ParentPPSetupId
          From #ProductionSetupResultSet
        Drop Table #ProductionSetupResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 91 (Return To Parent Sequence)') 
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        	 Return (2)
      End
    Else If @TransNum = 97
    BEGIN
 	    DECLARE @OldStatus Int,
 	  	  	  @PPPUId 	 Int,
 	  	  	  @NewStatus Int
 	    DECLARE @PPStartsUnits Table (PUId Int)
 	    Declare @Now DateTime
  	     Declare @ControlType 	 INT
  	     
  	     SELECT 	 @ControlType = NULL
  	     SELECT 	 @ControlType = Schedule_Control_Type
  	     FROM 	 dbo.PrdExec_Paths 	 p
  	     WHERE 	 p.Path_Id = @PathId
 	    Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  	    Select @Now = DATEADD(MILLISECOND, -DATEPART(MILLISECOND, @Now), @Now)
 	    Insert INTO @PPStartsUnits (PUID)
 	  	 SELECT  Distinct a.PU_Id
   	    	  	 From Production_Plan_Starts a
         	  	 Join PrdExec_Path_Units c on (c.PU_Id = a.PU_Id) And (c.Path_Id = @PathId) and (c.Is_Production_Point = 1)
 	    Select @OldStatus = PP_Status_Id From Production_Setup Where PP_Setup_Id = @PPSetupId
        If  @OldStatus <> @PPStatusId
          Begin
            Select @PromotedFrom_PPStatusId = PP_Status_Id
              From Production_Setup
            Where PP_Setup_Id = @PPSetupId
            Update Production_Setup Set PP_Status_Id = @PPStatusId, User_Id = @UserId, Entry_On = @EntryOn
              Where PP_Setup_Id = @PPSetupId
            if @@ERROR <> 0  
              Begin
                -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
                Drop Table #ProductionSetupResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (-1050)
              End
 	  	   /********PP Starts***************/
  	    	    If @PPStatusId = 3 AND @ControlType IS NOT NULL--Go to Active
 	  	  	 UPDATE Production_Plan_Starts Set pp_setup_id = @PPSetupId Where  PP_Id = @PPId and End_Time is Null and PU_Id in (select PUID From @PPStartsUnits)
 	  	   ELSE IF @OldStatus = 3 -- Move From Active
 	  	  	 BEGIN
   	    	    	      If @ControlType IS NOT NULL--Go to Active
   	    	    	      BEGIN
 	  	  	  	 UPDATE Production_Plan_Starts Set End_Time = @Now Where End_Time is Null and PU_Id in (select PUID From @PPStartsUnits)
 	  	  	  	 Declare pps_Cursor Cursor For Select PUID From @PPStartsUnits
 	  	  	  	 OPEN pps_Cursor
 	  	  	  	 PPSLoop:
 	  	  	  	 FETCH NEXT FROM pps_Cursor INTO @PPPUId
 	  	  	  	 IF @@Fetch_Status = 0
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT INTO Production_Plan_Starts (PP_Id,pp_setup_id,PU_Id,Start_Time,User_Id)
 	  	  	  	  	  	 SELECT @PPId,Null,@PPPUId,@Now,@UserId
 	  	  	  	  	 GOTO PPSLoop
 	  	  	  	 END
 	  	  	  	 Close pps_Cursor
 	  	  	  	 DEALLOCATE pps_Cursor
 	  	  	 END
  	    	    	  END
 	  	   /*******************************/
            Insert Into #ProductionSetupResultSet
              Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, Implied_Sequence, @PPStatusId, Pattern_Repititions, Comment_Id, 
              Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
              Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
                From Production_Setup
                Where PP_Setup_Id = @PPSetupId
            While (0=0) 
              Begin
                Select @How_Many = NULL, @Next_PPSetupId = NULL, @Min_ImpliedSequence = NULL, @AutoPromoteFrom_PPStatusId = NULL, @AutoPromoteTo_PPStatusId = NULL
                Select @AutoPromoteFrom_PPStatusId = AutoPromoteFrom_PPStatusId, @AutoPromoteTo_PPStatusId = AutoPromoteTo_PPStatusId
                  From PrdExec_Path_Status_Detail
                  Where PP_Status_Id = @PPStatusId
                  And Path_Id = @PathId
                If @AutoPromoteFrom_PPStatusId is NULL or @AutoPromoteTo_PPStatusId is NULL or (@PromotedFrom_PPStatusId <> @AutoPromoteTo_PPStatusId)
                  break
                Else
                  Select @PromotedFrom_PPStatusId = @AutoPromoteFrom_PPStatusId
                Select @PPStatusId = @AutoPromoteTo_PPStatusId
                Select @How_Many = How_Many
                  From PrdExec_Path_Status_Detail
                  Where PP_Status_Id = @AutoPromoteTo_PPStatusId
                  And Path_Id = @PathId
                Select @Min_ImpliedSequence = Min(Implied_Sequence)
                  From Production_Setup
                  Where PP_Id = @PPId
                  And PP_Status_Id = @AutoPromoteFrom_PPStatusId
                if @Min_ImpliedSequence is NULL
                  break
                Select @Next_PPSetupId = PP_Setup_Id
                  From Production_Setup
                  Where PP_Id = @PPId
                  And Implied_Sequence = @Min_ImpliedSequence
                Select @CurrentCount = Count(*) 
                  From Production_Setup 
                  Where PP_Id = @PPId 
                  And PP_Status_Id = @AutoPromoteTo_PPStatusId
                if @CurrentCount >= @How_Many and @How_Many is NOT NULL
                  break
   	  	  	  Select @NewStatus = @PPStatusId
                Update Production_Setup Set PP_Status_Id = @PPStatusId, User_Id = @UserId, Entry_On = @EntryOn
                  Where PP_Setup_Id = @Next_PPSetupId
                if @@ERROR <> 0  
                BEGIN
                    -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
                    Drop Table #ProductionSetupResultSet
                    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
                    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                    Return (-1060)
                END
 	    	  	  /********PP Starts***************/
  	    	    	   If @PPStatusId = 3 AND @ControlType IS NOT NULL--Active
 	  	  	  	 UPDATE Production_Plan_Starts Set pp_setup_id = @Next_PPSetupId Where  PP_Id = @PPId and End_Time is Null and PU_Id in (select PUID From @PPStartsUnits)
 	  	  	  /*****************************/
                Insert Into #ProductionSetupResultSet
                  Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, Implied_Sequence, @PPStatusId, Pattern_Repititions, Comment_Id, 
                  Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
                  Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
                    From Production_Setup
                    Where PP_Setup_Id = @Next_PPSetupId
              End  
 	  	   If @MyOwnTrans = 1 COMMIT TRANSACTION
            Select Result, PreDB, TransType, TransNum, PathId, PPSetupId, PPId, ImpliedSequence, PPStatusId, PatternRepititions, CommentId, ForecastQuantity, 
            BaseDimensionX, BaseDimensionY, BaseDimensionZ, BaseDimensionA, BaseGeneral1, BaseGeneral2, BaseGeneral3, BaseGeneral4, Shrinkage, PatternCode, UserId, EntryOn, TransactionTime, ParentPPSetupId
              From #ProductionSetupResultSet
            Drop Table #ProductionSetupResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 97 (Status Transition)') 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (2)
          End
    END
    Else If @TransNum = 98 or @TransNum = 99
      Begin
        Select @This_Movable = PPS.Movable, @This_Sequence = PS.Implied_Sequence, @This_Sort_Order = Case When PEPSD.SortWith_PPStatusId is NULL or PEPSD.SortWith_PPStatusId = 0 Then PEPSD.Sort_Order Else (Select Sort_Order From PrdExec_Path_Status_Detail Where PP_Status_Id = PEPSD.SortWith_PPStatusId and Path_Id = PEPSD.Path_Id) End
          From Production_Setup PS
          Join Production_Plan PP on PP.PP_Id = PS.PP_Id
          Join Production_Plan_Statuses PPS on PPS.PP_Status_Id = PS.PP_Status_Id
          Join PrdExec_Path_Status_Detail PEPSD on PEPSD.PP_Status_Id = PPS.PP_Status_Id and (PEPSD.Path_Id = PP.Path_Id or PEPSD.Path_Id = (Select Min(Path_Id) From PrdExec_Paths Where Prod_Id = PP.Prod_Id))
          Where PS.PP_Setup_Id = @PPSetupId
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Movable = ' + Convert(nvarchar(10), @This_Movable)) 
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'This_Sequence = ' + Convert(nvarchar(10), @This_Sequence)) 
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'This_Sort_Order = ' + Convert(nvarchar(10), @This_Sort_Order)) 
        If @This_Movable <> 1
          Begin
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
            Drop Table #ProductionSetupResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@This_Movable <> 1')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (4)
          End
        -- We AreMoving Up Or Down  - Find Implied Sequence Of Adjacent Item
        if @TransNum = 98
          Begin
            --Move Up
            Select @Adjacent_Sequence = min(Implied_Sequence) From Production_Setup Where PP_Id = @PPId and Implied_Sequence > @This_Sequence
          End
        else if @TransNum = 99
          Begin
            --Move Down
            Select @Adjacent_Sequence = max(Implied_Sequence) From Production_Setup Where PP_Id = @PPId and Implied_Sequence < @This_Sequence
          End
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjacent_Sequence = ' + Convert(nvarchar(10), @Adjacent_Sequence)) 
        -- Update The Implied Sequence
        if @Adjacent_Sequence is Not Null
          Begin
            Select @Adjacent_PP_Setup_Id = PP_Setup_Id From Production_Setup Where Implied_Sequence = @Adjacent_Sequence and PP_Id = @PPId
            Select @Adjacent_Movable = PPS.Movable, @Adjacent_Sort_Order = Case When PEPSD.SortWith_PPStatusId is NULL or PEPSD.SortWith_PPStatusId = 0 Then PEPSD.Sort_Order Else (Select Sort_Order From PrdExec_Path_Status_Detail Where PP_Status_Id = PEPSD.SortWith_PPStatusId and Path_Id = PEPSD.Path_Id) End
              From Production_Setup PS
              Join Production_Plan PP on PP.PP_Id = PS.PP_Id
              Join Production_Plan_Statuses PPS on PPS.PP_Status_Id = PS.PP_Status_Id
              Join PrdExec_Path_Status_Detail PEPSD on PEPSD.PP_Status_Id = PPS.PP_Status_Id and (PEPSD.Path_Id = PP.Path_Id or PEPSD.Path_Id = (Select Min(Path_Id) From PrdExec_Paths Where Prod_Id = PP.Prod_Id))
              Where PS.PP_Setup_Id = @Adjacent_PP_Setup_Id
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjacent_Movable = ' + Convert(nvarchar(10), @Adjacent_Movable)) 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjacent_Sort_Order = ' + Convert(nvarchar(10), @Adjacent_Sort_Order)) 
            If @Adjacent_Movable <> 1
              Begin
 	  	  	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
                Drop Table #ProductionSetupResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Adjacent_Movable <> 1')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (4)
              End
            If @This_Sort_Order <> @Adjacent_Sort_Order
              Begin
 	  	  	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
                Drop Table #ProductionSetupResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@This_Sort_Order <> @Adjacent_Sort_Order')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (4)
              End
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjacent_PP_Setup_Id = ' + Convert(nvarchar(10), @Adjacent_PP_Setup_Id)) 
            Update Production_Setup Set Implied_Sequence = @Adjacent_Sequence, User_Id = @UserId, Entry_On = @EntryOn
              Where PP_Setup_Id = @PPSetupId
            if @@ERROR <> 0  
              Begin
                -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
                Drop Table #ProductionSetupResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (-1070)
              End
            Insert Into #ProductionSetupResultSet
              Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, @Adjacent_Sequence, PP_Status_Id, Pattern_Repititions, Comment_Id, 
              Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
              Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
                From Production_Setup
                Where PP_Setup_Id = @PPSetupId
            Update Production_Setup Set Implied_Sequence = @This_Sequence, User_Id = @UserId, Entry_On = @EntryOn
              Where PP_Setup_Id = @Adjacent_PP_Setup_Id
            if @@ERROR <> 0  
              Begin
                -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
                Drop Table #ProductionSetupResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (-1080)
              End
            Insert Into #ProductionSetupResultSet
              Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, @This_Sequence, PP_Status_Id, Pattern_Repititions, Comment_Id, 
              Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
              Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
                From Production_Setup
                Where PP_Setup_Id = @Adjacent_PP_Setup_Id
 	  	  	  	  	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
            Select Result, PreDB, TransType, TransNum, PathId, PPSetupId, PPId, ImpliedSequence, PPStatusId, PatternRepititions, CommentId, ForecastQuantity, 
            BaseDimensionX, BaseDimensionY, BaseDimensionZ, BaseDimensionA, BaseGeneral1, BaseGeneral2, BaseGeneral3, BaseGeneral4, Shrinkage, PatternCode, UserId, EntryOn, TransactionTime, ParentPPSetupId
              From #ProductionSetupResultSet
            Drop Table #ProductionSetupResultSet
            If @TransNum = 98
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 98 (Move Setup Back)') 
            Else If @TransNum = 99
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 99 (Move Setup Forward)')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            	 Return (2)
          End
        else
          Begin
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
            Drop Table #ProductionSetupResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Adjacent_Sequence is Null')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (4)
          End
      End
   	 Else If @TransNum = 0
   	   Begin
     	  	 Select @PPId = Coalesce(@PPId,PP_Id),
     	  	  	 @Sequence = Coalesce(@Sequence,Implied_Sequence),
     	  	  	 @PPStatusId = Coalesce(@PPStatusId,PP_Status_Id),
          @PatternRepititions = Coalesce(@PatternRepititions,Pattern_Repititions),
     	  	  	 @CommentId = Coalesce(@CommentId,Comment_Id),
     	  	  	 @ForecastQuantity = Coalesce(@ForecastQuantity,Forecast_Quantity),
     	  	  	 @BaseDimensionX = Coalesce(@BaseDimensionX,Base_Dimension_X),
     	  	  	 @BaseDimensionY = Coalesce(@BaseDimensionY,Base_Dimension_Y),
     	  	  	 @BaseDimensionZ = Coalesce(@BaseDimensionZ,Base_Dimension_Z),
     	  	  	 @BaseDimensionA = Coalesce(@BaseDimensionA,Base_Dimension_A),
     	  	  	 @BaseGeneral1 = Coalesce(@BaseGeneral1,Base_General_1),
     	  	  	 @BaseGeneral2 = Coalesce(@BaseGeneral2,Base_General_2),
     	  	  	 @BaseGeneral3 = Coalesce(@BaseGeneral3,Base_General_3),
     	  	  	 @BaseGeneral4 = Coalesce(@BaseGeneral4,Base_General_4),
     	  	  	 @Shrinkage = Coalesce(@Shrinkage,Shrinkage),
     	  	  	 @PatternCode = Coalesce(@PatternCode,Pattern_Code), 
     	  	  	 @UserId = Coalesce(@UserId,User_Id), 
     	  	  	 @EntryOn = Coalesce(@EntryOn,Entry_On),
          @ParentPPSetupId = Coalesce(@ParentPPSetupId,Parent_PP_Setup_Id)
     	  	  From Production_Setup
     	  	  Where (PP_Setup_Id = @PPSetupId)
   	   End
    --Fields Not Editable In Client
 	  	 Select 
 	  	  	 @Shrinkage = Coalesce(@Shrinkage,Shrinkage)
 	  	  From Production_Setup
 	  	  Where (PP_Setup_Id = @PPSetupId)
    Update Production_Setup 
      Set PP_Id = @PPId,
      Implied_Sequence = @Sequence,
      PP_Status_Id = @PPStatusId,
      Pattern_Repititions = @PatternRepititions,
      Comment_Id = @CommentId, 
      Forecast_Quantity = @ForecastQuantity,     
      Base_Dimension_X = @BaseDimensionX,
      Base_Dimension_Y = @BaseDimensionY,
      Base_Dimension_Z = @BaseDimensionZ,
      Base_Dimension_A = @BaseDimensionA,
      Base_General_1 = @BaseGeneral1, 
      Base_General_2 = @BaseGeneral2, 
      Base_General_3 = @BaseGeneral3, 
      Base_General_4 = @BaseGeneral4, 
      Shrinkage = @Shrinkage, 
      Pattern_Code = @PatternCode, 
      User_Id = @UserId, 
      Entry_On = @EntryOn,
      Parent_PP_Setup_Id = @ParentPPSetupId
    Where PP_Setup_Id = @PPSetupId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        Drop Table #ProductionSetupResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        Return (-1090)
      End
    else 
      Begin
        Insert Into #ProductionSetupResultSet
          Select 16, 0, @TransType, @TransNum, @PathId, @PPSetupId, @PPId, @Sequence, @PPStatusId, @PatternRepititions, @CommentId, 
          @ForecastQuantity, @BaseDimensionX, @BaseDimensionY, @BaseDimensionZ, @BaseDimensionA, @BaseGeneral1, @BaseGeneral2, 
          @BaseGeneral3, @BaseGeneral4, @Shrinkage, @PatternCode, @UserId, @EntryOn, @TransactionTime, @ParentPPSetupId
 	  	  	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
        Select @ImpliedSequence = @Sequence
        Select Result, PreDB, TransType, TransNum, PathId, PPSetupId, PPId, ImpliedSequence, PPStatusId, PatternRepititions, CommentId, ForecastQuantity, 
        BaseDimensionX, BaseDimensionY, BaseDimensionZ, BaseDimensionA, BaseGeneral1, BaseGeneral2, BaseGeneral3, BaseGeneral4, Shrinkage, PatternCode, UserId, EntryOn, TransactionTime, ParentPPSetupId
          From #ProductionSetupResultSet
        Drop Table #ProductionSetupResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Sequence Successful')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        	 Return (2)
      End
  End
Else If @TransType = 3
  Begin
    --These qualifiers should be handled by the client code but double-check here
    Select @Check = COUNT(PP_Setup_Id) From Event_Details Where PP_Setup_Id = @PPSetupId
    if (@Check > 0)  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Cannot delete if Event_Details')
 	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        Drop Table #ProductionSetupResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Event Details Exists')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        Return (-1100)
      End
    Select @Check = Comment_Id From Production_Setup Where PP_Setup_Id = @PPSetupId
    If (@Check Is Not Null)
      Begin
        Update Comments 
          Set ShouldDelete = 1, 
              Comment = '',
              Comment_Text = ''
          Where Comment_Id = @Check
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
            Drop Table #ProductionSetupResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (-1110)
          End
      End
    -- TODO: Fix this later, this is a performance pig
    Delete Production_Setup_Detail Where PP_Setup_Id = @PPSetupId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Error deleting Setup_Detail')
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        Drop Table #ProductionSetupResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 Return (-1120)
      End
    --Refreshes Client
    Insert Into #ProductionSetupResultSet
      Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, @This_Sequence, PP_Status_Id, Pattern_Repititions, Comment_Id, 
      Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
      Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
        From Production_Setup
        Where Parent_PP_Setup_Id = @PPSetupId
    Update Production_Setup Set Parent_PP_Setup_Id = NULL, User_Id = @UserId, Entry_On = @EntryOn Where Parent_PP_Setup_Id = @PPSetupId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Error upd SourcePP')
 	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        Drop Table #ProductionSetupResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 Return (-1130)
      End
    --Refreshes Parent in the Client
    Insert Into #ProductionSetupResultSet
      Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, @This_Sequence, PP_Status_Id, Pattern_Repititions, Comment_Id, 
      Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
      Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
        From Production_Setup
        Where PP_Setup_Id = (Select Parent_PP_Setup_Id From Production_Setup Where PP_Setup_Id = @PPSetupId)
    Insert Into #ProductionSetupResultSet
      Select 16, 0, @TransType, @TransNum, @PathId, PP_Setup_Id, PP_Id, @This_Sequence, PP_Status_Id, Pattern_Repititions, Comment_Id, 
      Forecast_Quantity, Base_Dimension_X, Base_Dimension_Y, Base_Dimension_Z, Base_Dimension_A, Base_General_1, Base_General_2, 
      Base_General_3, Base_General_4, Shrinkage, Pattern_Code, @UserId, @EntryOn, @TransactionTime, Parent_PP_Setup_Id
        From Production_Setup
        Where PP_Setup_Id = @PPSetupId
    Delete From Production_Setup Where PP_Setup_Id = @PPSetupId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Error deleting Setup')
 	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        Drop Table #ProductionSetupResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 Return (-1140)
      End
 	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
    Select Result, PreDB, TransType, TransNum, PathId, PPSetupId, PPId, ImpliedSequence, PPStatusId, PatternRepititions, CommentId, ForecastQuantity, 
    BaseDimensionX, BaseDimensionY, BaseDimensionZ, BaseDimensionA, BaseGeneral1, BaseGeneral2, BaseGeneral3, BaseGeneral4, Shrinkage, PatternCode, UserId, EntryOn, TransactionTime, ParentPPSetupId
      From #ProductionSetupResultSet
    Drop Table #ProductionSetupResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Sequence Successful')
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (3)
  End
--If we get to the bottom of this proc and the transaction is still open something bad happpened rollback the changes. 
If @@Trancount > 0 
  BEGIN
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    Drop Table #ProductionSetupResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'TranCount > 0, Rolling Back.') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-1150)
  END
If @MyOwnTrans = 1 COMMIT TRANSACTION
Drop Table #ProductionSetupResultSet
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Return (4)') 
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Change')
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
Return (4)
