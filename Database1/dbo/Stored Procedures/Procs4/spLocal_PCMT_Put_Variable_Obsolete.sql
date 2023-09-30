
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Put_Variable_Obsolete]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 2.1
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini, Arido 
Date		:	2014-12-22
Version		:	2.1
Purpose		:	Check @intUser_Id. it cannot be null.
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini, Arido 
Date		:	2014-10-28
Version		:	2.0
Purpose		:	Support for PPA6. Update table Variables_Base.
				When a variable become obsolete, it basically need to stop collecting data:
				e.g. interval <> 0, or tied to a calculation, or tied to an event
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest, STI
Date			:	2009-09-25
Version		:	3.3.1
Purpose		: 	I added the following when deleting the UDPs:
						"AND
						 TableId = (SELECT TableID FROM dbo.Tables WITH (NOLOCK) WHERE TableName = 'Variables')"
				This will avoid to delete UDPs from other types.
-------------------------------------------------------------------------------------------------
Updated By	:	Stephane Turner, STI
Date			:	2008-06-25
Version		:	3.3.0
Purpose		: 	Change the way specifications are obsolete
-------------------------------------------------------------------------------------------------
Updated By	:	Alex Turgeon (System Technologies for Industry Inc)
Date			:	5-aug-06
Version		:	3.2.0
Purpose		: 	Delete spec_id from variable when make a variable obsolete
					Changes the way var_spec get rid of AS_ID
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-12-06
Version		:	3.1.1
Purpose		: 	When obsoleting a variable in P4, only the Var_Desc_Local was changed.
					Now Var_Desc_Local and Var_Desc_Global get the 'z_obs_' prefix.
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-25
Version		:	3.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PSMT Version 5.0.3
					Replaced #sheet_order and #sheets temp tables by TABLE variables
					Must keep #Variables temp table because it is used in an EXEC.
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-05-31
Version		:	3.0.0
Purpose		: 	P4 Migration
					Update can no longer be done in Var_Desc and Spec_Desc fields. Those fields are calculated in P4.
					Updates must be done in Var_Desc_Local and Spec_Desc_Local fields.
					PSMT Version 3.0.0
-------------------------------------------------------------------------------------------------
Modified By	:	Marc Charest, Solutions et Technologies Industrielles Inc.
On				:	24-may-2005	
Version		:	2.0.0
Purpose		:	The SP is now processing all variables at the same time. So we changed parameter
					@intVar_Id for @vcrVarIDs. The latest one is a piped separated list of variable IDs
					PSMT Version 2.1.0
-------------------------------------------------------------------------------------------------
Modified By	:	Eric Perron, Solutions et Technologies Industrielles Inc.
On				:	07-jan-2005	
Version		:	1.0.3
Purpose		:	Add the Datasource ID in the extended_info
					if it's a calculation, remove the calculation and add the calculation_id in the extended_info also
-------------------------------------------------------------------------------------------------
Modified By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	07-May-03	
Version		:	1.0.1
Purpose		:	Delete any existing alarm for the variable. Reset display order
-------------------------------------------------------------------------------------------------
Modified By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	1-Mar-2003	
Version		:	1.0.2
Purpose		:	Remove input and ouput tag attachment
-------------------------------------------------------------------------------------------------
Created By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	23-Dec-02	
Version		:	1.0.0
Purpose		:	This sp obsolete a variable. A z_obs is put a the beginning of
               the variable name. The variable is remove from alarm templates 
               and displays.
-------------------------------------------------------------------------------------------------
*/
--declare
@vcrVarIDs				NVARCHAR(4000),
@intType				INT=null,
@intUser_Id				INT=null,
@intDetachFromParent	BIT=1

--SELECT @vcrVarIDs = 250677, @intType = 0, @intUser_Id = 1, @intDetachFromParent =  0

AS
SET NOCOUNT ON

DECLARE
	@SQLCommand			NVARCHAR(1000),
	@NbrVars			INT,
	@VarRowNum			INT,
	@PrevSheetId		INT,
	@Sheet_Id			INT,
	@Var_Id				INT,
	@intCalcMgrDS_ID	INT,
	@OldVarOrder		INT,
	@NewVarOrder		INT,
	@vcrDetachFromParent	NVARCHAR(100)

DECLARE @specs TABLE(
		specid			INT, 
		specdesc		NVARCHAR(50), 
		newspecdesc		NVARCHAR(50), 
		specidlength	INT)

DECLARE @Sheets TABLE(
		Sheet_Id		INT)

DECLARE @Sheet_Variables TABLE(
		PKey			INT identity(1,1) PRIMARY KEY NOT NULL,
		Sheet_Id		INT,
		Var_Id			INT,
		Var_Order		INT,
		New_Var_Order	INT
)

CREATE TABLE #Variables(
		item_id			INT,
		var_id			INT,
		pu_id			INT,
		var_desc_Local	NVARCHAR(50),
		var_desc_Global	NVARCHAR(50),
		ds_id			INT,
		spec_id			INT,
		calculation_id	INT,	
		Event_Type		TINYINT,
		spec_desc		NVARCHAR(50),
		pug_desc		NVARCHAR(50),
		extended_info	NVARCHAR(255))

--------------------------------------------------------------------------------------------
--Getting the variable IDs
--------------------------------------------------------------------------------------------
INSERT #Variables(item_id, var_id)
	EXECUTE spLocal_PCMT_ParseString @vcrVarIDs, NULL, '[REC]', 'INT'

--------------------------------------------------------------------------------------------
--Getting the variables infos
--------------------------------------------------------------------------------------------
SET @SQLCommand = 'UPDATE #Variables SET '
-- Complaint for Proficy 6
SET @SQLCommand = @SQLCommand + 'Var_Desc_Local = v.Var_Desc,'
SET @SQLCommand = @SQLCommand + 'Var_Desc_Global = v.Var_Desc_Global,'
SET @SQLCommand = @SQLCommand + 'ds_id = v.ds_id, pu_id = v.pu_id, spec_id = v.spec_id, '
SET @SQLCommand = @SQLCommand + 'calculation_id = v.calculation_id, '
SET @SQLCommand = @SQLCommand + 'Event_Type = v.Event_Type, '
-- Complaint for Proficy 6
SET @SQLCommand = @SQLCommand + 'Spec_Desc = s.Spec_Desc_Local, '
SET @SQLCommand = @SQLCommand + 'pug_desc = pug.PUG_Desc, extended_info = v.extended_info '
SET @SQLCommand = @SQLCommand + 'from #Variables vv '
SET @SQLCommand = @SQLCommand + 'join dbo.Variables_Base v on (v.var_id = vv.var_id) '
--SET @SQLCommand = @SQLCommand + 'from #Variables vv, dbo.Variables v '
SET @SQLCommand = @SQLCommand + 'join dbo.PU_Groups pug on (pug.pug_id = v.pug_id) '
SET @SQLCommand = @SQLCommand + 'left join dbo.Specifications s on (s.spec_id = v.spec_id) '

EXEC sp_executesql @SQLCommand

--Inserting all child variables
INSERT INTO #Variables(
			var_id, 
			pu_id, 
			var_desc_Local, 
			var_desc_Global, 
			ds_id, spec_id, 
			calculation_id, 
			Event_Type,
			spec_desc, 
			pug_desc, 
			extended_info)
	SELECT	v2.var_id, 
			v.pu_id, 
			v2.var_desc, 
			v2.var_desc_Global, 
			v.ds_id, 
			v.spec_id, 
			NULL, 
			v2.Event_Type,
			v.spec_desc, 
			v.pug_desc, 
			v.extended_info
		FROM #Variables			v 
		JOIN dbo.Variables_Base v2 ON v2.pvar_id = v.var_id
--FROM dbo.variables v2, #Variables v
	--Child variables
	--WHERE v2.pvar_id = v.var_id

--Inserting all child variables and _AL variables
INSERT INTO #Variables(
			var_id, 
			pu_id, 
			var_desc_Local, 
			var_desc_Global, 
			ds_id, 
			spec_id, 
			calculation_id, 
			v2.Event_Type,
			spec_desc, 
			pug_desc, 
			extended_info)
	SELECT	v2.var_id, 
			v.pu_id, 
			v2.var_desc, 
			v2.var_desc_Global, 
			v.ds_id, 
			v.spec_id, 
			NULL, 
			v2.Event_Type,
			v.spec_desc, 
			v.pug_desc, 
			v.extended_info
		FROM #Variables			v 
		JOIN dbo.Variables_Base v2	ON v2.pu_id = v.pu_id 
		JOIN dbo.pu_groups		pug ON v2.pug_id = pug.pug_id 
		--FROM dbo.variables v2, #Variables v, dbo.pu_groups pug
		--_AL variables
		WHERE pug.pug_desc = 'QA Alarms' 
			AND v2.extended_info = CAST(v.var_id AS NVARCHAR(10))

--------------------------------------------------------------------------------------------
--Removing alarms
--------------------------------------------------------------------------------------------
DELETE
--select 'alarms', *
FROM dbo.Alarm_history
WHERE alarm_id IN (select alarm_id
		   FROM dbo.Alarms
		   WHERE atd_id IN (SELECT atd_id
                 		    FROM dbo.Alarm_Template_Var_Data
                 		    WHERE var_id IN (SELECT var_id FROM #Variables)))

DELETE
--select 'alarms', *
FROM dbo.Alarms
WHERE atd_id IN (SELECT atd_id
                 FROM dbo.Alarm_Template_Var_Data
                 WHERE var_id IN (SELECT var_id FROM #Variables))

--------------------------------------------------------------------------------------------
--Removing the variables from the alarm templates
--------------------------------------------------------------------------------------------
DELETE 
--select 'alarm templates', *
	FROM dbo.Alarm_Template_Var_Data
	WHERE var_id IN (SELECT var_id FROM #Variables)

--------------------------------------------------------------------------------------------
--Removing the variable from the displays
--------------------------------------------------------------------------------------------
-- 1.
-- We get all the Sheets (Sheet_Id) on which we want to delete variables
INSERT @Sheets (Sheet_Id)
	SELECT DISTINCT S.Sheet_Id
	FROM dbo.Sheets				S 
	JOIN dbo.Sheet_Variables	SV ON S.Sheet_Id = SV.Sheet_Id
	WHERE SV.Var_Id IN (SELECT Var_Id FROM #Variables) AND
		S.Sheet_Type <> 11				--don't want to re-order alarm displays

-- 2.
-- We delete from the sheets all the variables being under the obsoleting process
DELETE
--select 'displays', *
	FROM dbo.Sheet_Variables
	WHERE Var_Id IN (SELECT var_id FROM #Variables)

-- 3.
-- We get all remaining variables on all sheets affected by obsolete process
INSERT @Sheet_Variables (Sheet_Id, Var_Id, Var_Order)
	SELECT Sheet_Id, Var_Id, Var_Order 
	FROM dbo.Sheet_Variables
	WHERE Sheet_Id IN (SELECT Sheet_Id FROM @Sheets)
	ORDER BY Sheet_Id,Var_Order

-- 4.
-- We calculate the new variable order
-- Initialize loop variables (Sheets)
SET @NbrVars = (SELECT MAX(PKey) FROM @Sheet_Variables)
SET @VarRowNum = 1
SET @NewVarOrder = 1
SET @PrevSheetId = 0

-- Loop through all variables of every sheet
WHILE @VarRowNum <= @NbrVars
	BEGIN
		SELECT @Sheet_Id = Sheet_Id 
			FROM @Sheet_Variables 
			WHERE PKey = @VarRowNum

		IF @Sheet_Id <> @PrevSheetId
		BEGIN
			SET @PrevSheetId = @Sheet_Id
			SET @NewVarOrder = 1
		END
		
		UPDATE @Sheet_Variables 
			SET New_Var_Order = @NewVarOrder 
			WHERE PKey = @VarRowNum
		
		SET @NewVarOrder = @NewVarOrder + 1
		SET @VarRowNum = @VarRowNum + 1
	END

-- 5.
-- We update the database with new Var_Orders
UPDATE dbo.Sheet_Variables 
	SET Var_Order = SV2.New_Var_Order
--select 'displays', *
FROM dbo.Sheet_Variables	SV
JOIN @Sheet_Variables		SV2 ON SV.Sheet_Id = SV2.Sheet_Id AND SV.Var_Order = SV2.Var_Order
WHERE ((SV.Var_Id IS NULL) OR (SV.Var_Id = SV2.Var_Id))
	
--------------------------------------------------------------------------------------------
--Updating variable fields
--------------------------------------------------------------------------------------------
--1. Updating var_desc & extended_info from the #variables table
UPDATE #variables
SET
	var_desc_Local = 	'z_obs_' 
							+ 
							cast(var_desc_Local AS NVARCHAR(37)) 
							+ 
							':' 
							+ 
							cast(var_id AS NVARCHAR(6)),
							
	var_desc_Global = 'z_obs_' 
							+ 
							cast(var_desc_Global AS NVARCHAR(37)) 
							+ 
							':' 
							+ 
							cast(var_id AS NVARCHAR(6)),

	extended_info =	SUBSTRING(
								extended_info,
								1,
								CHARINDEX('TT=', extended_info) + 2) 
							+
                  	SUBSTRING(
								extended_info,
								CHARINDEX(';',extended_info,CHARINDEX('TT=',extended_info)+3),
								LEN(extended_info) - CHARINDEX(';',extended_info,CHARINDEX('TT=',extended_info)+3) + 1) 
							+
                 		';OBS=' + CONVERT(NVARCHAR(8),GETDATE(),11)

--2. Updating extended_info again
UPDATE #Variables
	SET extended_info = extended_info + ';DS_ID=' + CONVERT(NVARCHAR(10),ds_id)

--3. Updating calculation_id and extended_info (once again)
SELECT @intCalcMgrDS_ID = 16

UPDATE #variables
	SET	extended_info = extended_info + ';Calc_ID=' + CONVERT(NVARCHAR(10),calculation_id),
		calculation_id = NULL
	WHERE ds_id = @intCalcMgrDS_ID

--------------------------------------------------------------------------------------------
--Obsolete actual specs
--------------------------------------------------------------------------------------------
UPDATE dbo.var_specs
	SET as_id = NULL, expiration_date = COALESCE(expiration_date, GETDATE())
--select 'actual specs', *
	FROM dbo.var_specs	vs
	JOIN #variables		v ON v.var_id = vs.var_id
	WHERE vs.as_id IS NOT NULL

--5. Finally we update GBDB
SET @vcrDetachFromParent = ''
IF @intDetachFromParent = 1 BEGIN
	SET @vcrDetachFromParent = 'pvar_id = NULL, '
END

-- Description field(s) is/are not the same for each Proficy version
--SET @SQLCommand = 'UPDATE dbo.Variables SET Calculation_Id = NULL,'
SET @SQLCommand = 'UPDATE dbo.Variables_Base SET Calculation_Id = NULL,'
-- Complaint for Proficy 6
SET @SQLCommand = @SQLCommand + 'Var_Desc = vv.var_desc_Local, '
SET @SQLCommand = @SQLCommand + 'Var_Desc_Global = vv.var_desc_Global, '

SET @SQLCommand = @SQLCommand + 
	'	pug_order = 9999, 
		sampling_interval = 0, 
		sampling_offset = 0,
		Event_Type = 0, 
		extended_info = vv.extended_info, 
		input_tag = NULL, 
		output_tag = NULL, 
		DQ_tag = NULL, 
		Comparison_Operator_Id = NULL, 
		Comparison_Value = NULL, 
		ds_id = 4, 
		spec_id = NULL, ' + @vcrDetachFromParent +
		'user_defined1 = NULL, 
		user_defined2 = NULL, 
		user_defined3 = NULL 
		FROM dbo.variables_Base v
		JOIN #Variables vv ON v.var_id = vv.var_id'

--SELECT @SQLCommand SQLCommand
--SELECT '#Variables', * FROM #Variables
EXEC sp_executesql @SQLCommand

--------------------------------------------------------------------------------------------
--Deleting UDPs
--------------------------------------------------------------------------------------------
DELETE FROM Table_Fields_Values 
--select 'actual specs', * from Table_Fields_Values
	WHERE keyid IN (SELECT var_id FROM #Variables) 
		AND TableId = (SELECT TableID FROM dbo.Tables WITH (NOLOCK) WHERE TableName = 'Variables')

--insert sti_test (entry_on, sp_name) values (getdate(), 'updatin variables fields')

--------------------------------------------------------------------------------------------
--Obsolete specifications not used by non-obsoleted variables
--------------------------------------------------------------------------------------------
INSERT INTO @specs(specid, specdesc, specidlength)
SELECT DISTINCT spec_id, spec_desc, LEN(CAST(spec_id AS NVARCHAR(8)))
	FROM dbo.specifications 
	WHERE spec_desc NOT LIKE 'z_obs_%' 
		AND spec_id IN(SELECT spec_id FROM #variables) 
		AND	spec_id NOT IN(SELECT spec_id FROM variables WHERE spec_id IS NOT NULL AND var_desc NOT LIKE 'z_obs_%')

UPDATE @specs 
	SET newspecdesc = 'z_obs_' + LEFT(specdesc, 43 - specidlength) + ':' + CAST(specid AS NVARCHAR(8))

UPDATE dbo.specifications 
	SET spec_desc_local = (SELECT newspecdesc FROM @specs WHERE specid = spec_id)
--select 'actual specs', * from dbo.specifications 
	WHERE spec_id IN(SELECT specid FROM @specs)

UPDATE dbo.specifications 
	SET spec_desc_global = (SELECT newspecdesc FROM @specs WHERE specid = spec_id)
--select 'actual specs', * from dbo.specifications 
	WHERE spec_id IN(SELECT specid FROM @specs)

--------------------------------------------------------------------------------------------
--	Check @intUser_Id
--------------------------------------------------------------------------------------------
IF (@intUser_Id IS NULL) 
BEGIN
	SET @intUser_Id = 1
END

--------------------------------------------------------------------------------------------
--Log this transaction in the variable log
--------------------------------------------------------------------------------------------
INSERT dbo.Local_PG_PCMT_Log_Variables 
	([Timestamp], [user_id], type, pu_id, var_id, pug_desc, var_desc)
SELECT GETDATE(), @intUser_Id, 'Obsolete', pu_id, var_id, pug_desc, var_desc_local
	FROM #variables

DROP TABLE #variables

SELECT 1

SET NOCOUNT OFF
