CREATE PROCEDURE dbo.spServer_DBMgrUpdWasteEvent
  @WED_Id           int        OUTPUT, 	 --  1: Input/Output
  @PU_Id            int, 	  	         --  2: Input
  @Source_PU_Id     int, 	  	         --  3: Input
  @TimeStamp        Datetime, 	  	  	 --  4: Input
  @WET_Id           int, 	  	         --  5: Input
  @WEMT_Id          int, 	  	         --  6: Input
  @Reason_Level1    int, 	  	         --  7: Input
  @Reason_Level2    int, 	  	         --  8: Input
  @Reason_Level3    int, 	  	         --  9: Input
  @Reason_Level4    int, 	  	         -- 10: Input
  @Event_Id         int, 	  	         -- 11: Input
  @Amount           float, 	  	  	  	 -- 12: Input
  @Future1          float = Null, 	  	         -- 13: Input     /* 11/20/02 Marker1 */
  @Future2          float = Null, 	  	         -- 14: Input     /* 11/20/02 Marker2 */
  @Transaction_Type int, 	  	         -- 15: Input
  @TransNum 	  	  	 int, 	  	  	     -- New Param
  @UserId 	  	  	 int, 	  	  	  	 -- New Param
  @Action1 	  	  	 int, 	  	  	  	 -- New Param
  @Action2 	  	  	 int, 	  	  	  	 -- New Param
  @Action3 	  	  	 int, 	  	  	  	 -- New Param
  @Action4 	  	  	 int, 	  	  	  	 -- New Param
  @ActionCommentId 	 int, 	  	  	     -- New Param
  @ResearchCommentId int, 	  	         -- New Param
  @ResearchStatusId int, 	  	         -- New Param
  @CommentId 	  	 int, 	  	  	     -- New Param
  @Future3 	  	  	 float = Null, 	  	         -- New Param 	 /* 11/20/02 TargetProdRate */
  @ResearchOpenDate datetime, 	  	     -- New Param
  @ResearchCloseDate datetime, 	  	     -- New Param
  @ResearchUserId 	 int,           	  	 -- New Param
  @WEFault_Id 	  	 int 	  	  	 = Null, -- New Param
  @Event_Reason_Tree_Data_Id  Int = Null,  -- Used For Categories 	 
  @Dimension_Y 	  	 Float      = Null,  -- New Param
  @Dimension_Z 	  	 Float      = Null,  -- New Param
  @Dimension_A 	  	 Float      = Null,  -- New Param
  @Start_Coordinate_Z Float    = Null,  -- New Param
  @Start_Coordinate_A Float    = Null,  -- New Param
  @Dimension_X 	  	 Float      = Null,  -- New Param
  @Start_Coordinate_X Float    = Null,  -- New Param
  @Start_Coordinate_Y Float    = Null,  -- New Param
  @User_General_4 	 nVarChar(255) = Null,  -- New Param
  @User_General_5 	 nVarChar(255) = Null,  -- New Param
  @Work_Order_Number nVarChar(50) = Null,  -- New Param
  @User_General_1 	 nVarChar(255) = Null,  -- New Param
  @User_General_2 	 nVarChar(255) = Null,  -- New Param
  @User_General_3 	 nVarChar(255) = Null,  -- New Param
  @ECID 	  	  	  	 Int 	  	  	  = Null,
  @SignatureId 	  	 int          = Null,
  @ReturnResultSets 	 Int          = 1 	  	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
 AS
  --
  -- Return Values:
  --
  --   (-100) Error.
  --   (   1) Success: New record added.
  --   (   2) Success: Existing record modified.
  --   (   3) Success: Existing record deleted.
  --   (   4) Success: No action taken.
  --
  -- Declare local variables.
  --
  DECLARE @Old_WED_Id    int,
 	  	  	 @Old_Timestamp Datetime,
 	  	  	 @T1            char(20),
 	  	  	 @T2            char(20),
 	  	  	 @TreeId 	  	      Int,
 	  	  	 @MyOwnTrans    Int,
 	  	  	 @DeleteComment_Id1 int,
 	  	  	 @DeleteComment_Id2 int,
 	  	  	 @DeleteComment_Id3 int,
 	  	  	 @EntryOn 	  	 DateTime,
 	  	  	 @LastResearchStatus Int,
 	  	  	 @LastOpenDate 	 DateTime,
 	  	  	 @RC 	  	  	  	 Int = -100
Select @EntryOn = dbo.fnServer_CmnGetDate(getUTCdate())
  If @@Trancount = 0
 	   Select @MyOwnTrans = 1
  Else
 	   Select @MyOwnTrans = 0
 	   
 	 If (@TransNum =1010) -- Transaction From WebUI
 	 BEGIN
 	  	 SET @Event_Reason_Tree_Data_Id = Null 	   
 	  	 IF @WED_Id Is Not Null
 	  	 BEGIN
 	  	  	 SELECT @LastResearchStatus = Research_Status_Id,@LastOpenDate = Research_Open_Date 
 	  	  	   FROM Waste_Event_Details WHERE WED_Id = @WED_Id
 	  	 END
 	  	 IF @ResearchStatusId is Null And  @LastResearchStatus is Not Null
 	  	 BEGIN
 	  	  	 SET @ResearchOpenDate = Null
 	  	  	 SET @ResearchCloseDate = Null
 	  	  	 SET @ResearchUserId = Null 
 	  	 END
 	  	 IF @ResearchStatusId = 1 and (@LastResearchStatus != 1 or  @LastResearchStatus is Null)-- Open
 	  	 BEGIN
 	  	  	 SET @ResearchOpenDate = @EntryOn
 	  	  	 SET @ResearchCloseDate = Null
 	  	  	 SET @ResearchUserId = @UserId 
 	  	 END
 	  	 IF @ResearchStatusId = 2 and (@LastResearchStatus != 2  or  @LastResearchStatus is Null)-- Close
 	  	 BEGIN
 	  	  	 SET @ResearchCloseDate = @EntryOn
 	  	  	 IF @LastOpenDate Is Null
 	  	  	 SET @ResearchOpenDate = @EntryOn
 	  	  	 SET @ResearchUserId = @UserId 
 	  	 END
 	  	 SELECT @TransNum = 2
 	 END
  If @TransNum Not In (0,2,3,4,1000,1001,1002)
    BEGIN
      RETURN(4)
    END
  	 IF @TransNum in (1000,1001,1002)/* Update Comment*/
 	 BEGIN
 	  	 IF @WED_Id is Null or @UserId Is Null -- Check required fields
 	  	  	 RETURN(4)
 	  	 SET @Old_WED_Id  = NULL
 	  	 SELECT  @Old_WED_Id = WED_Id FROM Waste_Event_Details WHERE WED_Id = @WED_Id
 	  	 IF @Old_WED_Id is Null RETURN(3)-- Not Found
 	  	 IF @TransNum = 1000
 	  	  	 UPDATE Waste_Event_Details SET Cause_Comment_Id  = @CommentId ,User_Id  = @UserId,Entry_On = @EntryOn  
 	  	  	  	  	 WHERE WED_Id = @WED_Id
 	  	 IF @TransNum = 1001
 	  	  	 UPDATE Waste_Event_Details SET Action_Comment_Id = @ActionCommentId,User_Id  = @UserId ,Entry_On = @EntryOn
 	  	  	  	  	 WHERE WED_Id = @WED_Id
 	  	 IF @TransNum = 1002
 	  	  	 UPDATE Waste_Event_Details SET Research_Comment_Id = @ResearchCommentId,User_Id  = @UserId,Entry_On = @EntryOn 
 	  	  	  	  	 WHERE WED_Id = @WED_Id
 	  	 RETURN(2)
 	 END
   --
  -- Make sure mandatory arguments are not null.
  --
  If @Source_PU_Id = 0
 	  	 Select @Source_PU_Id = Null
  If @ECID = 0
 	 Select @ECID = Null
  IF @PU_Id IS NULL
    BEGIN
      RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@PU_Id')
      RETURN(-100)
    END
  IF @TimeStamp IS NULL
    BEGIN
      RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@TimeStamp')
      RETURN(-100)
    END
  IF @Transaction_Type IS NULL
    BEGIN
      RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@Transaction_Type')
      RETURN(-100)
    END
/* Check for dups*/
IF @ECID IS NOT NULL AND @Transaction_Type = 1 
BEGIN
 	 DECLARE @CheckWEDId INT
 	 SET @CheckWEDId =NULL
 	 SELECT @CheckWEDId = WED_Id
 	  	 FROM Waste_Event_Details
 	  	 WHERE EC_Id = @ECID and TimeStamp = @TimeStamp and PU_Id = @PU_Id 
 	 IF @CheckWEDId IS NOT NULL
 	 BEGIN
 	  	 RETURN(4)
 	 END
END
  --
  -- Make sure the transaction type is ok. Depending on the transaction type,
  -- other arguments may also become mandatory. Make sure these dependant
  -- mandatory arguments are not null.
  --
  IF @Transaction_Type = 2 OR @Transaction_Type = 3
    BEGIN
      IF @WED_Id IS NULL
        BEGIN
          RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@WED_Id')
          RETURN(-100)
        END
    END
  ELSE IF @Transaction_Type <> 1
    BEGIN
      RAISERROR('Unknown transaction type detected:  %lu', 11, -1, @Transaction_Type)
      RETURN(-100)
    END
  --
  -- Begin a new transaction.
  --
  If @MyOwnTrans = 1 
 	  	 Begin
 	  	  	 BEGIN TRANSACTION
 	  	  	 DECLARE @XLock BIT SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	  	 End
  --
  -- Handle a delete transaction.
  --
  IF @Transaction_Type = 3
    BEGIN
      --
      -- Find the record. If it cannot be found, return success as it is
      -- already deleted. Otherwise make sure that its event number and
      -- timestamp match the request. If not, abort the delete.
      --
      SELECT @Old_WED_Id = WED_Id,
             @Old_Timestamp = Timestamp
        FROM Waste_Event_Details WHERE WED_Id = @WED_Id
      IF @Old_WED_Id IS NULL
        BEGIN
          If @MyOwnTrans = 1 ROLLBACK TRANSACTION
       	   RETURN(3)
        END
      ELSE IF (@Old_Timestamp <> @Timestamp)
       	 BEGIN
          SELECT @T1 = CONVERT(char(20), @TimeStamp, 113),
                 @T2 = CONVERT(char(20), @Old_TimeStamp , 113)
          If @MyOwnTrans = 1 ROLLBACK TRANSACTION
          RAISERROR( 'Timestamp mismatch detected in delete request for table [Waste_Event_Details] (timestamp/oldtimestamp = %s / %s )' , 11, -1, @T1, @T2)
          RETURN(-100)
        END
      --
      -- Delete the record.
      --
 	  	 Select @DeleteComment_Id1 = NULL, @DeleteComment_Id2 = NULL, @DeleteComment_Id3 = NULL
 	  	 Select @DeleteComment_Id1 = Research_Comment_Id, @DeleteComment_Id1 = Cause_Comment_Id , @DeleteComment_Id1 = Action_Comment_Id From Waste_Event_Details WHERE WED_Id = @WED_Id
 	  	 If  @DeleteComment_Id1 IS NOT NULL 
 	  	 BEGIN
 	  	  	 Delete From Comments Where TopOfChain_Id = @DeleteComment_Id1
 	  	  	 Delete From Comments Where Comment_Id = @DeleteComment_Id1
 	  	 END 
 	  	 If  @DeleteComment_Id2 IS NOT NULL 
 	  	 BEGIN
 	  	  	 Delete From Comments Where TopOfChain_Id = @DeleteComment_Id2
 	  	  	 Delete From Comments Where Comment_Id = @DeleteComment_Id2
 	  	 END 
 	  	 If  @DeleteComment_Id3 IS NOT NULL 
 	  	 BEGIN
 	  	  	 Delete From Comments Where TopOfChain_Id = @DeleteComment_Id3
 	  	  	 Delete From Comments Where Comment_Id = @DeleteComment_Id3
 	  	 END 
 	     Execute spServer_DBMgrCleanupWasteTime @WED_Id,Null,@ReturnResultSets,@UserId
 	  	 DECLARE @originalContextInfo VARBINARY(128)
 	  	 DECLARE @ContextInfo varbinary(128)
 	  	 SET @originalContextInfo = Context_Info()
 	  	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	  	 SET Context_Info @ContextInfo 
 	  	 DELETE FROM Waste_Event_Details WHERE WED_Id = @WED_Id 	 
 	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo 
 	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	 Set @RC = 3
 	  	 GOTO ReturnRSandExit
    END
  --
  -- Handle an insert transaction.
  --
  IF @Transaction_Type = 1
  BEGIN
      --
      -- Insert the waste event.
      --
  	  	   -- Look up @Event_Reason_Tree_Data_Id If necessary
 	   If @Event_Reason_Tree_Data_Id is null and @Reason_Level1 is not null
 	  	 Begin
 	  	   Select @TreeId = Name_Id From Prod_Events where PU_Id = @Source_PU_Id and Event_Type = 3
 	    	   If @Reason_Level2 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else If @Reason_Level3 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else If @Reason_Level4 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else 
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id  = @Reason_Level4 and Tree_Name_Id = @TreeId
 	  	 End
     INSERT INTO Waste_Event_Details(User_Id, PU_Id, Source_PU_Id, TimeStamp, WET_Id, WEMT_Id,
 	  	  	  	  	  	  	  	 Reason_Level1, Reason_Level2, Reason_Level3,
 	  	  	  	  	  	  	  	 Reason_Level4, Event_Id, Amount,
 	  	  	  	  	  	  	  	 Action_Level1, Action_Level2, Action_Level3, Action_Level4, 
 	  	  	  	  	  	  	  	 Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id,Research_User_Id,
 	  	  	  	  	  	  	  	 Research_Status_Id, Research_Open_Date, Research_Close_Date, WEFault_Id, 
 	  	  	  	  	  	  	  	 Event_Reason_Tree_Data_Id, Dimension_Y, Dimension_Z, Dimension_A, 
 	  	  	  	  	  	  	  	 Start_Coordinate_Z, Start_Coordinate_A, Dimension_X, Start_Coordinate_X,
 	  	  	  	  	  	  	  	 Start_Coordinate_Y, User_General_4, User_General_5, Work_Order_Number, 
 	  	  	  	  	  	  	  	 User_General_1, User_General_2, User_General_3,EC_Id, Signature_Id,Entry_On)
        VALUES(@UserId, @PU_Id, @Source_PU_Id, @TimeStamp, @WET_Id, @WEMT_Id,
               @Reason_Level1, @Reason_Level2, @Reason_Level3,
               @Reason_Level4, @Event_Id, @Amount,
               @Action1, @Action2, @Action3, @Action4,
               @CommentId, @ActionCommentId,@ResearchCommentId, @ResearchUserId,
               @ResearchStatusId, @ResearchOpenDate, @ResearchCloseDate, @WEFault_Id, 
 	  	  	  	  	  	  	  @Event_Reason_Tree_Data_Id, @Dimension_Y, @Dimension_Z, @Dimension_A, 
 	  	  	  	  	  	  	  @Start_Coordinate_Z, @Start_Coordinate_A, @Dimension_X, @Start_Coordinate_X,
 	  	  	  	  	  	  	  @Start_Coordinate_Y, @User_General_4, @User_General_5, @Work_Order_Number, 
 	  	  	  	  	  	  	  @User_General_1, @User_General_2, @User_General_3,@ECID,@SignatureId,@EntryOn)
      SELECT @WED_Id = Scope_Identity()
      IF @WED_Id IS NULL
        BEGIN
          If @MyOwnTrans = 1 ROLLBACK TRANSACTION
          RAISERROR('Failed to determine new created identity in insert request for table %s. Request aborted.', 11, -1, 'Waste_Event_Details')
          RETURN(-100)
        END
      If @MyOwnTrans = 1 COMMIT TRANSACTION
 	   Set @RC = 1
 	   GOTO ReturnRSandExit
    END
  --
  -- Handle an update transaction.
  --
  IF @Transaction_Type = 2
    BEGIN
      -- Handle a modify transaction. First, Make sure the event has not
      -- been deleted.
      --
      SELECT @Old_WED_Id = WED_Id,
             @Old_Timestamp = Timestamp
        FROM Waste_Event_Details WHERE WED_Id = @WED_Id
      IF @Old_WED_Id IS NULL
        BEGIN
          If @MyOwnTrans = 1 ROLLBACK TRANSACTION
          RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@WED_Id')
          RETURN(-100)
        END
      --
      -- Update the waste event.
      --
     	 If @TransNum = 0
     	   Begin
       	  	 Select @PU_Id = IsNull(@PU_Id,PU_Id),
 	  	  	  	 @Source_PU_Id = IsNull(@Source_PU_Id,Source_PU_Id),
 	  	  	  	 @TimeStamp = IsNull(@TimeStamp,TimeStamp),
 	  	  	  	 @WET_Id = IsNull(@WET_Id,WET_Id),
 	  	  	  	 @WEMT_Id = IsNull(@WEMT_Id,WEMT_Id),
 	  	  	  	 @Reason_Level1 = IsNull(@Reason_Level1,Reason_Level1),
 	  	  	  	 @Reason_Level2 = IsNull(@Reason_Level2,Reason_Level2),
 	  	  	  	 @Reason_Level3 = IsNull(@Reason_Level3,Reason_Level3),
 	  	  	  	 @Reason_Level4 = IsNull(@Reason_Level4,Reason_Level4),
 	  	  	  	 @Event_Id = IsNull(@Event_Id,Event_Id),
 	  	  	  	 @Amount = IsNull(@Amount,Amount),
 	  	  	  	 @Action1 = IsNull(@Action1,Action_Level1),
 	  	  	  	 @Action2 = IsNull(@Action2,Action_Level2),
 	  	  	  	 @Action3 = IsNull(@Action3,Action_Level3),
 	  	  	  	 @Action4 = IsNull(@Action4,Action_Level4),
 	  	  	  	 @UserId = IsNull(@UserId,User_Id),
 	  	  	  	 @ResearchUserId = IsNull(@ResearchUserId,Research_User_Id),
 	  	  	  	 @ResearchStatusId = IsNull(@ResearchStatusId,Research_Status_Id),
 	  	  	  	 @ResearchOpenDate = IsNull(@ResearchOpenDate,Research_Open_Date),
 	  	  	  	 @ResearchCloseDate = IsNull(@ResearchCloseDate,Research_Close_Date),
 	  	  	  	 @WEFault_Id = IsNull(@WEFault_Id,WEFault_Id),
 	  	  	  	 @Dimension_Y = IsNull(@Dimension_Y,Dimension_Y),
 	  	  	  	 @Dimension_Z = IsNull(@Dimension_Z,Dimension_Z),
 	  	  	  	 @Dimension_A = IsNull(@Dimension_A,Dimension_A),
 	  	  	  	 @Start_Coordinate_Z = IsNull(@Start_Coordinate_Z,Start_Coordinate_Z),
 	  	  	  	 @Start_Coordinate_A = IsNull(@Start_Coordinate_A,Start_Coordinate_A),
 	  	  	  	 @Dimension_X = IsNull(@Dimension_X,Dimension_X),
 	  	  	  	 @Start_Coordinate_X = IsNull(@Start_Coordinate_X,Start_Coordinate_X),
 	  	  	  	 @Start_Coordinate_Y = IsNull(@Start_Coordinate_Y,Start_Coordinate_Y),
 	  	  	  	 @User_General_4 = IsNull(@User_General_4,User_General_4),
 	  	  	  	 @User_General_5 = IsNull(@User_General_5,User_General_5),
 	  	  	  	 @Work_Order_Number = IsNull(@Work_Order_Number,Work_Order_Number),
 	  	  	  	 @User_General_1 = IsNull(@User_General_1,User_General_1),
 	  	  	  	 @User_General_2 = IsNull(@User_General_2,User_General_2),
 	  	  	  	 @User_General_3 = IsNull(@User_General_3,User_General_3),
 	  	  	  	 @ECID = IsNull(@ECID,EC_Id),
            @SignatureId = IsNull(@SignatureId,Signature_Id),
            @CommentId = IsNull(@CommentId, Cause_Comment_Id),
            @ActionCommentId 	 = IsNull(@ActionCommentId, Action_Comment_Id),
            @ResearchCommentId = IsNull(@ResearchCommentId, Research_Comment_Id)
       	  	  From Waste_Event_Details
       	  	  Where (WED_Id = @WED_Id)
     	   End
     	 If @TransNum = 2  and @ECID Is Null  -- Always do ec Id
     	   Begin
       	  	 Select  	 @ECID = EC_Id From Waste_Event_Details 	 Where WED_Id = @WED_Id
     	   End
     	 If @TransNum = 3 -- From Waste Display (these fields not in message from old waste display)
     	   Begin
       	  	 Select @Dimension_Y = IsNull(@Dimension_Y,Dimension_Y),
 	  	  	  	 @Dimension_Z = IsNull(@Dimension_Z,Dimension_Z),
 	  	  	  	 @Dimension_A = IsNull(@Dimension_A,Dimension_A),
 	  	  	  	 @Dimension_X = IsNull(@Dimension_X,Dimension_X),
 	  	  	  	 @Start_Coordinate_Z = IsNull(@Start_Coordinate_Z,Start_Coordinate_Z),
 	  	  	  	 @Start_Coordinate_A = IsNull(@Start_Coordinate_A,Start_Coordinate_A),
 	  	  	  	 @Start_Coordinate_X = IsNull(@Start_Coordinate_X,Start_Coordinate_X),
 	  	  	  	 @Start_Coordinate_Y = IsNull(@Start_Coordinate_Y,Start_Coordinate_Y),
 	  	  	  	 @User_General_4 = IsNull(@User_General_4,User_General_4),
 	  	  	  	 @User_General_5 = IsNull(@User_General_5,User_General_5),
 	  	  	  	 @User_General_1 = IsNull(@User_General_1,User_General_1),
 	  	  	  	 @User_General_2 = IsNull(@User_General_2,User_General_2),
 	  	  	  	 @User_General_3 = IsNull(@User_General_3,User_General_3),
 	  	  	  	 @CommentId = IsNull(@CommentId, Cause_Comment_Id),
 	  	  	  	 @ActionCommentId 	 = IsNull(@ActionCommentId, Action_Comment_Id),
 	  	  	  	 @ResearchCommentId = IsNull(@ResearchCommentId, Research_Comment_Id),
 	  	  	  	 @ResearchUserId = IsNull(@ResearchUserId,Research_User_Id),
 	  	  	  	 @ResearchStatusId = IsNull(@ResearchStatusId,Research_Status_Id),
 	  	  	  	 @ResearchOpenDate = IsNull(@ResearchOpenDate,Research_Open_Date),
 	  	  	  	 @ResearchCloseDate = IsNull(@ResearchCloseDate,Research_Close_Date),
 	  	  	  	 @Work_Order_Number = IsNull(@Work_Order_Number,Work_Order_Number),
 	  	  	  	 @ECID = IsNull(@ECID,EC_Id),
 	  	  	  	 @SignatureId = IsNull(@SignatureId,Signature_Id)
      	  	  From Waste_Event_Details
       	  	  Where (WED_Id = @WED_Id)
     	   End
 	  	 If @TransNum = 4 -- From Waste  + Display(these fields not in message)
 	  	 Begin
       	  	 Select  	 @UserId = IsNull(@UserId,User_Id),
 	  	  	  	 @Dimension_X = IsNull(@Dimension_X,Dimension_X),
 	  	  	  	 @Dimension_Y = IsNull(@Dimension_Y,Dimension_Y),
 	  	  	  	 @Dimension_Z = IsNull(@Dimension_Z,Dimension_Z),
 	  	  	  	 @Dimension_A = IsNull(@Dimension_A,Dimension_A),
 	  	  	  	 @Start_Coordinate_X = IsNull(@Start_Coordinate_X,Start_Coordinate_X),
 	  	  	  	 @Start_Coordinate_Y = IsNull(@Start_Coordinate_Y,Start_Coordinate_Y),
 	  	  	  	 @Start_Coordinate_Z = IsNull(@Start_Coordinate_Z,Start_Coordinate_Z),
 	  	  	  	 @Start_Coordinate_A = IsNull(@Start_Coordinate_A,Start_Coordinate_A),
 	  	  	  	 @User_General_1 = IsNull(@User_General_1,User_General_1),
 	  	  	  	 @User_General_2 = IsNull(@User_General_2,User_General_2),
 	  	  	  	 @User_General_3 = IsNull(@User_General_3,User_General_3),
 	  	  	  	 @User_General_4 = IsNull(@User_General_4,User_General_4),
 	  	  	  	 @User_General_5 = IsNull(@User_General_5,User_General_5),
 	  	  	  	 @Work_Order_Number = IsNull(@Work_Order_Number,Work_Order_Number),
 	  	  	  	 @ResearchCloseDate = IsNull(@ResearchCloseDate,Research_Close_Date),
 	  	  	  	 @ResearchOpenDate = IsNull(@ResearchOpenDate,Research_Open_Date),
 	  	  	  	 @ResearchStatusId = IsNull(@ResearchStatusId,Research_Status_Id),
 	  	  	  	 @ResearchUserId = IsNull(@ResearchUserId,Research_User_Id),
 	  	  	  	 @ECID = IsNull(@ECID,EC_Id)
      	  	  From Waste_Event_Details
       	  	  Where (WED_Id = @WED_Id)
 	  	 End
     	   
 	   If @Event_Reason_Tree_Data_Id is null and @Reason_Level1 is not null
 	  	 Begin
 	  	   Select @TreeId = Name_Id From Prod_Events where PU_Id = @Source_PU_Id and Event_Type = 3
 	    	   If @Reason_Level2 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else If @Reason_Level3 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else If @Reason_Level4 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else 
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id  = @Reason_Level4 and Tree_Name_Id = @TreeId
 	  	 End
 	   If (@Old_Timestamp <> @Timestamp) -- Event Moved
 	    	 Execute spServer_DBMgrCleanupWasteTime @WED_Id,@Timestamp,@ReturnResultSets,@UserId
      UPDATE Waste_Event_Details
        SET PU_Id = @PU_Id,
 	  	 Source_PU_Id = @Source_PU_Id,
 	  	 TimeStamp = @TimeStamp,
 	  	 WET_Id = @WET_Id,
 	  	 WEMT_Id = @WEMT_Id,
 	  	 Reason_Level1 = @Reason_Level1,
 	  	 Reason_Level2 = @Reason_Level2,
 	  	 Reason_Level3 = @Reason_Level3,
 	  	 Reason_Level4 = @Reason_Level4,
 	  	 Event_Id = @Event_Id,
 	  	 Amount = @Amount,
 	  	 Action_Level1 = @Action1,
 	  	 Action_Level2 = @Action2,
 	  	 Action_Level3 = @Action3,
 	  	 Action_Level4 = @Action4,
 	  	 User_Id = @UserId,
 	  	 Research_User_Id = @ResearchUserId,
 	  	 Research_Status_Id = @ResearchStatusId,
 	  	 Research_Open_Date = @ResearchOpenDate,
 	  	 Research_Close_Date = @ResearchCloseDate,
 	  	 WEFault_Id = @WEFault_Id,
 	  	 Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id,
 	  	 Dimension_Y = @Dimension_Y, 
 	  	 Dimension_Z = @Dimension_Z, 
 	  	 Dimension_A = @Dimension_A,
 	  	 Start_Coordinate_Z = @Start_Coordinate_Z, 
 	  	 Start_Coordinate_A = @Start_Coordinate_A, 
 	  	 Dimension_X = @Dimension_X, 
 	  	 Start_Coordinate_X = @Start_Coordinate_X,
 	  	 Start_Coordinate_Y = @Start_Coordinate_Y, 
 	  	 User_General_4 = @User_General_4, 
 	  	 User_General_5 = @User_General_5, 
 	  	 Work_Order_Number = @Work_Order_Number, 
 	  	 User_General_1 = @User_General_1, 
 	  	 User_General_2 = @User_General_2, 
 	  	 User_General_3 = @User_General_3,
 	  	 EC_Id = @ECId,
 	  	 Signature_id = @SignatureId,
 	  	       Entry_On = @EntryOn,
          Cause_Comment_Id = @CommentId,
          Action_Comment_Id = @ActionCommentId, 	 
          Research_Comment_Id = @ResearchCommentId 
        WHERE WED_Id = @WED_Id
      If @MyOwnTrans = 1 COMMIT TRANSACTION
 	   Set @RC = 2
 	   GOTO ReturnRSandExit
    END
ReturnRSandExit:
 	 if (@ReturnResultSets = 1) -- Send out the Result Set
 	 Begin
 	  	 Select 9, 0, @TransNum, @UserId, @Transaction_Type, @WED_Id, @PU_Id, @Source_PU_Id, @WET_Id, @WEMT_Id,
 	  	  	  	 @Reason_Level1, @Reason_Level2, @Reason_Level3, @Reason_Level4, @Event_Id, @Amount, Null, Null,
 	  	  	  	 @TimeStamp, @Action1, @Action2, @Action3, @Action4, @ActionCommentId, @ResearchCommentId,
 	  	  	  	 @ResearchStatusId, @ResearchOpenDate, @ResearchCloseDate, @CommentId, Null, @ResearchUserId,
 	  	  	  	 @WEFault_Id, @Event_Reason_Tree_Data_Id, @Dimension_X, @Dimension_Y, @Dimension_Z, @Dimension_A,
 	  	  	  	 @Start_Coordinate_X, @Start_Coordinate_Y, @Start_Coordinate_Z, @Start_Coordinate_A,
 	  	  	  	 @User_General_1, @User_General_2, @User_General_3, @User_General_4, @User_General_5, 
 	  	  	  	 @Work_Order_Number, @ECId, @SignatureId
 	 End
 	 Else if (@ReturnResultSets = 2) -- Put the Result Set into the Pending Result Sets table for DBMgr to pickup later
 	 Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 Select  RSTId = 9, PreDB = 0, TransNum = @TransNum, UserId = @UserId, TransType = @Transaction_Type,
 	  	  	  	  	 WasteEventId = @WED_Id, PUId = @PU_Id, SourcePUId = @Source_PU_Id, TypeId = @WET_Id, MeasId = @WEMT_Id,
 	  	  	  	  	 Reason1 = @Reason_Level1, Reason2 = @Reason_Level2, Reason3 = @Reason_Level3, Reason4 = @Reason_Level4,
 	  	  	  	  	 EventId = @Event_Id, Amount = @Amount, Obsolete1 = Null, Obsolete2 = Null,
 	  	  	  	  	 TimeStampCol = @TimeStamp, Action1 = @Action1, Action2 = @Action2, Action3 = @Action3, Action4 = @Action4,
 	  	  	  	  	 ActionCommentId = @ActionCommentId, ResearchCommentId = @ResearchCommentId, ResearchStatusId = @ResearchStatusId,
 	  	  	  	  	 ResearchOpenDate = @ResearchOpenDate, ResearchCloseDate = @ResearchCloseDate, CommentId = @CommentId,
 	  	  	  	  	 Obsolete3 = Null, ResearchUserId = @ResearchUserId, FaultId = @WEFault_Id, RsnTreeDataId = @Event_Reason_Tree_Data_Id,
 	  	  	  	  	 DimensionX = @Dimension_X, DimensionY = @Dimension_Y, DimensionZ = @Dimension_Z, DimensionA = @Dimension_A,
 	  	  	  	  	 StartCoordinateX = @Start_Coordinate_X, StartCoordinateY = @Start_Coordinate_Y, StartCoordinateZ = @Start_Coordinate_Z,
 	  	  	  	  	 StartCoordinateA = @Start_Coordinate_A, General1 = @User_General_1, General2 = @User_General_2,
 	  	  	  	  	 General3 = @User_General_3, General4 = @User_General_4, General5 = @User_General_5, OrderNum = @Work_Order_Number,
 	  	  	  	  	 ECID = @ECId, ESigId = @SignatureId
 	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 End
 	 RETURN(@RC)
RETURN(4)
