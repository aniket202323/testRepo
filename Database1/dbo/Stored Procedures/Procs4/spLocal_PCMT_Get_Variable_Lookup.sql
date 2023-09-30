













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Variable_Lookup]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-11-01
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Replaced #Results temp table by @Results Table variable.
					Eliminated c_Variable cursor.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	22-Sep-2003	
Version		:	1.0.0
Purpose		:	Retreive informations for a given variable name 
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_PCMT_Get_Variable_Lookup 'test alex 5'
-------------------------------------------------------------------------------------------------
*/

@vcrVarDesc	varchar(50)

AS 

SET NOCOUNT ON 

DECLARE
@intVarId	integer,
@vcrAutDisp	varchar(50),
@vcrAlTpl	varchar(50),
@vcrAlDisp	varchar(50),
@RowNum		INT,
@NbrRows		INT

-- Var_Id list Table
DECLARE @VarId_List	TABLE
(
PKey		INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
Var_id	INT
)

-- Informations table
DECLARE @Results TABLE
(
pl_desc				varchar(50),
pu_desc				varchar(50),
pug_desc				varchar(50),
var_desc				varchar(50),
data_type_desc		varchar(50),
var_precision		integer,
eng_units			varchar(50),
spec_desc			varchar(50),
extended_info		varchar(255),
autolog_display	varchar(50),
alarm_template		varchar(50),
alarm_display		varchar(50)
)

-- Retrieve Var_Ids List
INSERT INTO @VarId_List (Var_Id)
	SELECT Var_Id
	FROM dbo.Variables
	WHERE Var_Desc = @vcrVarDesc

-- Initialize variables
SET @NbrRows = (SELECT COUNT(*) FROM @VarId_List)
SET @RowNum = 1


WHILE @RowNum <= @NbrRows
  BEGIN
    SET @vcrAutDisp = NULL
    SET @vcrAlDisp = NULL
    SET @vcrAlTpl = NULL

	 -- Retrieve information for each Var_Id
	 SET @intVarId = (SELECT Var_Id FROM @VarId_List WHERE PKey = @RowNum)

    SELECT @vcrAutDisp = sheet_desc
    FROM dbo.sheets s
         JOIN dbo.sheet_variables sv ON sv.sheet_id = s.sheet_id
    WHERE sv.var_id = @intVarId AND s.sheet_type in (1,2)

    SELECT @vcrAlDisp = sheet_desc
    FROM dbo.sheets s
         JOIN dbo.sheet_variables sv ON sv.sheet_id = s.sheet_id
    WHERE sv.var_id = @intVarId AND s.sheet_type = 11

    SELECT @vcrAlTpl = a.at_desc
    FROM dbo.alarm_templates a
         JOIN dbo.alarm_template_var_data atd ON atd.at_id = a.at_id
    WHERE atd.var_id = @intVarId

    INSERT @Results
    SELECT pl_desc, pu_desc, pug_desc, var_desc, data_type_desc, var_precision,
           v.eng_units, spec_desc, v.extended_info, @vcrAutDisp, @vcrAlTpl, @vcrAlDisp 
    FROM dbo.variables v
         JOIN dbo.prod_units pu ON pu.pu_id = v.pu_id
         JOIN dbo.pu_groups pug ON pug.pug_id = v.pug_id
         LEFT JOIN dbo.specifications s ON s.spec_id = v.spec_id
         JOIN dbo.prod_lines pl ON pl.pl_id = pu.pl_id
         JOIN dbo.data_type dt ON dt.data_type_id = v.data_type_id
    WHERE v.var_id = @intVarId
    
    SET @RowNum = @RowNum + 1
  END          

SELECT 
	pl_desc,pu_desc,pug_desc,var_desc,data_type_desc,var_precision,eng_units,
	spec_desc,extended_info,autolog_display,alarm_template,alarm_display
FROM 
	@Results 
ORDER BY 
	pl_desc, pu_desc, pug_desc

SET NOCOUNT OFF















