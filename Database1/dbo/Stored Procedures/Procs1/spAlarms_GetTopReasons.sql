/*
Get Top Selected Reason Tree for alarms 
@AlarmId               -Alarm Id
@ShowTopNReasons        -Top N Reasons
@ReasonType 	  	  	  - Type of reason
1 - Action
2 - Cause 
 	 EXECUTE spbf_APIGetTOPNReasons '1', 1, 1 	 
*/
CREATE PROCEDURE [dbo].[spAlarms_GetTopReasons]
@AlarmId int,
@ShowTopNReasons int = 5,
@ReasonType int = 1,
@UserId int
AS 
/***********************************************************/
/******** Copyright 2019 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/

DECLARE @VariableId INT

BEGIN
   
	SELECT @VariableId = Key_Id FROM Alarms WHERE Alarm_Id = @AlarmId;

    IF @VariableId is NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Alarm not found',
                   ErrorType = 'InvalidAlarmId',
                   PropertyName1 = 'AlarmId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @AlarmId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
	/* Since ReasonType is an Enum in core service this condition should not come here */
	IF @ReasonType not in (1,2)
			BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Invalid ReasonType',
                   ErrorType = 'InvalidReqestBodyParameter',
                   PropertyName1 = 'ReasonType',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @ReasonType,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
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
			SELECT  Code = 'InsufficientPermission',Error = 'No authorized alarm sheets configured for this user', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			RETURN
		END CATCH;
	IF NOT EXISTS (SELECT 1 FROM @AuthorizedSheets)
		BEGIN
			SELECT  Code = 'InsufficientPermission', Error = 'User is not authorized to the alarm sheet to access Variable Details for this Alarm', ErrorType = 'InsufficientPermission', PropertyName1 = 'UserName', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', 
			PropertyValue1 = (SELECT Username FROM Users_Base WHERE User_Id = @UserId), PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
 			RETURN
		END
---------------------------------------------------------------------------------


	DECLARE @ReasonTable table ( reasonL1Id int, reasonL2Id int, reasonL3Id int, reasonL4Id int, alarmStartDate datetime)
	DECLARE @TopReasons table ( reasonL1Id int, reasonL2Id int, reasonL3Id int, reasonL4Id int, groupStartDate datetime, freq int)	

	IF @ReasonType = 1 
		 /* populating @ReasonTable and @TopReasons table for ActionTree */
 		 BEGIN
 	  		INSERT INTO @ReasonTable(reasonL1Id, reasonL2Id, reasonL3Id, reasonL4Id, alarmStartDate)
				SELECT TOP 1000 Al.Action1, Al.Action2, Al.Action3, Al.Action4, Al.Start_Time  FROM dbo.Alarms Al
				WHERE Al.Key_Id = @VariableId and Al.Action1 is NOT NULL ORDER BY Al.Start_Time DESC;
			
			
			INSERT INTO @TopReasons(reasonL1Id, reasonL2Id, reasonL3Id, reasonL4Id, groupStartDate, freq) SELECT rt.reasonL1Id, rt.reasonL2Id, rt.reasonL3Id, rt.reasonL4Id, MAX(rt.alarmStartDate), COUNT(*) from @ReasonTable rt GROUP BY rt.reasonL1Id, rt.reasonL2Id, rt.reasonL3Id, rt.reasonL4Id
 			
		 END

		ELSE IF @ReasonType = 2
				 /* populating @ReasonTable and @TopReasons table for CauseTree */
			BEGIN
 	  		INSERT INTO @ReasonTable(reasonL1Id, reasonL2Id, reasonL3Id, reasonL4Id, alarmStartDate)
				SELECT TOP 1000 Al.Cause1, Al.Cause2, Al.Cause3, Al.Cause4, Al.Start_Time FROM dbo.Alarms Al
				WHERE Al.Key_Id = @VariableId and Al.Cause1 is NOT NULL ORDER BY Al.Start_Time DESC;
			
			INSERT INTO @TopReasons(reasonL1Id, reasonL2Id, reasonL3Id, reasonL4Id, groupStartDate, freq) SELECT rt.reasonL1Id, rt.reasonL2Id, rt.reasonL3Id, rt.reasonL4Id, MAX(rt.alarmStartDate), COUNT(*) from @ReasonTable rt GROUP BY rt.reasonL1Id, rt.reasonL2Id, rt.reasonL3Id, rt.reasonL4Id
 		 END

		 
		 /* extracting results based on populated @ReasonTable and @TopReasons */

		 SELECT l1.Event_Reason_Id as  'level1id',
 	  	  	  	    l1.Event_Reason_Name as 'level1name',
 	  	  	  	    l2.Event_Reason_Id as 'level2id',
 	  	  	  	    l2.Event_Reason_Name as  'level2name',
 	  	  	  	    l3.Event_Reason_Id as 'level3id',
 	  	  	  	    l3.Event_Reason_Name as 'level3name',
 	  	  	  	    l4.Event_Reason_Id as 'level4id',
 	  	  	  	    l4.Event_Reason_Name as 'level4name'
 	  	  	  	    FROM (Select top (@ShowTopNReasons) * from @TopReasons tr order by tr.freq DESC, groupStartDate DESC) tnr
 	  	  	  	    JOIN dbo.Event_Reasons l1 on tnr.reasonL1Id  = l1.Event_Reason_Id
 	  	  	  	    LEFT JOIN dbo.Event_Reasons l2 on tnr.reasonL2Id =  l2.Event_Reason_Id
 	  	  	  	    LEFT JOIN  dbo.Event_Reasons l3 on tnr.reasonL3Id = l3.Event_Reason_Id
 	  	  	  	    LEFT JOIN dbo.Event_Reasons l4 on tnr.reasonL4Id = l4.Event_Reason_Id;  	   
END
