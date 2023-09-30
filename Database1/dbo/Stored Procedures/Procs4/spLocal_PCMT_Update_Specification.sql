
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Update_Specification]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini - Arido 
Date		:	2014-08-04
Version		:	2.0
Purpose		: 	Compliant with PPA6.
				In Proficy 6 must use the field Spec_Desc_Local in dbo.Specifications
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2010-02-23
Version		:	4.1.1
Purpose		: 	I added TableId = @intTableId when deleting UDPs.
				I also get @intTableId before I actually delete UDPs.
-------------------------------------------------------------------------------------------------
Updated By	:	Marc Charest (System Technologies for Industry Inc)
Date			:	2009-01-27
Version		:	4.1.0
Purpose		: 	Added code to make SP able to manage quoted string like "O'Brien", "Joe's".
-------------------------------------------------------------------------------------------------
Updated By	:	Benoit Saenz de Ugarte (System Technologies for Industry Inc)
Date			:	2008-05-29
Version		:	4.0.0
Purpose		: 	Added 'Specification' table_id checking.
					If it is NULL, insert this value in the table tables (with table_id = 39)
-------------------------------------------------------------------------------------------------
Updated By	:	Stephane Turner (System Technologies for Industry Inc)
Date			:	2008-04-09
Version		:	3.0.0
Purpose		: 	Added global description
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-25
Version		:	2.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-05-31
Version		:	2.0.0
Purpose		: 	P4 Migration
					Update can no longer be done in Var_desc and PUG_Desc fields. Those fields are calculated in P4.
					Updates must be done in Var_Desc_Local and PUG_Desc_Local fields.
					PCMT Version 3.0.0
---------------------------------------------------------------------------------------------------------------------------------------
Modified by	:	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	19-Sep-2003
Version		:	1.0.1
Purpose		:	It is now updating the precision of every var attached to this spec
					PCMT Version 2.1.0
-----------------------------------------------------------------------------------
Created by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	17-Dec-2002	
Version		: 	1.0.0
Purpose		: 	This sp updates specification.
---------------------------------------------------------------------------------
*/

@vcrSpec_Desc	varchar(50),
@vcrGlobalDesc	varchar(50),
@intDT_Id		int, 
@vcrExtInfo		varchar(255), 
@intSpec_Prec	int, 
@intSpec_Id		int,
@intProp_Id		int,
@vcrTableFieldValues			VARCHAR(8000) = NULL,
@vcrTableFieldIDs				VARCHAR(8000) = NULL,
@intUser_Id		int
  
AS
SET NOCOUNT ON

DECLARE
@AppVersion		varchar(30),	-- Used to retrieve the Proficy database Version
@FieldName		varchar(50),
@SQLCommand		nvarchar(1000),
@intTableId		INTEGER

CREATE TABLE #TableFieldIds(
	item_id				INTEGER,
	Table_Field_Id		INTEGER
)

CREATE TABLE #TableFieldValues(
	item_id				INTEGER,
	Table_Field_Value	VARCHAR(8000)
)

-- Get the Proficy Database Version
SET @AppVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')

SET @vcrExtInfo				= REPLACE(@vcrExtInfo, '''', '''''')
SET @vcrSpec_Desc				= REPLACE(@vcrSpec_Desc, '''', '''''')
SET @vcrGlobalDesc			= REPLACE(@vcrGlobalDesc, '''', '''''') 
SET @vcrTableFieldValues	= REPLACE(@vcrTableFieldValues, '''', '''''') 
SET @vcrTableFieldIDs		= REPLACE(@vcrTableFieldIDs, '''', '''''') 

-- Old
--IF @AppVersion LIKE '4%'
--	SET @FieldName = 'Spec_Desc_Local'	-- P4
--ELSE
--	SET @FieldName = 'Spec_Desc'			-- P3

-- Updated for PPA6 (Juan Pablo Galanzini - Arido - Aug 2014)
IF @AppVersion LIKE '3%'
	SET @FieldName = 'Spec_Desc'			-- P3
ELSE
	SET @FieldName = 'Spec_Desc_Local'	-- P4

-- Create dynamic SQL to be able to refer to correct field for P3 and P4
SET @SQLCommand =	'UPDATE dbo.Specifications '
SET @SQLCommand = @SQLCommand + 'SET ' + @FieldName + ' = ' + isnull('''' + @vcrSpec_Desc + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'Data_Type_Id = ' + isnull(convert(nvarchar,@intDT_Id),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Extended_Info = ' + isnull('''' + @vcrExtInfo + '''','NULL') + ','
SET @SQLCommand = @SQLCommand + 'Spec_Precision = ' + isnull(convert(nvarchar,@intSpec_Prec),'NULL') + ','
SET @SQLCommand = @SQLCommand + 'Prop_Id = ' + isnull(convert(nvarchar,@intProp_Id),'NULL')
IF @AppVersion LIKE '4%'
	SET @SQLCommand = @SQLCommand + ',spec_desc_global = ' + isnull('''' + @vcrGlobalDesc + '''','NULL')
SET @SQLCommand = @SQLCommand + ' WHERE Spec_Id = ' + convert(nvarchar,@intSpec_Id)

EXEC sp_executesql @SQLCommand
			
UPDATE dbo.Variables 
	SET Var_Precision = @intSpec_Prec
	WHERE Spec_Id = @intSpec_Id

--Add Table_Field Values
SET @intTableId = (SELECT TableId FROM tables WHERE TableName = 'Specifications')
IF (@intTableId IS NULL)
BEGIN
	INSERT INTO Tables(Tableid, tablename) VALUES(39, 'Specifications')
	SET @intTableId = 39
END

DELETE FROM Table_Fields_Values 
	WHERE keyid = @intSpec_Id AND TableId = @intTableId

INSERT #TableFieldIds(item_id, Table_Field_Id)
	EXECUTE spLocal_PCMT_ParseString @vcrTableFieldIDs, NULL, '[REC]', 'INTEGER'

INSERT #TableFieldValues(item_id, Table_Field_Value)
	EXECUTE spLocal_PCMT_ParseString @vcrTableFieldValues, NULL, '[REC]', 'VARCHAR(255)'

INSERT Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
	SELECT @intSpec_Id, Table_Field_Id, @intTableId, Table_Field_Value
		FROM #TableFieldIds tfi 
		JOIN #TableFieldValues tfv ON (tfi.item_id = tfv.item_id)

--Log this transaction in the production groups log
INSERT INTO dbo.Local_PG_PCMT_Log_Specifications 
     ([Timestamp], [User_Id], Type, Spec_Id, 
      Spec_Desc, Data_Type_Id, Spec_Precision,
      Extended_Info)
VALUES (GETDATE(), @intUser_Id, 'Modify', @intSpec_Id,
        @vcrSpec_Desc, @intDT_Id, @intSpec_Prec,
        @vcrExtInfo)


SET NOCOUNT OFF
