
CREATE  FUNCTION [dbo].[fnDowntime_ModifyDowntime_Validations](
		@TransactionType Int
		,@TEDetId		Int  = Null
		,@StartTime		DateTime = Null 
		,@EndTime		DateTime = Null
		,@LocationId	Int
		,@FaultId		Int = Null
		,@Reason1Id		Int = Null
		,@Reason2Id		Int = Null
		,@Reason3Id		Int = Null
		,@Reason4Id		Int = Null
		,@Action1Id		Int = Null
		,@Action2Id		Int = Null
		,@Action3Id		Int = Null
		,@Action4Id		Int = Null
		,@RuleToCheck	Int = Null
		,@UserId		Int
		,@AddCommentId		Int
			)
		 RETURNS @outputtable table (TedDetId int, Code nvarchar(100), Error nvarchar(100), ErrorType nvarchar(100),PropertyName1 nvarchar(100),PropertyName2 nvarchar(100),PropertyName3 nvarchar(100),PropertyName4 nvarchar(100),
		PropertyValue1 nvarchar(100),PropertyValue2 nvarchar(100),PropertyValue3 nvarchar(100),PropertyValue4 nvarchar(100), RecordChanged int)
		
AS
BEGIN


DECLARE @MasterUnit Int
		,@MinStart	DateTime
		,@MinStart2  DateTime
		,@MaxEnd	DateTime
		,@CurrentStart	DateTime
		,@CurrentEnd	DateTime
		,@UsersSecurity  Int
		,@ActualSecurity Int
		,@CommentRequired Int
		,@CurrentMaster     Int
		,@CurrentCommentId	Int
		,@CurrentReason1Id	Int
		,@CurrentReason2Id	Int
		,@CurrentReason3Id	Int
		,@CurrentReason4Id	Int
		,@CurrentFaultId	Int
		,@CurrentLocationId	Int
		,@TreeId		Int
		/* Extra Fields needed for Update*/
		,@CurrStatus			Int
		,@CurrAction1			Int
		,@CurrAction2			Int
		,@CurrAction3			Int
		,@CurrAction4			Int
		,@ActionTreeId			Int
		,@CurrActionComment		Int
		,@CurrResearchComment	Int
		,@CurrResearchStatus	Int
		,@CurrResearchUser		Int
		,@CurrResearchOpen		Datetime
		,@CurrResearchClose		Datetime
		,@CurrSignatureId	    Int
		,@RecordChanged Int = 0
		,@ExistingStartTime		Datetime
		,@ExistingEndTime		Datetime

   DECLARE @UTCDate				datetime
		,@DBDate				datetime
		,@DBStartTime			datetime
		,@DaysBackOpenDowntimeEventCanBeAdded INT
		,@OpenDowntimeEventCanBeAddedDaysBack BIT


DECLARE @AvailableUnits TABLE  (PU_Id Int)
Declare @dbzone varchar(100)
Select @dbzone =value from site_parameters where parm_id =192
SET @RuleToCheck = COALESCE(@RuleToCheck, 0)
SET @DBStartTime = --dbo.fnServer_CmnConvertToDBTime(@StartTime,'UTC')

@StartTime at time zone 'UTC' at time zone @dbzone
SELECT @DaysBackOpenDowntimeEventCanBeAdded = CONVERT(int, COALESCE(Value, '0')) FROM Site_Parameters WHERE Parm_Id = 77
Select @OpenDowntimeEventCanBeAddedDaysBack = CONVERT(BIT, COALESCE(Value, 0)) From Site_Parameters Where Parm_Id = 78

SELECT @MasterUnit = COALESCE(Master_Unit,@LocationId) FROM Prod_Units_Base WHERE PU_Id = @LocationId
if exists (select 1 from User_Security WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4)
Begin
	INSERT INTO @AvailableUnits SELECT Distinct PU_Id From EVENT_Configuration WHERE ET_Id = 2 and pU_id = @MasterUnit
End
Else
Begin
	INSERT INTO @AvailableUnits SELECT DISTINCT PU_Id FROM dbo.fnMES_GetDowntimeAvailableUnits(@UserId)
End
SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel( @MasterUnit,@UserId,1)

SET @UTCDate = GETUTCDATE();
SET @DBDate =-- dbo.fnServer_CmnConvertToDbTime(GetUTCDate(),'UTC')
GetUTCDate() at time zone 'UTC' at time zone @dbzone

IF @TransactionType IN (1,2)
BEGIN
	IF @MasterUnit Is Null
	BEGIN
	INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null, Code = 'InvalidData', Error = 'Unit not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Unit', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
		RETURN
	END
END
/******************************************** RULE CHECKS ********************************/
IF @TransactionType = 1  -- ADD  Only at End
BEGIN
        SELECT @MinStart = MAX(End_Time) FROM Timed_Event_Details WHERE PU_Id = @MasterUnit
        IF @MinStart IS NULL
		BEGIN
			SELECT @MinStart = DATEADD(Month, -1, @DBDate)
        END
        SET @MaxEnd = NULL
END

IF @TransactionType = 2
BEGIN
    SELECT @CurrentStart = Start_Time,@CurrentEnd = End_Time
		FROM Timed_Event_Details a WHERE TEDET_Id = @TEDetId
	SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@MasterUnit,273,423,3,@UsersSecurity)
	IF @ActualSecurity = 0
		BEGIN
			SELECT @MinStart = @CurrentStart
			SELECT @MaxEnd = @CurrentEnd
		END
	ELSE
		BEGIN
			SELECT @MinStart = MAX(End_Time) FROM Timed_Event_Details WHERE PU_Id = @MasterUnit AND End_Time <= @CurrentStart
		    IF @MinStart IS NULL
				BEGIN
					SELECT @MinStart = DATEADD(day, -7, @CurrentStart)
				END

			SELECT @MaxEnd = MIN(Start_Time) FROM Timed_Event_Details WHERE PU_Id = @MasterUnit
		    IF @MaxEnd IS NULL
				BEGIN
	                SET @MaxEnd = @DBDate
	            END
		END
END

IF @TransactionType IN(1, 2)
    BEGIN
        SET @MinStart2 = @MinStart
		-- Set min start time when the flag is turned on
		IF @OpenDowntimeEventCanBeAddedDaysBack = 1
            BEGIN
				-- Set the min start time according to the days configured or set it to unlimited days when null
                IF @DaysBackOpenDowntimeEventCanBeAdded <> 0
                    BEGIN
                        SELECT @MinStart2 = DATEADD(day, -1 * @DaysBackOpenDowntimeEventCanBeAdded, @DBDate)
                    END
                ELSE
                    BEGIN
                        SET @MinStart2 = NULL
                    END
            END

        SELECT @MinStart = DATEADD(Millisecond, -DATEPART(Millisecond, @MinStart), @MinStart),
               @MinStart2 = DATEADD(Millisecond, -DATEPART(Millisecond, @MinStart2), @MinStart2),
               @MaxEnd = DATEADD(Millisecond, -DATEPART(Millisecond, @MaxEnd), @MaxEnd)

        SELECT @StartTime = DATEADD(Millisecond, -DATEPART(Millisecond, @StartTime), @StartTime),
               @EndTime = DATEADD(Millisecond, -DATEPART(Millisecond, @EndTime), @EndTime)

        IF @OpenDowntimeEventCanBeAddedDaysBack = 1 AND @EndTime IS NULL
			BEGIN
				--Check only if time got changed
                IF @CurrentStart IS NULL
                   OR dbo.fnServer_CmnConvertFromDBTime(@CurrentStart, 'UTC') <> @StartTime
				   OR ISNULL(@CurrentEnd, 0) <> ISNULL(@EndTime, 0)
                    BEGIN
                        IF @DaysBackOpenDowntimeEventCanBeAdded <> 0
                            BEGIN
                                IF @StartTime < dbo.fnServer_CmnConvertFromDBTime(@MinStart2, 'UTC')
                                    BEGIN
										INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										    SELECT null, Code = 'InvalidData', Error = 'Invalid - Start Time Too Old', ErrorType = 'StartTimeTooOld', PropertyName1 = 'StartTime', PropertyName2 = 'EarliestStartTime', PropertyName3 = '',PropertyName4 = '', PropertyValue1 = @StartTime, PropertyValue2 = @MinStart, PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
										    RETURN
                                    END
                            END
                    END
                SET @RuleToCheck = 2
            END
	END

/************************************  ADD  ************************/
IF @TransactionType = 1  -- ADD
BEGIN
	IF @MasterUnit IS NULL
	BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null, Code = 'InvalidData', Error = 'Unit not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Unit', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
		RETURN
	END
	IF @StartTime IS NULL
	BEGIN
	INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null,Code = 'InvalidData', Error = 'StartTime not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'StartTime', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
		RETURN
	END
	SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@MasterUnit,8,393,3,@UsersSecurity)
	IF @ActualSecurity = 0
	BEGIN
	INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Bad Attempt to Add Downtime', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
		RETURN
	END
	IF NOT EXISTS (SELECT 1 FROM @AvailableUnits WHERE PU_ID = @MasterUnit)
	BEGIN
	INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null,Code = 'InsufficientPermission', Error = 'Invalid add attempt', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
		RETURN
	END
	-- Check if an open downtime alteady exists
	IF EXISTS(SELECT 1 FROM Timed_Event_Details WHERE PU_Id = @MasterUnit AND End_Time IS NULL) AND  @EndTime IS NULL
	BEGIN
		-- Check if the flag to create and override an open downtime is true then check whether there are any downtimes past the start time of the new downtime
	   IF @OpenDowntimeEventCanBeAddedDaysBack = 0 OR EXISTS(SELECT 1 FROM Timed_Event_Details WHERE PU_Id = @MasterUnit AND End_Time IS NULL AND Start_Time <= @DBStartTime)
	    BEGIN
		   INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			   SELECT null,Code = 'DowntimeRecordConflict', Error = 'Open downtime exists', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			   RETURN
	    END
     END
	IF @StartTime >= @EndTime
	BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null,Code = 'InvalidData', Error = 'Invalid - StartTime Must be Less than EndTime', ErrorType = 'StartTimeNotBeforeEndTime', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
		RETURN
	END
	IF (@StartTime > GETUTCDATE())
	BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
	              SELECT null, Code = 'InvalidData', Error = 'Invalid -StartTime must be less than current time', ErrorType = 'StartTimeNotInFutureTime', PropertyName1 = 'StartTime', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @StartTime, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
	              RETURN
	    END
	    IF (@EndTime > GETUTCDATE())
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
	       SELECT null, Code = 'InvalidData', Error = 'Invalid -Endtime must be less than current time', ErrorType = 'EndTimeNotInFutureTime', PropertyName1 = 'EndTime', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @EndTime, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
	END
	IF @FaultId IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM Timed_Event_Fault  WHERE TEFault_Id = @FaultId AND PU_id = @MasterUnit AND (Source_PU_Id = @LocationId Or @LocationId = @MasterUnit))
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Fault Not Found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'FaultId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @FaultId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END
	SELECT @TreeId = Name_Id FROM Prod_Events WHERE PU_Id = @LocationId  AND Event_Type = 2
	If  @Reason1Id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Reason1Id AND Tree_Name_Id = @TreeId)
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Reason 1 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Cause1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason1Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END
	If  @Reason2Id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
						WHERE Level1_Id = @Reason1Id AND  Level2_Id = @Reason2Id AND Tree_Name_Id = @TreeId)
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Reason 2 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Cause2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason2Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END
	If  @Reason3Id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
						WHERE Level1_Id = @Reason1Id AND  Level2_Id = @Reason2Id AND  Level3_Id = @Reason3Id AND Tree_Name_Id = @TreeId)
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Reason 3 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Cause3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason3Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END
	If  @Reason4Id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
						WHERE Level1_Id = @Reason1Id AND  Level2_Id = @Reason2Id AND  Level3_Id = @Reason3Id AND  Level4_Id = @Reason4Id AND Tree_Name_Id = @TreeId)
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Reason 4 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Cause4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason4Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END

	SELECT @ActionTreeId = Action_Tree_Id FROM Prod_Events WHERE PU_Id = @LocationId  AND Event_Type = 2

	IF  @Action1Id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Action1Id AND Tree_Name_Id = @ActionTreeId)
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Action 1 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Action1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action1Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END
	IF  @Action2Id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
						WHERE Level1_Id = @Action1Id AND  Level2_Id = @Action2Id AND Tree_Name_Id = @ActionTreeId)
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Action 2 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Action2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action2Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END
	IF  @Action3Id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
						WHERE Level1_Id = @Action1Id AND  Level2_Id = @Action2Id AND  Level3_Id = @Action3Id AND Tree_Name_Id = @ActionTreeId)
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Action 3 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Action3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action3Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END
	IF  @Action4Id IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
						WHERE Level1_Id = @Action1Id AND  Level2_Id = @Action2Id AND  Level3_Id = @Action3Id AND  Level4_Id = @Action4Id AND Tree_Name_Id = @ActionTreeId)
		BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null,Code = 'InvalidData', Error = 'Invalid - Action 4 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Action4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action4Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
	END
	SELECT @StartTime = --dbo.fnServer_CmnConvertToDBTime(@StartTime,'UTC')
	@StartTime at time zone 'UTC' at time zone @dbzone
	SELECT @EndTime = --dbo.fnServer_CmnConvertToDBTime(@EndTime,'UTC')
	@EndTime at time zone 'UTC' at time zone @dbzone
IF (@RuleToCheck <> 2)
	IF Exists (SELECT 1 FROM Timed_event_Details
					WHERE PU_Id = @MasterUnit
							AND (@StartTime < End_Time  OR End_Time IS NULL)
							AND  (@EndTime > Start_Time OR @EndTime IS NULL))
	BEGIN
		SELECT TOP 1 @ExistingStartTime = Start_Time,
			@ExistingEndTime = End_Time
		FROM Timed_event_Details
		WHERE PU_Id = @MasterUnit
			AND (@StartTime < End_Time  OR End_Time IS NULL)
			AND  (@EndTime > Start_Time OR @EndTime IS NULL)

		SELECT @StartTime = dbo.fnServer_CmnConvertFromDBTime(@StartTime,'UTC')
		SELECT @EndTime = dbo.fnServer_CmnConvertFromDBTime(@EndTime,'UTC')
		SELECT @ExistingStartTime = dbo.fnServer_CmnConvertFromDBTime(@ExistingStartTime,'UTC')
		SELECT @ExistingEndTime = dbo.fnServer_CmnConvertFromDBTime(@ExistingEndTime,'UTC')
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null,Code = 'DowntimeRecordConflict', Error = 'Invalid - Attempt to merge', ErrorType = '', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = 'ExistingStartTime', PropertyName4 = 'ExistingEndTime', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = @ExistingStartTime, PropertyValue4 = @ExistingEndTime, RecordChanged=0
		RETURN
	END

	IF @AddCommentId IS NULL AND EXISTS (SELECT 1 FROM event_reasons
										WHERE Event_Reason_Id IN (@Reason1Id,@Reason2Id,@Reason3Id,@Reason4Id, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
												AND Comment_Required = 1)
	BEGIN
	INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null,Code = 'InvalidData', Error = 'Invalid - Comment Is Required', ErrorType = 'MissingRequiredData', PropertyName1 = 'Comment', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
		RETURN
	END
	IF @AddCommentId IS NOT NULL AND NOT EXISTS (SELECT * FROM Comments WHERE Comment_Id = @AddCommentId)
	BEGIN
	INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT null, Code = 'InvalidData', Error = 'Invalid - Comment Not Found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'CommentThreadId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @AddCommentId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
		RETURN
	END
	SET  @CurrentCommentId =@AddCommentId
	SET @RecordChanged = 1
END


/************************************  UPDATE  *******************************/
IF @TransactionType = 2
BEGIN
	IF NOT EXISTS(SELECT 1 FROM Timed_Event_Details WHERE TEDET_Id = @TEDetId)
		BEGIN
			INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
				SELECT null,Code = 'ResourceNotFound', Error = 'Record not found', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
				RETURN
		END
	SELECT   @CurrentStart = a.Start_time
			,@CurrentEnd = a.End_Time
			,@CurrentMaster = a.PU_Id
			,@CurrentCommentId = a.Cause_Comment_Id
			,@CurrentReason1Id	= a.Reason_Level1
			,@CurrentReason2Id	= a.Reason_Level2
			,@CurrentReason3Id	= a.Reason_Level3
			,@CurrentReason4Id	= a.Reason_Level4
			,@CurrentFaultId    = a.TEFault_Id
			,@CurrentLocationId	= a.Source_PU_Id
			,@CurrStatus = a.TEStatus_Id
			,@CurrAction1 = a.Action_Level1
			,@CurrAction2 = a.Action_Level2
			,@CurrAction3 = a.Action_Level3
			,@CurrAction4 = a.Action_Level4
			,@CurrActionComment = a.Action_Comment_Id
			,@CurrResearchComment	= a.Research_Comment_Id
			,@CurrResearchStatus	= a.Research_Status_Id
			,@CurrResearchUser		= a.Research_User_Id
			,@CurrResearchOpen = a.Research_Open_Date
			,@CurrResearchClose = a.Research_Close_Date
			,@CurrSignatureId = a.Signature_Id
		 FROM Timed_Event_Details a
		 WHERE TEDET_Id = @TEDetId
	SELECT @StartTime = @StartTime at time zone 'UTC' at time zone @dbzone 
	--dbo.fnServer_CmnConvertToDbTime(@StartTime,'UTC')
	SELECT @EndTime = @EndTime at time zone 'UTC' at time zone @dbzone 
	--dbo.fnServer_CmnConvertToDbTime(@EndTime,'UTC')

	IF @CurrentMaster != @MasterUnit
		BEGIN
			INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
				SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to change Unit', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
				RETURN
		END
	/********************* Validate Data (Security) ******************************/
	IF @CurrentCommentId IS NULL AND @AddCommentId IS NULL AND EXISTS (SELECT 1 FROM event_reasons
											WHERE Event_Reason_Id IN (@Reason1Id,@Reason2Id,@Reason3Id,@Reason4Id, @Action1Id, @Action2Id, @Action3Id, @Action4Id)
												 AND Comment_Required = 1)
		BEGIN
			INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
				SELECT null,Code = 'InvalidData', Error = 'Invalid - Comment Is Required', ErrorType = 'MissingRequiredData', PropertyName1 = 'Comment', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
				RETURN
		END
	IF @AddCommentId IS NOT NULL AND NOT EXISTS (SELECT * FROM Comments WHERE Comment_Id = @AddCommentId)
		BEGIN
			INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
				SELECT null, Code = 'InvalidData', Error = 'Invalid - Comment Not Found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'CommentThreadId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @AddCommentId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
				RETURN
		END

	IF  @StartTime <> @CurrentStart OR
	    (@EndTime IS NULL AND @CurrentEnd IS NOT NULL) OR (@EndTime IS NOT NULL AND @CurrentEnd IS NULL) OR (@EndTime IS NOT NULL AND @CurrentEnd <> @EndTime)
	BEGIN
		SET @RecordChanged = 1
		SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@MasterUnit,273,397,3,@UsersSecurity) /* Modify Times */
		IF @ActualSecurity = 0
			BEGIN
				IF  @StartTime <> @CurrentStart
					BEGIN
						INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
							SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Start Time', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
							RETURN
					END
				IF  (@EndTime IS NULL AND @CurrentEnd IS NOT NULL) OR (@EndTime IS NOT NULL AND @CurrentEnd IS NULL) OR (@EndTime IS NOT NULL AND @CurrentEnd <> @EndTime)
					BEGIN
						INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
							SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change End Time', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
							RETURN
					END
			END
		ELSE
			BEGIN
				/* Valid Time Checks */
				IF @StartTime >= @EndTime
				BEGIN
					SELECT @StartTime = dbo.fnServer_CmnConvertFromDBTime(@StartTime,'UTC')
					SELECT @EndTime = dbo.fnServer_CmnConvertFromDBTime(@EndTime,'UTC')
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
					SELECT null,Code = 'InvalidData', Error = 'Invalid - StartTime Must be Less than EndTime', ErrorType = 'StartTimeNotBeforeEndTime', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
					RETURN
				END
				IF (@RuleToCheck <> 2)
					IF EXISTS (SELECT 1 FROM Timed_event_Details WHERE PU_Id = @MasterUnit AND TEDET_Id != @TEDetId
									AND @StartTime < End_Time AND  (@EndTime > Start_Time OR @EndTime IS NULL))
						BEGIN
							SELECT TOP 1 @ExistingStartTime = Start_Time, @ExistingEndTime = End_Time
								FROM Timed_event_Details
								WHERE PU_Id = @MasterUnit
								AND TEDET_Id != @TEDetId
								AND @StartTime < End_Time
								AND (@EndTime > Start_Time OR @EndTime IS NULL)

							SELECT @StartTime = dbo.fnServer_CmnConvertFromDBTime(@StartTime,'UTC')
							SELECT @EndTime = dbo.fnServer_CmnConvertFromDBTime(@EndTime,'UTC')
							SELECT @ExistingStartTime = dbo.fnServer_CmnConvertFromDBTime(@ExistingStartTime,'UTC')
							SELECT @ExistingEndTime = dbo.fnServer_CmnConvertFromDBTime(@ExistingEndTime,'UTC')
							INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
							SELECT null,Code = 'DowntimeRecordConflict', Error = 'Invalid - Attempt to merge', ErrorType = '', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = 'ExistingStartTime', PropertyName4 = 'ExistingEndTime', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = @ExistingStartTime, PropertyValue4 = @ExistingEndTime, RecordChanged=0
							RETURN
						END
			END
	END

	IF  (@EndTime IS NOT NULL AND @CurrentEnd IS NULL) /* Close Security */
		BEGIN
			SET @RecordChanged = 1
			IF dbo.fnCMN_CheckSheetSecurity(@MasterUnit,130,397,3,@UsersSecurity) = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Close Record', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
						RETURN
				END
		END
	IF (@EndTime IS NULL AND @CurrentEnd IS NOT NULL) /* Open Security*/
	BEGIN
		SET @RecordChanged = 1
		IF  dbo.fnCMN_CheckSheetSecurity(@MasterUnit,129,397,3,@UsersSecurity) = 0
			BEGIN
				INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
					SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Open Record', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
					RETURN
			END
		IF (@RuleToCheck <> 2)
			IF EXISTS (SELECT 1 FROM Timed_event_Details WHERE PU_Id = @MasterUnit AND TEDET_Id != @TEDetId
							AND  Start_Time > @StartTime)
				BEGIN
					SELECT TOP 1 @ExistingStartTime = Start_Time, @ExistingEndTime = End_Time
						FROM Timed_event_Details
						WHERE PU_Id = @MasterUnit
						 AND TEDET_Id != @TEDetId
						 AND Start_Time > @StartTime

					SELECT @StartTime = dbo.fnServer_CmnConvertFromDBTime(@StartTime,'UTC')
					SELECT @EndTime = dbo.fnServer_CmnConvertFromDBTime(@EndTime,'UTC')
					SELECT @ExistingStartTime = dbo.fnServer_CmnConvertFromDBTime(@ExistingStartTime,'UTC')
					SELECT @ExistingEndTime = dbo.fnServer_CmnConvertFromDBTime(@ExistingEndTime,'UTC')
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
					SELECT null,Code = 'DowntimeRecordConflict', Error = 'Invalid - Attempt to merge - Open Downtime', ErrorType = '', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = 'ExistingStartTime', PropertyName4 = 'ExistingEndTime', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = @ExistingStartTime, PropertyValue4 = @ExistingEndTime, RecordChanged=0
					RETURN
				END
	END
	IF (@LocationId IS NULL AND @CurrentLocationId IS NOT NULL) OR (@LocationId IS NOT NULL AND @CurrentLocationId  != @LocationId) OR (@LocationId IS NOT NULL AND @CurrentLocationId IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF  dbo.fnCMN_CheckSheetSecurity(@MasterUnit,null,401,2,@UsersSecurity) = 0
			BEGIN
			INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
				SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Location', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
				RETURN
			END
		END
	IF (@FaultId IS NULL AND @CurrentFaultId IS NOT NULL) OR (@FaultId IS NOT NULL AND @CurrentFaultId  != @FaultId) OR (@FaultId IS NOT NULL AND @CurrentFaultId IS NULL)
	BEGIN
		SET @RecordChanged = 1
		IF  dbo.fnCMN_CheckSheetSecurity(@MasterUnit,null,400,2,@UsersSecurity) = 0
			BEGIN
				INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
					SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Fault', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
					RETURN
			END
		ELSE
			BEGIN
				IF @FaultId IS NOT NULL
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM Timed_Event_Fault  WHERE TEFault_Id = @FaultId AND PU_id = @MasterUnit AND (Source_PU_Id = @LocationId OR @LocationId = @MasterUnit))
							BEGIN
								INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
									SELECT null,Code = 'InvalidData', Error = 'Invalid - Fault Not Found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'FaultId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @FaultId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
									RETURN
							END
					END
			END
	END

    DECLARE @AssignActionsPermission INT = 0
    SELECT @AssignActionsPermission = dbo.fnCMN_CheckSheetSecurity(@MasterUnit,null,389,2,@UsersSecurity) /* Actions */

	/*
	 Initially AssignReasonsPermission will be same as AssignActionsPermission BUT it might change based on combination of fault and reasons
	 That's why a new variable has been used here
	 */
    DECLARE @AssignReasonsPermission INT = 0
    SELECT @AssignReasonsPermission = @AssignActionsPermission--dbo.fnCMN_CheckSheetSecurity(@MasterUnit,null,389,2,@UsersSecurity) /* Reasons */

	SELECT @TreeId = Name_Id FROM Prod_Events WHERE PU_Id = @LocationId  AND Event_Type = 2
	/*
	 Check here, if there is fault change and default reasons are populated for the fault, If so then set the AssignReasons permission to fault permission, [ even if the user is not having assign permission, he should be allowed to change to default fault reasons if the fault permission is there
	 Because here we are changing reasons based on the fault only,
	 */
	if(@FaultId IS NOT NULL AND @FaultId <> @CurrentFaultId )
	    BEGIN
	        DECLARE @DefaultReason1Id INT, @DefaultReason2Id INT, @DefaultReason3Id INT, @DefaultReason4Id INT

	        SELECT @DefaultReason1Id = Reason_Level1 ,@DefaultReason2Id = Reason_Level2 ,@DefaultReason3Id = Reason_Level3 ,@DefaultReason4Id = Reason_Level4
             from Timed_Event_Fault tef
            WHERE tef.TEFault_Id = @FaultId

	        /* Now Check if these default reasons are same as the requested update in the reasons
	           If they are same at all level, then set the assignReasons security to change fault security
	         */
	        IF(ISNULL(@Reason1Id,0) = ISNULL(@DefaultReason1Id,0) AND  ISNULL(@Reason2Id,0) = ISNULL(@DefaultReason2Id,0) AND ISNULL(@Reason3Id,0) = ISNULL(@DefaultReason3Id,0) AND ISNULL(@Reason4Id,0) = ISNULL(@DefaultReason4Id,0))
	            BEGIN
                    DECLARE @ChangeFaultPermission INT = 0
                    SELECT @ChangeFaultPermission =  dbo.fnCMN_CheckSheetSecurity(@MasterUnit,null,400,2,@UsersSecurity);
                    if(@ChangeFaultPermission > @AssignReasonsPermission)
                        BEGIN
                            SELECT @AssignReasonsPermission = @ChangeFaultPermission;
                        END
                end
        end

	IF  (@Reason1Id IS NULL AND @CurrentReason1Id IS NOT NULL) OR (@Reason1Id IS NOT NULL AND @CurrentReason1Id  != @Reason1Id) OR (@Reason1Id IS NOT NULL AND @CurrentReason1Id IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF @AssignReasonsPermission = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Reason Level 1', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
						RETURN
				END
			ELSE
				BEGIN
					IF  @Reason1Id IS NOT NULL
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Reason1Id AND Tree_Name_Id = @TreeId)
								BEGIN
									INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										SELECT null,Code = 'InvalidData', Error = 'Invalid - Reason 1 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Cause1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason1Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
										RETURN
								END
						END
				END
		END
	IF  (@Reason2Id IS NULL AND @CurrentReason2Id IS NOT NULL) OR (@Reason2Id IS NOT NULL AND @CurrentReason2Id  != @Reason2Id) OR (@Reason2Id IS NOT NULL AND @CurrentReason2Id IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF @AssignReasonsPermission = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Reason Level 2', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
						RETURN
				END
			ELSE
				BEGIN
					IF  @Reason2Id IS NOT NULL
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
											WHERE Level1_Id = @Reason1Id AND  Level2_Id = @Reason2Id AND Tree_Name_Id = @TreeId)
								BEGIN
									INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										SELECT null,Code = 'InvalidData', Error = 'Invalid - Reason 2 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Cause2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason2Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
										RETURN
								END
						END
				END
		END
	IF  (@Reason3Id IS NULL AND @CurrentReason3Id IS NOT NULL) OR (@Reason3Id IS NOT NULL AND @CurrentReason3Id  != @Reason3Id) OR (@Reason3Id IS NOT NULL AND @CurrentReason3Id IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF @AssignReasonsPermission = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Reason Level 3', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
						RETURN
				END
			ELSE
				BEGIN
					IF  @Reason3Id IS NOT NULL
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
											WHERE Level1_Id = @Reason1Id AND  Level2_Id = @Reason2Id AND  Level3_Id = @Reason3Id AND Tree_Name_Id = @TreeId)
								BEGIN
									INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										SELECT null,Code = 'InvalidData', Error = 'Invalid - Reason 3 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Cause3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason3Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
										RETURN
								END
						END
				END
		END
	IF  (@Reason4Id IS NULL AND @CurrentReason4Id IS NOT NULL) OR (@Reason4Id IS NOT NULL AND @CurrentReason4Id  != @Reason4Id) OR (@Reason4Id IS NOT NULL AND @CurrentReason4Id IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF @AssignReasonsPermission = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Reason Level 4', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
						RETURN
				END
			ELSE
				BEGIN
					IF  @Reason4Id IS NOT NULL
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
											WHERE Level1_Id = @Reason1Id AND  Level2_Id = @Reason2Id AND  Level3_Id = @Reason3Id AND  Level4_Id = @Reason4Id AND Tree_Name_Id = @TreeId)
								BEGIN
									INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										SELECT null,Code = 'InvalidData', Error = 'Invalid - Reason 4 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Cause4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason4Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
										RETURN
								END
						END
				END
		END
	SELECT @ActionTreeId = Action_Tree_Id FROM Prod_Events WHERE PU_Id = @LocationId  AND Event_Type = 2
	IF  (@Action1Id IS NULL AND @CurrAction1 IS NOT NULL) OR (@Action1Id IS NOT NULL AND @CurrAction1  != @Action1Id) OR (@Action1Id IS NOT NULL AND @CurrAction1 IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF @AssignActionsPermission = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Action Level 1', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
						RETURN
				END
			ELSE
				BEGIN
					IF  @Action1Id IS NOT NULL
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Action1Id AND Tree_Name_Id = @ActionTreeId)
								BEGIN
									INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										SELECT null,Code = 'InvalidData', Error = 'Invalid - Action 1 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Action1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action1Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
										RETURN
								END
						END
				END
		END
	IF  (@Action2Id IS NULL AND @CurrAction2 IS NOT NULL) OR (@Action2Id IS NOT NULL AND @CurrAction2  != @Action2Id) OR (@Action2Id IS NOT NULL AND @CurrAction2 IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF @AssignActionsPermission = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Action Level 2', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
						RETURN
				END
			ELSE
				BEGIN
					IF  @Action2Id IS NOT NULL
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
											WHERE Level1_Id = @Action1Id AND  Level2_Id = @Action2Id AND Tree_Name_Id = @ActionTreeId)
								BEGIN
									INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										SELECT null,Code = 'InvalidData', Error = 'Invalid - Action 2 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Action2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action2Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
										RETURN
								END
						END
				END
		END
	IF  (@Action3Id IS NULL AND @CurrAction3 IS NOT NULL) OR (@Action3Id IS NOT NULL AND @CurrAction3  != @Action3Id) OR (@Action3Id IS NOT NULL AND @CurrAction3 IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF @AssignActionsPermission = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Action Level 3', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
						RETURN
				END
			ELSE
				BEGIN
					IF  @Action3Id IS NOT NULL
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
											WHERE Level1_Id = @Action1Id AND  Level2_Id = @Action2Id AND  Level3_Id = @Action3Id AND Tree_Name_Id = @ActionTreeId)
								BEGIN
									INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										SELECT null,Code = 'InvalidData', Error = 'Invalid - Action 3 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Action3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action3Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
										RETURN
								END
						END
				END
		END
	IF  (@Action4Id IS NULL AND @CurrAction4 IS NOT NULL) OR (@Action4Id IS NOT NULL AND @CurrAction4  != @Action4Id) OR (@Action4Id IS NOT NULL AND @CurrAction4 IS NULL)
		BEGIN
			SET @RecordChanged = 1
			IF @AssignActionsPermission = 0
				BEGIN
					INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
						SELECT null,Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Change Action Level 4', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
						RETURN
				END
			ELSE
				BEGIN
					IF  @Action4Id IS NOT NULL
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
											WHERE Level1_Id = @Action1Id AND  Level2_Id = @Action2Id AND  Level3_Id = @Action3Id AND  Level4_Id = @Action4Id AND Tree_Name_Id = @ActionTreeId)
								BEGIN
									INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
										SELECT null,Code = 'InvalidData', Error = 'Invalid - Action 4 Not Found On Location', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Action4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Action4Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged = 0
										RETURN
								END
						END
				END
		END
END
-- To delete down time
IF @TransactionType = 3
	BEGIN

	 SELECT   @CurrentStart = a.Start_time
				,@CurrentEnd = a.End_Time
				,@CurrentMaster = a.PU_Id
				,@CurrentCommentId = a.Cause_Comment_Id
				,@CurrentReason1Id     = a.Reason_Level1
				,@CurrentReason2Id     = a.Reason_Level2
				,@CurrentReason3Id     = a.Reason_Level3
				,@CurrentReason4Id     = a.Reason_Level4
				,@CurrentFaultId    = a.TEFault_Id
				,@CurrentLocationId      = a.Source_PU_Id
				,@CurrStatus = a.TEStatus_Id
				,@CurrAction1 = a.Action_Level1
				,@CurrAction2 = a.Action_Level2
				,@CurrAction3 = a.Action_Level3
				,@CurrAction4 = a.Action_Level4
				,@CurrActionComment = a.Action_Comment_Id
				,@CurrResearchComment           = a.Research_Comment_Id
				,@CurrResearchStatus  = a.Research_Status_Id
				,@CurrResearchUser                      = a.Research_User_Id
				,@CurrResearchOpen = a.Research_Open_Date
				,@CurrResearchClose = a.Research_Close_Date
				,@CurrSignatureId = a.Signature_Id
				FROM Timed_Event_Details a with (nolock)
				WHERE TEDET_Id = @TEDetId


		IF @CurrentStart IS NULL
			BEGIN
				INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
				SELECT null, Code = 'ResourceNotFound', Error = 'Record not found', ErrorType = '', PropertyName1 = 'DowntimeId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @TEDetId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
				RETURN
		END

		IF @CurrentStart IS NOT NULL AND @CurrentEnd IS NULL
		  BEGIN
			INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
			SELECT null, Code = 'InvalidData', Error = 'Invalid - cannot delete open record', ErrorType = 'OpenRecord', PropertyName1 = 'DowntimeId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @TEDetId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
			RETURN
		END
		SELECT @StartTime = @CurrentStart
		SELECT @EndTime = @CurrentEnd

		SET @RecordChanged = 1
		IF  dbo.fnCMN_CheckSheetSecurity(@MasterUnit,7,392,3,@UsersSecurity) = 0
			BEGIN
				INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
					SELECT null, Code = 'InsufficientPermission', Error = 'Invalid - Attempt to Delete Down Time', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = '', RecordChanged=0
					RETURN
			END
	END

IF @RecordChanged = 1
	BEGIN
		INSERT INTO @outputtable (TedDetId ,Code, Error, ErrorType,PropertyName1,PropertyName2,PropertyName3,PropertyName4,PropertyValue1,PropertyValue2,PropertyValue3,PropertyValue4, RecordChanged)
		SELECT @TEDetId, 'Success',null,null,null,null,null,null,null,null,null,null, 1
		RETURN
	END

RETURN
END




