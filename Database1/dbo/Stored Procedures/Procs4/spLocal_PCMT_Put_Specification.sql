
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Put_Specification]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
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
Date			:	2005-11-03
Version		:	2.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-06-01
Version		:	2.0.0
Purpose		: 	P4 Migration
					Update can no longer be done in Var_desc and PUG_Desc fields. Those fields are calculated in P4.
					Updates must be done in Var_Desc_Local and PUG_Desc_Local fields.
					PCMT Version 3.0.0
-------------------------------------------------------------------------------------------------
Created by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	17-Dec-2002	
Version		: 	1.0.0
Purpose		: 	This sp inserts specification.
					PCMT Version 2.1.0
-------------------------------------------------------------------------------------------------
*/

@intDT_Id			integer, 
@intProp_Id			integer, 
@intSpec_Prec		integer, 
@vcrExtInfo			varchar(255), 
@vcrSpec_Desc		varchar(50),
@vcrGlobalDesc		varchar(50),
@vcrTableFieldValues			VARCHAR(8000) = NULL,
@vcrTableFieldIDs				VARCHAR(8000) = NULL,
@intUser_Id			integer

AS
SET NOCOUNT ON

DECLARE 
@intSpec_Id 		integer,
@AppVersion			varchar(30),				-- Used to retrieve the Proficy database Version
@SQLCommand			nvarchar(1000),
@intTableId			INTEGER

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
-- Description field is not the same for each Proficy version
--IF @AppVersion LIKE '4%'
--BEGIN
--	-- Write new specification
--	-- Verify for nulls because if one of the variables is NULL, the result concatenation will be NULL
--	SET @SQLCommand = 'INSERT Specifications (Data_Type_Id,Prop_Id,Spec_Precision,Extended_Info,Spec_Desc_Local,Spec_Desc_Global) VALUES (' + 
--							isnull(convert(varchar,@intDT_Id),'NULL') + ','+ 
--							isnull(convert(varchar,@intProp_Id),'NULL') + ',' +
--							isnull(convert(varchar,@intSpec_Prec),'NULL') + ',' +
--							isnull('''' + @vcrExtInfo + '''','NULL') + ',' +
--							isnull('''' + @vcrSpec_Desc + '''','NULL') + ',' +
--							isnull('''' + @vcrGlobalDesc + '''','NULL') + ')'
--END
--ELSE
--BEGIN
--	-- Write new specification
--	-- Verify for nulls because if one of the variables is NULL, the result concatenation will be NULL
--	SET @SQLCommand = 'INSERT Specifications (Data_Type_Id,Prop_Id,Spec_Precision,Extended_Info,Spec_Desc) VALUES (' + 
--							isnull(convert(varchar,@intDT_Id),'NULL') + ','+ 
--							isnull(convert(varchar,@intProp_Id),'NULL') + ',' +
--							isnull(convert(varchar,@intSpec_Prec),'NULL') + ',' +
--							isnull('''' + @vcrExtInfo + '''','NULL') + ',' +
--							isnull('''' + @vcrSpec_Desc + '''','NULL') + ')'
--END

-- Updated for PPA6 (Juan Pablo Galanzini - Arido - Aug 2014)
IF @AppVersion LIKE '3%'
BEGIN
	-- Write new specification
	-- Verify for nulls because if one of the variables is NULL, the result concatenation will be NULL
	SET @SQLCommand = 'INSERT Specifications (Data_Type_Id,Prop_Id,Spec_Precision,Extended_Info,Spec_Desc) VALUES (' + 
							isnull(convert(varchar,@intDT_Id),'NULL') + ','+ 
							isnull(convert(varchar,@intProp_Id),'NULL') + ',' +
							isnull(convert(varchar,@intSpec_Prec),'NULL') + ',' +
							isnull('''' + @vcrExtInfo + '''','NULL') + ',' +
							isnull('''' + @vcrSpec_Desc + '''','NULL') + ')'
END
ELSE
BEGIN
	-- Write new specification
	-- Verify for nulls because if one of the variables is NULL, the result concatenation will be NULL
	SET @SQLCommand = 'INSERT Specifications (Data_Type_Id,Prop_Id,Spec_Precision,Extended_Info,Spec_Desc_Local,Spec_Desc_Global) VALUES (' + 
							isnull(convert(varchar,@intDT_Id),'NULL') + ','+ 
							isnull(convert(varchar,@intProp_Id),'NULL') + ',' +
							isnull(convert(varchar,@intSpec_Prec),'NULL') + ',' +
							isnull('''' + @vcrExtInfo + '''','NULL') + ',' +
							isnull('''' + @vcrSpec_Desc + '''','NULL') + ',' +
							isnull('''' + @vcrGlobalDesc + '''','NULL') + ')'
END

EXEC sp_ExecuteSQL @SQLCommand

SET @vcrSpec_Desc	= REPLACE(@vcrSpec_Desc, '''''', '''')

-- Old
----SELECT @intSpec_Id = spec_id 
----FROM dbo.specifications 
----WHERE spec_desc = @vcrSpec_Desc AND
----      prop_id = @intProp_Id

-- Updated for PPA6 (Juan Pablo Galanzini - Arido - Aug 2014)
IF @AppVersion LIKE '3%'
BEGIN
	SELECT @intSpec_Id = spec_id 
		FROM dbo.specifications 
		WHERE spec_desc = @vcrSpec_Desc AND
			  prop_id = @intProp_Id
END
ELSE
BEGIN
	SELECT @intSpec_Id = spec_id 
		FROM dbo.specifications 
		WHERE Spec_Desc_Local = @vcrSpec_Desc AND
			  prop_id = @intProp_Id
END

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
VALUES (getdate(), @intUser_Id, 'Add', @intSpec_Id,
        @vcrSpec_Desc, @intDT_Id, @intSpec_Prec,
        @vcrExtInfo)

SET NOCOUNT OFF
