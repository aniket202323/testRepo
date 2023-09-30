CREATE PROCEDURE dbo.spEM_IEImportProdExecPathSchedAlarms
@PathCode 	  	 nVarChar(100),
@AlarmType 	  	 nVarChar(100),
@Threshold 	  	 nVarChar(100),
@Units 	  	  	 nVarChar(100),
@Priority 	  	 nVarChar(100),
@UserId 	  	 Int
AS
Declare @PathId 	  	  	 Int,
 	  	 @AlarmTypeId  	 Int,
 	  	 @PriorityId  	 Int,
 	  	 @IThresholdType 	 Int,
 	  	 @PEPAId 	  	  	 Int
/* Clean and verify arguments */
SELECT  	 @PathCode 	  	 = ltrim(rtrim(@PathCode)),
 	  	 @AlarmType  	  	 = ltrim(rtrim(@AlarmType)),
 	  	 @Threshold  	  	 = ltrim(rtrim(@Threshold)),
 	  	 @Units  	  	  	 = ltrim(rtrim(@Units)),
 	  	 @Priority  	  	 = ltrim(rtrim(@Priority))
IF @PathCode = '' 	  	 SELECT @PathCode = Null
IF @AlarmType = '' 	  	 SELECT @AlarmType = Null
IF @Threshold = '' 	  	 SELECT @Threshold = Null
IF @Units = '' 	  	  	 SELECT @Units = Null
IF @Priority = '' 	  	 SELECT @Priority = Null
IF @PathCode Is Null 
BEGIN
 	 SELECT 'Failed - Path Code missing'
 	 Return (-100)
END
IF @AlarmType Is Null 
BEGIN
 	 SELECT 'Failed - Alarm Type is missing'
 	 Return (-100)
END
IF @Threshold Is Null 
BEGIN
 	 SELECT 'Failed - Threshold Value is missing'
 	 Return (-100)
END
IF @Priority Is Null 
BEGIN
 	 SELECT 'Failed - Alarm Priority is missing'
 	 Return (-100)
END
SELECT @PathId = Path_Id FROM PrdExec_Paths WHERE Path_Code = @PathCode
IF @PathId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find Path'
 	 Return (-100)
END
SELECT @AlarmTypeId = PEPAT_Id FROM PrdExec_Path_Alarm_Types WHERE PEPAT_Desc = @AlarmType
IF @AlarmTypeId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find From Alarm Type'
 	 Return (-100)
END
IF @AlarmTypeId = 9
BEGIN
 	 SELECT @Threshold = CONVERT(nVarChar(10),PP_Status_Id)
 	  	  FROM Production_Plan_Statuses WHERE PP_Status_Desc = @Threshold
 	 IF @Threshold Is null
 	 BEGIN
 	  	 SELECT 'Failed - Unable to Find To Threshold Status'
 	  	 Return (-100)
 	 END
END
SELECT @PriorityId = AP_Id FROM Alarm_Priorities WHERE AP_Desc = @Priority
IF @PriorityId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find To Priority'
 	 Return (-100)
END
IF @Units Is Not Null
BEGIN
 	 SELECT @IThresholdType = Case WHEN  @Units = '%' Then 1
 	  	  	  	  	  	  	  	   WHEN  @Units is Null Then Null
 	  	  	  	  	  	  	  	   ELSE  2
 	  	  	  	  	  	  	 END
END
SELECT @PEPAId = PEPA_Id
 	 FROM PrdExec_Path_Alarms
 	 WHERE Path_Id = @PathId And PEPAT_Id = @AlarmTypeId
IF @PEPAId Is Null
BEGIN
 	 INSERT INTO PrdExec_Path_Alarms (Path_Id, PEPAT_Id, Threshold_Type_Selection, Threshold_Value, AP_Id)
 	  	 VALUES (@PathId, @AlarmTypeId, @IThresholdType, @Threshold, @PriorityId)
END
ELSE
BEGIN
 	 UPDATE PrdExec_Path_Alarms SET Threshold_Value = @Threshold, 
 	  	  	 Threshold_Type_Selection = @IThresholdType,
 	  	  	 AP_Id = @PriorityId
 	 WHERE PEPA_Id = @PEPAId
END
