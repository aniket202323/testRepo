
-------------------------------------------------------------------------------------------------
-- SP changed in PCMT Ver 1.30
-------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_PCMT_SetSPCCalc]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_SetSPCCalc
Author:					Marc Charest (STI)	
Date ALTERd:			2007-05-03
SP Type:				ADO or SDK Call
Editor Tab Spacing:		3

Description:
=========
This SP ALTERs or edit a SPC calculation.

Called by:  			PCMT.xls

Revision	Date		Who							What
========	==========	=================== 		=============================================
1.0.1		02-Dec-08	Marc Charest				I added an UPDATE instruction right after the EXECUTE spEM_DropVariable call
														because this spEM does not update the Var_Desc_Global field.
1.1.0		09-Apr-09	Marc Charest				I changed code to make PCMT able to manage parent variables that have 
														children differently named. 
1.2.0		30-Apr-09	Marc Charest				New code added to update children with the right info
														(interval, offset, eng_units, ext link, ud1, ud2, ud3, ext info & test name) 
1.2.1		13-Feb-13	Pablo Galanzini				Fixed a bug when is incremented the SubGroup Size (Line 333)
2.0			31-Jul-14	Pablo Galanzini	(Arido)		We cann't update field var_desc_local because it is derived 
														or constant field in PPA6
*****************************************************************************************************************
*/
@intUserId				INTEGER,
@intPUId				INTEGER,
@intPUGId				INTEGER,
@vcrVarName				VARCHAR(255),
@intSGSizeOld			INTEGER,
@intSGSize				INTEGER,
@intDataSourceId		INTEGER, 
@intDataTypeId			INTEGER, 
@intEventTypeId			INTEGER,
@intPrecision			INTEGER,
@vcrDefaultFailure		VARCHAR(255),
@intSPCTypeId			INTEGER,
@intSpecId				INTEGER,
@intTestFrequency		INTEGER,
@vcrGlobalDesc			VARCHAR(255),
@vcrLocalDesc			VARCHAR(255),
@vcrOldGlobalDesc		VARCHAR(255),
@intParentVarId 		INTEGER OUTPUT
AS

-- testing
-- EXEC dbo.spLocal_PCMT_SetSPCCalc 1, 473, 272, 'Test SPC JPG', 0, 3, 2, 2, 0, 2, '', 1, NULL, 1,'Test SPC JPG','Test SPC JPG','Test SPC JPG', @intVarId OUTPUT
--SELECT 
--@intUserId				= 1,
--@intPUId				= 473,
--@intPUGId				= 272,
--@vcrVarName				= 'SPC JPG',
--@intSGSizeOld			= 0,
--@intSGSize				= 3,
--@intDataSourceId		= 2, 
--@intDataTypeId			= 2, 
--@intEventTypeId			= 0,
--@intPrecision			= 2,
--@vcrDefaultFailure		= '',
--@intSPCTypeId			= 1,
--@intSpecId				= Null,
--@intTestFrequency		= 1,
--@vcrGlobalDesc			= 'SPC JPG',
--@vcrLocalDesc			= 'SPC JPG',
--@vcrOldGlobalDesc		= 'SPC JPG',
--@intParentVarId 		= 250709

SET NOCOUNT ON

DECLARE
@vcrVarNameTemp		VARCHAR(50),
@intChildVarId 		INTEGER,
@intCalcId 				INTEGER,
@intRangeVarId 		INTEGER,
@intStdDevVarId 		INTEGER,
@intMRVarId 			INTEGER,
@intCounter				INTEGER,
@vcrSSNumber			VARCHAR(2),
@vcrParentCalcName	VARCHAR(255),
@vcrChildName			VARCHAR(255),
@vcrChildGlobalDesc	VARCHAR(255),
@vcrChildLocalDesc	VARCHAR(255),
@vcrTestName			VARCHAR(255),
@vcrUD1					VARCHAR(255),
@vcrUD2					VARCHAR(255),
@vcrUD3					VARCHAR(255),
@vcrEI					VARCHAR(255),
@bitESign				BIT,
@vcrEngUnits			VARCHAR(255),
@vcrExtLink				VARCHAR(255),
@intSamplingInterval	INTEGER,
@intSamplingOffset		INTEGER


/*
SET @intUserId = 56
SET @intPUId = 3
SET @vcrVarName = 'SPC2008'
SET @intSGSizeOld = 7
SET @intSGSize = 5
*/


SELECT	@vcrTestName = Test_Name, 
			@vcrUD1 = User_Defined1, 
			@vcrUD2 = User_Defined2, 
			@vcrUD3 = User_Defined3, 
			@vcrEI = Extended_Info,
			@bitESign = Force_Sign_Entry, 
			@vcrEngUnits = Eng_Units,
			@vcrExtLink = External_Link,
			@intSamplingInterval = Sampling_Interval,
			@intSamplingOffset = Sampling_Offset
FROM 
			dbo.Variables 
WHERE 
			Var_Id = @intParentVarId

--Downsizing subgroup size if needed
IF @intSGSize < @intSGSizeOld BEGIN

	SET @intCounter = @intSGSizeOld

	--For each variable we want to get rid off
	WHILE @intCounter > @intSGSize BEGIN

		--Get the variable ID
		IF @intCounter < 10 BEGIN
			SET @vcrSSNumber = '0' + CAST(@intCounter AS VARCHAR(2)) END
		ELSE BEGIN
			SET @vcrSSNumber = CAST(@intCounter AS VARCHAR(2))
		END
		SET @vcrVarNameTemp = @vcrVarName + '-' + @vcrSSNumber	
		SET @intChildVarId = NULL
		--SELECT @intChildVarId = var_id FROM dbo.variables WHERE var_desc = @vcrVarNameTemp AND pu_id = @intPUId
		SELECT @intChildVarId = MAX(var_id) FROM dbo.variables WHERE PVar_Id = @intParentVarId		
	
		--Dropping variable
		IF @intChildVarId IS NOT NULL BEGIN
			EXECUTE spEM_DropVariable @intChildVarId, @intUserId		--Variable itself
			EXECUTE spEM_DropVariableSlave @intChildVarId				--Sheet and calculation instances

			UPDATE dbo.Variables 
				SET Var_Desc_Global = Var_Desc_Local 
				WHERE Var_Id = @intChildVarId
		END

		SET @intCounter = @intCounter - 1

	END

END

SELECT @vcrParentCalcName = 
	CASE 
		WHEN @intSPCTypeId = 2 THEN 'MSI_UchartTotal'
		WHEN @intSPCTypeId = 3 THEN 'MSI_PchartTotal'
		ELSE 'MSI_Calc_Average'
	END

/*
--Creating parent variable (if needed)
SELECT @intParentVarId = var_id FROM dbo.variables WHERE var_desc = @vcrVarName AND pu_id = @intPUId
IF @intParentVarId IS NULL BEGIN
	EXECUTE spEM_ALTERVariable @vcrVarName, @intPUId, @intPUGId, -1, @intUserId, @intParentVarId OUTPUT
END
*/	
--Setting average calculation on the parent variable
EXECUTE spEMCC_FindCalcByName @vcrParentCalcName, @intCalcId OUTPUT
EXECUTE spEMCC_BuildDataSetUpdate 94, @intCalcId, @intParentVarId, @intSPCTypeId, NULL, '', '', @intUserId

IF @intSPCTypeId NOT IN (1, 2, 3, 7) BEGIN

	--Creating variable for the range calculation (if needed)
	SET @vcrVarNameTemp = @vcrVarName + '-Range'
	SELECT @intRangeVarId = var_id FROM dbo.variables WHERE pvar_id = @intParentVarId AND var_desc LIKE '%-Range' + '%' --var_desc = @vcrVarNameTemp AND pu_id = @intPUId

	IF @intRangeVarId IS NULL 
	BEGIN
		--PRINT 'Call spEM_ALTERChildVariable with ' +  @vcrVarNameTemp
		-- Range
		EXECUTE spEM_ALTERChildVariable 
			@vcrVarNameTemp, @intParentVarId, -1, 16, 2, @intEventTypeId, 
			@intPrecision, 2, NULL, @intTestFrequency, @intUserId, @intRangeVarId OUTPUT

		UPDATE 
			dbo.variables 
		SET 
			var_desc_global = @vcrGlobalDesc + '-Range', 
			Test_Name = @vcrTestName, 
			User_Defined1 = @vcrUD1, 
			User_Defined2 = @vcrUD2, 
			User_Defined3 = @vcrUD3, 
			Extended_Info = @vcrEI,
			--Force_Sign_Entry = @bitESign,
			Eng_Units = @vcrEngUnits,
			External_Link = @vcrExtLink,
			Sampling_Interval = @intSamplingInterval,
			Sampling_Offset = @intSamplingOffset
		WHERE 
			var_id  = @intRangeVarId 
	END
	ELSE BEGIN
		
		UPDATE dbo.variables 
		SET var_desc_global = @vcrGlobalDesc + '-Range', 
			-- We cann't update field var_desc_local because it is derived or constant field (July 2014 - JPGalanzini - Arido)
			--var_desc_local = @vcrVarName + '-Range', 
			Test_Name = @vcrTestName, 
			User_Defined1 = @vcrUD1, 
			User_Defined2 = @vcrUD2, 
			User_Defined3 = @vcrUD3, 
			Extended_Info = @vcrEI,
			--Force_Sign_Entry = @bitESign,
			Eng_Units = @vcrEngUnits,
			External_Link = @vcrExtLink,
			Sampling_Interval = @intSamplingInterval,
			Sampling_Offset = @intSamplingOffset 
		WHERE var_id  = @intRangeVarId
	END

	--Setting calculation on the range variable
	EXECUTE spEMCC_FindCalcByName 'MSI_Calc_Range', @intCalcId OUTPUT
	EXECUTE spEMCC_BuildDataSetUpdate 94, @intCalcId, @intRangeVarId, NULL, NULL, '', '', @intUserId
	
	--Creating variable for the standard deviation calculation (if needed)
	SET @vcrVarNameTemp = @vcrVarName + '-StdDev'
	SELECT @intStdDevVarId = var_id FROM dbo.variables WHERE pvar_id = @intParentVarId AND var_desc LIKE '%-StdDev' + '%' --var_desc = @vcrVarNameTemp AND pu_id = @intPUId

	IF @intStdDevVarId IS NULL 
	BEGIN
		--PRINT 'Call spEM_ALTERChildVariable with ' +  @vcrVarNameTemp
		-- StdDev
		EXECUTE spEM_ALTERChildVariable 
			@vcrVarNameTemp, @intParentVarId, -1, 16, 2, @intEventTypeId, 
			@intPrecision, 3, NULL, @intTestFrequency, @intUserId, @intStdDevVarId OUTPUT

		UPDATE 
			dbo.variables 
		SET 
			var_desc_global = @vcrGlobalDesc + '-StdDev',
			Test_Name = @vcrTestName, 
			User_Defined1 = @vcrUD1, 
			User_Defined2 = @vcrUD2, 
			User_Defined3 = @vcrUD3, 
			Extended_Info = @vcrEI,
			--Force_Sign_Entry = @bitESign,
			Eng_Units = @vcrEngUnits,
			External_Link = @vcrExtLink,
			Sampling_Interval = @intSamplingInterval,
			Sampling_Offset = @intSamplingOffset   
		WHERE 
			var_id  = @intStdDevVarId 
	END
	ELSE BEGIN
		UPDATE 
			dbo.variables 
		SET 
			var_desc_global = @vcrGlobalDesc + '-StdDev', 
			-- We can't update field var_desc_local because it is derived or constant field (July 2014 - JPGalanzini - Arido)
--			var_desc_local = @vcrVarName + '-StdDev',
			Test_Name = @vcrTestName, 
			User_Defined1 = @vcrUD1, 
			User_Defined2 = @vcrUD2, 
			User_Defined3 = @vcrUD3, 
			Extended_Info = @vcrEI,
			--Force_Sign_Entry = @bitESign,
			Eng_Units = @vcrEngUnits,
			External_Link = @vcrExtLink,
			Sampling_Interval = @intSamplingInterval,
			Sampling_Offset = @intSamplingOffset  
		WHERE 
			var_id  = @intStdDevVarId
	END

	--Setting calculation on the standard deviation variable
	EXECUTE spEMCC_FindCalcByName 'MSI_Calc_StDev', @intCalcId OUTPUT
	EXECUTE spEMCC_BuildDataSetUpdate 94, @intCalcId, @intStdDevVarId, NULL, NULL, '', '', @intUserId

		
	--Creating variable for the moving range calculation (if needed)
	SET @vcrVarNameTemp = @vcrVarName + '-MR'
	SELECT @intMRVarId = var_id FROM dbo.variables WHERE pvar_id = @intParentVarId AND var_desc LIKE '%-MR' + '%' --var_desc = @vcrVarNameTemp AND pu_id = @intPUId

	IF @intMRVarId IS NULL 
	BEGIN
		--PRINT 'Call spEM_ALTERChildVariable with ' +  @vcrVarNameTemp
		-- MR
 		EXECUTE spEM_ALTERChildVariable 
 			@vcrVarNameTemp, @intParentVarId, -1, 16, 2, @intEventTypeId, 
 			@intPrecision, 4, NULL, @intTestFrequency, @intUserId, @intMRVarId OUTPUT

		UPDATE 
			dbo.variables 
		SET 
			var_desc_global = @vcrGlobalDesc + '-MR',
			Test_Name = @vcrTestName, 
			User_Defined1 = @vcrUD1, 
			User_Defined2 = @vcrUD2, 
			User_Defined3 = @vcrUD3, 
			Extended_Info = @vcrEI,
			--Force_Sign_Entry = @bitESign,
			Eng_Units = @vcrEngUnits,
			External_Link = @vcrExtLink,
			Sampling_Interval = @intSamplingInterval,
			Sampling_Offset = @intSamplingOffset  
		WHERE 
			var_id  = @intMRVarId 
	END
	ELSE BEGIN


		UPDATE 
			dbo.variables 
		SET 
			var_desc_global = @vcrGlobalDesc + '-MR', 
			-- We cann't update field var_desc_local because it is derived or constant field (July 2014 - JPGalanzini - Arido)
--			var_desc_local = @vcrVarName + '-MR', 
			Test_Name = @vcrTestName, 
			User_Defined1 = @vcrUD1, 
			User_Defined2 = @vcrUD2, 
			User_Defined3 = @vcrUD3, 
			Extended_Info = @vcrEI,
			--Force_Sign_Entry = @bitESign,
			Eng_Units = @vcrEngUnits,
			External_Link = @vcrExtLink,
			Sampling_Interval = @intSamplingInterval,
			Sampling_Offset = @intSamplingOffset  
		WHERE 
			var_id  = @intMRVarId
	END

	--Setting calculation on the moving range variable
	EXECUTE spEMCC_FindCalcByName 'MSI_MovingRange', @intCalcId OUTPUT
	EXECUTE spEMCC_BuildDataSet 99, @intCalcId, NULL, NULL, NULL, NULL, NULL, @intUserId

	--Add inputs to the moving range calculation
	EXECUTE spEMCC_BuildDataSetUpdate 35, @intCalcId, 19, @intMRVarId, @intRangeVarId, '', NULL, @intUserId
	EXECUTE spEMCC_BuildDataSetUpdate 35, @intCalcId, 20, @intMRVarId, @intRangeVarId, '', NULL, @intUserId
	EXECUTE spEMCC_BuildDataSetUpdate 94, @intCalcId, @intMRVarId, NULL, NULL, '', '', @intUserId

END

/*
IF @intSPCTypeId = 3 BEGIN
	EXECUTE spEMCC_BuildDataSet 99, @intCalcId, NULL, NULL, NULL, NULL, NULL, @intUserId
	EXECUTE spEMCC_BuildDataSetUpdate 35, @intCalcId, 25, @intParentVarId, 0, @vcrDefaultFailure, NULL, @intUserId
END
*/

-- Before
-- SET @intCounter = 1
SET @intCounter = @intSGSizeOld + 1
SET @intChildVarId = 0
--For each variable in the subgroup
WHILE @intCounter <= @intSGSize BEGIN

	--Get the variable name...
	IF @intCounter < 10 BEGIN
		SET @vcrSSNumber = '0' + CAST(@intCounter AS VARCHAR(2)) END
	ELSE BEGIN
		SET @vcrSSNumber = CAST(@intCounter AS VARCHAR(2))
	END
	--SET @vcrVarNameTemp = @vcrVarName + '-' + @vcrSSNumber

	--... then the variable ID
	SET @intChildVarId = NULL
	SELECT @intChildVarId = var_id FROM dbo.variables WHERE pvar_id = @intParentVarId AND var_desc LIKE @vcrVarName + '-' + @vcrSSNumber + '%' 
	-- var_desc = @vcrVarNameTemp AND pu_id = @intPUId
	-- SET @intChildVarId = (SELECT MIN(Var_Id) FROM dbo.Variables WHERE PVar_Id = @intParentVarId AND Var_Id > @intChildVarId)

	IF @intChildVarId IS NOT NULL BEGIN
		SET @vcrChildName = (SELECT Var_Desc FROM dbo.Variables WHERE Var_Id  = @intChildVarId )
		IF @vcrChildName <> @vcrOldGlobalDesc + '-' + @vcrSSNumber 
		BEGIN
			SELECT	@vcrChildLocalDesc = Var_Desc_Local, 
					@vcrChildGlobalDesc = Var_Desc_Global 
				FROM dbo.Variables 
				WHERE Var_Id = @intChildVarId END
		ELSE 
		BEGIN
			SET @vcrChildGlobalDesc = @vcrGlobalDesc + '-' + @vcrSSNumber
			SET @vcrChildLocalDesc = @vcrLocalDesc + '-' + @vcrSSNumber
		END END
	ELSE BEGIN
		SET @vcrChildGlobalDesc = @vcrGlobalDesc + '-' + @vcrSSNumber
		SET @vcrChildLocalDesc = @vcrLocalDesc + '-' + @vcrSSNumber	
	END

	--If variable does not exist then ALTER
	IF @intChildVarId IS NULL 
	BEGIN
		--SELECT 'Call spEM_ALTERChildVariable with ' +  @vcrChildLocalDesc

		--SELECT 	'Call spEM_ALTERChildVariable with ', @vcrChildLocalDesc, @intParentVarId, -1, @intDataSourceId, 
		--	@intDataTypeId, @intEventTypeId, @intPrecision, 1, @intSpecId, @intTestFrequency, @intUserId

		-- Var Child
		EXECUTE spEM_ALTERChildVariable 
			@vcrChildLocalDesc, @intParentVarId, -1, @intDataSourceId, @intDataTypeId, 
			@intEventTypeId, @intPrecision, 1, @intSpecId, @intTestFrequency, @intUserId, @intChildVarId OUTPUT

		--EXECUTE @RC = [GBDB].[dbo].[spEM_ALTERChildVariable] 
		--   @vcrVarNameTemp,@intParentVarId,@parm3,@intDS_Id,@intData_Type_Id
		--  ,@intEventTypeId,@intPrecision,@intSpc_group_var_type_id,@intSpec_Id,@intTestFrequency,@intUserId,@intChildVarId OUTPUT

		UPDATE 
			dbo.variables 
		SET 
			var_desc_global = @vcrChildGlobalDesc,
			Test_Name = @vcrTestName, 
			User_Defined1 = @vcrUD1, 
			User_Defined2 = @vcrUD2, 
			User_Defined3 = @vcrUD3, 
			Extended_Info = @vcrEI,
			--Force_Sign_Entry = @bitESign,
			Eng_Units = @vcrEngUnits,
			External_Link = @vcrExtLink,
			Sampling_Interval = @intSamplingInterval,
			Sampling_Offset = @intSamplingOffset  
		WHERE 
			var_id  = @intChildVarId 
	END
	ELSE 
	BEGIN

		UPDATE dbo.variables 
		SET var_desc_global = @vcrChildGlobalDesc, 
			-- We cann't update field var_desc_local because it is derived or constant field (July 2014 - JPGalanzini - Arido)
--			var_desc_local = @vcrChildLocalDesc,
			Test_Name = @vcrTestName, 
			User_Defined1 = @vcrUD1, 
			User_Defined2 = @vcrUD2, 
			User_Defined3 = @vcrUD3, 
			Extended_Info = @vcrEI,
			--Force_Sign_Entry = @bitESign,
			Eng_Units = @vcrEngUnits,
			External_Link = @vcrExtLink,
			Sampling_Interval = @intSamplingInterval,
			Sampling_Offset = @intSamplingOffset  
		WHERE var_id  = @intChildVarId
	END

	--Add input to average, range & standard deviation calculations
	EXECUTE spEMCC_BuildDataByID 84, @intParentVarId, @intChildVarId, 0, NULL, @intUserId
	IF @intSPCTypeId NOT IN (1, 2, 3, 7) BEGIN
		EXECUTE spEMCC_BuildDataByID 84, @intRangeVarId, @intChildVarId, 0, NULL, @intUserId
		EXECUTE spEMCC_BuildDataByID 84, @intStdDevVarId, @intChildVarId, 0, NULL, @intUserId
	END

	SET @intCounter = @intCounter + 1

END

IF @intSPCTypeId = 3 BEGIN
	EXECUTE spEMCC_BuildDataSet 99, @intCalcId, NULL, NULL, NULL, NULL, NULL, @intUserId
	EXECUTE spEMCC_BuildDataSetUpdate 35, @intCalcId, 25, @intParentVarId, 0, @vcrDefaultFailure, NULL, @intUserId

	UPDATE dbo.calculation_input_data 
		SET default_value = @vcrDefaultFailure 
		WHERE result_var_id = @intParentVarId 
		AND calc_input_id = 25
END

SET NOCOUNT OFF
