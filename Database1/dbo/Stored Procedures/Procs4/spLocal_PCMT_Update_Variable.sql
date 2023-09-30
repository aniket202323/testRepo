
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Update_Variable]
/*
-------------------------------------------------------------------------------------------------------------------------
Author			:	Rick Perreault, Solutions et Technologies Industrielles Inc.
Date ALTERd		:	12-Nov-02	
Version			:	1.0.0
SP Type			:	function
Called by		:	excel file
Description		:	This sp add a variable to proficy, ALTER production group if
               	if required, associate the variable to displays and template.
-------------------------------------------------------------------------------------------------
revision date who what
-------------------------------------------------------------------------------------------------------------------------
Modified By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On		:	19-Sep-02	
Version		:	1.0.1
Purpose		:	Update the specification precision and precision of all variable attached to it
-------------------------------------------------------------------------------------------------------------------------
Modified By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On		:	1-Mar-2003	
Version		:	1.2.0
Purpose		:	External Link have been added.
					PSMT Version 2.1.0
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date		:	2005-05-31
Version		:	2.0.0
Purpose		: 	P4 Migration
					Update can no longer be done in Var_desc and PUG_Desc fields. Those fields are calculated in P4.
					Updates must be done in Var_Desc_Local and PUG_Desc_Local fields.
					PSMT Version 3.0.0
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date		:	2005-11-25
Version		:	2.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PSMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date		:	2006-06-02Version		:	3.0.0
Purpose		: 	Added table fields values, ALTERs unit if it doesn't exists
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Eric Perron (System Technologies for Industry Inc)
Date		:	2006-06-27
Version		:	3.1.0
Purpose		: 	Bug fix.
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Patrick-Daniel Dubois (System Technologies for Industry Inc)
Date			:	2008-04-22
Version		:	4.0.0  => Compatible with PCMT version 1.7 and higher
Purpose		: 	Modified to be able to manage child variables
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Benoit Saenz de Ugarte (System Technologies for Industry Inc)
Date			:	2008-06-18
Version		:	4.0.1  => Compatible with PCMT version 1.7 and higher
Purpose		: 	Update Child variables even if the group size not change.
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2008-09-17
Version		:	4.0.2  => Compatible with PCMT version 1.7 and higher
Purpose		: 	It fixes a bug where the _AL variable was set with the pug_id and extended_info from the main variable
Service Call:	22294708
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2008-11-19
Version		:	4.0.3
Purpose		: 	Update alarm variables: add fields Sampling_Interval and Sampling_Offset
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2008-12-02
Version		:	4.0.4
Purpose		: 	I added an UPDATE instruction right after the EXECUTE spEM_DropVariable call
					because this spEM does not update the Var_Desc_Global field.
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2009-01-27
Version		:	4.0.5
Purpose		: 	Resolving key violation when editing variables. It happened when variables had a "-" somewhere into 
					the description except before the child number suffix (ex. My-Quality-Var-01).
					PCMT was creating new child variables instead of renaming older one at the time one tried to change 
					local description for a variable that has children.
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2009-01-29
Version		:	4.0.6
Purpose		: 	When upsizing subgroup size, PCMT misses to put records into the Alarm_Template_Var_Data for 
					the extra variables.
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2009-04-09
Version		:	4.1.0
Purpose		: 	I changed code to make PCMT able to manage parent variables that have children differently named. 
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2009-05-11
Version		:	4.2.0
Purpose		: 	frmVariableAdd form has new features to manage display-templates. We added code to SP to manage these
					new features.
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini (Arido Software)
Date		:	2013-02-13
Version		:	4.2.1
Purpose		: 	Fixed issue when user changed SubGroup Size, Update all UDPs and user_defined values for parent and child variables (if needed)
				in the Table_Fields_Values table had an Primary Key violation, adding a DISTINCT to avoid this issue (Line 1232)
-------------------------------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini (Arido Software)
Date		:	2015-01-20
Version		:	2.1
Purpose		: 	Complaint with PPA6
-------------------------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_PCMT_Update_Variable 6,38,'Utility Variables',3855,'NewName',0,2,
											 'Amps',null,null,2,3,0,0,0,null,null,1,'VT=PAM;RPT=N;TT=010030;VC=N;',null,null,null,null
-------------------------------------------------------------------------------------------------------------------------
*/

@intPLId						int = NULL,
@vcrPUDesc  				varchar(50) = NULL,
@intPUG_Id					int = NULL,
@vcrPUG_desc				varchar(50) = NULL,
@intVar_id					int,
@vcrGlobalDesc				varchar(50) = NULL,
@tintEvent_Type			tinyint = NULL,
@intDS_Id					int = NULL,
@vcrEng_Units				varchar(15) = NULL,
@intST_Id					int = NULL,
@intBase_Var_Id			int = NULL,
@intData_Type_Id			int = NULL,
@tintVar_Precision		tinyint = 0,
@sintSampling_Interval	smallint = NULL,
@sintSampling_Offset		smallint = NULL, 
@tintRepeating				tinyint = NULL,
@intRepeat_Backtime		int = NULL,
@intSpec_Id					int = NULL,
@tintSA_Id					tinyint = NULL,
@vcrUserDefined1			varchar(255) = NULL,
@intCalculation_Id		int = NULL,
@vcrInput_Tag				varchar(100) = NULL, 
@vcrOutput_Tag				varchar(100) = NULL,
@vcrDQ_Tag						VARCHAR(255) = NULL,
@vcrComparison_Operator_Id	INTEGER = NULL,
@vcrComparison_Value			VARCHAR(50) = NULL,
@vcrExternal_Link			varchar(255) = NULL,
@intAlarm_Template_Id	INT = NULL,
@intAlarm_Display_Id		INT = NULL,
@intAutolog_Display_Id	INT = NULL,
@intAutolog_Display_Order	INT = NULL,
@vcrUserDefined2			varchar(255) = NULL,
@vcrUserDefined3			varchar(255) = NULL,
@vcrExtendedInfo			varchar(255) = NULL,
@tintEventSubtype			tinyint = NULL,
@vcrVar_Desc				varchar(50) = NULL,
@vcrTestName				varchar(255) = NULL,
@vcrTableFieldValues		VARCHAR(8000) = NULL,
@vcrTableFieldIDs			VARCHAR(8000) = NULL,
@bitForceSignEntry			BIT = 0,
@intUser_Id					int = 55,
@intPVar_Id					INTEGER = NULL,
@intSPCTypeId				INTEGER = NULL,
@vcrSPCFailure				VARCHAR(255) = NULL,
@intSGSizeOld				INTEGER = NULL,
@intSGSize					INTEGER = NULL,
@vcrEIs						VARCHAR(8000) = '',
@vcrUDPs					VARCHAR(8000) = ''


AS

SET NOCOUNT ON

DECLARE 
@intOrder 					int,
@intOldSpecId				int,
@dtmTimestamp				datetime,
@AppVersion					varchar(30),		-- Used to retrieve the Proficy database Version
@FieldName					varchar(50),
@SQLCommand					nvarchar(2000),
@SQLCommandTemp			nvarchar(2000),
@intPU_Id					int,
@intALTERUnit				int,
@TableId						int,
@FieldId						int,
@intTableId					INTEGER,
@intQAVarId					INTEGER,
@intPropID					INTEGER,
@intQASpecID				INTEGER,
@intMaxOrder				INTEGER,
@intMaxVarId				INTEGER,
@intDifference				INTEGER,
@intOffset					INTEGER,
@vcrIndividualIDs 		VARCHAR(8000),
@vcrIndividualValues		VARCHAR(8000),
@vcrIndividualVarDesc	VARCHAR(255),
@intIndividualVarId		INTEGER,
@intCounter					INTEGER,

--> Added by PDD
@vcrVarNameTemp			VARCHAR(50),
@intChildVarId 			INTEGER,
@vcrSSNumber				VARCHAR(2),
@vcrOldVarDesc				VARCHAR(50),
	
@vcrChildGlobalDesc		VARCHAR(255),
@vcrChildLocalDesc		VARCHAR(255),
@vcrChildName				VARCHAR(255),

@DoInsert						BIT,
@Old_AT_Id						INT,
@Old_Sheet_Id					INT,
@intAlarm_Display_Order		INT,
@Down								INT,
@NextVarOrder					INT,
@OldVarOrder					INT

CREATE TABLE #TempOrder(
	New_Order	INT IDENTITY,
	Old_Order	INT,
	Var_Id		INT
)

-- contains all line descriptions
DECLARE @PlDescs TABLE (
	LineDesc		varchar(50))

CREATE TABLE #TableFieldIds(
	item_id				INTEGER,
	Table_Field_Id		INTEGER
)

CREATE TABLE #TableFieldValues(
	item_id				INTEGER,
	Table_Field_Value	VARCHAR(8000)
)

CREATE TABLE #Extended_Infos(
	Item_Id				INTEGER,
	Var_Name				VARCHAR(255),
	EI						VARCHAR(255),
	UD1					VARCHAR(255),
	UD2					VARCHAR(255),
	UD3					VARCHAR(255))

CREATE TABLE #AllUDPs(
	Item_Id				INTEGER,
	Var_Name				VARCHAR(255),
	UDPs					VARCHAR(7750))

--SELECT 'START'

IF @intPVar_Id = 0 BEGIN
	SET @intPVar_Id = NULL
END

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

SET @intALTERUnit = 0

-- retreive the pu_id from unit description
SET @intPU_Id = (SELECT pu_id FROM dbo.prod_units WHERE pu_desc = @vcrPUDesc AND pl_id = @intPLId)

IF @intPU_Id IS NULL
BEGIN
	SET @intALTERUnit = 1	
END
ELSE
BEGIN
	-- verify if unit already exists on the line
	IF NOT EXISTS(SELECT pl_id FROM dbo.prod_units WHERE pu_id = @intPU_Id and pl_id = @intPLId)
	BEGIN
		SET @intALTERUnit = 1	
	END
END
--SELECT 'STEP 1'

IF @intALTERUnit = 1
BEGIN
	-- get all line descriptions
	INSERT INTO @PlDescs (LineDesc)
		SELECT pl_desc 
		FROM dbo.prod_lines 

	-- verify if the unit desc contains a line desc, if so replaces the line desc in the unit desc
	IF (SELECT COUNT(LineDesc) 
		 FROM @PlDescs 
		 WHERE LineDesc LIKE '%' + SUBSTRING(@vcrPUDesc, 1, CHARINDEX(' ', @vcrPUDesc, 1) - 1) + '%') > 0
	BEGIN
		SET @vcrPUDesc = (SELECT pl_desc FROM dbo.prod_lines WHERE pl_id = @intPLId) + ' ' + 
							   SUBSTRING(@vcrPUDesc, CHARINDEX(' ', @vcrPUDesc, 1) + 1,
															 LEN(@vcrPUDesc) - CHARINDEX(' ', @vcrPUDesc, 1) + 1)

	END

	-- verify if the unit already exists on the line
	IF NOT EXISTS(SELECT pl_id FROM dbo.prod_units WHERE pu_desc = @vcrPUDesc AND pl_id = @intPLId)
	BEGIN
		-- ALTER the production unit
		SELECT @intOrder = ISNULL(MAX(pu_order),0) + 1
		FROM dbo.prod_units
		WHERE pl_id = @intPLId

		-- Description field is not the same for each Proficy version
		IF @AppVersion LIKE '4%'
		BEGIN
			SET @FieldName = 'PU_Desc_Local'	-- P4
		END

		ELSE
		BEGIN

			SET @FieldName = 'PU_Desc'			-- P3
		END
	
		SET @SQLCommand = 'INSERT INTO prod_units (PL_Id,' + @FieldName + ',PU_Order) VALUES (' + 
								ISNULL(CONVERT(varchar, @intPLId),'NULL') + ','+ 
								ISNULL('''' + @vcrPUDesc + '''','NULL') + ',' +
								ISNULL(CONVERT(varchar,@intOrder),'NULL') + ')'
	
		EXEC sp_ExecuteSQL @SQLCommand

		-- Get the Id of the new prod unit ALTERd
	   SELECT @intPU_Id = pu_id
	   FROM dbo.prod_units
	   WHERE pu_desc = @vcrPUDesc
	END
	ELSE
	BEGIN
		-- Get the Id of the existing unit
	   SELECT @intPU_Id = pu_id
	   FROM dbo.prod_units
	   WHERE pu_desc = @vcrPUDesc
	END
END
--SELECT 'STEP 2'


-- retreive pug_id on the unit
SET @intPUG_Id = (SELECT pug_id FROM dbo.pu_groups WHERE pug_desc = @vcrPug_Desc AND pu_id = @intPU_Id)

--Manage the production group
IF (@intPUG_Id IS NULL) AND (@vcrPug_Desc IS NOT NULL)
BEGIN
	SELECT @intOrder = ISNULL(MAX(pug_order),0) + 1
	FROM dbo.PU_Groups
	WHERE pu_id = @intPu_Id
 
	-- Description field is not the same for each Proficy version
	IF @AppVersion LIKE '4%'
	BEGIN
		SET @FieldName = 'PUG_Desc_Local'	-- P4
	END

	ELSE
	BEGIN
		SET @FieldName = 'PUG_Desc'			-- P3
	END

	-- ALTER dynamic SQL to be able to refer to correct field for P3 and P4
	SET @SQLCommand =	'INSERT dbo.PU_Groups (PU_Id,' + @FieldName + ',PUG_Order) '
	SET @SQLCommand = @SQLCommand + 'VALUES('
	SET @SQLCommand = @SQLCommand + ISNULL(CONVERT(nvarchar,@intPu_Id),'NULL') + ','
	SET @SQLCommand = @SQLCommand + ISNULL('''' + @vcrPug_Desc + '''','NULL') + ','
	SET @SQLCommand = @SQLCommand + ISNULL(CONVERT(nvarchar,@intOrder),'NULL') + ')'

	EXEC sp_executesql @SQLCommand
	
	SELECT @intPug_Id = PUG_Id
	FROM dbo.PU_Groups
	WHERE (Pu_Id = @intPu_Id) AND (PUG_Desc = @vcrPug_Desc)

	--Log this transaction in the production groups log
	INSERT INTO dbo.Local_PG_PCMT_Log_ProductionGroups ([Timestamp], [User_Id], Type, PU_Id, PUG_Desc)
		VALUES (getdate(), @intUser_Id, 'Add', @intPU_Id, @vcrPUG_Desc)
END

--SELECT 'STEP 3'
--Get the old spec_id
SET @intOldSpecId = (SELECT Spec_Id FROM dbo.Variables WHERE Var_Id = @intVar_id)

--Update spec precision and the attached variable precision
IF @intSpec_Id IS NOT NULL 
BEGIN
	UPDATE dbo.Specifications
	SET spec_precision = @tintVar_Precision
	WHERE spec_id = @intSpec_Id

	-- Complaint with PPA6
	UPDATE dbo.Variables_Base
		SET var_precision = @tintVar_Precision
		WHERE spec_id = @intSpec_Id

	--UPDATE dbo.Variables
	--SET var_precision = @tintVar_Precision
	--WHERE spec_id = @intSpec_Id
END

--Update the variable
-- Description field is not the same for each Proficy version
SET @FieldName = 'Var_Desc'			-- P3

-- Getting old local description before updating variable (in the case user just changed the local description)
SET @vcrOldVarDesc = (SELECT Var_Desc_Local FROM dbo.Variables WHERE Var_Id = @intVar_id)		

-- Complaint with PPA6
--SET @SQLCommand =	'UPDATE dbo.Variables '
SET @SQLCommand =	'UPDATE dbo.Variables_Base '
SET @SQLCommand = @SQLCommand + 'SET Repeat_Backtime = ' + ISNULL(CONVERT(nvarchar,@intRepeat_Backtime),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Data_Type_Id = ' + ISNULL(CONVERT(nvarchar,@intData_Type_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'DS_Id = ' + ISNULL(CONVERT(nvarchar,@intDS_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Spec_Id = ' + ISNULL(CONVERT(nvarchar,@intSpec_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'PU_Id = ' + ISNULL(CONVERT(nvarchar,@intPU_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'PUG_Id = ' + ISNULL(CONVERT(nvarchar,@intPUG_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Sampling_Interval = ' + ISNULL(CONVERT(nvarchar,@sintSampling_Interval),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Sampling_Offset = ' + ISNULL(CONVERT(nvarchar,@sintSampling_Offset),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Repeating = ' + ISNULL(CONVERT(nvarchar,@tintRepeating),'NULL') + ','

SET @SQLCommand = @SQLCommand + 'SA_Id = ' + ISNULL(CONVERT(nvarchar,@tintSA_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Force_Sign_Entry = ' + ISNULL(CONVERT(nvarchar,@bitForceSignEntry),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Event_Type = ' + ISNULL(CONVERT(nvarchar,@tintEvent_Type),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Var_Precision = ' + ISNULL(CONVERT(nvarchar,@tintVar_Precision),'NULL') + ','

IF (SELECT var_desc FROM dbo.variables WHERE var_id = @intVar_id) != @vcrVar_Desc
BEGIN
	SET @SQLCommand = @SQLCommand + @FieldName + ' = ' + ISNULL('''' + @vcrVar_Desc + '''','NULL') + ','
END

SET @SQLCommand = @SQLCommand + 'Eng_Units = ' + ISNULL('''' + @vcrEng_Units + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'Test_Name = ' + ISNULL('''' + @vcrTestName + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'User_Defined1 = ' + ISNULL('''' + @vcrUserDefined1 + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'User_Defined2 = ' + ISNULL('''' + @vcrUserDefined2 + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'User_Defined3 = ' + ISNULL('''' + @vcrUserDefined3 + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'Extended_Info = ' + ISNULL('''' + @vcrExtendedInfo + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'Output_Tag = ' + ISNULL('''' + @vcrOutput_Tag + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'DQ_Tag = ' + ISNULL('''' + @vcrDQ_Tag + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'Comparison_Operator_Id = ' + ISNULL(CONVERT(nvarchar,@vcrComparison_Operator_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Comparison_Value = ' + ISNULL('''' + @vcrComparison_Value + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'Sampling_Type = ' + ISNULL(CONVERT(nvarchar,@intST_Id),'NULL') + ','
-- Base_Var_Id is no longer exists in P4, so discarded from PSMT
-- SET @SQLCommand = @SQLCommand + 'Base_Var_Id = ' + ISNULL(CONVERT(nvarchar,@intBase_Var_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Input_Tag = ' + ISNULL('''' + @vcrInput_Tag + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'Calculation_Id = ' + ISNULL(CONVERT(nvarchar,@intCalculation_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'External_Link = ' + ISNULL('''' + @vcrExternal_Link + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'var_desc_global = ' + ISNULL('''' + @vcrGlobalDesc + '''','NULL')			
SET @SQLCommand = @SQLCommand + ' WHERE Var_Id = ' + CONVERT(nvarchar,'@intVar_id')

SET @SQLCommandTemp = @SQLCommand
SET @SQLCommandTemp = REPLACE(@SQLCommandTemp, '@intVar_id', CONVERT(nvarchar,@intVar_id))

EXEC sp_executesql @SQLCommandTemp


/*********************************************************************************/

--> Added by PDD
IF @intSPCTypeId = -1 AND @intSGSize <> @intSGSizeOld BEGIN

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
			SET @vcrVarNameTemp = @vcrVar_Desc + '-' + @vcrSSNumber	
			SET @intChildVarId = NULL
			--SELECT @intChildVarId = var_id FROM dbo.variables WHERE var_desc = @vcrVarNameTemp AND pu_id = @intPU_Id
			SELECT @intChildVarId = MAX(var_id) FROM dbo.variables WHERE PVar_Id = @intVar_id		

			--Dropping variable
			IF @intChildVarId IS NOT NULL BEGIN
				EXECUTE spEM_DropVariable @intChildVarId, @intUser_Id		--Variable itself
				EXECUTE spEM_DropVariableSlave @intChildVarId	--Sheet and calculation instances

				-- Complaint with PPA6
				--UPDATE dbo.Variables 
					--SET Var_Desc_Global = Var_Desc_Local WHERE Var_Id = @intChildVarId		
				UPDATE dbo.Variables_Base 
					SET Var_Desc_Global = Var_Desc WHERE Var_Id = @intChildVarId		
				
			END

			SET @intCounter = @intCounter - 1
		END
	END
END

--Upsizing subgroup size if needed
--IF @intSGSize > @intSGSizeOld BEGIN		-- 2008-06-18: Comment by Benoit to update child when parent change
	SET @intCounter = 1
	SET @intChildVarId = 0
	--For each variable in the subgroup
	WHILE @intCounter <= @intSGSize BEGIN

		--Get the variable name...
		IF @intCounter < 10 BEGIN
			SET @vcrSSNumber = '0' + CAST(@intCounter AS VARCHAR(2)) END
		ELSE BEGIN
			SET @vcrSSNumber = CAST(@intCounter AS VARCHAR(2))
		END

		SET @intChildVarId = (SELECT MIN(Var_Id) FROM dbo.Variables WHERE PVar_Id = @intVar_id AND Var_Id > @intChildVarId AND Calculation_Id IS NULL)
		
		IF @intChildVarId IS NOT NULL BEGIN
			SET @vcrChildName = (SELECT Var_Desc FROM dbo.Variables WHERE Var_Id  = @intChildVarId )
			IF @vcrChildName <> @vcrOldVarDesc + '-' + @vcrSSNumber BEGIN
				SELECT @vcrChildLocalDesc = Var_Desc_Local, @vcrChildGlobalDesc = Var_Desc_Global FROM dbo.Variables WHERE Var_Id = @intChildVarId END		
				
			ELSE BEGIN
				SET @vcrChildGlobalDesc = @vcrGlobalDesc + '-' + @vcrSSNumber
				SET @vcrChildLocalDesc = @vcrVar_Desc + '-' + @vcrSSNumber
			END END
		ELSE BEGIN
			SET @vcrChildGlobalDesc = @vcrGlobalDesc + '-' + @vcrSSNumber
			SET @vcrChildLocalDesc = @vcrVar_Desc + '-' + @vcrSSNumber	
		END

		--If variable does not exist then ALTER
		IF @intChildVarId IS NULL BEGIN
			EXECUTE spEM_ALTERChildVariable 
					@vcrChildLocalDesc, @intVar_id, -1, @intDS_Id, @intData_Type_Id, @tintEvent_Type, 
					@tintVar_Precision, 1, @intSpec_Id, @sintSampling_Interval, @intUser_Id, @intChildVarId OUTPUT

			-- Complaint with PPA6
			--UPDATE dbo.Variables 
			UPDATE dbo.Variables_Base 
				SET var_desc_global = @vcrChildGlobalDesc,		
					Sampling_Offset = @sintSampling_Offset,
					Repeating =	@tintRepeating, 
					Event_Subtype_Id = @tintEventSubtype,
					Eng_Units = @vcrEng_Units,
					External_Link = @vcrExternal_Link
				WHERE var_id  = @intChildVarId END
		ELSE BEGIN

			-- Complaint with PPA6
			--UPDATE dbo.Variables 
			UPDATE dbo.Variables_Base 
			SET 
				PUG_Order = -1, 
				DS_Id = @intDS_Id, 
				Data_Type_Id = @intData_Type_Id, 
				Event_Type = @tintEvent_Type, 
				Var_Precision = @tintVar_Precision, 
				SPC_Group_Variable_Type_Id = 1, 
				Spec_Id = @intSpec_Id, 
				Sampling_Interval = @sintSampling_Interval,
				Sampling_Offset = @sintSampling_Offset,
				Repeating =	@tintRepeating, 
				Event_Subtype_Id = @tintEventSubtype,
				Eng_Units = @vcrEng_Units,
				External_Link = @vcrExternal_Link,
				var_desc_global = @vcrChildGlobalDesc 
				-- We cann't update field var_desc_local because it is derived or constant field 
				--var_desc_local = @vcrChildLocalDesc
				--var_desc = @vcrChildGlobalDesc 				
			WHERE 
				var_id  = @intChildVarId
			
		END

		SET @intCounter = @intCounter + 1

	END
--END
/*********************************************************************************/



IF @intSPCTypeId <> -1 AND @intPVar_Id IS NULL BEGIN

	EXECUTE spLocal_PCMT_SetSPCCalc 
		@intUser_Id,
		@intPU_Id,
		@intPUG_Id,
		@vcrVar_Desc,
		@intSGSizeOld,
		@intSGSize,
		@intDS_Id, 
		@intData_Type_Id, 
		@tintEvent_Type,
		@tintVar_Precision,
		@vcrSPCFailure,
		@intSPCTypeId,
		@intSpec_Id,
		1,
		@vcrGlobalDesc,
		@vcrVar_Desc,
		@vcrOldVarDesc,
		@intVar_id OUTPUT

END
	

--Updating _AL variable
SET @intQAVarId = (	SELECT var_id 
							FROM dbo.variables v LEFT JOIN dbo.pu_groups pug ON (v.pug_id = pug.pug_id) 
							WHERE pug.pug_desc like 'Q%Alarms' and v.pu_id = @intPU_Id AND v.extended_info = CAST(@intVar_id AS VARCHAR(10))
						)
IF @intQAVarId IS NOT NULL BEGIN

	SET @intPropID = (SELECT prop_id FROM dbo.specifications WHERE spec_id = @intSpec_Id)
	SET @intQASpecID = (SELECT spec_id FROM dbo.specifications WHERE prop_id = @intPropID AND spec_desc = 'FireAlarm')

	IF @intQASpecID IS NOT NULL BEGIN

		IF @vcrVar_Desc IS NOT NULL BEGIN
			SET @SQLCommand = REPLACE(@SQLCommand, '''' + @vcrVar_Desc + '''', '''' + @vcrVar_Desc + '_AL' + '''')
		END
		IF @vcrGlobalDesc IS NOT NULL BEGIN
			SET @SQLCommand = REPLACE(@SQLCommand, '''' + @vcrGlobalDesc + '''', '''' + @vcrGlobalDesc + '_AL' + '''')
		END

		--2008-09-17 Marc Charest (Service Call 22294708)
		SET @SQLCommand = REPLACE(@SQLCommand, 'Extended_Info = ' + ISNULL('''' + @vcrExtendedInfo + '''','NULL') + ',', '')
		SET @SQLCommand = REPLACE(@SQLCommand, 'PUG_Id = ' + ISNULL(CONVERT(nvarchar,@intPUG_Id),'NULL') + ',', '')

		SET @SQLCommandTemp = @SQLCommand
		SET @SQLCommandTemp = REPLACE(@SQLCommandTemp, '@intVar_id', CONVERT(nvarchar,@intQAVarId))
		EXEC sp_ExecuteSQL @SQLCommandTemp
	
		--Updating QA variable with good infos	
		-- Complaint with PPA6
		--UPDATE dbo.Variables 
		UPDATE dbo.Variables_Base 
		SET
			Data_Type_Id = 2, 
			var_precision = 2,
			DS_Id = 4, 
			Spec_Id = @intQASpecID,
			user_defined1 = NULL,
			user_defined2 = NULL,
			user_defined3 = NULL,
			calculation_id = NULL,
			output_tag = NULL,
			input_tag = NULL,
			pvar_id = NULL,
			Sampling_Interval = 0,
			Sampling_Offset = NULL,
			Event_Type = 0
		WHERE
			var_id = @intQAVarId 
	END

	ELSE 
	BEGIN
		SET @intQAVarId = NULL
	END
			
END

		
--SELECT 'STEP 5'
--Log this transaction in the variable log
INSERT INTO dbo.Local_PG_PCMT_Log_Variables ([Timestamp], [User_Id], Type, Repeat_Backtime, Data_Type_Id, 
				DS_Id, Spec_Id, PU_Id, Var_Id, PUG_Desc, Sampling_Interval, Sampling_Offset, Repeating, SA_Id,
				Event_Type, Var_Precision, Var_Desc, Eng_Units, Test_Name, Output_Tag, Extended_Info, Sampling_Type, Base_Var_Id,
				User_Defined1, User_Defined2, User_Defined3,
				Input_Tag, Calculation_Id, External_Link,
				Alarm_Template_Id, Alarm_Display_Id, Autolog_Display_Id, Autolog_Display_Order)
	VALUES 	(getdate(), @intUser_Id, 'Modify', @intRepeat_Backtime, @intData_Type_Id, @intDS_Id, @intSpec_Id, 
				@intPU_Id, @intVar_Id, @vcrPUG_Desc, @sintSampling_Interval, @sintSampling_Offset, @tintRepeating, 
				@tintSA_Id, @tintEvent_Type, @tintVar_Precision, @vcrVar_Desc, @vcrEng_Units, @vcrTestName, @vcrOutput_Tag, @vcrExtendedInfo,
				@intST_Id, @intBase_Var_Id, 
				@vcrUserDefined1, @vcrUserDefined2, @vcrUserDefined3,
				@vcrInput_Tag, @intCalculation_Id, @vcrExternal_Link,
				@intAlarm_Template_Id, @intAlarm_Display_Id, @intAutolog_Display_Id, @intAutolog_Display_Order)



	-------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------
	--Add variable to the alarm template
	-------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------
	SET @DoInsert = 0
	SET @Old_AT_Id = NULL
	SET @Old_AT_Id = (SELECT TOP 1 AT_Id FROM dbo.Alarm_Template_Var_Data WHERE Var_Id = @intVar_id)

	--We have a template where we need to insert
	IF @intAlarm_Template_Id IS NOT NULL BEGIN
	
		--We were having template data before
		IF @Old_AT_Id IS NOT NULL BEGIN

			--We did not change template
			IF @Old_AT_Id = @intAlarm_Template_Id BEGIN

				--We are downsizing
				IF @intSGSize < @intSGSizeOld BEGIN

					SET @DoInsert = 1
					
				END

				--We are upsizing
				IF @intSGSize > @intSGSizeOld BEGIN

					SET @DoInsert = 1

				END END

			--We changed template
			ELSE BEGIN

				SET @DoInsert = 1

				--Removing parent and children from old template
				DELETE FROM dbo.Alarm_Template_Var_Data 
				WHERE
					(Var_id = @intVar_Id OR Var_Id IN (SELECT Var_Id FROM dbo.Variables WHERE PVar_Id = @intVar_Id))
					AND AT_Id = @Old_AT_Id
					
			END END

		--We were not having template data before
		ELSE BEGIN

			SET @DoInsert = 1				
		
		END END	

	--We have no template where we need to insert
	ELSE BEGIN

		--We were having template data before
		IF @Old_AT_Id IS NOT NULL BEGIN

			--Removing parent and children from old template
			DELETE FROM dbo.Alarm_Template_Var_Data 
			WHERE 
				(var_id = @intVar_id OR var_id IN (SELECT var_id FROM dbo.variables WHERE pvar_id = @intVar_id))
				AND AT_Id = @Old_AT_Id		

		END

	END 

	--We detected the need to insert template data
	IF @DoInsert = 1 BEGIN

		--Inserting template data only for additional children
		INSERT dbo.Alarm_Template_Var_Data(at_id, var_id) 
		SELECT @intAlarm_Template_Id, V.Var_Id 
		FROM 
			dbo.variables V
		WHERE 
			(Var_Id = @intVar_Id 
			 OR PVar_id = @intVar_Id)
			 AND NOT EXISTS (	SELECT * 
									FROM
										dbo.Alarm_Template_Var_Data ATVD
									WHERE
										ATVD.Var_id = V.Var_Id)

		--Inserting template data only for additional children
		INSERT dbo.Alarm_Template_Var_Data(AT_Id, Var_Id, ATVRD_Id)		
		SELECT
			@intAlarm_Template_Id, V.Var_Id, ATVRD_Id
		FROM
			dbo.Alarm_Template_Variable_Rule_Data ATVRD, 
			dbo.variables V
		WHERE 
			(V.Var_Id = @intVar_Id OR V.PVar_Id = @intVar_Id) AND ATVRD.AT_Id = @intAlarm_Template_Id
			 AND NOT EXISTS (	SELECT * 
									FROM
										dbo.Alarm_Template_Var_Data ATVD
									WHERE
										ATVD.Var_id = V.Var_Id
										AND ATVD.ATVRD_Id IS NOT NULL)

	END







	-------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------
	--Add variable to the alarm sheet
	-------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------
	SET @DoInsert = 0
	SET @Old_Sheet_Id = NULL
	SET @Old_Sheet_Id = (	SELECT TOP 1 SV.Sheet_Id 
									FROM 
										dbo.Sheet_Variables SV
										LEFT JOIN dbo.Sheets S ON (S.Sheet_Id = SV.Sheet_Id)
									WHERE 
										Var_Id = @intVar_id
										AND Sheet_Type = 11)

	SET @intAlarm_Display_Order = (SELECT MAX(Var_Order) + 1 FROM dbo.Sheet_Variables WHERE Sheet_Id = @intAlarm_Display_Id)

	--We have a sheet where we need to insert
	IF @intAlarm_Display_Id IS NOT NULL BEGIN
	
		--We were having sheet data before
		IF @Old_Sheet_Id IS NOT NULL BEGIN

			--We did not change sheet
			IF @Old_Sheet_Id = @intAlarm_Display_Id BEGIN

				--We are downsizing
				IF @intSGSize < @intSGSizeOld BEGIN

					SET @DoInsert = 1

				END

				--We are upsizing
				IF @intSGSize > @intSGSizeOld BEGIN

					SET @DoInsert = 1

				END END

			--We changed sheet
			ELSE BEGIN

				SET @DoInsert = 1

				--Removing parent and children from old sheet
				DELETE FROM dbo.Sheet_Variables 
				WHERE
					(Var_id = @intVar_Id OR Var_Id IN (SELECT Var_Id FROM dbo.Variables WHERE PVar_Id = @intVar_Id))
					AND Sheet_Id = @Old_Sheet_Id

				--Re-ordering old sheet
				TRUNCATE TABLE #TempOrder
				INSERT #TempOrder (Old_Order, Var_Id)
				SELECT Var_Order, NULL FROM dbo.Sheet_Variables WHERE Sheet_Id = @Old_Sheet_Id ORDER BY Var_Order
				UPDATE dbo.Sheet_Variables
				SET 
					Var_Order = New_Order
				FROM
					#TempOrder
				WHERE
					Var_Order = Old_Order
					AND Sheet_Id = @Old_Sheet_Id
	
			END END

		--We were not having sheet data before
		ELSE BEGIN

			SET @DoInsert = 1				
		
		END END		

	--We have no sheet where we need to insert
	ELSE BEGIN

		--We were having sheet data before
		IF @Old_Sheet_Id IS NOT NULL BEGIN

			--Removing parent and children from old sheet
			DELETE FROM dbo.Sheet_Variables 
			WHERE 
				(var_id = @intVar_id OR var_id IN (SELECT var_id FROM dbo.variables WHERE pvar_id = @intVar_id))
				AND Sheet_Id = @Old_Sheet_Id		

			--Re-ordering old sheet
			TRUNCATE TABLE #TempOrder
			INSERT #TempOrder (Old_Order, Var_Id)
			SELECT Var_Order, NULL FROM dbo.Sheet_Variables WHERE Sheet_Id = @Old_Sheet_Id ORDER BY Var_Order
			UPDATE dbo.Sheet_Variables
			SET 
				Var_Order = New_Order
			FROM
				#TempOrder

			WHERE
				Var_Order = Old_Order
				AND Sheet_Id = @Old_Sheet_Id

		END

	END 

	--We detected the need to insert sheet data
	IF @DoInsert = 1 BEGIN

		DELETE FROM dbo.Sheet_Variables 
		WHERE 
			(var_id = @intVar_id OR var_id IN (SELECT var_id FROM dbo.variables WHERE pvar_id = @intVar_id))
			AND Sheet_Id = @intAlarm_Display_Id

		TRUNCATE TABLE #TempOrder
		INSERT #TempOrder (Old_Order, Var_Id)
		SELECT Var_Order, NULL FROM dbo.Sheet_Variables 
		WHERE 
			Sheet_Id = @intAlarm_Display_Id 
			AND Var_Order < @intAlarm_Display_Order
		ORDER BY 
			Var_Order ASC

		INSERT #TempOrder (Old_Order, Var_Id)
		SELECT NULL, Var_Id FROM dbo.Variables 
		WHERE 
			Var_id = @intVar_Id OR PVar_Id = @intVar_Id
		ORDER BY 
			Var_Id ASC
		
		INSERT #TempOrder (Old_Order, Var_Id)
		SELECT Var_Order, NULL FROM dbo.Sheet_Variables 
		WHERE 
			Sheet_Id = @intAlarm_Display_Id 
			AND Var_Order >= @intAlarm_Display_Order
		ORDER BY 
			Var_Order ASC
		
		INSERT dbo.Sheet_Variables (Var_Order, Var_Id, Sheet_Id)
		SELECT New_Order, Var_Id, @intAlarm_Display_Id
		FROM #TempOrder
		WHERE
			Var_Id IS NOT NULL

		UPDATE dbo.Sheet_Variables
		SET 
			Var_Order = New_Order
		FROM
			#TempOrder T
		WHERE
			Sheet_Id = @intAlarm_Display_Id
			AND Var_Order = Old_Order 

	END









	-------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------
	--Add variable to the autolog sheet
	-------------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------------
	SET @DoInsert = 0
	SET @Old_Sheet_Id = NULL
	SET @Old_Sheet_Id = (	SELECT TOP 1 SV.Sheet_Id 
									FROM 
										dbo.Sheet_Variables SV
										LEFT JOIN dbo.Sheets S ON (S.Sheet_Id = SV.Sheet_Id)
									WHERE 
										Var_Id = @intVar_id
										AND Sheet_Type <> 11)

	--We have a sheet where we need to insert
	IF @intAutolog_Display_Id IS NOT NULL BEGIN

		--We were having sheet data before
		IF @Old_Sheet_Id IS NOT NULL BEGIN

			--We did not change sheet
			IF @Old_Sheet_Id = @intAutolog_Display_Id BEGIN

				--We are downsizing
				IF @intSGSize < @intSGSizeOld BEGIN

					SET @DoInsert = 1

				END

				SET @OldVarOrder = (SELECT Var_Order FROM dbo.Sheet_Variables WHERE Var_Id = @intVar_id AND Sheet_Id = @intAutolog_Display_Id)

				--We are upsizing
				IF @intSGSize > @intSGSizeOld OR @OldVarOrder <> @intAutolog_Display_Order BEGIN

					SET @DoInsert = 1

				END END

			--We changed sheet
			ELSE BEGIN

				SET @DoInsert = 1

				--Removing parent and children from old sheet
				DELETE FROM dbo.Sheet_Variables 
				WHERE
					(Var_id = @intVar_Id OR Var_Id IN (SELECT Var_Id FROM dbo.Variables WHERE PVar_Id = @intVar_Id))
					AND Sheet_Id = @Old_Sheet_Id

				--Re-ordering old sheet
				TRUNCATE TABLE #TempOrder
				INSERT #TempOrder (Old_Order, Var_Id)
				SELECT Var_Order, NULL FROM dbo.Sheet_Variables WHERE Sheet_Id = @Old_Sheet_Id ORDER BY Var_Order
				UPDATE dbo.Sheet_Variables
				SET 
					Var_Order = New_Order
				FROM
					#TempOrder
				WHERE
					Var_Order = Old_Order
					AND Sheet_Id = @Old_Sheet_Id
	
			END END

		--We were not having sheet data before
		ELSE BEGIN

			SET @DoInsert = 1				
		
		END END	

	--We have no sheet where we need to insert
	ELSE BEGIN

		--We were having sheet data before
		IF @Old_Sheet_Id IS NOT NULL BEGIN

			--Removing parent and children from old sheet
			DELETE FROM dbo.Sheet_Variables 
			WHERE 
				(var_id = @intVar_id OR var_id IN (SELECT var_id FROM dbo.variables WHERE pvar_id = @intVar_id))
				AND Sheet_Id = @Old_Sheet_Id		

			--Re-ordering old sheet
			TRUNCATE TABLE #TempOrder
			INSERT #TempOrder  (Old_Order, Var_Id)
			SELECT Var_Order, NULL FROM dbo.Sheet_Variables WHERE Sheet_Id = @Old_Sheet_Id ORDER BY Var_Order
			UPDATE dbo.Sheet_Variables
			SET 
				Var_Order = New_Order
			FROM
				#TempOrder
			WHERE
				Var_Order = Old_Order
				AND Sheet_Id = @Old_Sheet_Id

		END

	END 

	--We detected the need to insert sheet data
	IF @DoInsert = 1 BEGIN

		SET @NextVarOrder = ISNULL((SELECT TOP 1 Var_Order FROM dbo.Sheet_Variables 
											 WHERE
													Var_Order >= @intAutolog_Display_Order
													AND (	Var_Id NOT IN (SELECT Var_Id FROM dbo.Variables WHERE PVar_Id = @intVar_id
															OR Var_Id IS NULL)
													AND Sheet_Id = @intAutolog_Display_Id)
											 ORDER BY Var_Order ASC), 1000000000)

		DELETE FROM dbo.Sheet_Variables 
		WHERE 
			(var_id = @intVar_id OR var_id IN (SELECT var_id FROM dbo.variables WHERE pvar_id = @intVar_id))
			AND Sheet_Id = @intAutolog_Display_Id

		TRUNCATE TABLE #TempOrder
		INSERT #TempOrder (Old_Order, Var_Id)
		SELECT Var_Order, NULL FROM dbo.Sheet_Variables
		WHERE 
			Sheet_Id = @intAutolog_Display_Id 
			AND Var_Order < @NextVarOrder
		ORDER BY 
			Var_Order ASC

		INSERT #TempOrder (Old_Order, Var_Id)
		SELECT NULL, Var_Id FROM dbo.Variables 
		WHERE 
			Var_id = @intVar_Id OR PVar_Id = @intVar_Id
		ORDER BY 
			Var_Id ASC
		
		INSERT #TempOrder (Old_Order, Var_Id)
		SELECT Var_Order, NULL FROM dbo.Sheet_Variables 
		WHERE 
			Sheet_Id = @intAutolog_Display_Id 
			AND Var_Order >= @NextVarOrder
		ORDER BY 
			Var_Order ASC

		INSERT INTO dbo.Sheet_Variables (Var_Order, Var_Id, Sheet_Id)
		SELECT New_Order * 10000, Var_Id, @intAutolog_Display_Id
		FROM #TempOrder
		WHERE
			Var_Id IS NOT NULL

		UPDATE dbo.Sheet_Variables
		SET 
			Var_Order = New_Order
		FROM
			#TempOrder T
		WHERE
			Sheet_Id = @intAutolog_Display_Id
			AND Var_Order = Old_Order 

		UPDATE dbo.Sheet_Variables
		SET 
			Var_Order = Var_Order / 10000
		WHERE
			Var_Order >= 10000
			AND Sheet_Id = @intAutolog_Display_Id

	END

	DROP TABLE #TempOrder











--Update the var_specs table
SET @dtmTimestamp = getdate()

--Put the expiration if the variable had a spec_id and has change
IF (@intOldSpecId IS NOT NULL) AND (ISNULL(@intOldSpecId,-1) <> ISNULL(@intSpec_Id,-1))
BEGIN
	UPDATE dbo.Var_Specs 
	SET Expiration_Date = @dtmTimestamp
	WHERE 

		(Expiration_Date IS NULL) 
		AND ((Var_Id = @intVar_Id) OR Var_Id IN (SELECT Var_Id FROM dbo.Variables WHERE PVar_Id = @intVar_Id))
		AND AS_Id IN (SELECT AS_Id FROM dbo.Active_Specs WITH(NOLOCK) WHERE Expiration_Date IS NULL AND spec_id = @intOldSpecId)
END

--Insert the new spec value
IF (@intSpec_Id IS NOT NULL) AND (ISNULL(@intOldSpecId,-1) <> ISNULL(@intSpec_Id,-1))
BEGIN

	INSERT INTO dbo.Var_Specs(var_id, prod_id, effective_date, expiration_date, l_entry, l_reject, l_warning, l_user, 
						target, u_user, u_warning, u_reject, u_entry, test_freq, comment_id, as_id)
	SELECT 
		B.Var_Id, prod_id, timestamp, expiration_date, l_entry, l_reject, l_warning, l_user,
		target, u_user, u_warning, u_reject, u_entry, test_freq, comment_id, as_id
	FROM
		(
			SELECT puc.prod_id, @dtmTimestamp as [timestamp], a.expiration_date, a.l_entry, a.l_reject, a.l_warning, a.l_user,
					 a.target, a.u_user, a.u_warning, a.u_reject, a.u_entry, a.test_freq, a.comment_id, a.as_id
			FROM 
				dbo.Prod_Units pu
			  	JOIN dbo.PU_Characteristics puc ON (puc.pu_id = CASE WHEN pu.master_unit IS NULL THEN pu.pu_id 
																					 ELSE pu.master_unit END)
			  	JOIN dbo.Active_Specs a ON (a.char_id = puc.char_id)
			WHERE pu.pu_id = @intPu_Id AND a.spec_id = @intSpec_Id AND 
					a.effective_date <=  @dtmTimestamp AND (a.expiration_date > @dtmTimestamp OR a.expiration_date is null)
		) A,
		(SELECT Var_Id FROM dbo.Variables WHERE Var_id = @intVar_Id or PVar_id = @intVar_Id) B

/*
		SELECT @intVar_Id, puc.prod_id, @dtmTimestamp, a.expiration_date, a.l_entry, a.l_reject, a.l_warning, a.l_user,
				 a.target, a.u_user, a.u_warning, a.u_reject, a.u_entry, a.test_freq, a.comment_id, a.as_id
		FROM 
			dbo.Prod_Units pu
		  	JOIN dbo.PU_Characteristics puc ON (puc.pu_id = CASE WHEN pu.master_unit IS NULL THEN pu.pu_id 
																				 ELSE pu.master_unit END)
		  	JOIN dbo.Active_Specs a ON (a.char_id = puc.char_id)
		WHERE pu.pu_id = @intPu_Id AND a.spec_id = @intSpec_Id AND 
				a.effective_date <=  @dtmTimestamp AND (a.expiration_date > @dtmTimestamp OR a.expiration_date is null)
*/
END

--Add Table_Field Values
DELETE FROM Table_Fields_Values 
	WHERE keyid = @intVar_id 
		OR keyid IN (SELECT var_id FROM dbo.variables WHERE pvar_id = @intVar_id)

SET @intTableId = (SELECT TableId FROM tables WHERE TableName = 'Variables')

INSERT #TableFieldIds(item_id, Table_Field_Id)
	EXECUTE spLocal_PCMT_ParseString @vcrTableFieldIDs, NULL, '[REC]', 'INTEGER'

INSERT #TableFieldValues(item_id, Table_Field_Value)
	EXECUTE spLocal_PCMT_ParseString @vcrTableFieldValues, NULL, '[REC]', 'VARCHAR(255)'

INSERT INTO Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
	SELECT var_id, Table_Field_Id, @intTableId, Table_Field_Value
	FROM #TableFieldIds tfi 
	JOIN #TableFieldValues tfv ON (tfi.item_id = tfv.item_id),
		dbo.variables 
	WHERE var_id = @intVar_id OR pvar_id = @intVar_id

-- Update all UDPs and user_defined values for parent and child variables (if needed)
IF @vcrUDPs <> '' BEGIN

	SET @intTableId = (SELECT TableId FROM tables WHERE TableName = 'Variables')

	INSERT #AllUDPs(Item_Id, Var_Name, UDPs)
		EXECUTE spLocal_PCMT_ParseString @vcrUDPs, '[FLD1]', '[REC1]', 'VARCHAR(255)', 'VARCHAR(8000)'

	SET @intCounter = 1
	SET @intIndividualVarId = @intVar_id
	WHILE @intCounter <= (SELECT COUNT(item_id) FROM #AllUDPs) BEGIN
		
		SET @vcrIndividualIDs = (SELECT SUBSTRING(UDPs, 1, CHARINDEX('@$', UDPs) - 1) FROM #AllUDPs WHERE item_id = @intCounter) 
		SET @vcrIndividualValues = (SELECT SUBSTRING(UDPs, CHARINDEX('@$', UDPs) + 2, 8000) FROM #AllUDPs WHERE item_id = @intCounter) 
		SET @vcrIndividualVarDesc = (SELECT var_name FROM #AllUDPs WHERE item_id = @intCounter) 
		SET @intIndividualVarId = (SELECT var_id FROM dbo.variables WHERE (var_id = @intVar_id AND var_desc_global = @vcrIndividualVarDesc) OR (var_desc_global = @vcrIndividualVarDesc AND pvar_id = @intVar_id))		
		

		DELETE FROM Table_Fields_Values 
			WHERE keyid = @intIndividualVarId 
				OR keyid IN (SELECT var_id FROM dbo.variables WHERE pvar_id = @intIndividualVarId)

		DELETE FROM #TableFieldIds

		INSERT #TableFieldIds(item_id, Table_Field_Id)
			EXECUTE spLocal_PCMT_ParseString @vcrIndividualIDs, NULL, '[REC]', 'INTEGER'

		DELETE FROM #TableFieldValues

		INSERT #TableFieldValues(item_id, Table_Field_Value)
			EXECUTE spLocal_PCMT_ParseString @vcrIndividualValues, NULL, '[REC]', 'VARCHAR(255)'

		INSERT INTO Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
		SELECT DISTINCT var_id, Table_Field_Id, @intTableId, Table_Field_Value
			FROM #TableFieldIds tfi 
				JOIN #TableFieldValues tfv ON (tfi.item_id = tfv.item_id),
				dbo.variables 
			WHERE var_id = @intIndividualVarId 
				OR pvar_id = @intIndividualVarId
		
		SET @intCounter = @intCounter + 1

	END

END


--Update all extended_infos and user_defined values for parent and child variables (if needed)
IF @vcrEIs <> '' BEGIN
	INSERT #Extended_Infos(Item_Id, Var_Name, EI, UD1, UD2, UD3)
		EXECUTE spLocal_PCMT_ParseString @vcrEIs, '[FLD]', '[REC]', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)', 'VARCHAR(255)'
	
	-- Complaint with PPA6
	--UPDATE dbo.Variables 
	UPDATE dbo.Variables_Base 
	SET
		extended_info = ei.ei,
		user_defined1 = ei.ud1,
		user_defined2 = ei.ud2,
		user_defined3 = ei.ud3
	FROM
		dbo.Variables_Base v,
		--dbo.variables v,
		#Extended_Infos ei
	WHERE
		(v.pvar_id = @intVar_Id AND v.var_desc_global = ei.var_name)		
		or
		(v.var_id = @intVar_Id AND v.var_desc_global = ei.var_name)		
		
	
END

SELECT @intVar_id, 0 --ISNULL(@intQAVarId, 0)

DROP TABLE #TableFieldIds
DROP TABLE #TableFieldValues
DROP TABLE #Extended_Infos
DROP TABLE #AllUDPs

SET NOCOUNT OFF
