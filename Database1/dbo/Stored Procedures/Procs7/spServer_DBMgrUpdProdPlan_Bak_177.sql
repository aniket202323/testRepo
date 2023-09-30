CREATE PROCEDURE dbo.[spServer_DBMgrUpdProdPlan_Bak_177]
@PPId int OUTPUT,
@TransType int,
@TransNum int,
@PathId int, 
@CommentId int,
@ProdId int,
@ImpliedSequence int OUTPUT,
@PPStatusId int,
@PPTypeId int,
@SourcePPId int,
@UserId int,
@ParentPPId int,
@ControlType tinyint,
@ForecastStartTime datetime,
@ForecastEndTime datetime,
@EntryOn datetime OUTPUT,
@ForecastQuantity float,
@ProductionRate float, 
@AdjustedQuantity float, 
@BlockNumber nVarChar(50),
@ProcessOrder nVarChar(50),
@TransactionTime datetime = Null,
@Misc1 int = Null,
@Misc2 int = Null,
@Misc3 int = Null,
@Misc4 int = Null,
@BOMFormulationId bigint = NULL,
@UserGeneral1 	 nVarChar(255) = NULL,
@UserGeneral2 	 nVarChar(255) = NULL,
@UserGeneral3 	 nVarChar(255) = NULL,
@ExtendedInfo  	  VarChar(255) = NULL,
@InsertIntoPendingResultSet int = 0 --Flag to put ProductionPlan record in Pending_ResultSets table which inturn gets publised to RabbitMQ
AS
Declare @DebugFlag tinyint,
    	 @ID int,
 	  	 @SControlType Tinyint,
 	  	 @Now DateTime,
 	  	 @NewPPId 	 Int,
 	  	 @PPSetupId 	 Int,
 	  	 @PPStartId 	 Int,
 	  	 @MyPUId  	 Int,
 	  	 @DBMgrUpdProdSetupRC int,
 	  	 @DBMgrUpdProdPlanStartsFROMPlan int,
 	   @MyOwnTrans 	  	  	 Int
 	   Declare @Implied_Sequence Int,@Implied_Sequence_Offset Int, @Implied_Sequence_String nVarChar(15)
If @@Trancount = 0
 	 SELECT @MyOwnTrans = 1
Else
 	 SELECT @MyOwnTrans = 0
/*
Insert Into User_Parameters (Parm_Id, User_Id, Value, HostName) Values(100, 6, 1, '')
update User_Parameters set value = 0 WHERE Parm_Id = 100 and User_Id = 6
*/
SELECT @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) FROM User_Parameters WHERE User_Id = 6 and Parm_Id = 100
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) SELECT dbo.fnServer_CmnGetDate(getUTCdate()) SELECT @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdProdPlan /PPId: ' + Isnull(convert(nvarchar(10),@PPId),'Null') + ' /TransType: ' + Isnull(convert(nVarChar(4),@TransType),'Null') + 
     	 ' /TransNum: ' +  Isnull(convert(nVarChar(4),@TransNum),'Null') + ' /PathId: ' +  Isnull(convert(nVarChar(4),@PathId),'Null') + 
     	 ' /CommentId: ' +  Isnull(convert(nvarchar(10),@CommentId),'Null') + ' /ProdId: ' +  Isnull(convert(nVarChar(4),@ProdId),'Null') + 
     	 ' /ImpliedSequence: ' +  Isnull(convert(nvarchar(10),@ImpliedSequence),'Null') + ' /PPStatusId: ' +  Isnull(convert(nVarChar(4),@PPStatusId),'Null') + 
     	 ' /PPTypeId: ' +  Isnull(convert(nVarChar(4),@PPTypeId),'Null') + ' /SourcePPId: ' +  Isnull(convert(nvarchar(10),@SourcePPId),'Null') + 
     	 ' /UserId: ' +  Isnull(convert(nVarChar(4),@UserId),'Null') + ' /ParentPPId: ' +  Isnull(convert(nvarchar(10),@ParentPPId),'Null') + 
     	 ' /ControlType ' +  Isnull(convert(nVarChar(4),@ControlType),'Null') + ' /ForecastStartTime: ' +  Isnull(convert(nVarChar(25),@ForecastStartTime),'Null') + 
     	 ' /ForecastEndTime: ' +  Isnull(convert(nVarChar(25),@ForecastEndTime),'Null') + ' /EntryOn ' +  Isnull(convert(nVarChar(25),@EntryOn),'Null') +  
     	 ' /ForecastQuantity: ' +  Isnull(convert(nvarchar(10),@ForecastQuantity),'Null') + ' /ProductionRate: ' +  Isnull(convert(nvarchar(10),@ProductionRate),'Null') +
     	 ' /AdjustedQuantity: ' +  Isnull(convert(nvarchar(10),@AdjustedQuantity),'Null') + ' /BlockNumber: ' +  Isnull(convert(nVarChar(50),@BlockNumber),'Null') +
     	 ' /ProcessOrder: ' +  Isnull(convert(nVarChar(50),@ProcessOrder),'Null') + ' /TransactionTime: ' +  Isnull(convert(nVarChar(25),@TransactionTime),'Null') +
     	 ' /Misc1: ' +  Isnull(convert(nVarChar(50),@Misc1),'Null') + ' /Misc2: ' +  Isnull(convert(nVarChar(25),@Misc2),'Null') +
     	 ' /Misc3: ' +  Isnull(convert(nVarChar(50),@Misc3),'Null') + ' /Misc4: ' +  Isnull(convert(nVarChar(25),@Misc4),'Null') +
 	  	  	 ' /BOMFormulationId: ' +  Isnull(convert(nvarchar(10),@BOMFormulationId),'Null'))
  End
Declare @Check int, @Sequence int, @Previous_Sequence int, @Next_Sequence int, @LastSeq_Move int, @Start_Date datetime, 
 	 @End_Date datetime, @This_Movable bit, @This_Sequence int, @This_Sort_Order tinyint, @Adjacent_Sequence int, 
 	 @Adjacent_PP_Id int, @Adjacent_Movable bit, @Adjacent_Sort_Order tinyint, @How_Many int,/* tinyint to int */
 	 @AutoPromoteFROM_PPStatusId int, @AutoPromoteTo_PPStatusId int, @CurrentCount int, @Min_ImpliedSequence int, @Min_ImpliedSequenceoffset int,
 	 @PromotedFROM_PPStatusId int, @Next_PPId int,@This_Sequence_Offset Int,@Adjacent_Sequence_Offset Int
DECLARE @PrevFSTime  DateTime,
 	  	 @PrevFETime  DateTime,
 	  	 @DupId 	  	  Int
Declare @SourceComment_Id int, @DestComment_Id int, @SourcePtrComment varbinary(16), @DestPtrComment varbinary(16), 
 	 @SourcePtrCommentValid int, @SourcePtrCommentText varbinary(16), @DestPtrCommentText varbinary(16), 
 	 @SourcePtrCommentTextValid int
Declare @x int, @xID int
SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
Declare  @ProductionPlanRS Table(Result tinyint, PreDB tinyint, TransType int, TransNum int, 
 	 PathId int,  PPId int, CommentId int, ProdId int, ImpliedSequence int, PPStatusId int, PPTypeId int, SourcePPId int, 
 	 UserId int, ParentPPId int, ControlType tinyint, ForecastStartTime datetime, ForecastEndTime datetime, EntryOn datetime, 
 	 ForecastQuantity float, ProductionRate float,  AdjustedQuantity float, BlockNumber nVarChar(50), 
 	 ProcessOrder nVarChar(50), TransactionTime datetime,BOMFormulationId BigInt,UserGeneral1 nVarChar(255),UserGeneral2 nVarChar(255),
 	 UserGeneral3 nVarChar(255),ExtendedInfo nVarChar(255))
Create Table #PPStartsResultSet(Result tinyint, PreDB tinyint, TransType int, TransNum int, PUId Int, PPStartId Int, 
 	 StartTime DateTime, EndTime DateTime, PPId Int, CommentId Int, PPSetupId Int, UserId Int)
--0 FOR this value means dont put the message record onto Pending_ResultSets
SET @InsertIntoPendingResultSet = Coalesce(@InsertIntoPendingResultSet,0);
  --
  -- Transaction Types
  -- 1 - Insert
  -- 2 - Update
  -- 3 - Delete
  --
  -- Transaction Numbers
  -- 00 - Coalesce
  -- 01 - Comment Update
  -- 02 - No Coalesce
  -- 03 - Call FROM Model 804
  -- 91 - Return To Parent Process Order
  -- 92 - Create Child Process Order Based On Start Time (@Misc1=Parent_PP_Setup_Id)
  -- 93 - Create Child Process Order Before Process Order (@Misc1=Parent_PP_Setup_Id)
  -- 94 - Create Child Process Order After Process Order (@Misc1=Parent_PP_Setup_Id)
  -- 95 - Re Work Process Order
  -- 96 - Bind/UnBind Process Order
  -- 97 - Process Order Status Transition
  -- 98 - Move Process Order Back
  -- 99 - Move Process Order Forward
  -- 1000 Update Comment
  --
  -- Return Values:
  --
  --   (-100) Error.
  --   (   1) Success: New record added.
  --   (   2) Success: Existing record Entry.
  --   (   3) Success: Existing record deleted.
  --   (   4) Success: No action taken.
  --
If (@TransNum is NULL)
  SELECT @TransNum = 0
If (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
IF @ForecastStartTime Is Not Null and @ForecastEndTime Is Not Null
BEGIN
 	 IF @ForecastEndTime < @ForecastStartTime
 	 BEGIN
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed Start is greater Than end') 
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
      Return (-100)
 	 END
END
If @TransNum Not IN (0,1,2,3,91,92,93,94,95,96,97,98,99,1000) 
  Begin
   	 Drop Table #PPStartsResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Invalid TransNum') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-100)
  End
SET @EntryOn = Coalesce(@EntryOn,@TransactionTime, @Now)
If @PPId = 0
  SELECT @PPId = NULL
IF @TransNum = 1000 /* Update Comment*/
 	 BEGIN
 	  	 IF @PPId is Null or @UserId Is Null -- Check required fields
 	  	  	 RETURN(4)
 	  	 SET @Check  = NULL
 	  	 SELECT  @Check = PP_Id FROM Production_Plan WHERE PP_Id  = @PPId
 	  	 IF @Check is Null RETURN(4)-- Not Found
 	  	  	 UPDATE Production_Plan SET Comment_id = @CommentId,User_Id  = @UserId,Entry_On = @EntryOn  
 	  	  	  	 WHERE PP_Id  = @PPId
 	  	  --Before returning publish a production_plan message
 	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  BEGIN
 	  	  
 	  	  	 --Publish Message for Production Plan here
 	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	 SELECT 0,
 	  	  	  	  	 (
 	  	  	  	  	 SELECT  
 	  	  	  	  	 RSTId = 15
 	  	  	  	  	 ,PreDB = 0
 	  	  	  	  	 ,TransType = @TransType
 	  	  	  	  	 ,TransNum = @TransNum
 	  	  	  	  	 ,PathId = Path_Id
 	  	  	  	  	 ,PPId = PP_Id
 	  	  	  	  	 ,CommentId = Comment_Id
 	  	  	  	  	 ,ProdId = Prod_Id
 	  	  	  	  	 ,ImpliedSequence = Implied_Sequence
 	  	  	  	  	 ,PPStatusId = PP_Status_Id
 	  	  	  	  	 ,PPTypeId = PP_Type_Id
 	  	  	  	  	 ,SourcePPId = Source_PP_Id
 	  	  	  	  	 ,UserId = User_Id
 	  	  	  	  	 ,ParentPPId = Parent_PP_Id
 	  	  	  	  	 ,ControlType = 	 Control_Type
 	  	  	  	  	 ,ForecastStartTime = Forecast_Start_Date
 	  	  	  	  	 ,ForecastEndTime = Forecast_End_Date
 	  	  	  	  	 ,EntryOn = Entry_On
 	  	  	  	  	 ,ForecastQuantity = Forecast_Quantity
 	  	  	  	  	 ,ProductionRate = Production_Rate
 	  	  	  	  	 ,AdjustedQuantity = Adjusted_Quantity
 	  	  	  	  	 ,BlockNumber = Block_Number
 	  	  	  	  	 ,ProcessOrder = Process_Order
 	  	  	  	  	 ,TransactionTime = @TransactionTime
 	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	 ,BOMFormulationId = BOM_Formulation_Id
 	  	  	  	  	 ,UserGen1 = User_General_1
 	  	  	  	  	 ,UserGen2 = User_General_2
 	  	  	  	  	 ,UserGen3 = User_General_3
 	  	  	  	  	 ,ExtendedInfo = Extended_Info
 	  	  	  	  	 FROM PRODUCTION_PLAN WHERE PP_Id = @PPId
 	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	 ,@UserId
 	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  END
 	  	 RETURN(2)
 	 END
SELECT @Check = NULL
If @PathId = 0
  SELECT @PathId = NULL
If @PathId Is Not Null 
 	 SELECT @SControlType = Schedule_Control_Type FROM Prdexec_Paths WHERE Path_Id = @PathId
If @ImpliedSequence = 0
  SELECT @ImpliedSequence = NULL
SELECT @Sequence = NULL, @Previous_Sequence = NULL, @Next_Sequence = NULL
--Check For Unique Process Order Number On This Path
IF @PathId IS Null
BEGIN
 	 IF @PPId IS NULL
 	 BEGIN
 	  	 SELECT @Check = count(PP_Id),@DupId = Max(PP_Id)
 	  	  	 FROM Production_Plan 
 	  	  	 WHERE Path_Id is NULL  and Process_Order = @ProcessOrder
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @Check = count(PP_Id),@DupId = Max(PP_Id) 
 	  	  	 FROM Production_Plan 
 	  	  	 WHERE Path_Id is NULL  and Process_Order = @ProcessOrder AND PP_Id <> @PPId
 	 END
END
ELSE
BEGIN
 	 IF @PPId IS NULL
 	 BEGIN
 	  	 SELECT @Check = count(PP_Id),@DupId = Max(PP_Id) 
 	  	  	 FROM Production_Plan 
 	  	  	 WHERE Path_Id = @PathId  and Process_Order = @ProcessOrder
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @Check = count(PP_Id),@DupId = Max(PP_Id) 
 	  	  	 FROM Production_Plan 
 	  	  	 WHERE Path_Id = @PathId and Process_Order = @ProcessOrder AND PP_Id <> @PPId
 	 END
END
IF @TransNum = 3
BEGIN
 	 IF  @Check > 0  --is this a reload??
 	 BEGIN
 	  	 IF (SELECT Actual_Start_Time FROM  Production_Plan WHERE PP_Id = @DupId) IS NULL
 	  	 BEGIN
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Model 804 reload')
 	  	  	 RETURN(4)
 	  	 END
 	 END
 	 SELECT @PPTypeId = 1 --Default to Scheduled
 	 SELECT @PPStatusId = 1 --Default to Pending
 	 IF @PathId IS NULL
 	 BEGIN
 	  	 SELECT @PrevFETime = MAX(Forecast_End_Date)
 	  	  	 FROM Production_Plan
 	  	  	 WHERE Path_Id Is Null
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @PrevFETime = MAX(Forecast_End_Date)
 	  	  	 FROM Production_Plan
 	  	  	 WHERE Path_Id = @PathId
 	 END
 	 IF @PrevFETime IS NULL
 	 BEGIN
 	  	 SELECT @ForecastStartTime = DateAdd(Millisecond,-DatePart(Millisecond,@Now),@Now)
 	  	 SELECT @ForecastEndTime = DateAdd(Hour,4,@ForecastStartTime)
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @ForecastStartTime = @PrevFETime
 	  	 IF @PathId IS NULL
 	  	 BEGIN
 	  	  	 SELECT @PrevFSTime = MAX(Forecast_Start_Date)
 	  	  	  	 FROM Production_Plan
 	  	  	  	 WHERE Path_Id Is Null  and Forecast_End_Date = @PrevFETime
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SELECT @PrevFSTime = MAX(Forecast_Start_Date)
 	  	  	  	 FROM Production_Plan
 	  	  	  	 WHERE Path_Id = @PathId  and Forecast_End_Date = @PrevFETime
 	  	 END
 	  	 IF @PrevFSTime IS NULL
 	  	 BEGIN
 	  	  	 SELECT @ForecastEndTime = DateAdd(Hour,4,@ForecastStartTime)
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SELECT @ForecastEndTime = DateAdd(Minute,DateDiff(Minute,@PrevFSTime,@PrevFETime),@ForecastStartTime)
 	  	 END
 	 END
 	 -- Fix Duplicates
 	 IF  @Check > 0
 	 BEGIN
 	  	 SELECT @Check = 0
 	  	 SELECT @ProcessOrder = RIGHT(@ProcessOrder,27) + '_' + RIGHT(CONVERT(nVarChar(4),datepart(Year,@Now)),2)
 	  	 IF LEN(datepart(Month,@Now)) = 1
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + '0' + CONVERT(nVarChar(1),datepart(Month,@Now))
 	  	 ELSE
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + CONVERT(nVarChar(2),datepart(Month,@Now))
 	  	 IF LEN(datepart(Day,@Now)) = 1
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + '0' + CONVERT(nVarChar(1),datepart(Day,@Now))
 	  	 ELSE
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + CONVERT(nVarChar(2),datepart(Day,@Now))
 	  	 IF LEN(datepart(Hour,@Now)) = 1
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + '0' + CONVERT(nVarChar(1),datepart(Hour,@Now))
 	  	 ELSE
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + CONVERT(nVarChar(2),datepart(Hour,@Now))
 	  	 IF LEN(datepart(Minute,@Now)) = 1
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + '0' + CONVERT(nVarChar(1),datepart(Minute,@Now))
 	  	 ELSE
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + CONVERT(nVarChar(2),datepart(Minute,@Now))
 	  	 IF LEN(datepart(Second,@Now)) = 1
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + '0' + CONVERT(nVarChar(1),datepart(Second,@Now))
 	  	 ELSE
 	  	  	 SELECT @ProcessOrder = @ProcessOrder + CONVERT(nVarChar(2),datepart(Second,@Now))
 	 END
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Model 804') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Forcast StartTime:' + Isnull(convert(nVarChar(25),@ForecastStartTime),'Null')) 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Forcast EndTime:' + Isnull(convert(nVarChar(25),@ForecastEndTime),'Null')) 
END
If @Check > 0
  Begin
   	 Drop Table #PPStartsResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Duplicate Process_Order') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-100)
  End
-- MKW - 2007-06-11 - Block unbinding an active order because the production plan records aren't closed
IF  	 @TransType = 2 	 AND @TransNum = 96 	 AND isnull(@PathId, 0) = 0
  BEGIN
 	 SELECT @PPStatusId = PP_Status_Id
 	 FROM dbo.Production_Plan
 	 WHERE PP_Id = @PPId
 	 IF @PPStatusId = 3
 	   BEGIN
 	     	 Drop Table #PPStartsResultSet
 	     If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Cannot unbind active order') 
 	     If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	 Return (-100)
 	   END
  END
If Not @TransNum = 92
  SELECT @Start_Date = Forecast_Start_Date, @End_Date = Forecast_End_Date
   FROM Production_Plan
    WHERE PP_Id = @PPId
Else
  SELECT @Start_Date = Forecast_Start_Date, @End_Date = Forecast_End_Date
   FROM Production_Plan
    WHERE PP_Id = @ParentPPId
If Not (@TransType = 2 and @TransNum = 1)
 	 If @MyOwnTrans = 1 BEGIN TRANSACTION
If @TransType = 1 or (@TransType = 2 and @TransNum = 96) or (@TransType = 2 and (@TransNum = 0 or @TransNum = 2) and (@Start_Date <> @ForecastStartTime or @End_Date <> @ForecastEndTime))
  Begin  /**********Insert************/
    If Not (@TransNum = 93 or @TransNum = 94)
      Begin
        SELECT @Previous_Sequence = max(Implied_Sequence) FROM Production_Plan WHERE (Path_Id = @PathId OR (Path_Id is NULL and @PathId is NULL)) and Forecast_Start_Date <= Coalesce(@ForecastStartTime, @Start_Date)
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Previous_Sequence = ' + Convert(nvarchar(10), @Previous_Sequence)) 
        SELECT @Next_Sequence = min(Implied_Sequence) FROM Production_Plan WHERE (Path_Id = @PathId OR (Path_Id is NULL and @PathId is NULL)) and Forecast_Start_Date > Coalesce(@ForecastStartTime, @Start_Date)
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Next_Sequence = ' + Convert(nvarchar(10), @Next_Sequence)) 
 	  	 
        SELECT @Sequence = Round(0.5 * (@Next_Sequence - @Previous_Sequence), 0) + @Previous_Sequence
        If @Sequence Is Null 
          if @Previous_Sequence is NULL and @Next_Sequence is NULL
            SELECT @Sequence = 1
          else if @Next_Sequence is NULL
            SELECT @Sequence = @Previous_Sequence + 1
          else if @Previous_Sequence is NULL
            Begin
              SELECT @Sequence = @Next_Sequence - 1
              if @Sequence = 0 SELECT @Sequence = 1
            End
      End
    Else
      Begin
        SELECT @Previous_Sequence = Implied_Sequence FROM Production_Plan WHERE PP_Id = @PPId
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Previous_Sequence = ' + Convert(nvarchar(10), @Previous_Sequence)) 
        SELECT @Next_Sequence = min(Implied_Sequence) FROM Production_Plan WHERE (Path_Id = @PathId OR (Path_Id is NULL and @PathId is NULL)) and Implied_Sequence > @Previous_Sequence
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Next_Sequence = ' + Convert(nvarchar(10), @Next_Sequence)) 
        If @TransNum = 93
          SELECT @Sequence = @Previous_Sequence
        Else If @TransNum = 94
          SELECT @Sequence = @Previous_Sequence + Round(0.5 * (@Next_Sequence - @Previous_Sequence), 0)
        If @Sequence Is Null or @Sequence = 0
          if @Previous_Sequence is NULL and @Next_Sequence is NULL
            SELECT @Sequence = 1
          else if @Next_Sequence is NULL
            if @TransNum = 93
              SELECT @Sequence = @Previous_Sequence
            else if @TransNum = 94
              SELECT @Sequence = @Previous_Sequence + 1
          else if @Previous_Sequence is NULL
            Begin
              if @TransNum = 93
                SELECT @Sequence = @Next_Sequence - 1
              else if @TransNum = 94
                SELECT @Sequence = @Next_Sequence
              if @Sequence = 0 SELECT @Sequence = 1
            End
      End
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Sequence = ' + Convert(nvarchar(10), @Sequence)) 
    SELECT @LastSeq_Move = @Sequence - 1
 	    
  End /**********Insert************/
else if @TransType = 2 and (@TransNum = 0 or @TransNum = 2)
  Begin /**********Update************/
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ImpliedSequence = ' +  Isnull(Convert(nvarchar(10), @ImpliedSequence),'null')) 
    if @ImpliedSequence is NULL
      Begin
        SELECT @ImpliedSequence = Implied_Sequence FROM Production_Plan WHERE PP_Id = @PPId
      End
    SELECT @Sequence = @ImpliedSequence
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Sequence = ' +  Isnull(Convert(nvarchar(10), @Sequence),'Null')) 
  End /**********Update************/
If @TransType = 1
  Begin /**********Insert************/
    If @TransNum IN (0,2,3)
      Begin
        If @ProcessOrder is NULL or LTrim(RTrim(@ProcessOrder)) = ''
          Begin
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Process_Order is NULL...Create One') 
            SELECT @ProcessOrder = Convert(nVarChar(30),dbo.fnServer_CmnGetDate(getUTCdate()),21)
          End
 	  	   SET @Implied_Sequence_String = dbo.fnCmn_getuniqueIntForDate(@ForecastStartTime,@PathId)
 	  	   SET @Implied_Sequence = CAST(LEFT(@Implied_Sequence_String,PATINDEX('%;%',@Implied_Sequence_String)-1) as Int)
 	  	   SET @Implied_Sequence_Offset = 0
 	  	   SET @Implied_Sequence_Offset = CAST(LEFT(REVERSE(@Implied_Sequence_String),PATINDEX('%;%',REVERSE(@Implied_Sequence_String))-1) as Int)
 	  	   /*
 	  	   Alter Table Production_Plan Add Implied_Sequence_Offset Int Default(0)
 	  	   */
        	 Insert Into Production_Plan (Path_Id, Process_Order, PP_Status_Id, Prod_Id, Block_Number, Forecast_Start_Date, 
 	  	  	  	 Forecast_End_Date, Forecast_Quantity, Implied_Sequence, Comment_Id, PP_Type_Id, Production_Rate,  Source_PP_Id, 
 	  	  	  	 User_Id, Entry_On, Adjusted_Quantity, Parent_PP_Id, Control_Type, BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info,Implied_Sequence_Offset)
        	 Values (@PathId, @ProcessOrder, @PPStatusId, @ProdId, @BlockNumber, @ForecastStartTime, @ForecastEndTime, 
 	  	  	  	 @ForecastQuantity, @Implied_Sequence, @CommentId, @PPTypeId, @ProductionRate, @SourcePPId, @UserId, @EntryOn, 
 	  	  	  	 @AdjustedQuantity, @ParentPPId, @ControlType, @BOMFormulationId,@UserGeneral1,@UserGeneral2,@UserGeneral3,@ExtendedInfo,@Implied_Sequence_Offset)
 	  	  	 SELECT @NewPPId = Scope_Identity()
   	  	 If @PPStatusId = 3 and @PathId is NOT NULL
 	  	   Begin
 	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Calling spServer_DBMgrUpdProdPlanStartsFROMPlan')
 	    	  	  	 Execute @DBMgrUpdProdPlanStartsFROMPlan = spServer_DBMgrUpdProdPlanStartsFROMPlan @NewPPId, @PathId, @UserId, @SControlType, @PPStatusId, 1 
 	  	  	  	 if @DBMgrUpdProdPlanStartsFROMPlan <= -1000
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Drop Table #PPStartsResultSet
 	  	  	  	  	  	 if @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) SELECT @ID, 'Error Code = ' + Convert(nvarchar(10), @DBMgrUpdProdPlanStartsFROMPlan)
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	  	  	  	 return @DBMgrUpdProdPlanStartsFROMPlan
 	  	  	  	  	 End
 	  	   End
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
           	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Failed') 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
           	 Return (-100)
          End
        else 
          Begin
            Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
              SELECT 15, 0, @TransType, @TransNum, @PathId, @PPId, @CommentId, @ProdId, @Sequence, @PPStatusId, @PPTypeId, @SourcePPId, @UserId,
              @ParentPPId, @ControlType, @ForecastStartTime, @ForecastEndTime, @EntryOn, @ForecastQuantity, @ProductionRate, @AdjustedQuantity,
              @BlockNumber, @ProcessOrder, @TransactionTime,@BOMFormulationId,@UserGeneral1,@UserGeneral2,@UserGeneral3,@ExtendedInfo  
            If @MyOwnTrans = 1 COMMIT TRANSACTION
            SELECT @ImpliedSequence = @Sequence
            SELECT @PPId = PP_Id FROM Production_Plan WHERE (Path_Id = @PathId OR (Path_Id is NULL and @PathId is NULL)) and Process_Order = @ProcessOrder
            Update @ProductionPlanRS Set PPId = @PPId WHERE PPId is NULL or PPId = 0
            SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType,
 	  	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
              FROM @ProductionPlanRS
 	        	  	 If (SELECT count(*) FROM #PPStartsResultSet) > 0
 	  	  	  	       SELECT * FROM #PPStartsResultSet
       	  	  	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Process Order Successful') 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            	  --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
           	 Return (1)
          End
      End
    Else If @TransNum = 92 or @TransNum = 93 or @TransNum = 94
      Begin  
        If @ProcessOrder is NULL or LTrim(RTrim(@ProcessOrder)) = ''
          Begin
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Process_Order is NULL...Create One') 
            SELECT @ProcessOrder = Process_Order + '-C' FROM Production_Plan WHERE PP_Id = @ParentPPId
            SELECT @Check = count(PP_Id) FROM Production_Plan WHERE (Path_Id = @PathId OR (Path_Id is NULL and @PathId is NULL)) and Process_Order = @ProcessOrder
            If @Check > 0
              Begin
                SELECT @ProcessOrder = Convert(nVarChar(30), dbo.fnServer_CmnGetDate(getUTCdate()), 21)
                SELECT @x = 0
                NextAvailChildDesc:
                SELECT @x = @x + 1
                SELECT @xID = Null
                SELECT @xID = PP_Id FROM Production_Plan
                WHERE Process_Order = @ProcessOrder + Convert(nvarchar(10), @x)
                If @xID is Null
                  Begin
                    SELECT @ProcessOrder = @ProcessOrder + Convert(nvarchar(10), @x)
                  End
                Else
                  Begin
                    Goto NextAvailChildDesc
                  End
              End
          End
        If @TransNum = 93 
          SELECT @ForecastStartTime = DateAdd(Minute, -2, Forecast_Start_Date), @ForecastEndTime = DateAdd(Minute, -1, Forecast_Start_Date)
            FROM Production_Plan
            WHERE PP_Id = @PPId
        Else If @TransNum = 94
          SELECT @ForecastStartTime = DateAdd(Minute, 1, Forecast_End_Date), @ForecastEndTime = DateAdd(Minute, 2, Forecast_End_Date)
            FROM Production_Plan
            WHERE PP_Id = @PPId
        SELECT @PPSetupId = @Misc1
        If @PPSetupId = 0
          SELECT @PPSetupId = NULL
       SELECT @PPId = NULL, @PPStatusId = 1, @ProdId = Prod_Id, @BlockNumber = Block_Number, @CommentId = NULL, 
       	  	 @PPTypeId = 1, @ProductionRate = Production_Rate, @SourcePPId = Source_PP_Id, @AdjustedQuantity = Adjusted_Quantity, 
       	  	 @ControlType = Control_Type
          FROM Production_Plan
          WHERE PP_Id = @ParentPPId
 	  	   
 	  	   SET @Implied_Sequence_String = dbo.fnCmn_getuniqueIntForDate(@ForecastStartTime,@PathId)
 	  	   SET @Implied_Sequence = CAST(LEFT(@Implied_Sequence_String,PATINDEX('%;%',@Implied_Sequence_String)-1) as Int)
 	  	   SET @Implied_Sequence_Offset = 0
 	  	   SET @Implied_Sequence_Offset = CAST(LEFT(REVERSE(@Implied_Sequence_String),PATINDEX('%;%',REVERSE(@Implied_Sequence_String))-1) as Int)
        Insert Into Production_Plan (Path_Id, Process_Order, PP_Status_Id, Prod_Id, Block_Number, Forecast_Start_Date, 
   	  	  	 Forecast_End_Date, Forecast_Quantity, Implied_Sequence, Comment_Id, PP_Type_Id, Production_Rate, Source_PP_Id, 
 	    	  	 User_Id, Entry_On, Adjusted_Quantity, Parent_PP_Id, Control_Type, BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info,Implied_Sequence_Offset)
        Values (@PathId, @ProcessOrder, @PPStatusId, @ProdId, @BlockNumber, @ForecastStartTime, @ForecastEndTime, 
 	  	  	  	 @ForecastQuantity, @Implied_Sequence, @CommentId, @PPTypeId, @ProductionRate, @SourcePPId, @UserId, @EntryOn, 
 	  	  	  	 @AdjustedQuantity, @ParentPPId, @ControlType, @BOMFormulationId,@UserGeneral1,@UserGeneral2,@UserGeneral3,@ExtendedInfo,@Implied_Sequence_Offset)
 	  	  	  	 SELECT @NewPPId = Scope_Identity()
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Failed') 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
           	 Return (-100)
          End
 	    	  	 If  @PPStatusId = 3 and @PathId is NOT NULL
 	  	  	  	   Begin
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Calling spServer_DBMgrUpdProdPlanStartsFROMPlan')
 	  	  	  	  	 Execute @DBMgrUpdProdPlanStartsFROMPlan = spServer_DBMgrUpdProdPlanStartsFROMPlan @NewPPId, @PathId, @UserId, @SControlType, @PPStatusId, 1
 	  	  	  	  	 if @DBMgrUpdProdPlanStartsFROMPlan <= -1000
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Drop Table #PPStartsResultSet
 	  	  	  	  	  	 if @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) SELECT @ID, 'Error Code = ' + Convert(nvarchar(10), @DBMgrUpdProdPlanStartsFROMPlan)
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	  	  	  	 return @DBMgrUpdProdPlanStartsFROMPlan
 	  	  	  	  	 End
 	  	  	  	   End
        else 
          Begin
            --Refreshes Parent in the Client
            Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
              SELECT 15, 0, 2, 0, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, @UserId,
              Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
              Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
                FROM Production_Plan
                WHERE PP_Id = @ParentPPId
            Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
              SELECT 15, 0, @TransType, @TransNum, @PathId, @PPId, @CommentId, @ProdId, @Sequence, @PPStatusId, @PPTypeId, @SourcePPId, @UserId,
              @ParentPPId, @ControlType, @ForecastStartTime, @ForecastEndTime, @EntryOn, @ForecastQuantity, @ProductionRate, @AdjustedQuantity,
              @BlockNumber, @ProcessOrder, @TransactionTime,@BOMFormulationId,@UserGeneral1,@UserGeneral2,@UserGeneral3,@ExtendedInfo
            If @MyOwnTrans = 1 COMMIT TRANSACTION
            SELECT @ImpliedSequence = @Sequence
            SELECT @PPId = PP_Id FROM Production_Plan WHERE (Path_Id = @PathId OR (Path_Id is NULL and @PathId is NULL)) and Process_Order = @ProcessOrder
            SELECT @UserGeneral1 = User_General_1,
 	  	  	  	  @UserGeneral2 = User_General_2, 
 	  	  	  	  @UserGeneral3 = User_General_3, 
 	  	  	  	  @ExtendedInfo = Extended_Info,
 	  	  	  	  @BOMFormulationId = BOM_Formulation_Id 
 	  	  	  	  FROM Production_Plan WHERE PP_Id = @ParentPPId
            Update Production_Plan Set User_General_1 = @UserGeneral1, User_General_2 = @UserGeneral2, User_General_3 = @UserGeneral3, Extended_Info = @ExtendedInfo, BOM_Formulation_Id = @BOMFormulationId WHERE PP_Id = @PPId
            SELECT @SourceComment_Id = comment_id
              FROM Production_Plan
              WHERE PP_Id = @ParentPPId
            if @SourceComment_Id > 0
              Begin
                insert into comments(Comment, Comment_Text, CS_Id, Modified_On, User_Id, Entry_On) values ('', '', 2, dbo.fnServer_CmnGetDate(getUTCdate()), @UserId, dbo.fnServer_CmnGetDate(getUTCdate()))
                SELECT @DestComment_Id = Scope_Identity()
                update comments set TopOfChain_Id = @DestComment_Id WHERE comment_id = @DestComment_Id
                update Production_Plan set comment_id = @DestComment_Id WHERE PP_Id = @PPId
                SELECT @SourcePtrComment = TEXTPTR(comment) FROM comments WHERE comment_id = @SourceComment_Id
                SELECT @SourcePtrCommentValid = TEXTVALID ('comments.comment', @SourcePtrComment)
                if @SourcePtrCommentValid = 1
                  Begin
                    SELECT @DestPtrComment = TEXTPTR(comment) FROM comments WHERE comment_id = @DestComment_Id
                    UPDATETEXT comments.comment @DestPtrComment 0 0 WITH LOG comments.comment @SourcePtrComment
                  End
                SELECT @SourcePtrCommentText = TEXTPTR(comment_text) FROM comments WHERE comment_id = @SourceComment_Id
                SELECT @SourcePtrCommentTextValid = TEXTVALID ('comments.comment_text', @SourcePtrCommentText)
                if @SourcePtrCommentTextValid = 1
                  Begin
                    SELECT @DestPtrCommentText = TEXTPTR(comment_text) FROM comments WHERE comment_id = @DestComment_Id
                    UPDATETEXT comments.comment_text @DestPtrCommentText 0 0 WITH LOG comments.comment_text @SourcePtrCommentText
                  End
              End
            Update @ProductionPlanRS Set PPId = @PPId WHERE PPId is NULL or PPId = 0
            Update @ProductionPlanRS Set CommentId = @DestComment_Id WHERE PPId = @PPId
            SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
 	  	  	  	  	 
              FROM @ProductionPlanRS
       	  	  	 If (SELECT count(*) FROM #PPStartsResultSet) > 0
       	  	  	  	 SELECT * FROM #PPStartsResultSet
        	  	  	 Drop Table #PPStartsResultSet
              --Handle Sequence "Create Child Sequence"
            If @PPSetupId is NOT NULL
              exec spServer_DBMgrUpdProdSetup NULL, @TransType, 92, @UserId, @PPId, NULL, @PPStatusId, NULL, NULL, @ForecastQuantity, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @PathId, @EntryOn, @TransactionTime, @PPSetupId
            If @DebugFlag = 1
              Begin
                If @TransNum = 92 
                  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 92 (Create Child Process Order Based On Start Time)')
                Else If @TransNum = 93
                  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 93 (Create Child Process Order Before Process Order)')
                Else If @TransNum = 94
                  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 94 (Create Child Process Order After Process Order)')
              End
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            	  --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
           	 Return (1)
          End
      End 
    Else If @TransNum = 95
      Begin  
        If @ProcessOrder is NULL or LTrim(RTrim(@ProcessOrder)) = ''
          Begin
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Process_Order is NULL...Create One') 
            SELECT @ProcessOrder = Process_Order + '-R' FROM Production_Plan WHERE PP_Id = @SourcePPId
            SELECT @Check = count(PP_Id) FROM Production_Plan WHERE (Path_Id = @PathId OR (Path_Id is NULL and @PathId is NULL)) and Process_Order = @ProcessOrder
            If @Check > 0
              Begin
                SELECT @ProcessOrder = Convert(nVarChar(30), dbo.fnServer_CmnGetDate(getUTCdate()), 21)
                SELECT @x = 0
                NextAvailReWorkDesc:
                SELECT @x = @x + 1
                SELECT @xID = Null
                SELECT @xID = PP_Id FROM Production_Plan
                WHERE Process_Order = @ProcessOrder + Convert(nvarchar(10), @x)
                If @xID is Null
                  Begin
                    SELECT @ProcessOrder = @ProcessOrder + Convert(nvarchar(10), @x)
                  End
                Else
                  Begin
                    Goto NextAvailReWorkDesc
                  End
              End
          End
        SELECT @PathId = Path_Id,@PPStatusId = 1,@ProdId = Prod_Id,@BlockNumber = Block_Number,@PPTypeId = 2,
 	  	  	    @ProductionRate = Production_Rate,@AdjustedQuantity = Adjusted_Quantity,@ParentPPId = Parent_PP_Id,
 	  	  	    @ControlType = Control_Type
 	  	 FROM Production_Plan
 	  	 WHERE PP_Id = @SourcePPId
 	  	   SET @Implied_Sequence_String = dbo.fnCmn_getuniqueIntForDate(@ForecastStartTime,@PathId)
 	  	   SET @Implied_Sequence = CAST(LEFT(@Implied_Sequence_String,PATINDEX('%;%',@Implied_Sequence_String)-1) as Int)
 	  	   SET @Implied_Sequence_Offset = 0
 	  	   SET @Implied_Sequence_Offset = CAST(LEFT(REVERSE(@Implied_Sequence_String),PATINDEX('%;%',REVERSE(@Implied_Sequence_String))-1) as Int)
      Insert Into Production_Plan (Path_Id, Process_Order, PP_Status_Id, Prod_Id, Block_Number, Forecast_Start_Date, 
 	  	  	 Forecast_End_Date, Forecast_Quantity, Implied_Sequence, Comment_Id, PP_Type_Id,  Production_Rate, Source_PP_Id, 
 	  	  	 User_Id,  Entry_On, Adjusted_Quantity, Parent_PP_Id, Control_Type, BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info,Implied_Sequence_Offset)
        Values (@PathId, @ProcessOrder, @PPStatusId, @ProdId, @BlockNumber, @ForecastStartTime, @ForecastEndTime, 
 	  	  	 @ForecastQuantity, @Implied_Sequence, @CommentId, @PPTypeId, @ProductionRate, @SourcePPId, @UserId, @EntryOn, @AdjustedQuantity, 
 	  	  	 @ParentPPId, @ControlType, @BOMFormulationId,@UserGeneral1,@UserGeneral2,@UserGeneral3,@ExtendedInfo,@Implied_Sequence_Offset)
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        	  	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Failed') 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
           	 Return (-100)
          End
        else 
          Begin
            Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
              SELECT 15, 0, @TransType, @TransNum, @PathId, @PPId, @CommentId, @ProdId, @Sequence, @PPStatusId, @PPTypeId, @SourcePPId, @UserId,
              @ParentPPId, @ControlType, @ForecastStartTime, @ForecastEndTime, @EntryOn, @ForecastQuantity, @ProductionRate, @AdjustedQuantity,
              @BlockNumber, @ProcessOrder, @TransactionTime,@BOMFormulationId,@UserGeneral1,@UserGeneral2,@UserGeneral3,@ExtendedInfo
            If @MyOwnTrans = 1 COMMIT TRANSACTION
            SELECT @ImpliedSequence = @Sequence
            SELECT @PPId = PP_Id FROM Production_Plan WHERE (Path_Id = @PathId OR (Path_Id is NULL and @PathId is NULL)) and Process_Order = @ProcessOrder
            SELECT  @UserGeneral1 = User_General_1, 
 	  	  	  	  	 @UserGeneral2 = User_General_2, 
 	  	  	  	  	 @UserGeneral3 = User_General_3, 
 	  	  	  	  	 @ExtendedInfo = Extended_Info, 
 	  	  	  	  	 @BOMFormulationId = BOM_Formulation_Id 
            FROM Production_Plan WHERE PP_Id = @SourcePPId
            Update Production_Plan Set User_General_1 = @UserGeneral1, User_General_2 = @UserGeneral2, User_General_3 = @UserGeneral3, Extended_Info = @ExtendedInfo, BOM_Formulation_Id = @BOMFormulationId WHERE PP_Id = @PPId
            SELECT @SourceComment_Id = comment_id
              FROM Production_Plan
              WHERE PP_Id = @SourcePPId
            if @SourceComment_Id > 0
              Begin
                insert into comments(Comment, Comment_Text, CS_Id, Modified_On, User_Id, Entry_On) values ('', '', 2, dbo.fnServer_CmnGetDate(getUTCdate()), @UserId, dbo.fnServer_CmnGetDate(getUTCdate()))
                SELECT @DestComment_Id = Scope_Identity()
                update comments set TopOfChain_Id = @DestComment_Id WHERE comment_id = @DestComment_Id
                update Production_Plan set comment_id = @DestComment_Id WHERE PP_Id = @PPId
                SELECT @SourcePtrComment = TEXTPTR(comment) FROM comments WHERE comment_id = @SourceComment_Id
                SELECT @SourcePtrCommentValid = TEXTVALID ('comments.comment', @SourcePtrComment)
                if @SourcePtrCommentValid = 1
                  Begin
                    SELECT @DestPtrComment = TEXTPTR(comment) FROM comments WHERE comment_id = @DestComment_Id
                    UPDATETEXT comments.comment @DestPtrComment 0 0 WITH LOG comments.comment @SourcePtrComment
                  End
                SELECT @SourcePtrCommentText = TEXTPTR(comment_text) FROM comments WHERE comment_id = @SourceComment_Id
                SELECT @SourcePtrCommentTextValid = TEXTVALID ('comments.comment_text', @SourcePtrCommentText)
                if @SourcePtrCommentTextValid = 1
                  Begin
                    SELECT @DestPtrCommentText = TEXTPTR(comment_text) FROM comments WHERE comment_id = @DestComment_Id
                    UPDATETEXT comments.comment_text @DestPtrCommentText 0 0 WITH LOG comments.comment_text @SourcePtrCommentText
                  End
              End
            Update @ProductionPlanRS Set PPId = @PPId WHERE PPId is NULL or PPId = 0
            Update @ProductionPlanRS Set CommentId = @DestComment_Id WHERE PPId = @PPId
            SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
 	  	  	  	  	 
              FROM @ProductionPlanRS
 	  	       If (SELECT count(*) FROM #PPStartsResultSet) > 0
 	  	  	  	 SELECT * FROM #PPStartsResultSet
     	  	     Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 95 (Re Work Process Order)')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            	  --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
           	 Return (1)
          End
      End
  End   /**********Insert************/
Else If @TransType = 2
  Begin /**********Update************/
    If @TransNum = 1
      Begin
        Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
          SELECT 15, 0, @TransType, @TransNum, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, User_Id,
          Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, Entry_On, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
          Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
            FROM Production_Plan
            WHERE PP_Id = @PPId
        SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
 	  	  	  	 
          FROM @ProductionPlanRS
     	  	 If (SELECT count(*) FROM #PPStartsResultSet) > 0
 	  	    	 SELECT * FROM #PPStartsResultSet
     	  	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 1 (Comment Update)') 
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
         	  --Before returning publish a production_plan message --Not sure if we need this here, as there has been no change
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
        	 Return (2)
      End
    Else If @TransNum = 91
      Begin
        Update Production_Plan Set Forecast_Quantity = Actual_Good_Quantity, User_Id = @UserId, Entry_On = @EntryOn
          WHERE PP_Id = @PPId
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (-100)
          End
        Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
          SELECT 15, 0, @TransType, @TransNum, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, @UserId,
          Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
          Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
            FROM Production_Plan
            WHERE PP_Id = @PPId
        If @MyOwnTrans = 1 COMMIT TRANSACTION
        SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
 	  	  	  	 
          FROM @ProductionPlanRS
 	  	     If (SELECT count(*) FROM #PPStartsResultSet) > 0
 	  	  	   SELECT * FROM #PPStartsResultSet
 	  	     Drop Table #PPStartsResultSet
        --Handle Sequence "Return To Parent Sequence"
        SELECT @PPSetupId = PP_Setup_Id
          FROM Production_Setup
          WHERE Parent_PP_Setup_Id in (SELECT PP_Setup_Id FROM Production_Setup WHERE PP_Id = (SELECT Parent_PP_Id FROM Production_Plan WHERE PP_Id = @PPId))
        exec spServer_DBMgrUpdProdSetup @PPSetupId, @TransType, @TransNum, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @PathId, @EntryOn, @TransactionTime, NULL
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 91 (Return To Parent Process Order)') 
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
         	  --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
        	 Return (2)
      End
    Else If @TransNum = 96
      Begin
        Update Production_Plan Set Path_Id = @PathId, User_Id = @UserId, Entry_On = @EntryOn, Implied_Sequence = @Sequence
          WHERE PP_Id = @PPId
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
       	  	  	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed') 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (-100)
          End
        Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
          SELECT 15, 0, @TransType, @TransNum, @PathId, PP_Id, Comment_Id, Prod_Id, @Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, @UserId,
          Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
          Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
            FROM Production_Plan
            WHERE PP_Id = @PPId
        If @MyOwnTrans = 1 COMMIT TRANSACTION
        SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
          FROM @ProductionPlanRS
 	      	 If (SELECT count(*) FROM #PPStartsResultSet) > 0
   	  	  	 SELECT * FROM #PPStartsResultSet
     	  	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 96 (Bind/UnBind Process Order)')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
         	  --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
        	 Return (2)
      End
    Else If @TransNum = 97
    BEGIN
        If (SELECT PP_Status_Id FROM Production_Plan WHERE PP_Id = @PPId) <> @PPStatusId
        BEGIN
            SELECT @PromotedFROM_PPStatusId = PP_Status_Id
              FROM Production_Plan
            WHERE PP_Id = @PPId
 	  	  	 
            Update Production_Plan Set PP_Status_Id = @PPStatusId, User_Id = @UserId, Entry_On = @EntryOn
              WHERE PP_Id = @PPId 
            if @@ERROR <> 0  
            BEGIN
                -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
                If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	  	 Drop Table #PPStartsResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed') 
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (-100)
            END
 	  	   If (@PPStatusId = 3  or @PromotedFROM_PPStatusId = 3) and @PathId is NOT NULL
 	  	   BEGIN
 	  	  	 IF (@PromotedFROM_PPStatusId = 3) and (@PPStatusId <> 3 )
 	  	  	 BEGIN
 	 /* 	  	  Close Any Active Setups */
 	  	  	  	 DECLARE @Setups TABLE (PPSetupId INT)
 	  	  	  	 DECLARE @MYPPSetupId INT
 	  	  	  	 INSERT INTO @Setups (PPSetupId) 
 	  	  	  	  	 SELECT Distinct PP_Setup_Id FROM production_Setup WHERE PP_Id = @PPId AND PP_Status_Id = 3
 	  	  	  	 DECLARE pps_Cursor Cursor FOR SELECT PPSetupId FROM @Setups
 	  	  	  	 OPEN pps_Cursor
 	  	  	  	 pps_Cursor_Loop:
 	  	  	  	 FETCH NEXT FROM pps_Cursor INTO @MYPPSetupId
 	  	  	  	 IF @@FETCH_STATUS = 0
 	  	  	  	 BEGIN
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Closing PPStart' + convert(nvarchar(10),@MYPPSetupId))
 	                	  	 EXECUTE spServer_DBMgrUpdProdSetup @MYPPSetupId, 2, 0, @UserId, Null, NULL, 4, NULL, NULL, Null, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @PathId, @EntryOn, @Now, Null
 	  	  	  	  	 GOTO pps_Cursor_Loop
 	  	  	  	 END
 	  	  	  	 CLOSE pps_Cursor
 	  	  	  	 DEALLOCATE pps_Cursor
 	  	  	 END
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Calling spServer_DBMgrUpdProdPlanStartsFROMPlan')
 	  	  	 Execute @DBMgrUpdProdPlanStartsFROMPlan = spServer_DBMgrUpdProdPlanStartsFROMPlan @PPId,@PathId,@UserId,@SControlType,@PPStatusId, 1
 	  	  	 if @DBMgrUpdProdPlanStartsFROMPlan <= -1000
 	  	  	 BEGIN
 	  	  	  	 Drop Table #PPStartsResultSet
 	  	  	  	 if @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) SELECT @ID, 'Error Code = ' + Convert(nvarchar(10), @DBMgrUpdProdPlanStartsFROMPlan)
 	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	  	 return @DBMgrUpdProdPlanStartsFROMPlan
 	  	  	 END
 	  	   END
           Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
              SELECT 15, 0, @TransType, @TransNum, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, @PPStatusId, PP_Type_Id, Source_PP_Id, @UserId,
              Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
              Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
                FROM Production_Plan
                WHERE PP_Id = @PPId            
            While (0=0) 
              Begin
                SELECT @How_Many = NULL, @Next_PPId = NULL, @Min_ImpliedSequence = NULL, @AutoPromoteFROM_PPStatusId = NULL, @AutoPromoteTo_PPStatusId = NULL
 	  	  	  	 ,@Min_ImpliedSequenceoffset =NULL
                SELECT @AutoPromoteFROM_PPStatusId = AutoPromoteFROM_PPStatusId, @AutoPromoteTo_PPStatusId = AutoPromoteTo_PPStatusId
                  FROM PrdExec_Path_Status_Detail
                  WHERE PP_Status_Id = @PPStatusId
                  And Path_Id = @PathId
                If @AutoPromoteFROM_PPStatusId is NULL or @AutoPromoteTo_PPStatusId is NULL or (@PromotedFROM_PPStatusId <> @AutoPromoteTo_PPStatusId)
                  break
                Else
                  SELECT @PromotedFROM_PPStatusId = @AutoPromoteFROM_PPStatusId
                SELECT @PPStatusId = @AutoPromoteTo_PPStatusId
                SELECT @How_Many = How_Many
                  FROM PrdExec_Path_Status_Detail
                  WHERE PP_Status_Id = @AutoPromoteTo_PPStatusId
                  And Path_Id = @PathId
 	  	  	  	 --Auto promote will work only if implied sequence and implied sequence offset are properly set. For a path these two columns should be unique.
 	  	  	  	 --Replace Min with TOP 1 ASC
                SELECT TOP 1 @Min_ImpliedSequence = Implied_Sequence
                  FROM Production_Plan
                  WHERE Path_Id = @PathId
                  And PP_Status_Id = @AutoPromoteFROM_PPStatusId
 	  	  	  	   Order by Implied_Sequence 
 	  	  	  	   SELECT TOP 1 @Min_ImpliedSequenceoffset=Implied_Sequence_Offset
 	  	  	  	   from Production_Plan
 	  	  	  	   Where Path_Id= @PathId
 	  	  	  	   And PP_Status_Id = @AutoPromoteFROM_PPStatusId
 	  	  	  	   AND Implied_Sequence = @Min_ImpliedSequence
 	  	  	  	   Order by Implied_Sequence_Offset
                if @Min_ImpliedSequence is NULL
                  break
                SELECT @Next_PPId = PP_Id
                  FROM Production_Plan
                  WHERE Path_Id = @PathId
                  And Implied_Sequence = @Min_ImpliedSequence AND Implied_Sequence_Offset = @Min_ImpliedSequenceoffset
                SELECT @CurrentCount = Count(*) 
                  FROM Production_Plan 
                  WHERE Path_Id = @PathId 
                  And PP_Status_Id = @AutoPromoteTo_PPStatusId
                if @CurrentCount >= @How_Many and @How_Many is NOT NULL
                  break
                Update Production_Plan Set PP_Status_Id = @PPStatusId, User_Id = @UserId, Entry_On = @EntryOn
                  WHERE PP_Id = @Next_PPId
                if @@ERROR <> 0  
                  Begin
                    -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
                    If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	  	  	 Drop Table #PPStartsResultSet
                    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed') 
                    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                    Return (-100)
                  End
       	  	  	 If @PPStatusId = 3 and @PathId is NOT NULL
       	  	  	   Begin
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Calling spServer_DBMgrUpdProdPlanStartsFROMPlan')
         	  	  	  	 Execute @DBMgrUpdProdPlanStartsFROMPlan = spServer_DBMgrUpdProdPlanStartsFROMPlan @Next_PPId,@PathId,@UserId,@SControlType,@PPStatusId, 1
 	  	  	  	  	 if @DBMgrUpdProdPlanStartsFROMPlan <= -1000
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Drop Table #PPStartsResultSet
 	  	  	  	  	  	 if @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) SELECT @ID, 'Error Code = ' + Convert(nvarchar(10), @DBMgrUpdProdPlanStartsFROMPlan)
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	  	  	  	 return @DBMgrUpdProdPlanStartsFROMPlan
 	  	  	  	  	 End
       	  	  	   End
                Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
                  SELECT 15, 0, @TransType, @TransNum, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, @PPStatusId, PP_Type_Id, Source_PP_Id, @UserId,
                  Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
                  Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
                    FROM Production_Plan
                    WHERE PP_Id = @Next_PPId            
              End
            If @MyOwnTrans = 1 COMMIT TRANSACTION
            SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
              FROM @ProductionPlanRS
       	  	  	 If (SELECT count(*) FROM #PPStartsResultSet) > 0
 	  	  	      	 SELECT * FROM #PPStartsResultSet
       	  	  	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 97 (Process Order Status Transition)') 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
             	  --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
            	 Return (2)
 	  	  	 End
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 97 (Process Order Status  = old status can not Transition)') 
 	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  --Before returning publish a production_plan message -- Need to check if we really need to push as there was no update here
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
 	  	  	  	 Return (2) -- not really an error - told to update twice
 	  	  	 END
      End
    Else If @TransNum = 98 or @TransNum = 99
      Begin
        SELECT @This_Movable = PPS.Movable, @This_Sequence = PP.Implied_Sequence, 
 	  	 @This_Sequence_Offset = PP.Implied_Sequence_Offset,
 	  	 @This_Sort_Order = Case When PEPSD.SortWith_PPStatusId is NULL or PEPSD.SortWith_PPStatusId = 0 Then PEPSD.Sort_Order Else (SELECT Sort_Order FROM PrdExec_Path_Status_Detail WHERE PP_Status_Id = PEPSD.SortWith_PPStatusId and Path_Id = PEPSD.Path_Id) End
          FROM Production_Plan PP
          Join Production_Plan_Statuses PPS on PPS.PP_Status_Id = PP.PP_Status_Id
          Join PrdExec_Path_Status_Detail PEPSD on PEPSD.PP_Status_Id = PPS.PP_Status_Id and (PEPSD.Path_Id = PP.Path_Id or PEPSD.Path_Id = (SELECT Min(Path_Id) FROM PrdExec_Paths WHERE Prod_Id = PP.Prod_Id))
          WHERE PP.PP_Id = @PPId
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Movable = ' + Convert(nvarchar(10), @This_Movable)) 
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'This_Sequence = ' + Convert(nvarchar(10), @This_Sequence)) 
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'This_Sort_Order = ' + Convert(nvarchar(10), @This_Sort_Order)) 
        If @This_Movable <> 1 
          Begin
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@This_Movable <> 1')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (4)
          End
        -- We Are Moving Up Or Down  - Find Implied Sequence Of Adjacent Item
        if @TransNum = 98
          Begin
            --Move Up
            ;With Tmp98 as (
 	  	  	 SELECT --@Adjacent_Sequence = min(Implied_Sequence) 
 	  	  	 Row_Number() over (Partition by A.Path_Id Order by A.Implied_Sequence, ISNULL(A.Implied_Sequence_Offset,0)) Rownum, A.PP_Id, A.Implied_Sequence, A.Implied_Sequence_Offset
 	  	  	 FROM Production_Plan A Join Production_Plan_Statuses b on b.PP_Status_Id=A.PP_Status_Id WHERE Path_Id = @PathId 
 	  	  	 AND b.Movable = 1
 	  	  	 and cast(Implied_Sequence as  bigint)+cast(ISNULL(A.Implied_Sequence_Offset,0) as bigint) > cast(@This_Sequence as bigint)+cast(@This_Sequence_Offset as bigint)
 	  	  	 --And  Implied_Sequence >= @This_Sequence  --AND ISNULL(Implied_Sequence_Offset,0) > ISNULL(@This_Sequence_Offset,0)
 	  	  	 )
 	  	  	 Select @Adjacent_Sequence = Implied_Sequence, @Adjacent_Sequence_Offset = ISNULL(Implied_Sequence_Offset,0) from Tmp98 Where Rownum = 1
          End
        else if @TransNum = 99
          Begin
            --Move Down
            ;With Tmp99 as (
 	  	  	 SELECT --@Adjacent_Sequence = max(Implied_Sequence) 
 	  	  	 Row_Number() over (Partition by A.Path_Id Order by A.Implied_Sequence Desc, ISNULL(A.Implied_Sequence_Offset,0) Desc) Rownum, A.PP_Id, A.Implied_Sequence, A.Implied_Sequence_Offset
 	  	  	 FROM Production_Plan A Join Production_Plan_Statuses b on b.PP_Status_Id=A.PP_Status_Id WHERE Path_Id = @PathId 
 	  	  	 AND b.Movable = 1
 	  	  	 --and Implied_Sequence <= @This_Sequence       --AND ISNULL(Implied_Sequence_Offset,0) < ISNULL(@This_Sequence_Offset,0)                    
 	  	  	 and cast(Implied_Sequence as  bigint)+cast(ISNULL(A.Implied_Sequence_Offset,0) as bigint) < cast(@This_Sequence as bigint)+cast(@This_Sequence_Offset as bigint)
 	  	  	 )
 	  	  	 Select @Adjacent_Sequence = Implied_Sequence, @Adjacent_Sequence_Offset = ISNULL(Implied_Sequence_Offset,0) from Tmp99 Where Rownum = 1
          End
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjacent_Sequence = ' + Convert(nvarchar(10), @Adjacent_Sequence)) 
        -- Update The Implied Sequence
        if @Adjacent_Sequence is Not Null
          Begin
            SELECT @Adjacent_PP_Id = PP_Id FROM Production_Plan A Join Production_Plan_Statuses b on b.PP_Status_Id=A.PP_Status_Id 
 	  	  	 WHERE Implied_Sequence = @Adjacent_Sequence and Path_Id = @PathId And b.Movable =1 And ISNULL(Implied_Sequence_Offset,0) = @Adjacent_Sequence_Offset
            SELECT @Adjacent_Movable = PPS.Movable, @Adjacent_Sort_Order = Case When PEPSD.SortWith_PPStatusId is NULL or PEPSD.SortWith_PPStatusId = 0 Then PEPSD.Sort_Order Else (SELECT Sort_Order FROM PrdExec_Path_Status_Detail WHERE PP_Status_Id = PEPSD.SortWith_PPStatusId and Path_Id = PEPSD.Path_Id) End
              FROM Production_Plan PP
              Join Production_Plan_Statuses PPS on PPS.PP_Status_Id = PP.PP_Status_Id
              Join PrdExec_Path_Status_Detail PEPSD on PEPSD.PP_Status_Id = PPS.PP_Status_Id and (PEPSD.Path_Id = PP.Path_Id or PEPSD.Path_Id = (SELECT Min(Path_Id) FROM PrdExec_Paths WHERE Prod_Id = PP.Prod_Id))
              WHERE PP.PP_Id = @Adjacent_PP_Id
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjacent_Movable = ' + Convert(nvarchar(10), @Adjacent_Movable)) 
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjacent_Sort_Order = ' + Convert(nvarchar(10), @Adjacent_Sort_Order)) 
            If @Adjacent_Movable <> 1
              Begin
                If @MyOwnTrans = 1 ROLLBACK TRANSACTION
         	  	 Drop Table #PPStartsResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Adjacent_Movable <> 1')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (4)
              End
            If @This_Sort_Order <> @Adjacent_Sort_Order
              Begin
                If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	  	 Drop Table #PPStartsResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@This_Sort_Order <> @Adjacent_Sort_Order')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (4)
              End
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjacent_PP_Id = ' + Convert(nvarchar(10), @Adjacent_PP_Id)) 
            Update Production_Plan Set Implied_Sequence = @Adjacent_Sequence, User_Id = @UserId, Entry_On = @EntryOn, Implied_Sequence_Offset = @Adjacent_Sequence_Offset
              WHERE PP_Id = @PPId
            if @@ERROR <> 0  
              Begin
                -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
                If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	  	 Drop Table #PPStartsResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (-100)
              End
            Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
              SELECT 15, 0, @TransType, @TransNum, Path_Id, PP_Id, Comment_Id, Prod_Id, @Adjacent_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, @UserId,
              Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
              Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
                FROM Production_Plan
                WHERE PP_Id = @PPId
            Update Production_Plan Set Implied_Sequence = @This_Sequence, User_Id = @UserId, Entry_On = @EntryOn,Implied_Sequence_Offset = @This_Sequence_Offset
              WHERE PP_Id = @Adjacent_PP_Id
            if @@ERROR <> 0  
              Begin
                -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
                If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	  	 Drop Table #PPStartsResultSet
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
                If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
                Return (-100)
              End
            Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
              SELECT 15, 0, @TransType, @TransNum, Path_Id, PP_Id, Comment_Id, Prod_Id, @This_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, @UserId,
              Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
              Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
                FROM Production_Plan
                WHERE PP_Id = @Adjacent_PP_Id
            If @MyOwnTrans = 1 COMMIT TRANSACTION
            SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
              FROM @ProductionPlanRS
 	        	  	 If (SELECT count(*) FROM #PPStartsResultSet) > 0
      	  	  	  	 SELECT * FROM #PPStartsResultSet
       	  	  	 Drop Table #PPStartsResultSet
            If @TransNum = 98
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 98 (Move Process Order Back)') 
            Else If @TransNum = 99
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum = 99 (Move Process Order Forward)')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
             	  --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
            	 Return (2)
          End
        else
          Begin
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	  	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Adjacent_Sequence is Null')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (4)
          End
      End
   	 Else If @TransNum = 0
   	   Begin
     	 SELECT @PathId = Coalesce(@PathId, Path_Id), 
 	  	  	  	 @ProcessOrder = Coalesce(@ProcessOrder, Process_Order), 
     	  	  	 @PPStatusId = Coalesce(@PPStatusId, PP_Status_Id), 
     	  	  	 @ProdId = Coalesce(@ProdId, Prod_Id), 
     	  	  	 @BlockNumber = Coalesce(@BlockNumber, Block_Number), 
     	  	  	 @ForecastStartTime = Coalesce(@ForecastStartTime, Forecast_Start_Date), 
     	  	  	 @ForecastEndTime = Coalesce(@ForecastEndTime, Forecast_End_Date), 
     	  	  	 @ForecastQuantity = Coalesce(@ForecastQuantity, Forecast_Quantity), 
     	  	  	 @CommentId = Coalesce(@CommentId, Comment_Id), 
     	  	  	 @PPTypeId = Coalesce(@PPTypeId, PP_Type_Id), 
     	  	  	 @ProductionRate = Coalesce(@ProductionRate, Production_Rate), 
     	  	  	 @SourcePPId = Coalesce(@SourcePPId, Source_PP_Id), 
     	  	  	 @UserId = Coalesce(@UserId, User_Id), 
     	  	  	 @Sequence = Coalesce(@Sequence, Implied_Sequence), 
     	  	  	 @EntryOn = Coalesce(@EntryOn, Entry_On), 
 	  	  	  	 @AdjustedQuantity = Coalesce(@AdjustedQuantity, Adjusted_Quantity), 
 	  	  	  	 @ParentPPId = Coalesce(@ParentPPId, Parent_PP_Id), 
 	  	  	  	 @ControlType = Coalesce(@ControlType, Control_Type),
 	  	  	  	 @BOMFormulationId = Coalesce(@BOMFormulationId, BOM_Formulation_Id),
 	  	  	  	 @UserGeneral1 = Coalesce(@UserGeneral1, User_General_1),
 	  	  	  	 @UserGeneral2 = Coalesce(@UserGeneral2, User_General_2),
 	  	  	  	 @UserGeneral3 = Coalesce(@UserGeneral3, User_General_3),
 	  	  	  	 @ExtendedInfo = Coalesce(@ExtendedInfo,Extended_Info)
     	  	  FROM Production_Plan
     	  	  WHERE (PP_Id = @PPId)
    	   End
 	  	 Declare @OldPPStatusId Int
 	  	 SELECT @OldPPStatusId = PP_Status_Id FROM Production_Plan WHERE PP_Id = @PPId
    --Fields Not Editable In Client
 	  	 SELECT @AdjustedQuantity = Coalesce(@AdjustedQuantity, Adjusted_Quantity), 
      @ParentPPId = Coalesce(@ParentPPId, Parent_PP_Id)
 	  	  FROM Production_Plan
 	  	  WHERE (PP_Id = @PPId)
    Update Production_Plan 
 	  	 Set Path_Id = @PathId,
 	  	 Process_Order = @ProcessOrder,
 	  	 PP_Status_Id = @PPStatusId,
 	  	 Prod_Id = @ProdId,     
 	  	 Block_Number = @BlockNumber,
 	  	 Forecast_Start_Date = @ForecastStartTime,
 	  	 Forecast_End_Date = @ForecastEndTime,
 	  	 Forecast_Quantity = @ForecastQuantity,
 	  	 Comment_Id = @CommentId, 
 	  	 PP_Type_Id = @PPTypeId, 
 	  	 Production_Rate = @ProductionRate, 
 	  	 Source_PP_Id = @SourcePPId, 
 	  	 User_Id = @UserId,
 	  	 Implied_Sequence = @Sequence,
 	  	 Entry_On = @EntryOn,
 	  	 Adjusted_Quantity = @AdjustedQuantity,
 	  	 Parent_PP_Id = @ParentPPId,
 	  	 Control_Type = @ControlType,
 	  	 BOM_Formulation_Id = @BOMFormulationId,
 	  	 User_General_1 = @UserGeneral1,
 	  	 User_General_2 = @UserGeneral2,
 	  	 User_General_3 = @UserGeneral3,
 	  	 Extended_Info = @ExtendedInfo
    WHERE PP_Id = @PPId
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID,convert(nvarchar(10),@PPStatusId)+ '::' + convert(nvarchar(10),@OldPPStatusId ))
   	 If ((@PPStatusId = 3 and (@OldPPStatusId <> 3 or @OldPPStatusId is null)) or (@PPStatusId <> 3 and (@OldPPStatusId = 3))) and @PathId is NOT NULL
   	 BEGIN
 	  	 IF (@OldPPStatusId = 3) and (@PPStatusId <> 3 )
 	  	 BEGIN
/* 	  	  Close Any Active Setups */
 	  	  	 DECLARE @Setups2 TABLE (PPSetupId INT)
 	  	  	 DECLARE @MYPPSetupId2 INT
 	  	  	 INSERT INTO @Setups2 (PPSetupId) 
 	  	  	  	 SELECT Distinct PP_Setup_Id FROM production_Setup WHERE PP_Id = @PPId AND PP_Status_Id = 3
 	  	  	 DECLARE pps_Cursor Cursor FOR SELECT PPSetupId FROM @Setups2
 	  	  	 OPEN pps_Cursor
 	  	  	 pps_Cursor_Loop2:
 	  	  	 FETCH NEXT FROM pps_Cursor INTO @MYPPSetupId2
 	  	  	 IF @@FETCH_STATUS = 0
 	  	  	 BEGIN
 	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Closing PPStart' + convert(nvarchar(10),@MYPPSetupId))
               	  	 EXECUTE spServer_DBMgrUpdProdSetup @MYPPSetupId2, 2, 0, @UserId, Null, NULL, 4, NULL, NULL, Null, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @PathId, @EntryOn, @Now, Null
 	  	  	  	 GOTO pps_Cursor_Loop2
 	  	  	 END
 	  	  	 CLOSE pps_Cursor
 	  	  	 DEALLOCATE pps_Cursor
 	  	 END
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Calling spServer_DBMgrUpdProdPlanStartsFROMPlan')
 	  	 Execute @DBMgrUpdProdPlanStartsFROMPlan = spServer_DBMgrUpdProdPlanStartsFROMPlan @PPId,@PathId,@UserId,@SControlType,@PPStatusId, 1
 	  	 if @DBMgrUpdProdPlanStartsFROMPlan <= -1000
 	  	 BEGIN
 	  	  	 Drop Table #PPStartsResultSet
 	  	  	 if @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) SELECT @ID, 'Error Code = ' + Convert(nvarchar(10), @DBMgrUpdProdPlanStartsFROMPlan)
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	 return @DBMgrUpdProdPlanStartsFROMPlan
 	  	 END
    END
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        Return (-100)
      End
    else 
      Begin
        Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
          SELECT 15, 0, @TransType, @TransNum, @PathId, @PPId, @CommentId, @ProdId, @Sequence, @PPStatusId, @PPTypeId, @SourcePPId, @UserId,
          @ParentPPId, @ControlType, @ForecastStartTime, @ForecastEndTime, @EntryOn, @ForecastQuantity, @ProductionRate, @AdjustedQuantity,
          @BlockNumber, @ProcessOrder, @TransactionTime,@BOMFormulationId, 	 @UserGeneral1, @UserGeneral2, @UserGeneral3,@ExtendedInfo
        If @MyOwnTrans = 1 COMMIT TRANSACTION
        SELECT @ImpliedSequence = @Sequence
        SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
          FROM @ProductionPlanRS
     	  	 If (SELECT count(*) FROM #PPStartsResultSet) > 0
   	  	  	 SELECT * FROM #PPStartsResultSet
     	  	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Process Order Successful')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
         	  --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
        	 Return (2)
      End
  End /**********Update************/
Else If @TransType = 3
  Begin /**********DELETE************/
    --These qualifiers should be handled by the client code but double-check here
    -- ECR 29405 If the user has rights through security to delete Process Orders then they should be able
    -- to delete a PO even if it has a Production_Plan_Start or a link to the PP_Id in Event_Details.
    -- Null links in Event_Details
    update Event_Details set PP_Id = null WHERE PP_Id = @PPId
 	 --before removing the record get the record
 	 Insert Into #PPStartsResultSet
  	    	 Select 17, 0, 3, 0, PU_Id, PP_Start_Id, Start_Time, End_Time, PP_Id, Comment_Id, PP_Setup_Id, User_Id
  	    	  From Production_Plan_Starts Where PP_Id = @PPId
    -- Remove records in Production_Plan_Starts with this @PPId
    delete FROM Production_Plan_Starts WHERE PP_Id = @PPId
    SELECT @Check = Comment_Id FROM Production_Plan WHERE PP_Id = @PPId
    If (@Check Is Not Null)
      Begin
        Update Comments 
          Set ShouldDelete = 1, 
              Comment = '',
              Comment_Text = ''
          WHERE Comment_Id = @Check
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
           	 Drop Table #PPStartsResultSet
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            Return (-100)
          End
      End
    -- TODO: Fix this later, this is a performance pig
    Delete FROM Production_Setup_Detail 
      WHERE PP_Setup_Id in (SELECT PP_Setup_Id FROM Production_Setup WHERE PP_Id = @PPId)
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Error deleting Setup_Detail')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 Return (-100)
      End
    Declare
      @CursorPPSetupId int
    Declare PPSetupCursor INSENSITIVE CURSOR For 
      SELECT PP_Setup_Id
        FROM Production_Setup
        WHERE PP_Id = @PPId
      For Read Only
      Open PPSetupCursor  
    MyPPSetupLoop:
      Fetch Next FROM PPSetupCursor Into @CursorPPSetupId
      If (@@Fetch_Status = 0)
        Begin
          exec @DBMgrUpdProdSetupRC = spServer_DBMgrUpdProdSetup @CursorPPSetupId, @TransType, @TransNum, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @PathId, @EntryOn, @TransactionTime, NULL
 	  	  	  	  	 if @DBMgrUpdProdSetupRC <= -1000
 	  	  	  	  	  	 Begin
     	  	  	  	   Drop Table #PPStartsResultSet
 	  	  	  	  	     Close PPSetupCursor
 	  	  	  	  	     Deallocate PPSetupCursor
 	  	  	  	  	  	  	 if @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	     If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) SELECT @ID, 'Error Code = ' + Convert(nvarchar(10), @DBMgrUpdProdSetupRC)
 	  	  	  	  	     If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	  	  	  	  	 return @DBMgrUpdProdSetupRC
 	  	  	  	  	  	 End
          Goto MyPPSetupLoop
        End
    Close PPSetupCursor
    Deallocate PPSetupCursor
    --Refreshes Client
    Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
      SELECT 15, 0, 2, 0, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, PP_Status_Id, PP_Type_Id, NULL, @UserId,
      Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
      Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
        FROM Production_Plan
        WHERE Source_PP_Id = @PPId
    Update Production_Plan Set Source_PP_Id = NULL, User_Id = @UserId, Entry_On = @EntryOn WHERE Source_PP_Id = @PPId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Error upd SourcePP')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    	  	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 Return (-100)
      End
    --Refreshes Client
    Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
      SELECT 15, 0, 2, 0, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, @UserId,
      NULL, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
      Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
        FROM Production_Plan
        WHERE Parent_PP_Id = @PPId
    Update Production_Plan Set Parent_PP_Id = NULL, User_Id = @UserId, Entry_On = @EntryOn WHERE Parent_PP_Id = @PPId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Error upd SourcePP')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
       	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 Return (-100)
      End
    --Refreshes Parent in the Client
    Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
      SELECT 15, 0, 2, 0, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, @UserId,
      Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
      Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
        FROM Production_Plan
        WHERE PP_Id = (SELECT Parent_PP_Id FROM Production_Plan WHERE PP_Id = @PPId)
    Insert Into @ProductionPlanRS(Result,PreDB,TransType,TransNum,PathId,
 	  	  	  	  	  	  	 PPId,CommentId,ProdId,ImpliedSequence,PPStatusId,
 	  	  	  	  	  	  	 PPTypeId,SourcePPId,UserId,ParentPPId,ControlType,
 	  	  	  	  	  	  	 ForecastStartTime,ForecastEndTime,EntryOn,ForecastQuantity,ProductionRate,
 	  	  	  	  	  	  	 AdjustedQuantity,BlockNumber,ProcessOrder,TransactionTime,BOMFormulationId,
 	  	  	  	  	  	  	 UserGeneral1,UserGeneral2,UserGeneral3,ExtendedInfo)
      SELECT 15, 0, @TransType, @TransNum, Path_Id, PP_Id, Comment_Id, Prod_Id, Implied_Sequence, PP_Status_Id, PP_Type_Id, Source_PP_Id, @UserId,
      Parent_PP_Id, Control_Type, Forecast_Start_Date, Forecast_End_Date, @EntryOn, Forecast_Quantity, Production_Rate, Adjusted_Quantity,
      Block_Number, Process_Order, @TransactionTime,BOM_Formulation_Id,User_General_1,User_General_2,User_General_3,Extended_Info
        FROM Production_Plan
        WHERE PP_Id = @PPId
    Delete FROM Production_Plan_Transitions WHERE PP_Id = @PPId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	     Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 Return (-100)
      End
    Delete FROM Production_Plan WHERE PP_Id = @PPId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	     Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 Return (-100)
      End
    If @MyOwnTrans = 1 COMMIT TRANSACTION
    SELECT 	 Result, PreDB, TransType, TransNum, PathId, 
 	  	  	 PPId, CommentId, ProdId, ImpliedSequence, PPStatusId, 
 	  	  	 PPTypeId, SourcePPId, UserId, ParentPPId, ControlType, 
 	  	  	 ForecastStartTime, ForecastEndTime, EntryOn, ForecastQuantity, ProductionRate, 
 	  	  	 AdjustedQuantity, BlockNumber, ProcessOrder, TransactionTime,0,
 	  	  	 0,0,0,BOMFormulationId,UserGeneral1,
 	  	  	 UserGeneral2,UserGeneral3,ExtendedInfo
      FROM @ProductionPlanRS
    	  If (SELECT count(*) FROM #PPStartsResultSet) > 0
 	  BEGIN
 	  	 SELECT * FROM #PPStartsResultSet
 	  	 --Need to send a ProductionPlanStart message from here for this delete befor droping the table
 	  	 IF (@InsertIntoPendingResultSet = 1)
 	  	 BEGIN
 	  	  
 	  	 --Publish Message for Production Plan Start here, as this record has been deleted from this sproc only
 	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	 SELECT 0,
 	  	  	  	 (
 	  	  	  	 SELECT  
 	  	  	  	  	 RSTId = Result
 	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	 ,PUId = PUId
 	  	  	  	  	 ,PPStartId = PPStartId
 	  	  	  	  	 ,StartTime = StartTime
 	  	  	  	  	 ,EndTime = EndTime
 	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	 ,PPSetupId = PPSetupId
 	  	  	  	  	 ,UserId = UserId
 	  	  	  	 FROM #PPStartsResultSet
 	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	 ,@UserId
 	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	 END
 	  END
  	    	  
   	 Drop Table #PPStartsResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Process Order Successful')
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    --Before returning publish a production_plan message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
 	  	  	   
 	  	  	  	 --Publish Message for Production Plan here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PathId = PathId
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,ProdId = ProdId
 	  	  	  	  	  	 ,ImpliedSequence = ImpliedSequence
 	  	  	  	  	  	 ,PPStatusId = PPStatusId
 	  	  	  	  	  	 ,PPTypeId = PPTypeId
 	  	  	  	  	  	 ,SourcePPId = SourcePPId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	 ,ParentPPId = ParentPPId
 	  	  	  	  	  	 ,ControlType = 	 ControlType
 	  	  	  	  	  	 ,ForecastStartTime = ForecastStartTime
 	  	  	  	  	  	 ,ForecastEndTime = ForecastEndTime
 	  	  	  	  	  	 ,EntryOn = EntryOn
 	  	  	  	  	  	 ,ForecastQuantity = ForecastQuantity
 	  	  	  	  	  	 ,ProductionRate = ProductionRate
 	  	  	  	  	  	 ,AdjustedQuantity = AdjustedQuantity
 	  	  	  	  	  	 ,BlockNumber = BlockNumber
 	  	  	  	  	  	 ,ProcessOrder = ProcessOrder
 	  	  	  	  	  	 ,TransactionTime = TransactionTime
 	  	  	  	  	  	 ,Misc1 = 0
 	  	  	  	  	  	 ,Misc2 = 0
 	  	  	  	  	  	 ,Misc3 = 0
 	  	  	  	  	  	 ,Misc4 = 0
 	  	  	  	  	  	 ,BOMFormulationId = BOMFormulationId
 	  	  	  	  	  	 ,UserGen1 = UserGeneral1
 	  	  	  	  	  	 ,UserGen2 = UserGeneral2
 	  	  	  	  	  	 ,UserGen3 = UserGeneral3
 	  	  	  	  	  	 ,ExtendedInfo = ExtendedInfo
 	  	  	  	  	  	 FROM @ProductionPlanRS
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
    Return (3)
  End /**********DELETE************/
--If we get to the bottom of this proc and the transaction is still open something bad happpened rollback the changes. 
If @@Trancount > 0 
  BEGIN
    If @MyOwnTrans = 1 ROLLBACK TRANSACTION
   	 Drop Table #PPStartsResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'TranCount > 0, Rolling Back.') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-100)
  END
If @MyOwnTrans = 1 COMMIT TRANSACTION
Drop Table #PPStartsResultSet
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Return (4)') 
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Change')
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
Return (4)
