
CREATE PROCEDURE dbo.spPO_ModifyProcessOrderStartsOnUnit
@TransType	int
,@PP_Start_Id  		bigint				= Null OUTPUT
,@Unit_Id			int
,@PP_Id				int				= Null
,@PP_Setup_Id			int				= Null
,@Start_Time			datetime		= Null
,@End_Time			datetime		= Null
,@Comment_Id			int				= Null
,@User_Id			int
AS
/*
Times In and Out are in UTC
@TransactionType
	1 - Add
    3 - Delete
Update is not supported for now
	2 - Update

*/
IF (@TransType = 1)
    BEGIN
        -- selecting startime to current time
        select @Start_Time =  GETUTCDATE()
    end


    If (@Start_Time is not null)
        SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,'UTC')

    If (@End_Time is not null)
        SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,'UTC')

DECLARE @CurUnitId			int
DECLARE @ScheduleControlled	bit
DECLARE @PathId				int
DECLARE @PPStatusId			int
DECLARE @TransNum			int
DECLARE @InsertIntoPendingResultSet int = 1; -- Aksing core sproc to push associated messages
    Set @TransNum = 0
    If (@TransType = 2)
        Set @TransNum = 2 -- Do not coalesce on update

----------------------------------------------------------------------------------------------------------------------------------
-- Make sure we have a good user
----------------------------------------------------------------------------------------------------------------------------------
    IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @User_Id )
        BEGIN
            SELECT Error = 'Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

----------------------------------------------------------------------------------------------------------------------------------
-- Make sure we have a good PP_Id and its active
----------------------------------------------------------------------------------------------------------------------------------
Select @PPStatusId = PP_Status_Id FROM Production_Plan WHERE PP_id = @PP_Id

    IF @PPStatusId is Null
        BEGIN
            SELECT Error = 'Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = 'ProcessOrderId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

    IF @PPStatusId NOT in (3)
        BEGIN
            SELECT Error = 'Process Order status must be active', Code = 'InvalidData', ErrorType = 'InvalidStatus', PropertyName1 = 'PPStatusId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

    ----------------------------------------------------------------------------------------------------------------------------------
-- Rule checks
----------------------------------------------------------------------------------------------------------------------------------
    IF @TransType in (1)
        BEGIN
            IF @Unit_Id IS NULL
                BEGIN
                    SELECT Error = 'Unit not found', Code = 'InvalidData', ErrorType = 'MissingRequiredData', PropertyName1 = 'UnitId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
        END

    IF @TransType in (1,2)
        BEGIN
            IF @PP_Id IS NULL
                BEGIN
                    SELECT Error = 'Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = 'ProcessOrderId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            IF @Start_Time IS NULL
                BEGIN
                    SELECT Error = 'Start Time not found', Code = 'InvalidData', ErrorType = 'MissingRequiredData', PropertyName1 = 'StartTime', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            if (@Start_Time is not null) and (@End_Time is not null) and (@Start_Time >= @End_Time)
                BEGIN
                    SELECT Error = 'Start Time must be before End Time', Code = 'InvalidData', ErrorType = 'StartTimeNotBeforeEndTime', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            IF (@PP_Setup_Id is not null) AND (NOT EXISTS(SELECT 1 FROM Production_Setup WHERE PP_Setup_Id = @PP_Setup_Id and PP_Id = @PP_Id))
                BEGIN
                    SELECT Error = 'PP Setup not found', Code = 'InvalidData', ErrorType = 'InvalidParameterValue', PropertyName1 = 'PPSetupId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            IF (@Comment_Id is not null) AND (NOT EXISTS(SELECT 1 FROM Comments WHERE Comment_id = @Comment_Id and ((TopOfChain_Id = Comment_Id) or (TopOfChain_Id is null))))
                BEGIN
                    SELECT Error = 'Comment not found', Code = 'InvalidData', ErrorType = 'InvalidParameterValue', PropertyName1 = 'CommentId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

        END



----------------------------------------------------------------------------------------------------------------------------------
-- If it's a delete, load the information from the Production Plan Start and return error if it doesn't exist
----------------------------------------------------------------------------------------------------------------------------------
    IF @TransType in (3)
        BEGIN
            SELECT @Unit_Id = Null
            SELECT	@Unit_Id					= pps.PU_Id
                 ,@PP_Setup_Id				= pps.pp_setup_id
                 ,@Start_Time				= pps.Start_Time
                 ,@End_Time				= pps.End_Time
                 ,@Comment_Id				= pps.Comment_Id
                 ,@User_Id				= pps.User_Id
                 ,@PathId				= po.Path_Id
                 ,@ScheduleControlled	= pth.Is_Schedule_Controlled
            FROM	Production_Plan_Starts pps
                        JOIN	Production_Plan po ON po.PP_Id = pps.PP_Id
                        JOIN	Prdexec_Paths pth ON pth.Path_Id = po.Path_Id
            WHERE	pps.PP_Start_Id = @PP_Start_Id and pps.PP_Id = @PP_Id
            IF (@Unit_Id is null)
                BEGIN
                    SELECT Error = 'Process Order Start not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderStartNotFound', PropertyName1 = 'ProcessOrderStartId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
        END





    /*
    ----------------------------------------------------------------------------------------------------------------------------------
-- If it's an update return error if it doesn't exist.  Also, get some fields of the order that we don't want to change
----------------------------------------------------------------------------------------------------------------------------------
    IF @TransactionType = 2 -- Update
        BEGIN
            SELECT @CurUnitId = Null
            SELECT	@CurUnitId				= pps.PU_Id
                 ,@PathId				= po.Path_Id
                 ,@ScheduleControlled	= pth.Is_Schedule_Controlled
                 ,@UnitId				= coalesce(@UnitId, pps.PU_Id)
            FROM	Production_Plan_Starts pps
                        JOIN	Production_Plan po ON po.PP_Id = pps.PP_Id
                        JOIN	Prdexec_Paths pth ON pth.Path_Id = po.Path_Id
            WHERE	pps.PP_Start_Id = @PPStartId and pps.PP_Id = @PPId

            IF (@CurUnitId is null)
                BEGIN
                    SELECT Error = 'Process Order Start not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderStartNotFound', PropertyName1 = 'ProcessOrderStartId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
            IF (@CurUnitId <> @UnitId)
                BEGIN
                    SELECT Error = 'Unit Id cannot be changed', Code = 'InvalidData', ErrorType = 'InvalidParameterValue', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
        END
*/
    ----------------------------------------------------------------------------------------------------------------------------------
-- If it's an add validate inputs and get some data we need
----------------------------------------------------------------------------------------------------------------------------------
    IF @TransType = 1 -- Add
        BEGIN

            create table #NextAvailableUnits(Id bigint, name nvarchar(max), Caption nvarchar(max))
            INSERT INTO #NextAvailableUnits EXEC spPO_getNextAvailableUnits @PP_Id
            if(@Unit_Id not in (select Id from #NextAvailableUnits))
                BEGIN
                    SELECT Error = 'Error: Unit Not available for transition', Code = 'POConflict', ErrorType = 'InvalidUnitTransition', PropertyName1 = 'Unit', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Unit_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                end

            SELECT @PathId = po.Path_Id ,@ScheduleControlled = pth.Is_Schedule_Controlled FROM Production_Plan po
                    JOIN Prdexec_Paths pth ON pth.Path_Id = po.Path_Id
                    WHERE po.PP_Id = @PP_Id
            IF (@PathId is null)
                BEGIN
                    SELECT Error = 'Path not found', Code = 'ResourceNotFound', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Path', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END


            IF Not Exists(Select 1 from Prod_Units_Base where PU_Id = @Unit_Id)
                BEGIN
                    SELECT Error = 'Unit not found', Code = 'ResourceNotFound', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'UnitId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            IF Not Exists(Select 1 From PrdExec_Path_Units Where Path_Id = @PathId and PU_Id = @Unit_Id)
                BEGIN
                    SELECT Error = 'Unit not on path', Code = 'InvalidData', ErrorType = 'UnitNotOnPath', PropertyName1 = 'UnitId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END

            /*
             Check if this is a valid start transition
             */
        END

Declare @DatabaseTimeZone nvarchar(200)
select @DatabaseTimeZone = value from site_parameters where parm_id=192

--All the validations are done , so begining a transaction so that we can rollback on each step incase if there is an error
BEGIN TRANSACTION
    ----------------------------------------------------------------------------------------------------------------------------------
-- Execute the transaction using the DBMgr sproc
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @RC int
    EXECUTE @RC = spServer_DBMgrUpdProdPlanStarts
                  @PP_Start_Id OUTPUT, @TransType, @TransNum, @Unit_Id, @Start_Time, @End_Time, @PP_Id, @Comment_Id, @PP_Setup_Id, @User_Id, @ScheduleControlled, null, @InsertIntoPendingResultSet

    IF (@RC < 0) -- spServer sproc had an error
        BEGIN
            SELECT Error = 'Unknown error occurred in spServer_DBMgrUpdProdPlanStarts, return val = ' + CONVERT(varchar, @RC), Code = 'UnknownError',  ErrorType = 'UnknownError', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @RC, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            ROLLBACK TRANSACTION
			RETURN
        END

    /*
     Now update the predicted things
     */
    if(@TransType <> 3)
        BEGIN
            /*
             If transaction type is not three then call the spServer_DBMgrUpdProdStats to update the predicted quantities
             */
            create table #ProdStatsValues
            (
                dummy1 int, dummy2 int, dummy3 int, dummy4 int, dummy5 int,
                StatType int, Id int, StartTime DateTime, EndTime DatetIme, GoodItems int, BadItems int,RunningMinutes float,
                DownMinutes float, GoodQuantity float, BadQuantity float,
                PredictedTotalDuration float, PredictedRemainingDuration float, PredictedRemainingQuantity float, AlarmCount int, LateItems int, Repetitions int
            )

--- Declare variables to store the values from table to pass them to spServer_DBMgrUpdProdStats, couldn't pass them directly
            DECLARE @StatTypeStats int, @IdStats int, @StartTimeStats DateTime, @EndTimeStats DatetIme, @GoodItemsStats int, @BadItemsStats int, @RunningMinutesStats float,
                @DownMinutesStats float, @GoodQuantityStats float, @BadQuantityStats float,
                @PredictedTotalDurationStats float, @PredictedRemainingDurationStats float, @PredictedRemainingQuantityStats float, @AlarmCountStats int, @LateItemsStats int, @RepetitionsStats int

            DECLARE @ParentPPId INT, @return_value INT;

            INSERT INTO #ProdStatsValues EXEC spServer_SchMgrCalcStats @PP_Id,
                                              @ParentPPId = @ParentPPId OUTPUT
			--Update the stats only if we get some values in this table
			IF(SELECT COUNT(1) FROM #ProdStatsValues) = 1
			BEGIN
					Select @StatTypeStats = StatType, @IdStats = Id, @StartTimeStats = StartTime, @EndTimeStats = EndTime, @GoodItemsStats = GoodItems, @BadItemsStats  = BadItems,
				       @RunningMinutesStats = RunningMinutes, @DownMinutesStats = DownMinutes, @GoodQuantityStats = GoodQuantity, @BadQuantityStats = BadQuantity,
				       @PredictedTotalDurationStats = PredictedTotalDuration, @PredictedRemainingDurationStats = PredictedRemainingDuration, @PredictedRemainingQuantityStats = PredictedRemainingQuantity,
				       @AlarmCountStats = AlarmCount, @LateItemsStats = LateItems, @RepetitionsStats = Repetitions from #ProdStatsValues
				-- Insert the output of stored procedures into temp table
				/*
				 Only TransType 2 is supported [update of PO from spServer_DBMgrUpdProdStats, see the sproc]
				 default value of @TransNum will be used [2], it will throw error if transNum is not in (0,2,1010, NULL)
				 Need to check when to pass transNum 2 [most probably will be used for parentProcessOrder
				 */

				EXEC	@return_value = [dbo].[spServer_DBMgrUpdProdStats]
				                        2, 0, @StatTypeStats , @PP_Id, @StartTimeStats, @EndTimeStats, @GoodItemsStats, @BadItemsStats, @RunningMinutesStats,
				                        @DownMinutesStats, @GoodQuantityStats, @BadQuantityStats, @PredictedTotalDurationStats,
				                        @PredictedRemainingDurationStats,
				                        @PredictedRemainingQuantityStats, @AlarmCountStats, @LateItemsStats, @RepetitionsStats, @PPId = @PP_Id OUTPUT, @ParentPPId = @ParentPPId OUTPUT, @InsertIntoPendingResultSet =1

				
				If(@return_value < 0)
				BEGIN
					SELECT Error = 'ERROR in core sproc call spServer_DBMgrUpdProdStats, return val = ' + CONVERT(varchar, @return_value), Code = 'ERROR', ErrorType = 'ERROR', PropertyName1 = 'ReturnValue', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @return_value, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
					ROLLBACK TRANSACTION
					DROP TABLE #ProdStatsValues;
					RETURN
				END	
			END
			DROP TABLE #ProdStatsValues;
  --IF we reach here no errors so far we can commit this transaction
	COMMIT TRANSACTION          

            SELECT
                PP_Start_Id, PP_Id, Start_Time at time zone @DatabaseTimeZone at time zone 'UTC' as 'Start_Time', End_Time at time zone @DatabaseTimeZone at time zone 'UTC' as 'End_Time', pub.PU_Id,pub.PU_Desc, Is_Production from Production_Plan_Starts
                        LEFT JOIN Prod_Units_Base pub WITH (nolock) ON Production_Plan_Starts.PU_Id = pub.PU_Id
                         where PP_Start_Id = @PP_Start_Id

        END
