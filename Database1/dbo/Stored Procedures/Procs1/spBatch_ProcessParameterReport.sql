CREATE Procedure dbo.spBatch_ProcessParameterReport 
 	 @EventTransactionId 	  	 Int,
 	 @BatchUnitId 	  	  	 Int,
 	 @BatchProcedureUnitId 	 Int,
 	 @BatchProcedureGroupId 	 int, 	 
 	 @ProcedureUnitId 	  	 Int,
 	 @UserId 	  	  	  	 Int,
 	 @SecondUserId 	  	  	 Int,
 	 @Debug 	  	  	  	 Int = NULL
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
-------------------------------------------------------------------------------
-- Declare General Variables
-------------------------------------------------------------------------------
Declare 
 	 @EventTimeStamp  	    	    	 DateTime,
  	 @BatchName  	    	    	    	 nvarchar(50),
  	 @BatchInstance  	    	    	 Int,
  	 @UnitProcedureName  	    	    	 nvarchar(50),
  	 @UnitProcedureInstance 	    	 Int,
  	 @OperationName  	    	    	 nvarchar(50),
  	 @OperationInstance  	    	    	 Int,
  	 @PhaseName  	    	    	    	 nvarchar(50),
  	 @PhaseInstance  	    	    	 Int,
  	 @ParameterName  	    	    	 nvarchar(50),
  	 @ParameterAttributeName  	    	 nvarchar(50),
  	 @ParameterAttributeUOM  	    	 nvarchar(50),
  	 @ParameterAttributeValue  	 nvarchar(50),
  	 @ParameterAttributeComments 	 nvarchar(255),
  	 @UserName  	    	    	   	 nvarchar(100),
  	 @UserSignature  	    	   	 nvarchar(255),
 	 @VarUOM 	  	  	  	  	 nvarchar(15),
 	 @VarPercision 	  	  	  	 Int
Declare
 	 @EventNum   	    	 nvarchar(50),
 	 @EventId   	    	 Int,
 	 @EventUnit          Int,
 	 @DataType  	    	 Int,
 	 @ParameterType   	 nvarchar(25),
 	 @BatchStartTime  	 datetime,
 	 @BatchEndTime  	  	 datetime,
 	 @BatchProductId 	 int,
 	 @VarId  	    	     	 Int,
 	 @VarUnitId       	 int,
 	 @CommentId       	 int,
 	 @EventType 	  	 nvarchar(100),
 	 @EntryOn 	  	  	 Datetime
Declare
 	 @Error 	 nvarchar(255),
 	 @Rc 	  	 int
Declare @ID Int
DECLARE 	 @CheckTestId 	  	 BigInt,
 	  	 @CheckCommentId 	 Int,
 	  	 @LastCommentId 	  	 Int,
 	  	 @SPCommentId 	  	 Int
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_ProcessParameterReport)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_ProcessParameterReport /EventTransactionId: ' + Isnull(convert(nvarchar(10),@EventTransactionId),'Null')  + 
 	 ' /BatchUnitId: ' + isnull(convert(nvarchar(10),@BatchUnitId),'Null') + 
 	 ' /BatchProcedureUnitId: ' + isnull(convert(nvarchar(10),@BatchProcedureUnitId),'Null') + ' /BatchProcedureGroupId: ' + isnull(convert(nvarchar(10),@BatchProcedureGroupId),'Null') + 
 	 ' /ProcedureUnitId: ' + isnull(convert(nvarchar(10),@ProcedureUnitId),'Null') + ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null') + 
  ' /SecondUserId: ' + isnull(convert(nvarchar(10),@SecondUserId),'Null') + ' /Debug: ' + isnull(convert(nvarchar(10),@Debug),'Null'))
  End
-------------------------------------------------------------------------------
-- Set Up Real-Time Updates
-------------------------------------------------------------------------------
  	    	  
Create Table #VarUpdates (
  	  Var_Id  	    	    	   	 Int,
  	  PU_Id  	    	    	   	  	 Int,
  	  User_Id  	    	    	   	 Int,
  	  Canceled  	    	   	  	 Int,
  	  Result  	    	    	   	 nvarchar(25) Null,
  	  Result_On  	    	   	  	 DateTime,
  	  Trans_Type  	    	   	 Int Null,
  	  Post_Update  	    	   	 Int Null,
 	  Second_User 	  	  	  	 Int Null
)
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
Select @Error = Null
Select @Rc = 0
-------------------------------------------------------------------------------
-- Load Variables with the Event_Transactions record being processed
-------------------------------------------------------------------------------
Select   	 @EventTimeStamp   	    	    	 = EventTimeStamp,
 	  	 @BatchName  	    	    	    	 = LTrim(RTrim(BatchName)),
 	  	 @BatchInstance  	    	    	 = BatchInstance,
 	  	 @UnitProcedureName  	    	    	 = LTrim(RTrim(UnitProcedureName)),
 	  	 @UnitProcedureInstance  	    	 = UnitProcedureInstance,
 	  	 @OperationName  	    	    	 = LTrim(RTrim(OperationName)),
 	  	 @OperationInstance  	    	    	 = OperationInstance,
 	  	 @PhaseName  	    	    	    	 = LTrim(RTrim(PhaseName)),
 	  	 @PhaseInstance  	    	    	 = PhaseInstance,
 	  	 @ParameterName  	    	    	 = LTrim(RTrim(ParameterName)),
 	  	 @ParameterAttributeName  	    	 = LTrim(RTrim(ParameterAttributeName)),
 	  	 @ParameterAttributeUOM  	    	 = LTrim(RTrim(ParameterAttributeUOM)),
 	  	 @ParameterAttributeValue  	 = LTrim(RTrim(ParameterAttributeValue)),
 	  	 @ParameterAttributeComments  	 = LTrim(RTrim(ParameterAttributeComments)),
 	  	 @UserName  	    	    	   	 = LTrim(RTrim(UserName)),
 	  	 @UserSignature  	    	    	 = LTrim(RTrim(UserSignature)),
 	  	 @EventType 	  	  	  	 = LTrim(RTrim(EventType))
 	 From  Event_Transactions 
 	 Where EventTransactionId = @EventTransactionId
-------------------------------------------------------------------------------
-- Check record
-------------------------------------------------------------------------------
IF 	 @BatchName = '' or @BatchName Is Null
 	 SELECT 	 @BatchName = Null
ELSE
 SELECT 	 @BatchName = @BatchName + Isnull('|' + Convert(nvarchar(10),@BatchInstance),'')
IF 	 @UnitProcedureName = '' or @UnitProcedureName Is Null
 	  SELECT 	 @UnitProcedureName = Null
ELSE
 	  SELECT 	 @UnitProcedureName = @UnitProcedureName + Isnull(':' + Convert(nvarchar(10),@UnitProcedureInstance),'')
 	 
IF 	 @OperationName = '' or @OperationName Is Null
 	 SELECT 	 @OperationName = Null
ELSE
 	 SELECT 	 @OperationName = @OperationName  + Isnull(':' + Convert(nvarchar(10),@OperationInstance),'')
IF 	 @PhaseName = '' SELECT 	 @PhaseName = Null
IF 	 @UnitProcedureName = '' SELECT 	 @UnitProcedureName = Null
IF 	 @OperationName = '' SELECT 	 @OperationName = Null
IF 	 @ParameterName = '' SELECT 	 @ParameterName = Null
IF 	 @ParameterAttributeName = '' SELECT 	 @ParameterAttributeName = Null
IF 	 @ParameterAttributeUOM = '' SELECT 	 @ParameterAttributeUOM = Null
IF 	 @ParameterAttributeValue = '' SELECT 	 @ParameterAttributeValue = Null
IF 	 @ParameterAttributeComments = '' SELECT 	 @ParameterAttributeComments = Null
IF 	 @UserName = '' SELECT 	 @UserName = Null
IF 	 @UserSignature = '' SELECT 	 @UserSignature = Null
If (@ParameterName is Null) 
  Begin
  	  Select @Error = 'Missing Parameter Name'
  	  Goto Errc
  End
If (@ParameterAttributeName <> 'Value') or (@ParameterAttributeName is null)
  Begin
  	  Select @Error = 'Missing Parameter Attribute Name'
  	  Goto Errc
  End
If (@ParameterAttributeValue is null)
  Begin
  	  Select @Error = 'Missing Parameter Attribute Value'
  	  Goto Errc
  End
If LEN(@ParameterAttributeValue) > 25
  Begin
  	  Select @Error = 'Parameter Attribute Value must be < 25'
  	  Goto Errc
  End
Select @DataType = 2
If isnumeric(@ParameterAttributeValue) = 0
  Select  @DataType = 3
If @BatchProcedureGroupId Is Null
  Begin
  	  Select @Error = 'Variable Group Is Null'
  	  Goto Errc
  End
Select @BatchEndTime = @EventTimestamp
-------------------------------------------------------------------------------
-- Create Variable And Get Timestamp Of Batch
-------------------------------------------------------------------------------
Select @Rc = 0
exec @Rc = spBatch_GetSingleVariable
 	 @EventTransactionId,
 	 @VarId OUTPUT,
 	 @BatchName OUTPUT,
 	 @BatchUnitId,
 	 @BatchProcedureUnitId,
 	 @BatchProcedureGroupId,
 	 @BatchStartTime OUTPUT,
 	 @BatchEndTime OUTPUT, 	  	  	  	 
 	 @BatchProductId OUTPUT,
 	 0,
 	 @UnitProcedureName,
 	 @OperationName,
 	 @PhaseName,
 	 @PhaseInstance,
 	 @ParameterName,
 	 @ParameterAttributeUOM,
 	 @DataType,
 	 @ParameterType OUTPUT,
 	 @VarUOM 	  	 OUTPUT,
 	 @VarPercision 	 OUTPUT,
 	 @UserId,
 	 @Debug
If @Rc <> 1 Goto Errc
Select @ParameterAttributeValue = dbo.fnCmn_ConvertEngUnit(@ParameterAttributeUOM,@VarUOM,@ParameterAttributeValue,@VarPercision)
-------------------------------------------------------------------------------
-- Find Event Id To Attach Test Result To
-------------------------------------------------------------------------------
-- NOTE:  	 This Event Numbering Convention Is Also Used In "Create Events" 
-- 	  	  	  	 Stored Procedure And MUST Match
--
-------------------------------------------------------------------------------
Select @EventId = NULL
If @EventType = 'EventReport'
 	 Begin
 	  	 Select @BatchEndTime = @EventTimeStamp
 	 End
Else
 	 Begin
 	  	 If @ParameterType = 'Procedure'
 	  	   Begin 
 	  	     Select @EventNum = 'U:' + @BatchName + '!' + @UnitProcedureName
 	  	     Select @EventUnit = @BatchProcedureUnitId
 	  	 
 	  	   End
 	  	 Else
 	  	   Begin
 	  	     Select @EventNum = @BatchName
 	  	     Select @EventUnit = @BatchUnitId
 	  	 
 	  	   End
 	  	 
 	  	 If @ParameterType <> 'Operation' and @ParameterType <> 'Phase'
 	  	 Begin
 	  	  	 Select @EventId = Event_Id
 	  	  	   From Events
 	  	  	   Where PU_Id = @EventUnit and Event_Num = @EventNum
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- If Event Id Is Not Found - Is Just A Warning - Processing Will Continue
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 If @EventId Is Null
 	  	  	   Begin
 	  	  	     Select @Error = 'Warning - ' + @ParameterType + ' Event Id Not Found For Parameter Update'
 	  	  	   	  	 UPDATE 	 Event_Transactions 
 	  	  	  	  	  	 SET 	 OrphanedReason  	  	 = @Error 
 	  	  	  	  	  	 WHERE 	 EventTransactionId  	 = @EventTransactionId
 	  	  	 
 	  	  	   End 
 	  	 End
 	 End
-------------------------------------------------------------------------------
-- If There Is A Comment, Go Ahead And Insert It
-------------------------------------------------------------------------------
If @ParameterAttributeComments Is Not Null
  Begin
    insert into comments (user_id, modified_on, cs_id, comment, comment_text, entry_on) 
      Values (@UserId, @EventTimeStamp, 1, @ParameterAttributeComments, @ParameterAttributeComments, @EventTimeStamp)
    Select @CommentId = Scope_Identity()
 	  	 --NOTE: Currently We Do Not Send A Real-Time Update Specifically For The Comment
  End
-------------------------------------------------------------------------------
-- Go Ahead And Update Variable
-------------------------------------------------------------------------------
Declare @Test_Id BigInt
--Prepare Unit Id
If @ParameterType <> 'Batch' and @ParameterType <> 'Procedure'
  Select @VarUnitId = @BatchProcedureUnitId
Else
  Select @VarUnitId = @BatchUnitId
If @BatchEndTime is Null
  Begin
  	  Select @Error = 'Unable to find event timestamp'
  	  Goto Errc
  End
-------------------------------------------------------------------------------
-- Get the current values for the test record, if any
-------------------------------------------------------------------------------
SELECT 	 @CheckTestId 	  	 = NULL,
 	 @CheckCommentId 	  	 = NULL
SELECT 	 @CheckTestId 	  	 = Test_Id,
 	 @CheckCommentId 	  	 = Comment_Id
 	 FROM 	 Tests
 	 WHERE 	 Var_Id 	  	 = @VarId
 	 AND 	 Result_On 	 = @BatchEndTime
-------------------------------------------------------------------------------
-- If this is a new test record of the existing test record has no comment,
-- it will call the sp passing the new comment as the input parameters (null or
-- not)
-------------------------------------------------------------------------------
IF 	 @CheckTestId 	 Is Null
BEGIN
 	 SELECT 	 @SPCommentId 	 = @CommentId
END
ELSE
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- If there is a tesst record
 	 -------------------------------------------------------------------------------
 	 IF 	 @CheckCommentId 	 Is Null
 	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- but not existing comment, it will call the sp with the new comment (null or
 	  	 -- not)
 	  	 -------------------------------------------------------------------------------
 	  	 SELECT 	 @SPCommentId 	 = @CommentId
 	 END
 	 ELSE
 	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- there is a test with comment, so calls the sp passing the existing commentid
 	  	 -------------------------------------------------------------------------------
 	  	 SELECT 	 @SPCommentId 	 = @CheckCommentId
 	  	 IF 	 @CommentId 	 Is Not Null
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- If the new comment exist, we need to add to the chain:
 	  	  	 --  Set the TopOfChain column for the TopOfChain comment, if not already done
 	  	  	 --
 	  	  	 -- The tests.commentId should always be the TopOfChain comment
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 UPDATE 	 Comments
 	  	  	  	 SET 	 TopOfChain_Id 	 = @CheckCommentId
 	  	  	  	 WHERE 	 Comment_Id 	 = @CheckCommentId
 	  	  	  	 AND 	 TopOfChain_Id 	 Is Null 	 
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 --  Make the last comment in the chain to point to the new comment
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 SELECT 	 @LastCommentId 	 = NULL
 	  	  	 SELECT 	 @LastCommentId 	 = Comment_Id
 	  	  	  	 FROM 	 Comments
 	  	  	  	 WHERE 	 TopOfChain_Id 	 = @CheckCommentId
 	  	  	  	 AND 	 NextComment_Id 	 Is Null
 	  	  	 IF 	 @LastCommentId 	 Is Not Null
 	  	  	 BEGIN
 	  	  	  	 UPDATE 	 Comments
 	  	  	  	  	 SET 	 NextComment_Id 	 = @CommentId
 	  	  	  	  	 WHERE 	 Comment_Id 	 = @LastCommentId
 	  	  	 END
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 --  Set the TopChain column for the new comment to poin to the TopOfChain comment
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 UPDATE 	 Comments
 	  	  	  	 SET 	 TopOfChain_Id 	 = @CheckCommentId
 	  	  	  	 WHERE 	 Comment_Id 	 = @CommentId
 	  	 END
 	 END
END
-------------------------------------------------------------------------------
-- TransNum of 4 to update comment
-------------------------------------------------------------------------------
Execute spServer_DBMgrUpdTest2 @VarId,@UserId,0,@ParameterAttributeValue,@BatchEndTime,4,@SPCommentId,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 null,@EventId,@VarUnitId,@Test_Id OUTPUT,
 	    	    	    	    	    	    	   @EntryOn OUTPUT,@SecondUserId
-------------------------------------------------------------------------------
-- Send Out Real-Time Updates
-------------------------------------------------------------------------------
Insert InTo #VarUpdates(Var_Id,PU_Id,User_Id,Canceled,Result,Result_On,Trans_Type,Post_Update,Second_User)
 Values(@VarId,@VarUnitId,@UserId,0,@ParameterAttributeValue,@BatchEndTime,1,1,@SecondUserId)
If (Select Count(*) From #VarUpdates) > 0
  	  Select 2,Var_Id,PU_Id,User_Id,Canceled,Result,Result_On,Trans_Type,Post_Update,Second_User From #VarUpdates
Finish:
-------------------------------------------------------------------------------
-- Normal exit
-------------------------------------------------------------------------------
Select @Rc = 1
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessParameterReport)')
RETURN(@Rc)
-------------------------------------------------------------------------------
-- Handle exceptions
-------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	  	 = isnull(OrphanedReason,@Error),
 	  	 OrphanedFlag  	  	 = 1 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessParameterReport)')
RETURN(-100)
