CREATE PROCEDURE dbo.spDowntime_ModifyDowntime
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

AS

/*
Times In and Out are in UTC
@TransactionType
	1 - Add
	2 - Update
	3 - Delete
	4 -
*/
/*

select dbo.fnserver_cmnconvertfromdbtime('2017-03-23 15:12:01.000','UTC')
select top 10 TEDET_Id,Start_Time,End_Time,pu_id from timed_event_Details  order by  Start_Time desc

DECLARE @StartTime DateTime,@EndTime DateTime

EXECUTE spDowntime_ModifyDowntime 1,null,'2017-03-23 20:06:01.000' ,'2017-03-23 20:08:01.000' ,1,Null,Null,Null,Null,Null,null,1,null

EXECUTE spDowntime_ModifyDowntime 2,232811,@StartTime ,@EndTime ,Null,Null,Null,Null,Null,Null,1,1
EXECUTE spDowntime_ModifyDowntime 2,232771,@StartTime,@EndTime ,Null,Null,Null,Null,Null,Null,1,1

*/

DECLARE  @MasterUnit Int
		,@MinStart	DateTime
		,@MinStart2  DateTime
		,@MaxEnd	DateTime
		,@CurrentStart	DateTime
		,@CurrentEnd	DateTime
 		,@CurrentCommentId	Int
		,@CurrStatus			Int
		,@CurrActionComment		Int
		,@CurrResearchComment	Int
		,@CurrResearchStatus	Int
		,@CurrResearchUser		Int
		,@CurrResearchOpen		Datetime
		,@CurrResearchClose		Datetime
		,@CurrSignatureId	    Int
		,@RecordChanged Int = 0


SET @RuleToCheck = COALESCE(@RuleToCheck, 0)
SELECT @MasterUnit = Coalesce(Master_Unit,@LocationId) From Prod_Units_Base WHERE PU_Id = @LocationId

    -- Restricting add_security check for transactionType 1 (add)
IF (@TransactionType = 1 AND NOT EXISTS(Select 1 from dbo.fnDowntime_GetDowntimeSecurity( cast(@MasterUnit as nvarchar),NULL,@UserId) where AddSecurity = 1))
Begin
  SELECT Code = 'InsufficientPermission', ERROR = 'Fatal - User does not have downtime add permission, on any active configured sheets for the Unit', ErrorType = 'NoActiveSheetsFound', PropertyName1 = 'MasterUnit', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @MasterUnit, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
RETURN
End 

/**************In case of @RuleToCheck = 1 (Used to get the available edit times for a downtime record)***************/
IF @TransactionType IN (1,2) AND @RuleToCheck = 1
	BEGIN
		DECLARE  @DBDate datetime, @DaysBackOpenDowntimeEventCanBeAdded INT, @OpenDowntimeEventCanBeAddedDaysBack BIT
				,@UsersSecurity  Int, @ActualSecurity Int
		Select @DaysBackOpenDowntimeEventCanBeAdded = CONVERT(INT, COALESCE(Value, '0')) From Site_Parameters Where Parm_Id = 77
		Select @OpenDowntimeEventCanBeAddedDaysBack = CONVERT(BIT, COALESCE(Value, 0)) From Site_Parameters Where Parm_Id = 78
		Select @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel( @MasterUnit,@UserId,1)
		SET @DBDate = dbo.fnServer_CmnConvertToDbTime(GetUTCDate(),'UTC')

		IF @TransactionType = 1
			BEGIN
				SELECT @MinStart = MAX(End_Time) FROM Timed_Event_Details WHERE PU_Id = @MasterUnit
				IF @MinStart IS NULL
					BEGIN
						SELECT @MinStart = DATEADD(Month, -1, @DBDate)
					END
				SET @MaxEnd = NULL
			END
		ELSE -- transaction type = 2
			BEGIN
				SELECT @CurrentStart = Start_Time, @CurrentEnd = End_Time FROM Timed_Event_Details AS a WHERE TEDET_Id = @TEDetId
				SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@MasterUnit, 273, 423, 3, @UsersSecurity)
				IF @ActualSecurity = 0
					BEGIN
						SELECT @MinStart = @CurrentStart
						SELECT @MaxEnd = @CurrentEnd
					END
				ELSE
					BEGIN
						SELECT @MinStart = MAX(End_Time) FROM Timed_Event_Details WHERE PU_Id = @MasterUnit
                                                                                AND End_Time <= @CurrentStart
						IF @MinStart IS NULL
							BEGIN
								SELECT @MinStart = DATEADD(day, -7, @CurrentStart)
							END

						SELECT @MaxEnd = MIN(Start_Time) FROM Timed_Event_Details WHERE PU_Id = @MasterUnit
                                                                                AND Start_Time >= @CurrentEnd
						IF @MaxEnd IS NULL
							BEGIN
								SET @MaxEnd = @DBDate
							END
					END
			END
		SET @MinStart2 = @MinStart
        IF @OpenDowntimeEventCanBeAddedDaysBack = 1
            BEGIN
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

		SELECT MinStartTime = dbo.fnServer_CmnConvertFromDBTime(@MinStart, 'UTC'),
                       MaxEndTime = dbo.fnServer_CmnConvertFromDBTime(@MaxEnd, 'UTC'),
                       MinStartTimeForOpenDT = dbo.fnServer_CmnConvertFromDBTime(@MinStart2, 'UTC')
        RETURN

	END


/******* Validation Start ********/
DECLARE @Code nvarchar(100),@Error nvarchar(1000),@tedet_id int, @ErrorType nvarchar(max),
@PropertyName1 nvarchar(max), @PropertyName2 nvarchar(max), @PropertyName3 nvarchar(max), @PropertyName4 nvarchar(max),
@PropertyValue1 nvarchar(max),@PropertyValue2 nvarchar(max),@PropertyValue3 nvarchar(max),@PropertyValue4 nvarchar(max)

-- Pass the new values to fnDowntime_ModifyDowntime_Validations for validation
SELECT @tedet_id = TedDetId, @Code = code, @Error =error, @ErrorType = ErrorType,
	   @PropertyName1 = PropertyName1, @PropertyName2 = PropertyName2,
	   @PropertyName3 = PropertyName3, @PropertyName4 = PropertyName4,
	   @PropertyValue1 = PropertyValue1, @PropertyValue2 = PropertyValue2,
	   @PropertyValue3 = PropertyValue3, @PropertyValue4 = PropertyValue4,
	   @RecordChanged = RecordChanged
	   FROM  fnDowntime_ModifyDowntime_Validations(
		 @TransactionType, @TEDetId, @StartTime, @EndTime, @LocationId, @FaultId
		,@Reason1Id, @Reason2Id, @Reason3Id, @Reason4Id
		,@Action1Id, @Action2Id, @Action3Id, @Action4Id
		,@RuleToCheck, @UserId, @AddCommentId)

IF (@Code <> 'Success')
	BEGIN
		SELECT @Code AS 'Code', @Error AS 'Error',  @ErrorType AS 'ErrorType', @PropertyName1 AS 'PropertyName1', @PropertyName2 AS 'PropertyName2', @PropertyName3 AS 'PropertyName3', @PropertyName4 AS 'PropertyName4', @PropertyValue1 AS 'PropertyValue1', @PropertyValue2 AS 'PropertyValue2', @PropertyValue3 AS 'PropertyValue3', @PropertyValue4 AS 'PropertyValue4'
		RETURN
	END

/**** For addition of downtime , assigning the variable that will hold the CommentId to be updated in the CauseCommentId column *****/
IF @TransactionType = 1
	BEGIN
		SET  @CurrentCommentId =@AddCommentId
	END

/**** For addition and updation converting times to db time *****/
IF @TransactionType IN (1,2)
	BEGIN
		SELECT @StartTime = DATEADD(Millisecond, -DATEPART(Millisecond, @StartTime), @StartTime),
               @EndTime = DATEADD(Millisecond, -DATEPART(Millisecond, @EndTime), @EndTime)
		SELECT @StartTime = dbo.fnServer_CmnConvertToDbTime(@StartTime,'UTC')
		SELECT @EndTime = dbo.fnServer_CmnConvertToDbTime(@EndTime,'UTC')
	END

/***********For Updation and Deletion selecting the current the Downtime record details for passing to core sporc**************/
IF @TransactionType in (2,3)
	BEGIN
		SELECT   @CurrentStart = a.Start_time
				,@CurrentEnd = a.End_Time
				,@CurrentCommentId = a.Cause_Comment_Id --
				,@CurrStatus = a.TEStatus_Id --
				,@CurrActionComment = a.Action_Comment_Id --
				,@CurrResearchComment	= a.Research_Comment_Id --
				,@CurrResearchStatus	= a.Research_Status_Id --
				,@CurrResearchUser		= a.Research_User_Id --
				,@CurrResearchOpen = a.Research_Open_Date  --
				,@CurrResearchClose = a.Research_Close_Date --
				,@CurrSignatureId = a.Signature_Id --
			 FROM Timed_Event_Details a
			 WHERE TEDET_Id = @TEDetId

		IF @TransactionType = 2
			BEGIN
				IF @CurrentCommentId Is Null AND @AddCommentId Is Not Null
					BEGIN
						--Database manager does not update comment - do it direct
						SET @CurrentCommentId = @AddCommentId
						UPDATE Timed_Event_Details SET Cause_Comment_Id = @AddCommentId WHERE TEDET_Id = @TEDetId
					END
			END
		ELSE
			BEGIN
				SELECT @StartTime = @CurrentStart
				SELECT @EndTime = @CurrentEnd
			END
	END

--Creation/Updation/Deletion of Downtime using Core sproc
IF @RecordChanged = 1
	BEGIN
		EXECUTE spServer_DBMgrUpdTimedEvent @TEDetId OUTPUT,@MasterUnit,@LocationId,@StartTime,@EndTime
									,@CurrStatus,@FaultId,@Reason1Id,@Reason2Id,@Reason3Id
									,@Reason4Id,Null,Null,@TransactionType,2
									,@UserId,@Action1Id,@Action2Id,@Action3Id,@Action4Id
									,@CurrActionComment,@CurrResearchComment,@CurrResearchStatus,@CurrentCommentId,Null
									,Null,Null,Null,Null,Null
									,Null,@CurrResearchOpen,@CurrResearchClose,@CurrResearchUser,Null
									,@CurrSignatureId,0


		IF @TransactionType = 1 AND @TEDetId IS NULL
			BEGIN
				SELECT Code = 'InvalidData', ERROR = 'Fatal - Record not Created', ErrorType = 'RecordNotAdded', PropertyName1 = 'UnknownError', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN
			END
		ELSE IF @TransactionType = 3 AND @TEDetId IS NULL
			BEGIN
				SELECT Code = 'InvalidData', ERROR = 'Fatal - Record not Deleted', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
				RETURN
			END
	END

IF @TransactionType in (1,2)
	BEGIN
		EXECUTE  spDowntime_GetDowntime 1,Null,Null,null,Null,@UserId,@TEDetId,null,null,null,null,null,null,null, 0,1,null, null, null
	END

