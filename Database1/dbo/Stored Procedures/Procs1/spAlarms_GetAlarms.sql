CREATE PROCEDURE dbo.spAlarms_GetAlarms
 	  	  @TimeSelection nVarChar(2)
		 ,@StartTime DATETIME = NULL 
		 ,@EndTime  DATETIME  = NULL         
 	  	 ,@PUIds 	 nvarchar(max) = null 
 	  	 ,@AlarmId 	 Int = Null           
 	  	 ,@IncludeAcknowledged       BIT = 1
		 ,@IncludeClosed       BIT = 1
		 ,@PrioritiesFiler nVarChar(5)
		 ,@SortColumn       nVarChar(20) = 'Start_Time' -- Default sort column
         ,@SortDirection        nVarChar(5) = 'DESC' -- Default sort order
		 ,@UserId Int 
AS

If (@PUIds IS NOT NULL)
 	 Set @PUIds = REPLACE(@PUIds, ' ', '')
IF @PUIds = '' SET @PUIds = Null
IF @AlarmId < 1 SET @AlarmId = Null
IF @PUIds IS NULL AND @AlarmId IS  NULL
	BEGIN
	 	SELECT Error = 'ERROR: Need either PUIds (Production unit Ids) or AlarmId, both cant be blank', Code = 'InvalidData', ErrorType = 'MissingRequiredData', PropertyName1 = 'PUIds', PropertyName2 = 'AlarmId', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PUIds, PropertyValue2 = @AlarmId, PropertyValue3 = '', PropertyValue4 = ''
 		RETURN
	END
--Error template
--BEGIN
 	 --SELECT  Error = 'ERROR: Valid User Required'
--SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 --	 RETURN
--END

CREATE TABLE #Authorized_Variable_Ids  (Id Int)
DECLARE @AuthorizedSheets Table(Sheet_Id INT, Access_Level INT, Var_Id INT, PU_Id INT)

DECLARE @FilteredAlarms Table (
	[Alarm_Id] [int] NOT NULL,
	[Alarm_Desc] [nvarchar](1000) NOT NULL,
	[Start_Time] [datetime] NOT NULL,
	[End_Time] [datetime] NULL,
	[Priority_Id] [int] NOT NULL,
	[Priority] [dbo].[Varchar_Desc] NOT NULL,
	[Ack] [bit] NOT NULL,
	[VarId] INT
	)
DECLARE @AlarmsCounts Table(
    [TotalAlarmsCount] [int] NULL,
	[AcknowledgedAlarmCount] [int] NULL,
	[NonAcknowledgedAlarmCount] [int] NULL,
	[LowPriorityAlarmCount] [int] NULL,
	[MediumPriorityAlarmCount] [int] NULL,
	[HighPriorityAlarmCount] [int] NULL
)

DECLARE @AlarmDetails TABLE(
	[AlarmId] [int] NOT NULL,
	[Description] [nvarchar](1000) NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[AlarmRule] [dbo].[Varchar_Desc] NOT NULL,
	[ATDid] [int] NULL,
	[PUId] [int] NULL,
	[UnitDesc] [dbo].[Varchar_Desc] NOT NULL,
	[StartResult] [dbo].[Varchar_Value] NULL,
	[EndResult] [dbo].[Varchar_Value] NULL,
	[VarId] [int] NOT NULL,
	[VarDesc] [dbo].[Varchar_Desc] NOT NULL,
	[ACK] [bit] NOT NULL,
	[ACKUserId] [int] NULL,
	[ACKUser] [nvarchar](255) NULL,
	[ACKDate] [datetime] NULL,
	[APId] [int] NOT NULL,
	[APDesc] Varchar_Desc NOT NULL,
	[CauseLevel1] [int] NULL,
	[CauseName1] [nvarchar](100) NULL,
	[CauseLevel2] [int] NULL,
	[CauseName2] [nvarchar](100) NULL,
	[CauseLevel3] [int] NULL,
	[CauseName3] [nvarchar](100) NULL,
	[CauseLevel4] [int] NULL,
	[CauseName4] [nvarchar](100) NULL,
	[ActionLevel1] [int] NULL,
	[ActionName1] [nvarchar](100) NULL,
	[ActionLevel2] [int] NULL,
	[ActionName2] [nvarchar](100) NULL,
	[ActionLevel3] [int] NULL,
	[ActionName3] [nvarchar](100) NULL,
	[ActionLevel4] [int] NULL,
	[ActionName4] [nvarchar](100) NULL,
	[ResearchUserId] [int] NULL,
	[ResearchUserName] [nvarchar](255) NULL,
	[ResearchStatusId] [int] NULL,
	[ResearchStatusDesc] [dbo].[Varchar_Desc] NULL,
	[ResearchOpenDate] [datetime] NULL,
	[ResearchCloseDate] [datetime] NULL,
	[ResearchCommentId] [int] NULL,
	[CauseCommentId] [int] NULL,
	[ActionCommentId] [int] NULL,
	[ESignature_Level] [int] NULL,
	[CauseTreeId] [int] ,
	[ActionTreeId] [int] ,
	[AlarmTypeId] [int],
	[AlarmTypeDesc] [nvarchar](50),
	--Supporting Column for calculations
	[ActionRequired] [BIT] NOT NULL,
	[CauseRequired] [BIT] NOT NULL,
	--Calculated Columns
	[CanPerform] [BIT] ,
	[CanAcknowledge] [BIT] ,
	[Duration] [int] ,
	[SubTypeDescription] [nvarchar](50) ,
	[EventCount] [int],
	[Variable_Data_Type_Id] [int],
	[Variable_Data_Type_Desc] [nvarchar](50)
)
---------------------------------------------------------------
---Populating the Filtered and Orderd set of Alarms
---------------------------------------------------------------
IF (@AlarmId IS NULL)
	BEGIN 
	--GetS List of Alrams based on time selection and unit list
	
		--IF NOT EXISTS (SELECT DISTINCT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@PUIds,','))
 	--		BEGIN
 	--		 	 --Throw 'Not Valid Units'
		--		 SELECT Error = 'ERROR: Valid units not Found', Code = 'InvalidData', ErrorType = 'ValidUnitsNotFound', PropertyName1 = 'PUIds', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PUIds, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 	--		 	 RETURN
 	--		END
		-----------------------------------------------------------------------------------
		--Getting the Authorized sheets , variables and units for this user for alarms view
		-----------------------------------------------------------------------------------
		;BEGIN TRY
			INSERT INTO @AuthorizedSheets EXEC spAlarms_GetAlarmSheets @UserId, null, @PUIds
		END TRY
		BEGIN CATCH
			SELECT Error = 'No authorized alarm sheets configured for this user', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END CATCH;
		
		INSERT INTO #Authorized_Variable_Ids SELECT Var_Id FROM @AuthorizedSheets
		IF NOT EXISTS (SELECT 1 FROM #Authorized_Variable_Ids)
			BEGIN
				 --Throw 'InsufficientPermission'
				SELECT Error = 'No Authorized Alarm displays configured for the User for the requested units', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UnitId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @PUIds , PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			END

		--------------------------------
		--Calcuate Start and end time
		--------------------------------
		IF (@TimeSelection <> 7)
		 BEGIN
		  --Getting the Start Time and End Time from the time selection function	
		  EXECUTE dbo.spBF_CalculateReportTimeFromTimeSelection null, null, @TimeSelection  , @StartTime  Output,@EndTime  Output, 1
		 END

		IF @StartTime Is Null OR @EndTime Is Null
 			BEGIN 
 				SELECT Error = 'Could not Calculate Start Date and Endate, provide valid timeselection', Code = 'InvalidData', ErrorType = 'ValidDatesNotFound', PropertyName1 = 'TimeSelection', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @TimeSelection, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 				RETURN
 			END

		SET @StartTime = dbo.fnServer_CmnConvertToDbTime(@StartTime, 'UTC') --Converted to DB time for querying the table
		SET @EndTime = dbo.fnServer_CmnConvertToDbTime(@EndTime, 'UTC')		--Converted to DB time for querying the table
		
	    --Filter according to priority
		If (@PrioritiesFiler IS NOT NULL)
		 	 Set @PrioritiesFiler = REPLACE(@PrioritiesFiler, ' ', '')
		IF @PrioritiesFiler = '' SET @PrioritiesFiler = Null
		IF @PrioritiesFiler IS NULL
		 BEGIN
		 -- SET @PrioritiesFiler = 'LOW,MEDIUM,HIGH'
		  SET @PrioritiesFiler = '1,2,3'
		 END

		--Default Sorting order and sort column
	    IF @SortColumn IS NULL
	    	BEGIN
	    		SET @SortColumn = 'Start_Time'
	    		SET @SortDirection = 'DESC'
	    	END
        -- For all other sortColumns except for startDate the default sort direction is asc
	    SET @SortDirection = coalesce(@SortDirection,'ASC')		

	    DECLARE @Sql nvarchar(max)= '';

	    --Dynamic Query for Sorting the Data set and filtering		
	    SET @Sql = ';WITH AlarmRecordsTempView As (
  	    	SELECT A.Alarm_Id, A.Alarm_Desc, A.Start_Time, A.End_Time, AP.AP_Id AS Priority_Id, AP.AP_Desc AS Priority, A.Ack, A.Key_Id
			    FROM Alarms A
	    		LEFT OUTER JOIN Alarm_Template_Variable_Rule_Data ATVRD ON A.ATVRD_Id = ATVRD.ATVRD_Id
				LEFT OUTER JOIN Alarm_Template_SPC_Rule_Data ATSRD ON A.ATSRD_Id = ATSRD.ATSRD_Id
	    		INNER JOIN Alarm_Priorities AP ON (AP.AP_Id = ATVRD.AP_Id OR AP.AP_Id = ATSRD.AP_Id)
	    		WHERE A.Key_Id IN (SELECT Id FROM #Authorized_Variable_Ids) AND 
	    		((A.Start_Time >= '+''''+CAST(@StartTime as nvarchar)+''''+' AND A.Start_Time <= '+''''+CAST(@EndTime as nvarchar)+''''+')
				  OR A.End_Time IS NULL)
				 )	    		
	    		SELECT * FROM AlarmRecordsTempView WHERE Priority_Id IN ('+@PrioritiesFiler+')  ORDER BY '+@SortColumn+' '+@SortDirection
		--Second sort for same priority
		IF(@SortColumn <> 'Start_Time')
			BEGIN
				SET @Sql = @Sql+ ' ,Start_Time DESC'
			END
		-- Inserting into table			
	    INSERT INTO @FilteredAlarms EXEC(@sql)
		IF @IncludeAcknowledged = 0
			BEGIN
				DELETE FROM @FilteredAlarms WHERE Ack = 1
			END
		IF @IncludeClosed = 0
			BEGIN
				DELETE FROM @FilteredAlarms WHERE End_Time IS NOT NULL
			END
    -- we have filtered sorted list of alarms in @FilteredAlarms table		
	
	
     END
ELSE -- Query Based on Alarm ID
	BEGIN

		INSERT INTO @FilteredAlarms (Alarm_Id, Alarm_Desc, Start_Time, End_Time, Priority_Id, Priority, Ack, VarId)
		SELECT A.Alarm_Id, A.Alarm_Desc, A.Start_Time, A.End_Time, AP.AP_Id AS Priority_Id, AP.AP_Desc AS Priority, A.Ack, A.Key_Id
			FROM Alarms A
			LEFT OUTER JOIN Alarm_Template_Variable_Rule_Data ATVRD ON A.ATVRD_Id = ATVRD.ATVRD_Id
			LEFT OUTER JOIN Alarm_Template_SPC_Rule_Data ATSRD ON A.ATSRD_Id = ATSRD.ATSRD_Id
			INNER JOIN Alarm_Priorities AP ON (AP.AP_Id = ATVRD.AP_Id OR AP.AP_Id = ATSRD.AP_Id)
			WHERE A.Alarm_Id = @AlarmId
------------------------------------------------------------------------------
--  Checking if the User is authorised for getting data under this unit
------------------------------------------------------------------------------	
	DECLARE @AlarmVariable Int
	SELECT @AlarmVariable = VarId FROM @FilteredAlarms
	;BEGIN TRY
			INSERT INTO @AuthorizedSheets EXEC spAlarms_GetAlarmSheets @UserId, @AlarmVariable, NULL
		END TRY
		BEGIN CATCH
			SELECT Error = 'No authorized alarm sheets configured for this user', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END CATCH;
	IF NOT EXISTS (SELECT 1 FROM @AuthorizedSheets)
		BEGIN
			SELECT Error = 'User is not authorized to the alarm sheet for getting or updating this Alarm data', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 			RETURN
		END
	END


---------------------------------------------------------------
----Inserting the recods in the detailed Alarms Table
---------------------------------------------------------------

INSERT INTO @AlarmDetails 
(AlarmId, Description, StartTime, EndTime, AlarmRule, PUId, UnitDesc, StartResult, EndResult, VarId, VarDesc, 
ACK, ACKUserId, ACKUser, ACKDate, APId, APDesc, 
CauseLevel1, CauseName1, CauseLevel2, CauseName2, CauseLevel3, CauseName3, CauseLevel4, CauseName4, 
ActionLevel1, ActionName1, ActionLevel2, ActionName2, ActionLevel3, ActionName3, ActionLevel4, ActionName4, 
ResearchUserId, ResearchUserName, ResearchStatusId, ResearchStatusDesc, ResearchOpenDate, ResearchCloseDate, ResearchCommentId, 
CauseCommentId, ActionCommentId, ESignature_Level, CauseTreeId, ActionTreeId,
CauseRequired, ActionRequired, AlarmTypeId, AlarmTypeDesc, Variable_Data_Type_Id, Variable_Data_Type_Desc)
SELECT 
AL.Alarm_Id, AL.Alarm_Desc, AL.Start_Time, AL.End_Time, AT.AT_Desc, AL.Source_PU_Id, PU.PU_Desc, AL.Start_Result, AL.End_Result, AD.Var_Id, VB.Var_Desc,
AL.ACK , AL.ACK_by, US2.UserName, AL.ACK_On, FA.Priority_Id, FA.Priority, 
AL.Cause1 , RE.Event_Reason_Name , AL.Cause2 , RE2.Event_Reason_Name , AL.Cause3 , RE3.Event_Reason_Name , AL.Cause4 , RE4.Event_Reason_Name , 
AL.Action1 , RE5.Event_Reason_Name , AL.Action2 , RE6.Event_Reason_Name , AL.Action3 , RE7.Event_Reason_Name , AL.Action4 , RE8.Event_Reason_Name , 
AL.Research_User_Id, US.UserName, AL.Research_Status_Id, RS.Research_Status_Desc, AL.Research_Open_Date, AL.Research_Close_Date, AL.Research_Comment_Id,
AL.Cause_Comment_Id, AL.Action_Comment_Id, AT.ESignature_Level, Coalesce(AD.Override_Cause_Tree_Id, AT.Cause_Tree_Id), Coalesce(AD.Override_Action_Tree_Id, AT.Action_Tree_Id),
AT.Cause_Required, AT.Action_Required, ATY.Alarm_Type_Id, ATY.Alarm_Type_Desc, VB.Data_Type_Id , DT.Data_Type_Desc 
From @FilteredAlarms FA JOIN Alarms AL ON FA.Alarm_Id = AL.Alarm_Id
				 Inner Join Alarm_Template_Var_Data AD On AL.ATD_Id = AD.ATD_Id
                 Inner Join Alarm_Templates AT on AD.AT_Id = AT.AT_Id
                 Left Outer Join Users US2 on AL.Ack_By = US2.User_Id
                 Left Outer Join Event_Reasons RE on AL.Cause1 = RE.Event_Reason_Id
                 Left Outer Join Event_Reasons RE2 on AL.Cause2 = RE2.Event_Reason_Id
                 Left Outer Join Event_Reasons RE3 on AL.Cause3 = RE3.Event_Reason_Id
                 Left Outer Join Event_Reasons RE4 on AL.Cause4 = RE4.Event_Reason_Id
                 Left Outer Join Event_Reasons RE5 on AL.Action1 = RE5.Event_Reason_Id
                 Left Outer Join Event_Reasons RE6 on AL.Action2 = RE6.Event_Reason_Id
                 Left Outer Join Event_Reasons RE7 on AL.Action3 = RE7.Event_Reason_Id
                 Left Outer Join Event_Reasons RE8 on AL.Action4 = RE8.Event_Reason_Id
				 Left Outer Join Users US on AL.Research_User_Id = US.User_Id
				 Left Outer Join Research_Status RS on AL.Research_Status_Id = RS.Research_Status_Id
				 JOIN Prod_Units_Base PU ON AL.Source_PU_Id = PU.PU_Id
				 JOIN Variables_Base VB ON AD.Var_Id = VB.Var_Id
				 JOIN Data_Type DT ON VB.Data_Type_Id = DT.Data_Type_Id
				 JOIN Alarm_Types ATY ON AL.Alarm_Type_Id = ATY.Alarm_Type_Id

---------------------------------------------------------------
-- Calculating the Derived Columns in the Detailed Alarm Table
---------------------------------------------------------------

UPDATE @AlarmDetails  SET 
--1. Deriving and updating the SubTypeDescription (Batch , reels , rolls)

SubTypeDescription = 
     CASE 
		 WHEN (Select EV.Event_Num From Events EV Where EV.PU_Id = PUId 
		             And EV.TimeStamp = ( Select top 1  TimeStamp From Events E Where E.PU_Id= PUId And 
										StartTime > E.Start_Time and StartTime <= E.TimeStamp order by Timestamp DESC
									  )
			   ) IS NULL THEN NULL
		 ELSE
			(Select Min(ES.Event_SubType_Desc) From Event_SubTypes ES Inner Join Event_Configuration EC  On ES.Event_SubType_Id = EC.Event_SubType_Id
			Where ES.ET_Id = 1 And EC.PU_Id = PUId)
	END
 
--2. Total of Events happened during the alarm

 ,EventCount =
	 CASE 
		WHEN EndTime IS NULL
			THEN (SELECT Count(*) From Events E Where E.PU_Id = PUId And E.TimeStamp >= StartTime)
		ELSE
			(Select Count(*) From Events E Where E.PU_Id = PUId And E.TimeStamp >=StartTime And E.TimeStamp <=EndTime)
	 END	

--3. Calculating Duration of the alarm
 ,Duration = 
	 CASE
		WHEN EndTime IS NULL
			THEN null
		ELSE
			DateDiff(SECOND, StartTime , EndTime)
	 END
--4. Deriving Can Perform
 ,CanPerform =
	 CASE 
		WHEN (ActionRequired = 1 OR CauseRequired =1)
			THEN 1 
		ELSE 
			0 
	 END 
--5. Deriving Can Acknowledge
 ,CanAcknowledge =
	 CASE 
		WHEN ((ActionRequired = 0 OR ActionLevel1 IS NOT NULL) AND (CauseRequired = 0 OR CauseLevel1 IS NOT NULL))
			THEN 1 
		 ELSE 
			0 
	 END

----------------------------------------------------------------
---Retrun the detailed Result set For Alarms
----------------------------------------------------------------
SELECT 
AlarmId, Description, dbo.fnServer_CmnConvertFromDbTime(StartTime, 'UTC') AS StartTime, dbo.fnServer_CmnConvertFromDbTime(EndTime, 'UTC') AS EndTime, 
AlarmRule, PUId, UnitDesc, StartResult, EndResult, VarId, VarDesc, ACK, ACKUserId, ACKUser, dbo.fnServer_CmnConvertFromDbTime(ACKDate, 'UTC') AS ACKDate, APId, APDesc, Duration, 
CauseLevel1, CauseName1, CauseLevel2, CauseName2, CauseLevel3, CauseName3, CauseLevel4, CauseName4, 
ActionLevel1, ActionName1, ActionLevel2, ActionName2, ActionLevel3, ActionName3, ActionLevel4, ActionName4, 
ResearchUserId, ResearchUserName, ResearchStatusId, ResearchStatusDesc, dbo.fnServer_CmnConvertFromDbTime(ResearchOpenDate, 'UTC') AS ResearchOpenDate, dbo.fnServer_CmnConvertFromDbTime(ResearchCloseDate, 'UTC') AS ResearchCloseDate, ResearchCommentId, 
CauseCommentId, ActionCommentId, ESignature_Level, CauseTreeId, ActionTreeId, ActionRequired, CauseRequired, SubTypeDescription, EventCount, 
CanPerform, CanAcknowledge, AlarmTypeId, AlarmTypeDesc, Variable_Data_Type_Id, Variable_Data_Type_Desc

FROM @AlarmDetails

----------------------------------------------------------------
---Retrun the Counts Result set For Alarms
----------------------------------------------------------------
IF (@AlarmId IS NULL)
	BEGIN
		-- Result set for getting the counts
		INSERT INTO @AlarmsCounts 
		SELECT COUNT(1) AS TotalAlarmsCount, COUNT( CASE A.ACK WHEN 1 THEN 1 END) AS AcknowledgedAlarmCount,
		   COUNT( CASE A.ACK WHEN 0 THEN 1 END) AS NonAcknowledgedAlarmCount,
		   COUNT( CASE AP.AP_Id WHEN 1 THEN 1 END) AS LowPriorityAlarmCount,
		   COUNT( CASE AP.AP_Id WHEN 2 THEN 1 END) AS MediumPriorityAlarmCount,
		   COUNT( CASE AP.AP_Id WHEN 3 THEN 1 END) AS HighPriorityAlarmCount
		FROM Alarms A 
		LEFT OUTER JOIN Alarm_Template_Variable_Rule_Data ATVRD ON A.ATVRD_Id = ATVRD.ATVRD_Id
		LEFT OUTER JOIN Alarm_Template_SPC_Rule_Data ATSRD ON A.ATSRD_Id = ATSRD.ATSRD_Id
		INNER JOIN Alarm_Priorities AP ON (AP.AP_Id = ATVRD.AP_Id OR AP.AP_Id = ATSRD.AP_Id)
		WHERE A.Key_Id IN (SELECT Id FROM #Authorized_Variable_Ids) AND 
		((A.Start_Time >= @StartTime AND A.Start_Time <= @EndTime) OR End_Time IS NULL)
		--First Result Set
		SELECT * FROM @AlarmsCounts
	END

