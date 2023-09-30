
CREATE PROCEDURE [dbo].[spLocal_PCMT_UnobsoleteVariable]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_UnobsoleteVariable
Author:					Marc Charest (STI)	
Date Created:			2007-05-03
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3
-------------------------------------------------------------------------------------------------
Updated By	:	Stephane Turner, STI
Date			:	2008-06-25
Version		:	1.0.1
Purpose		: 	Unobsolete specification
-------------------------------------------------------------------------------------------------
Updated By	:	Jonathan Corriveau, STI
Date			:	2008-11-14
Version		:	1.0.2
Purpose		: 	Correct the stored procedure to proceed only on the selected variable
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest, STI
Date			:	2009-01-27
Version		:	1.0.3
Purpose		: 	SP was putting back too much entries into alarm templates 
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest, STI
Date		:	2009-10-15
Version		:	1.0.4
Purpose		: 	SP now calls spLocal_PCMT_UpdateEditQuery in order to verify if variable can be 
				unobsoleted or not.
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini, Arido 
Date		:	2014-07-31
Version		:	2.0
Purpose		: 	Update fields in dbo.Variables_Base Var_Desc_Global, Var_Desc and Extended_Info in PPA6
*****************************************************************************************************************
*/
--DECLARE
@intVarId				INT
AS

-- TEST
--SELECT @intVarId = 250721

SET NOCOUNT ON

DECLARE
@dtmTimestamp			DATETIME,
@intCounter				INT,
@intVarCount			INT,
@vcrEditQuery			NVARCHAR(4000),
@intMaxVarOrder			INT,
@intSheetId				INT,
@intPUId				INT,
@specid 				INT, 
@specdesc 				VARCHAR(50), 
@vcrPUDesc				VARCHAR(255),
@vcrPUGDesc				VARCHAR(255),
@vcrext					NVARCHAR(1000), 
@intf					INT,
@intt					INT


DECLARE @Sheets TABLE(
	item_id		INT IDENTITY,
	sheet_id		INT)

CREATE TABLE #Sheet_Vars(
	item_id		INT IDENTITY,
	var_id		INT,
	sheet_id		INT)

DECLARE @Variables TABLE(
	item_id			INT IDENTITY,
	query_string	VARCHAR(5000))

-- Change for PCMT ver.2.0 in PPA-6 (JPGalanzini - Arido - July 2014)
-- Change Extended_Info that it was changed when the variable was changed to obsolete
SELECT @vcrext = v.Extended_Info
	FROM variables v 
	WHERE v.var_id = @intVarId

SET @intf = CHARINDEX('DS_ID=',@vcrext)
SET @intt = CASE CHARINDEX(';',SUBSTRING(@vcrext, @intf, LEN(@vcrext))) 
				WHEN 0 THEN LEN(@vcrext)
				ELSE CHARINDEX(';',SUBSTRING(@vcrext, @intf, LEN(@vcrext))) 
			END
SET @vcrext = REPLACE(@vcrext,SUBSTRING(@vcrext, @intf, @intt),'')
--SELECT @vcrext

SET @intf = CHARINDEX('OBS=',@vcrext)
SET @intt = CHARINDEX(';',SUBSTRING(@vcrext, @intf, LEN(@vcrext)))
--SELECT @vcrext, @intf, @intt, SUBSTRING(@vcrext, @intf, @intt)
SET @vcrext = REPLACE(@vcrext,SUBSTRING(@vcrext, @intf, @intt),'')	


SET @intPUId = (SELECT pu_id FROM dbo.Local_PG_PCMT_Edit_Queries WHERE var_id = @intVarId)
SET @dtmTimestamp = (SELECT [timestamp] FROM dbo.Local_PG_PCMT_Edit_Queries WHERE var_id = @intVarId)

--Setting variables back on units
INSERT @Variables
SELECT query_string 
	FROM dbo.Local_PG_PCMT_Edit_Queries 
	WHERE [timestamp] = @dtmTimestamp AND pu_id = @intPUId AND var_id = @intVarId 

SET @intCounter = 1
SET @intVarCount = (SELECT COUNT(item_id) FROM @Variables)
--SELECT @intVarCount AS intVarCount
WHILE @intCounter <= @intVarCount BEGIN
	SET @vcrPUDesc = (SELECT pu_desc FROM dbo.variables v, dbo.prod_units pu WHERE v.pu_id = pu.pu_id AND var_id =@intVarId)
	SET @vcrPUGDesc = (SELECT pug_desc FROM dbo.variables v, dbo.pu_groups pug WHERE v.pug_id = pug.pug_id AND var_id =@intVarId)
	SET @vcrEditQuery = (SELECT query_string FROM @Variables WHERE item_id = @intCounter)

	--This call make sure that query string is compatible with PCMT current version
	EXECUTE spLocal_PCMT_UpdateEditQuery @vcrEditQuery OUTPUT

	--SELECT @vcrEditQuery AS vcrEditQuery
	--If SP returned empty string, it means we cannot unobsolete variable
	IF @vcrEditQuery = '' BEGIN
		--Cleaning local tables
		DELETE FROM dbo.Local_PG_PCMT_Edit_Queries WHERE [timestamp] = @dtmTimestamp AND pu_id = @intPUId AND var_id = @intVarId
		DELETE FROM dbo.Local_PG_PCMT_Sheet_Variables WHERE [timestamp] = @dtmTimestamp AND pu_id = @intPUId AND var_id = @intVarId
		DELETE FROM dbo.Local_PG_PCMT_Alarm_Template_Var_Data WHERE [timestamp] = @dtmTimestamp AND pu_id = @intPUId AND var_id = @intVarId
		DROP TABLE #Sheet_Vars
		SELECT -1 --Returned value
		SET NOCOUNT OFF
		RETURN
	END

	SELECT @intVarCount	--Returned value

	SET @vcrEditQuery = REPLACE(@vcrEditQuery, '[PU_Desc]', @vcrPUDesc)
	SET @vcrEditQuery = REPLACE(@vcrEditQuery, '[PUG_Desc]', @vcrPUGDesc) 
	EXECUTE sp_executeSQL @vcrEditQuery
	SET @intCounter = @intCounter + 1	
END

--Setting variables back into sheets
INSERT @Sheets
	SELECT DISTINCT sheet_id 
		FROM dbo.Local_PG_PCMT_Sheet_Variables 
		WHERE [timestamp] = @dtmTimestamp AND pu_id = @intPUId AND var_id = @intVarId

SET @intCounter = 1
SET @intVarCount = (SELECT COUNT(sheet_id) FROM @Sheets)
WHILE @intCounter <= @intVarCount BEGIN

	SET @intSheetId = (SELECT sheet_id FROM @Sheets WHERE item_id = @intCounter)

	--process only if sheet still exists
	IF EXISTS (SELECT sheet_id FROM dbo.sheets WHERE sheet_id = @intSheetId) BEGIN

		SET @intMaxVarOrder = (SELECT MAX(var_order) FROM dbo.sheet_variables WHERE sheet_id = @intSheetId)
	
		INSERT #Sheet_Vars (var_id, sheet_id)
		SELECT var_id, sheet_id FROM dbo.Local_PG_PCMT_Sheet_Variables 
		WHERE sheet_id = @intSheetId AND pu_id = @intPUId AND [timestamp] = @dtmTimestamp AND var_id = @intVarId
		ORDER BY var_id
		
		INSERT dbo.sheet_variables (var_order, var_id, sheet_id)
		SELECT @intMaxVarOrder + item_id, var_id, sheet_id
		FROM #Sheet_Vars
		ORDER BY item_id
	
		TRUNCATE TABLE #Sheet_Vars

	END

	SET @intCounter = @intCounter + 1	

END

SET @intCounter = @intCounter - 1


-------------------------------------------------
-- Setting variables back into alarm templates --
-------------------------------------------------

--NULL entries like Plant Apps Admin tool does
INSERT dbo.Alarm_Template_Var_Data(
		AT_Id, 
		Var_Id, 
		ATVRD_Id)
	SELECT
		atvd.at_id,
		atvd.var_id,
		NULL
	FROM dbo.Local_PG_PCMT_Alarm_Template_Var_Data atvd,
		dbo.variables v
	WHERE atvd.var_id = v.var_id
		AND (v.var_id = @intVarId) --OR v.pvar_id = @intVarId)		Removed on 2009-01-27 by Marc Charest (v1.0.3)

--Entries for the rules
INSERT dbo.Alarm_Template_Var_Data(AT_Id, Var_Id, ATVRD_Id)
SELECT
	atvd.at_id,
	atvd.var_id,
	atvrd.atvrd_id
FROM
	dbo.Alarm_Template_Variable_Rule_Data atvrd,
	dbo.Local_PG_PCMT_Alarm_Template_Var_Data atvd,
	dbo.variables v
WHERE
	atvrd.at_id = atvd.at_id
	AND atvd.var_id = v.var_id
	AND (v.var_id = @intVarId) --OR v.pvar_id = @intVarId)		Removed on 2009-01-27 by Marc Charest (v1.0.3)


--Cleaning local tables
DELETE FROM dbo.Local_PG_PCMT_Edit_Queries WHERE [timestamp] = @dtmTimestamp AND pu_id = @intPUId AND var_id = @intVarId
DELETE FROM dbo.Local_PG_PCMT_Sheet_Variables WHERE [timestamp] = @dtmTimestamp AND pu_id = @intPUId AND var_id = @intVarId
DELETE FROM dbo.Local_PG_PCMT_Alarm_Template_Var_Data WHERE [timestamp] = @dtmTimestamp AND pu_id = @intPUId AND var_id = @intVarId

--	Update fields
UPDATE dbo.Variables_Base
	SET Var_Desc_Global = REPLACE(REPLACE(Var_Desc_Global,'z_obs_',''),':'+RTRIM(LTRIM(STR(@intVarId))),''),
		Var_Desc = REPLACE(REPLACE(Var_Desc_Global,'z_obs_',''),':'+RTRIM(LTRIM(STR(@intVarId))),''),
		Extended_Info = @vcrext
	WHERE var_id = @intVarId
	
	
--Unobsolete specification
SET @specid = (SELECT spec_id FROM dbo.variables WHERE var_id = @intVarId)
IF @specid IS NOT NULL
BEGIN
	SET @specdesc = (SELECT spec_desc FROM dbo.specifications WHERE spec_id = @specid AND spec_desc LIKE 'z_obs_%')
	
	IF @specdesc IS NOT NULL
	BEGIN
		SET @specdesc = RIGHT(@specdesc, LEN(@specdesc) - 6)
		SET @specdesc = LEFT(@specdesc, LEN(@specdesc) - (LEN(CAST(@specid AS VARCHAR(8))) + 1))

		UPDATE 	dbo.specifications 
			SET spec_desc_local = @specdesc, spec_desc_global = @specdesc
			WHERE spec_id = @specid
	
	END
END


DROP TABLE #Sheet_Vars
RETURN
