CREATE PROCEDURE dbo.spAlarms_GetVaraiableDetails
 	  	  @AlarmId 	 Int,
		  @UserId int
		            
 	  	 
AS

DECLARE 
@VariableId INT, 
@VariabeTriggerId INT =NULL,
@VariableTriggerDesc nVARCHAR (100) = NULL,
@SourceUnitId int,
@SourceUnitDesc nVARCHAR (100)

--Get the details from Alarm Record
SELECT @VariableId = Key_Id, @SourceUnitId = Source_PU_Id
	FROM Alarms WHERE Alarm_Id = @AlarmId

IF(@VariableId IS NULL)
	BEGIN
		SELECT Error = 'ERROR: AlarmId not valid', Code = 'InvalidData', ErrorType = 'InvalidAlarmId', PropertyName1 = 'AlarmId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @AlarmId , PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 		RETURN
	END


------------------------------------------------------------------------------
--  Checking if the User is authorised to get Variable details for this alarm
------------------------------------------------------------------------------
DECLARE @AuthorizedSheets Table(Sheet_Id INT, Access_Level INT, Var_Id INT, PU_Id INT)
	;BEGIN TRY
			INSERT INTO @AuthorizedSheets EXEC spAlarms_GetAlarmSheets @UserId, @VariableId, NULL
		END TRY
		BEGIN CATCH
			SELECT Error = 'No authorized alarm sheets configured for this user', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END CATCH;
	IF NOT EXISTS (SELECT 1 FROM @AuthorizedSheets)
		BEGIN
			SELECT Error = 'User is not authorized to the alarm sheet to access Variable Details for this Alarm', Code = 'InsufficientPermission', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 			RETURN
		END
---------------------------------------------------------------------------------


--------------------------------------------------------------
-- Getting the variable triggers reason why the alarm happend
--------------------------------------------------------------
SELECT  @VariabeTriggerId = Coalesce(AVR.Alarm_Variable_Rule_Id, ASR.Alarm_SPC_Rule_Id), 
	    @VariableTriggerDesc = Coalesce(AVR.Alarm_Variable_Rule_Desc, ASR.Alarm_SPC_Rule_Desc)
	FROM Alarms A 
		LEFT OUTER JOIN Alarm_Template_Variable_Rule_Data ATVRD ON A.ATVRD_Id = ATVRD.ATVRD_Id
		LEFT OUTER JOIN Alarm_Variable_Rules AVR ON ATVRD.Alarm_Variable_Rule_Id = AVR.Alarm_Variable_Rule_Id
		LEFT OUTER JOIN Alarm_Template_SPC_Rule_Data ATSRD ON A.ATSRD_Id = ATSRD.ATSRD_Id
		LEFT OUTER JOIN Alarm_SPC_Rules ASR ON ATSRD.Alarm_SPC_Rule_Id = ASR.Alarm_SPC_Rule_Id
		WHERE A.Alarm_Id = @AlarmId



-- Calculating the variable history times
DECLARE @SiteParamValue nvarchar(max), @HistoryDuration int
select @SiteParamValue = SP.Value from Site_Parameters SP JOIN Parameters P ON P.Parm_Id = SP.Parm_Id WHERE P.Parm_Id =612
--Duration in minutes to get the variable history from alarm start/end time
set @SiteParamValue = Coalesce(@SiteParamValue , '240')  -- in case site parameter is not available hard code the duration to be 240 minutes
SET @HistoryDuration = CAST(@SiteParamValue AS int)
-- HistoryStart time = startTime-4 hrs, HistoryEndTime = StartTime + 6 hrs

--First result Set Variable Details
SELECT TOP 1 A.Key_Id AS Variable_Id, VB.Var_Desc AS Variable_Name, VB.Eng_Units AS Eng_Unit, VB.Data_Type_Id AS Data_Type_Id, 
	   dbo.fnServer_CmnConvertFromDbTime(DATEADD(MINUTE,-@HistoryDuration,A.Start_Time), 'UTC') AS Variable_History_Start_Time, 

	   CASE WHEN A.End_Time IS NULL 
	    THEN 
		--This check is needed to add a second to the start time incase site parameter duration is 0 and end time is null to keep Variable_History_End_Time > Variable_History_Start_Time
			CASE WHEN @HistoryDuration = 0
				 THEN dbo.fnServer_CmnConvertFromDbTime(DATEADD(SECOND,1,A.Start_Time), 'UTC') 
				 ELSE dbo.fnServer_CmnConvertFromDbTime(DATEADD(MINUTE,@HistoryDuration,A.Start_Time), 'UTC') 
			END
		ELSE dbo.fnServer_CmnConvertFromDbTime(DATEADD(MINUTE,@HistoryDuration,A.End_Time), 'UTC')
	   END
		AS Variable_History_End_Time,
	   DT.Data_Type_Desc,
	   @VariabeTriggerId AS VariableTriggerId,
	   @VariableTriggerDesc AS VariableTriggerDesc
	   FROM Alarms A JOIN Variables_Base VB ON A.Key_Id = VB.Var_Id
	   JOIN Data_Type DT ON VB.Data_Type_Id=DT.Data_Type_Id
	   WHERE A.Alarm_Id = @AlarmId
       


