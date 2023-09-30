CREATE PROCEDURE dbo.spServer_DBMgrUpdProdStats
@TransType int,
@TransNum int,
@StatsType int, 
@PId int, 
@ActualStartTime datetime, 
@ActualEndTime datetime, 
@ActualGoodItems int, 
@ActualBadItems int, 
@ActualRunningTime float, 
@ActualDownTime float, 
@ActualGoodQuantity float, 
@ActualBadQuantity float, 
@PredictedTotalDuration float, 
@PredictedRemainingDuration float, 
@PredictedRemainingQuantity float,
@AlarmCount int,
@LateItems int,
@ActualRepetitions int,
@PPId int output,
@ParentPPId int output,
@InsertIntoPendingResultSet int = 0 --Flag to put Production Stats record in Pending_ResultSets table which inturn gets publised to RabbitMQ
  AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
Declare @DebugFlag tinyint,
        	  @ID int,
  	        @MyOwnTrans  	    	    	  Int,
 	  	    @PathId INT,
 	  	    @UserId INT
select @PPId = null
select @ParentPPId = null
If @@Trancount = 0
 	 Select @MyOwnTrans = 1
Else
 	 Select @MyOwnTrans = 0
--0 FOR this value means dont put the message record onto Pending_ResultSets
SET @InsertIntoPendingResultSet = Coalesce(@InsertIntoPendingResultSet,0);
/*
Insert Into User_Parameters (Parm_Id, User_Id, Value, HostName) Values(100, 6, 1, '')
update User_Parameters set value = 1 where Parm_Id = 100 and User_Id = 6
*/
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdProdStats /TransType: ' + coalesce(convert(nvarchar(10),@TransType),'Null') + ' /TransNum: ' + coalesce(convert(nvarchar(10),@TransNum),'Null') + 
  ' /StatsType: ' + coalesce(convert(nvarchar(10),@StatsType),'Null') + ' /PId: ' + coalesce(convert(nvarchar(10),@PId),'Null') + 
 	 ' /ActualStartTime: ' + coalesce(convert(nVarChar(25),@ActualStartTime),'Null') + ' /ActualEndTime: ' + coalesce(convert(nVarChar(25),@ActualEndTime),'Null') + 
 	 ' /ActualGoodItems: ' + coalesce(convert(nvarchar(10),@ActualGoodItems),'Null') + ' /ActualBadItems: ' + coalesce(convert(nVarChar(25),@ActualBadItems),'Null') + 
 	 ' /ActualRunningTime: ' + coalesce(convert(nVarChar(25),@ActualRunningTime),'Null') + ' /ActualDownTime: ' + coalesce(convert(nVarChar(25),@ActualDownTime),'Null') + 
 	 ' /ActualGoodQuantity: ' + coalesce(convert(nVarChar(25),@ActualGoodQuantity),'Null') + ' /ActualBadQuantity: ' + coalesce(convert(nVarChar(25),@ActualBadQuantity),'Null') + 
 	 ' /PredictedTotalDuration ' + coalesce(convert(nVarChar(25),@PredictedTotalDuration),'Null') + ' /PredictedRemainingDuration: ' + coalesce(convert(nVarChar(25),@PredictedRemainingDuration),'Null') + 
 	 ' /PredictedRemainingQuantity: ' + coalesce(convert(nVarChar(25),@PredictedRemainingQuantity),'Null') + ' /AlarmCount ' + coalesce(convert(nVarChar(25),@AlarmCount),'Null') +  
 	 ' /LateItems: ' + coalesce(convert(nVarChar(25),@LateItems),'Null') + ' /ActualRepetitions ' + coalesce(convert(nVarChar(25),@ActualRepetitions),'Null'))
  End
/****************************************************/
/********Copyright 1998 Mountain Systems Inc.********/
/****************************************************/
  --
  -- Statistics Types
  -- 1 - Production_Plan
  -- 2 - Production_Setup
  --
  -- Transaction Types
  -- 1 - Insert
  -- 2 - Update
  -- 3 - Delete
  --
  -- Return Values:
  --
  --   (-100)  Error.
  --   (   1)  Success: New record added.
  --   (   2)  Success: Existing record modified.
  --   (   3)  Success: Existing record deleted.
  --   (   4)  Success: No action taken.
  --
If (@TransType <> 2)
  Begin
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransType <> 2')
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-100)
  End
If (@TransNum is NULL)
  select @TransNum = 2
IF (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
If (@TransNum <> 0) And (@TransNum <> 2)
  Begin
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(@TransNum <> 0) And (@TransNum <> 2)')
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-100)
  End
If @TransType = 2
  Begin
 	  	 If @MyOwnTrans = 1 
 	  	  	 Begin
 	  	  	  	 BEGIN TRANSACTION
        DECLARE @XLock BIT SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	  	  	 End
    If @StatsType = 1
      Begin
 	  	 select @PPId = @PId
       	 If @TransNum = 0
       	   Begin
            Select @ActualStartTime = Coalesce(@ActualStartTime,Actual_Start_Time),
         	  	  	 --@ActualEndTime = Coalesce(@ActualEndTime,Actual_End_Time),   -- Allow EndTime to go back to null 11/15/2011
         	  	  	 @ActualGoodItems = Coalesce(@ActualGoodItems,Actual_Good_Items),
         	  	  	 @ActualBadItems = Coalesce(@ActualBadItems,Actual_Bad_Items),
         	  	  	 @ActualRunningTime = Coalesce(@ActualRunningTime,Actual_Running_Time),
         	  	  	 @ActualDownTime = Coalesce(@ActualDownTime,Actual_Down_Time),
         	  	  	 @ActualGoodQuantity = Coalesce(@ActualGoodQuantity,Actual_Good_Quantity),
         	  	  	 @ActualBadQuantity = Coalesce(@ActualBadQuantity,Actual_Bad_Quantity),
         	  	  	 @PredictedTotalDuration = Coalesce(@PredictedTotalDuration,Predicted_Total_Duration),
         	  	  	 @PredictedRemainingDuration = Coalesce(@PredictedRemainingDuration,Predicted_Remaining_Duration),
         	  	  	 @PredictedRemainingQuantity = Coalesce(@PredictedRemainingQuantity,Predicted_Remaining_Quantity),
              @AlarmCount = Coalesce(@AlarmCount,Alarm_Count),
              @LateItems = Coalesce(@LateItems,Late_Items),
              @ActualRepetitions = Coalesce(@ActualRepetitions, Actual_Repetitions),
  	    	    	    	    	    	    	  @ParentPPId = Parent_PP_Id,
 	  	  	  	  	  	  	   @UserId = User_Id
          	    	   From Production_Plan
          	    	   Where (PP_Id = @PId)
        	    End
  	    	    else
  	    	    begin
            Select @ParentPPId = Parent_PP_Id , @UserId = User_Id 	   From Production_Plan Where (PP_Id = @PId)
      	    end
                   -- Check if update is really required, otherwise just return (4) i.e no change
 	  	  	  	 Declare @IsStatsChanged int = 0
 	  	  	  	 DECLARE  @StartTimeCurrent DateTime, @EndTimeCurrent DatetIme, @GoodItemsCurrent float, @BadItemsCurrent float, @RunningMinutesCurrent float,
 	  	  	  	 @DownMinutesCurrent float, @GoodQuantityCurrent float, @BadQuantityCurrent float,
 	  	  	  	 @PredictedTotalDurationCurrent float, @PredictedRemainingDurationCurrent float, @PredictedRemainingQuantityCurrent float, @AlarmCountCurrent int, @LateItemsCurrent int, @RepetitionsCurrent int
 	  	  	  	 select @StartTimeCurrent =  Actual_Start_Time, @EndTimeCurrent = Actual_End_Time, @GoodItemsCurrent = Actual_Good_Items, @BadItemsCurrent = Actual_Bad_Items,
 	  	  	  	  	    @RunningMinutesCurrent = Actual_Running_Time, @DownMinutesCurrent =  Actual_Down_Time,
 	  	  	  	  	    @GoodQuantityCurrent =  Actual_Good_Quantity, @BadQuantityCurrent =  Actual_Bad_Quantity,@PredictedTotalDurationCurrent =  Predicted_Total_Duration,
 	  	  	  	  	    @PredictedRemainingDurationCurrent = Predicted_Remaining_Duration, @PredictedRemainingQuantityCurrent = Predicted_Remaining_Quantity, @AlarmCountCurrent  = Alarm_Count, @LateItemsCurrent = Late_Items, @RepetitionsCurrent = Actual_Repetitions
 	  	  	  	 from Production_Plan where PP_Id = @PPId
 	  	  	  	 DECLARE  @DummyInt Int, @DummyFloat float, @DummyDate Datetime
                Select @DummyInt = -2147483648; Select @DummyFloat = CAST('-1.79E+308' AS float); select @DummyDate = cast('1753-1-1' as datetime) -- Used for null values
 	  	  	  	  	  
 	  	  	  	 if(coalesce(@ActualStartTime, @DummyDate) != coalesce(@StartTimeCurrent,@DummyDate))
                        BEGIN
                            -- StartTime changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@ActualEndTime, @DummyDate) != coalesce(@EndTimeCurrent,@DummyDate))
                        BEGIN
                            -- End_time changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@ActualGoodItems, @DummyInt) != coalesce(@GoodItemsCurrent,@DummyInt))
                        BEGIN
                            -- GoodItems changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@ActualBadItems, @DummyFloat) != coalesce(@BadItemsCurrent,@DummyFloat))
                        BEGIN
                            -- BadItems changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@ActualRunningTime, @DummyFloat) != coalesce(@RunningMinutesCurrent,@DummyFloat))
                        BEGIN
                            -- RunningMinutes changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@ActualDownTime, @DummyFloat) != coalesce(@DownMinutesCurrent,@DummyFloat))
                        BEGIN
                            -- DownMinutes changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@ActualGoodQuantity, @DummyFloat) != coalesce(@GoodQuantityCurrent,@DummyFloat))
                        BEGIN
                            -- GoodQuantity changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@ActualBadQuantity, @DummyFloat) != coalesce(@BadQuantityCurrent,@DummyFloat))
                        BEGIN
                            -- BadQuantity changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@PredictedTotalDuration, @DummyFloat) != coalesce(@PredictedTotalDurationCurrent,@DummyFloat))
                        BEGIN
                            -- PredictedTotalDuration changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@PredictedRemainingDuration, @DummyFloat) != coalesce(@PredictedRemainingDurationCurrent,@DummyFloat))
                        BEGIN
                            -- PredictedRemainingDuration changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@PredictedRemainingQuantity, @DummyFloat) != coalesce(@PredictedRemainingQuantityCurrent,@DummyFloat))
                        BEGIN
                            -- PredictedRemainingQuantity changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@AlarmCount, @DummyInt) != coalesce(@AlarmCountCurrent,@DummyInt))
                        BEGIN
                            -- AlarmCount changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@LateItems, @DummyInt) != coalesce(@LateItemsCurrent,@DummyInt))
                        BEGIN
                            -- LateItems changed
                            select @IsStatsChanged = 1
                        END
                    if(coalesce(@ActualRepetitions, @DummyInt) != coalesce(@RepetitionsCurrent,@DummyInt))
                        BEGIN
                            -- Repetitions changed
                            select @IsStatsChanged = 1
                        END
 	  	 if(@IsStatsChanged = 0)
 	  	  	 BEGIN
 	  	  	  	 
 	  	  	  	 if @@ERROR <> 0  
 	  	  	  	   Begin
 	  	  	  	  	 -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	  	 If @MyOwnTrans = 1  ROLLBACK TRANSACTION
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	  	  	 Return (-100)
 	  	  	  	   End
 	  	  	  	 else 
 	  	  	  	   Begin
 	  	  	  	  	 If @MyOwnTrans = 1  COMMIT TRANSACTION
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Return (4)') 
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Change')
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        	  	  	  	 Return (4)
 	  	  	  	   End
 	  	  	 END
        Update Production_Plan 
          Set Actual_Start_Time = @ActualStartTime,
          Actual_End_Time = @ActualEndTime,
          Actual_Good_Items = @ActualGoodItems,
          Actual_Bad_Items = @ActualBadItems,     
          Actual_Running_Time = @ActualRunningTime,
          Actual_Down_Time = @ActualDownTime,
          Actual_Good_Quantity = @ActualGoodQuantity,
          Actual_Bad_Quantity = @ActualBadQuantity,
          Predicted_Total_Duration = @PredictedTotalDuration, 
          Predicted_Remaining_Duration = @PredictedRemainingDuration, 
          Predicted_Remaining_Quantity = @PredictedRemainingQuantity,
          Alarm_Count = @AlarmCount,
          Late_Items = @LateItems,
          Actual_Repetitions = @ActualRepetitions
        Where PP_Id = @PId
 	  	 --publish production_stats message after updation
 	  	 IF (@InsertIntoPendingResultSet = 1)
 	  	 BEGIN
 	  	 --Publish Message for Production stat here
 	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	 SELECT 0,
 	  	  	  	 (
 	  	  	  	 SELECT  
 	  	  	  	  	 RSTId = 19
 	  	  	  	  	 ,PreDB = 0
 	  	  	  	  	 ,TransType = @TransType
 	  	  	  	  	 ,TransNum = @TransNum
 	  	  	  	  	 ,PathId = Path_Id
 	  	  	  	  	 ,StatsType = 1 -- for production plan related stats
 	  	  	  	  	 ,Id = PP_Id
 	  	  	  	  	 ,ActualStartTime = Actual_Start_Time
 	  	  	  	  	 ,ActualEndTime = Actual_End_Time
 	  	  	  	  	 ,ActualGoodItems = Actual_Good_Items
 	  	  	  	  	 ,ActualBadItems = Actual_Bad_Items
 	  	  	  	  	 ,ActualRunningTime = Actual_Running_Time
 	  	  	  	  	 ,ActualDownTime = Actual_Down_Time
 	  	  	  	  	 ,ActualGoodQuantity = Actual_Good_Quantity
 	  	  	  	  	 ,ActualBadQuantity = Actual_Bad_Quantity
 	  	  	  	  	 ,PredictedTotalDuration = Predicted_Total_Duration
 	  	  	  	  	 ,PredictedRemainingDuration = Predicted_Remaining_Duration
 	  	  	  	  	 ,PredictedRemainingQuantity = Predicted_Remaining_Quantity
 	  	  	  	  	 ,AlarmCount = Alarm_Count
 	  	  	  	  	 ,LateItems = Late_Items
 	  	  	  	  	 ,Repetitions = Actual_Repetitions
 	  	  	  	  	 ,PPId = PP_Id
 	  	  	  	  	 ,ParentPPId = Parent_PP_Id
 	  	  	  	  	 FROM 
 	  	  	  	 Production_Plan WHERE PP_Id = @PId
 	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	 ,@UserId
 	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	 END
      End
    Else If @StatsType = 2
      Begin
       	 If @TransNum = 0
       	   Begin
            Select @ActualStartTime = Coalesce(@ActualStartTime,Actual_Start_Time),
         	  	  	 --@ActualEndTime = Coalesce(@ActualEndTime,Actual_End_Time),  -- Allow EndTime to go back to null 11/15/2011
         	  	  	 @ActualGoodItems = Coalesce(@ActualGoodItems,Actual_Good_Items),
         	  	  	 @ActualBadItems = Coalesce(@ActualBadItems,Actual_Bad_Items),
         	  	  	 @ActualRunningTime = Coalesce(@ActualRunningTime,Actual_Running_Time),
         	  	  	 @ActualDownTime = Coalesce(@ActualDownTime,Actual_Down_Time),
         	  	  	 @ActualGoodQuantity = Coalesce(@ActualGoodQuantity,Actual_Good_Quantity),
         	  	  	 @ActualBadQuantity = Coalesce(@ActualBadQuantity,Actual_Bad_Quantity),
         	  	  	 @PredictedTotalDuration = Coalesce(@PredictedTotalDuration,Predicted_Total_Duration),
         	  	  	 @PredictedRemainingDuration = Coalesce(@PredictedRemainingDuration,Predicted_Remaining_Duration),
         	  	  	 @PredictedRemainingQuantity = Coalesce(@PredictedRemainingQuantity,Predicted_Remaining_Quantity),
              @AlarmCount = Coalesce(@AlarmCount,Alarm_Count),
              @LateItems = Coalesce(@LateItems,Late_Items),
              @ActualRepetitions = Coalesce(@ActualRepetitions, Actual_Repetitions),
  	    	    	    	    	    	    	  @PPId = PP_Id
 	  	  	  	  	  	  	  , @UserId = User_Id
          	    	   From Production_Setup
          	    	   Where (PP_Setup_Id = @PId)
        	    End
  	    	    else
  	    	    begin
            Select @PPId = PP_Id, @UserId = User_Id From Production_Setup Where (PP_Setup_Id = @PId)
   	    	    end
  	    	  if (@PPId is not null)
  	          Select @ParentPPId = Parent_PP_Id, @PathId = Path_Id  From Production_Plan Where (PP_Id = @PPId)
        Update Production_Setup 
          Set Actual_Start_Time = @ActualStartTime,
          Actual_End_Time = @ActualEndTime,
          Actual_Good_Items = @ActualGoodItems,
          Actual_Bad_Items = @ActualBadItems,     
          Actual_Running_Time = @ActualRunningTime,
          Actual_Down_Time = @ActualDownTime,
          Actual_Good_Quantity = @ActualGoodQuantity,
          Actual_Bad_Quantity = @ActualBadQuantity,
          Predicted_Total_Duration = @PredictedTotalDuration, 
          Predicted_Remaining_Duration = @PredictedRemainingDuration, 
          Predicted_Remaining_Quantity = @PredictedRemainingQuantity,
          Alarm_Count = @AlarmCount,
          Late_Items = @LateItems,
          Actual_Repetitions = @ActualRepetitions
        Where PP_Setup_Id = @PId
 	  	 --publish production_stats message after updation
 	  	 IF (@InsertIntoPendingResultSet = 1)
 	  	 BEGIN
 	  	 --Publish Message for Production stat here
 	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	 SELECT 0,
 	  	  	  	 (
 	  	  	  	 SELECT  
 	  	  	  	  	 RSTId = 19
 	  	  	  	  	 ,PreDB = 0
 	  	  	  	  	 ,TransType = @TransType
 	  	  	  	  	 ,TransNum = @TransNum
 	  	  	  	  	 ,PathId = @PathId
 	  	  	  	  	 ,StatsType = 2 -- For production setup stats
 	  	  	  	  	 ,Id = PP_Setup_Id
 	  	  	  	  	 ,ActualStartTime = Actual_Start_Time
 	  	  	  	  	 ,ActualEndTime = Actual_End_Time
 	  	  	  	  	 ,ActualGoodItems = Actual_Good_Items
 	  	  	  	  	 ,ActualBadItems = Actual_Bad_Items
 	  	  	  	  	 ,ActualRunningTime = Actual_Running_Time
 	  	  	  	  	 ,ActualDownTime = Actual_Down_Time
 	  	  	  	  	 ,ActualGoodQuantity = Actual_Good_Quantity
 	  	  	  	  	 ,ActualBadQuantity = Actual_Bad_Quantity
 	  	  	  	  	 ,PredictedTotalDuration = Predicted_Total_Duration
 	  	  	  	  	 ,PredictedRemainingDuration = Predicted_Remaining_Duration
 	  	  	  	  	 ,PredictedRemainingQuantity = Predicted_Remaining_Quantity
 	  	  	  	  	 ,AlarmCount = Alarm_Count
 	  	  	  	  	 ,LateItems = Late_Items
 	  	  	  	  	 ,Repetitions = Actual_Repetitions
 	  	  	  	  	 ,PPId = @PPId
 	  	  	  	  	 ,ParentPPId = @ParentPPId
 	  	  	  	  	 FROM 
 	  	  	  	 Production_Setup WHERE PP_Setup_Id = @PId
 	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	 ,@UserId
 	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	 END
 	 END
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
        If @MyOwnTrans = 1  ROLLBACK TRANSACTION
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        Return (-100)
      End
    else 
      Begin
        If @MyOwnTrans = 1  COMMIT TRANSACTION
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Status Successful')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        	 Return (2)
      End
  End
--If we get to the bottom of this proc and the transaction is still open something bad happpened rollback the changes. 
If @@Trancount > 0 and @MyOwnTrans = 1  
  BEGIN
    ROLLBACK TRANSACTION
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'TranCount > 0, Rolling Back.') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-100)
  END
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Return (4)') 
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Change')
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
Return (4)
