
CREATE PROCEDURE dbo.spMES_ModifyNonProductiveTime
		@TransactionType Int
		,@NptId  		Int  = Null
		,@StartTime		DateTime
		,@EndTime		DateTime
		,@LocationId	Int
		,@Reason1Id		Int = Null
		,@Reason2Id		Int = Null
		,@Reason3Id		Int = Null
		,@Reason4Id		Int = Null
		,@RuleToCheck	Int = Null
		,@UserId		Int
		,@AddCommentId		Int	
		
AS

/* 
Times In and Out are in UTC
@TransactionType
	1 - Add
	2 - Update -- ONLY EndTime For Now
	3 - Delete
	4 - 

*/



DECLARE	@MinStart	DateTime
		,@MinStart2  DateTime
		,@MaxEnd	DateTime
		,@CurrentEnd	DateTime
		,@CurrentStart DateTime
		,@UsersSecurity  Int
		,@ActualSecurity Int
		,@CurrentCommentId	Int
		,@TreeId		Int
		,@LineId		Int
		,@RecordChanged Int = 0
		,@ExistingStartTime		Datetime
		,@ExistingEndTime		Datetime
        ,@CurrentReason1Id INT
        ,@CurrentReason2Id INT
        ,@CurrentReason3Id INT
        ,@CurrentReason4Id INT

DECLARE @AvailableUnits TABLE  (PU_Id Int)

INSERT INTO @AvailableUnits SELECT Distinct PU_Id FROM dbo.fnMES_GetNonProductiveTimeAvailableUnits(@UserId)
IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @LocationId)
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Unit not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Unit', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
SELECT @LineId = PL_Id FROM Prod_Units_Base WHERE PU_Id = @LocationId 
IF NOT EXISTS (SELECT 1 FROM User_Security WHERE User_Id = @UserId  and Group_Id = 1 and Access_Level = 4)
BEGIN
	IF EXISTS(SELECT 1 FROM Sheets s
			Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
			WHERE  Sheet_Type  = 27	AND (s.PL_Id = @LineId OR su.PU_Id = @LocationId) AND Group_Id Is Null)
	BEGIN
		Select @UsersSecurity = 3
	END	
	ELSE
	BEGIN
		Select @UsersSecurity = Max(u.Access_Level) 
				from Sheets s
				Join User_Security u on u.Group_Id = s.Group_Id and u.User_Id = @UserId 
				Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
				WHERE  Sheet_Type  = 27  and (s.PL_Id  = @LineId  OR su.PU_Id = @LocationId)
		SELECT @UsersSecurity = Coalesce(@UsersSecurity,0)
	END
END
ELSE
BEGIN
	SELECT @UsersSecurity = 4
END
/*
 This security check is inconsistent with thick client, In thick client if the user has access to the npt sheet, he is allowed
 to add npt, irrespective of access level, This check should be only null check, if UsersSecurity is null then insufficient permission
 */
IF NOT (@UsersSecurity > 1)
	BEGIN
		SELECT Code = 'InsufficientPermission', ERROR = 'Invalid attempt to Create/Update NPT', ErrorType = '', PropertyName1 = 'UserSecurity', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @UsersSecurity, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END


/******************************************** RULE CHECKS ********************************/
IF @TransactionType = 1  -- ADD  Only at End   May need to look at Sheet max edit?
BEGIN
	IF @RuleToCheck = 1  -- MinStart, MaxEnd
	BEGIN
		SELECT @MinStart = Max(End_Time) FROM NonProductive_Detail WHERE PU_Id = @LocationId
		IF @MinStart Is Null 
		BEGIN
			SELECT @MinStart = DateAdd(Month,-1,GETUTCDATE())
		END
		ELSE
		BEGIN
			SELECT @MinStart = dbo.fnServer_CmnConvertFromDbTime(@MinStart,'UTC')
		END
		SELECT @MaxEnd = GetUTCDate()
		SELECT @MaxEnd = DateAdd(Millisecond,-Datepart(Millisecond,@MaxEnd),@MaxEnd)
		SELECT StartTime = @StartTime,EndTime = @EndTime
		RETURN
	END
END
IF @TransactionType = 2 
BEGIN
	IF @RuleToCheck = 1  -- MinStart, MaxEnd ... Rules????
	BEGIN
		BEGIN
			SELECT @CurrentEnd = End_Time,@CurrentStart = Start_Time FROM NonProductive_Detail WHERE NPDet_Id = @NptId

			SELECT @MinStart = Max(End_Time) FROM NonProductive_Detail WHERE PU_Id = @LocationId And End_Time <= @CurrentStart
			IF @MinStart Is Null SELECT @MinStart = DateAdd(day,-7,@CurrentStart)
			SELECT @MaxEnd = Min(Start_Time) FROM NonProductive_Detail WHERE PU_Id = @LocationId And Start_Time >= @CurrentEnd
			IF @MaxEnd Is Null
			BEGIN
				SELECT @MaxEnd = dbo.fnServer_CmnConvertToDbTime(GetUTCDate(),'UTC')
				SELECT @MaxEnd = DateAdd(Millisecond,-Datepart(Millisecond,@MaxEnd),@MaxEnd)
			END
		END
		SELECT @StartTime = dbo.fnServer_CmnConvertFromDBTime(@MinStart,'UTC')
		SELECT @EndTime = dbo.fnServer_CmnConvertFromDBTime(@MaxEnd,'UTC')
		SELECT StartTime = @StartTime,EndTime = @EndTime
		RETURN
	END
END

IF @TransactionType in (1,2)
BEGIN
	---No Millisecond Support
	SELECT @StartTime = DateAdd(Millisecond,-Datepart(Millisecond,@StartTime),@StartTime)
	SELECT @EndTime = DateAdd(Millisecond,-Datepart(Millisecond,@EndTime),@EndTime)
END
Select @TreeId = Non_Productive_Reason_Tree From Prod_Units_Base where PU_Id = @LocationId
/************************************  ADD  ************************/
IF @TransactionType = 1  -- ADD
BEGIN
		IF @LocationId IS NULL
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Unit not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Unit', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
	IF @StartTime IS NULL
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Start time not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'StartTime', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
	IF @EndTime IS NULL
	BEGIN
		SELECT Code = 'InvalidData', Error = 'End time not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'EndTime', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
	IF @StartTime >= @EndTime 
	BEGIN
        SELECT Code = 'InvalidData', ERROR = 'Invalid - StartTime Must be Less than EndTime', ErrorType = 'StartTimeNotBeforeEndTime', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = '', PropertyValue4 = '' 
		RETURN
	END
	IF Not Exists(SELECT 1 FROM @AvailableUnits WHERE PU_ID = @LocationId)
	BEGIN
		SELECT Code = 'InsufficientPermission', ERROR = 'Invalid add attempt', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
	IF Exists (Select 1 FROM NonProductive_Detail WHERE PU_Id = @LocationId    
					AND @StartTime < End_Time AND  @EndTime > Start_Time) 
	BEGIN
		SELECT Code = 'NPTRecordConflict', ERROR = 'Invalid - Attempt to merge', ErrorType = '', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	If  @Reason1Id is not null
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Reason1Id And Tree_Name_Id = @TreeId)
		BEGIN
			SELECT Code = 'InvalidData', ERROR = 'Invalid - Reason 1 Not Found On Reason Tree', ErrorType = 'MissingRequiredData', PropertyName1 = 'Reason1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN			
		END
	END
	If  @Reason2Id is not null
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
						WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And Tree_Name_Id = @TreeId)
		BEGIN
			SELECT Code = 'InvalidData', ERROR = 'Invalid - Reason 2 Not Found On Reason Tree', ErrorType = 'MissingRequiredData', PropertyName1 = 'Reason2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN			
		END
	END
	If  @Reason3Id is not null
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
						WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And  Level3_Id = @Reason3Id And Tree_Name_Id = @TreeId)
		BEGIN
			SELECT Code = 'InvalidData', ERROR = 'Invalid - Reason 3 Not Found On Reason Tree', ErrorType = 'MissingRequiredData', PropertyName1 = 'Reason3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN			
		END
	END
	If  @Reason4Id is not null
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
						WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And  Level3_Id = @Reason3Id And  Level4_Id = @Reason4Id And Tree_Name_Id = @TreeId)
		BEGIN
			SELECT Code = 'InvalidData', ERROR = 'Invalid - Reason 4 Not Found On Reason Tree', ErrorType = 'MissingRequiredData', PropertyName1 = 'Reason4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN			
		END
	END
	IF @AddCommentId IS NULL AND EXISTS (SELECT 1 FROM event_reasons 
										WHERE Event_Reason_Id IN (@Reason1Id,@Reason2Id,@Reason3Id,@Reason4Id)
												AND Comment_Required = 1)
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Invalid - Comment Is Required', ErrorType = 'MissingRequiredData', PropertyName1 = 'Comment', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN	
	END
	SET  @CurrentCommentId =@AddCommentId
	SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,'UTC')
	SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,'UTC') 
	IF Exists (Select 1 FROM NonProductive_Detail 
					WHERE PU_Id = @LocationId 
							AND (@StartTime < End_Time  or End_Time Is Null)
							AND  (@EndTime > Start_Time or @EndTime Is Null))
	BEGIN
		SELECT TOP 1 @ExistingStartTime = Start_Time,
			@ExistingEndTime = End_Time
		FROM Timed_event_Details 
		WHERE PU_Id = @LocationId 
			AND (@StartTime < End_Time  or End_Time Is Null)
			AND  (@EndTime > Start_Time or @EndTime Is Null)

		SELECT @StartTime = dbo.fnServer_CmnConvertFromDBTime(@StartTime,'UTC')
		SELECT @EndTime = dbo.fnServer_CmnConvertFromDBTime(@EndTime,'UTC')
		SELECT @ExistingStartTime = dbo.fnServer_CmnConvertFromDBTime(@ExistingStartTime,'UTC')
		SELECT @ExistingEndTime = dbo.fnServer_CmnConvertFromDBTime(@ExistingEndTime,'UTC')
		SELECT Code = 'NPTRecordConflict', Error = 'Invalid - Attempt to merge', ErrorType = '', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = 'ExistingStartTime', PropertyName4 = 'ExistingEndTime', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = @ExistingStartTime, PropertyValue4 = @ExistingEndTime
		RETURN
	END
	SET @RecordChanged = 1
END


/************************************  UPDATE  ENDTIME AND NPT REASONS *******************************/
IF @TransactionType = 2 
BEGIN
	IF NOT EXISTS(SELECT 1 FROM NonProductive_Detail  WHERE NPDet_Id = @NptId)
	BEGIN
		SELECT ERROR = 'Record not found'
		RETURN	
	END
	SELECT   @StartTime = a.Start_time
			,@CurrentEnd = a.End_Time
			,@CurrentCommentId = a.Comment_Id
			,@CurrentReason1Id	= a.Reason_Level1
			,@CurrentReason2Id	= a.Reason_Level2
			,@CurrentReason3Id	= a.Reason_Level3
			,@CurrentReason4Id	= a.Reason_Level4
			,@LocationId = a.PU_Id
		 FROM NonProductive_Detail a
		 WHERE NPDet_Id = @NptId
	SELECT @EndTime = dbo.fnServer_CmnConvertToDbTime(@EndTime,'UTC')
	/********************* Validate Data ******************************/
	IF   @CurrentEnd <> @EndTime
	BEGIN
		SET @RecordChanged = 1
		/* Valid Time Checks */
		IF Exists (Select 1 FROM NonProductive_Detail WHERE PU_Id = @LocationId  And NPDet_Id != @NptId  
						AND @StartTime < End_Time AND  @EndTime > Start_Time) 
		BEGIN
			SELECT Code = 'NPTRecordConflict', ERROR = 'Invalid - Attempt to merge', ErrorType = '', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END
		IF @StartTime >= @EndTime 
		BEGIN
			SELECT Code = 'InvalidData', ERROR = 'Invalid - StartTime Must be Less than EndTime', ErrorType = 'StartTimeNotBeforeEndTime', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @StartTime, PropertyValue2 = @EndTime, PropertyValue3 = '', PropertyValue4 = '' 
			RETURN
		END
	END
	  IF(ISNULL(@CurrentReason1Id,0) <> ISNULL(@Reason1Id,0) OR ISNULL(@CurrentReason2Id,0) <> ISNULL(@Reason2Id,0) OR ISNULL(@CurrentReason3Id,0) <> ISNULL(@Reason3Id,0) OR ISNULL(@CurrentReason4Id,0) <> ISNULL(@Reason4Id,0))
        BEGIN
            SET @RecordChanged = 1
            If  @Reason1Id is not null
                BEGIN
                    IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Reason1Id And Tree_Name_Id = @TreeId)
                        BEGIN
                            SELECT Code = 'InvalidData', ERROR = 'Invalid - Reason 1 Not Found On Reason Tree', ErrorType = 'MissingRequiredData', PropertyName1 = 'Reason1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                            RETURN
                        END
                END
            If  @Reason2Id is not null
                BEGIN
                    IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
                                  WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And Tree_Name_Id = @TreeId)
                        BEGIN
                            SELECT Code = 'InvalidData', ERROR = 'Invalid - Reason 2 Not Found On Reason Tree', ErrorType = 'MissingRequiredData', PropertyName1 = 'Reason2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                            RETURN
                        END
                END
            If  @Reason3Id is not null
                BEGIN
                    IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
                                  WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And  Level3_Id = @Reason3Id And Tree_Name_Id = @TreeId)
                        BEGIN
                            SELECT Code = 'InvalidData', ERROR = 'Invalid - Reason 3 Not Found On Reason Tree', ErrorType = 'MissingRequiredData', PropertyName1 = 'Reason3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                            RETURN
                        END
                END
            If  @Reason4Id is not null
                BEGIN
                    IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data
                                  WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And  Level3_Id = @Reason3Id And  Level4_Id = @Reason4Id And Tree_Name_Id = @TreeId)
                        BEGIN
                            SELECT Code = 'InvalidData', ERROR = 'Invalid - Reason 4 Not Found On Reason Tree', ErrorType = 'MissingRequiredData', PropertyName1 = 'Reason4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                            RETURN
                        END
                END
            IF @AddCommentId IS NULL AND EXISTS (SELECT 1 FROM event_reasons
                                                 WHERE Event_Reason_Id IN (@Reason1Id,@Reason2Id,@Reason3Id,@Reason4Id)
                                                   AND Comment_Required = 1)
                BEGIN
                    SELECT Code = 'InvalidData', Error = 'Invalid - Comment Is Required', ErrorType = 'MissingRequiredData', PropertyName1 = 'Comment', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
                    RETURN
                END
            SET  @CurrentCommentId =@AddCommentId


        end
END

IF @RecordChanged = 1
BEGIN
	EXECUTE spServer_DBMgrUpdNonProductiveTime @NptId OUTPUT,@LocationId ,@StartTime,@EndTime,@Reason1Id
								,@Reason2Id,@Reason3Id,@Reason4Id,@TransactionType,2
								,@UserId,@CurrentCommentId,Null,Null,Null,2

END
EXECUTE  spMES_GetNonProductiveTime 1,Null,Null,null,Null,@UserId,@NptId


