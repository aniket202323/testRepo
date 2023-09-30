
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_ProductionUnit_VariableEdit]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_ProductionUnit

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Alberto Ledesma - Arido Software
Date ALTERd		:	2010-11-04
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This sp returns the specific lines as production unit selected
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what
-------------------------------------------------------------------------------------------------
*/
@Lines				VARCHAR(100),
@pu_desc			VARCHAR(50),
@var_desc			VARCHAR(50)

AS

SET NOCOUNT ON

SET @pu_desc 	= ISNULL(@pu_desc,'')
SET @pu_desc 	= LTRIM(RTRIM(@pu_desc))
SET @pu_desc  = CASE WHEN @pu_desc = '[Enter unit filter]' THEN '' ELSE @pu_desc END


CREATE TABLE #Temp_LinesParam(
RecId	INT,
Pl_ID	INT	)

INSERT INTO #Temp_LinesParam 
EXEC SPCMN_ReportCollectionParsing @PRMCollectionString = @Lines, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',', @PRMDataType01 = 'NVARCHAR(200)'


SELECT pu.pu_id, pu_desc
FROM 
	dbo.prod_units pu
	JOIN dbo.prod_lines pl	ON pl.pl_id	= pu.pl_id
	JOIN variables v		ON v.pu_id	= pu.pu_id
WHERE 
	pu.pu_id != 0 
	AND pu.pu_desc LIKE '%' + @pu_desc + '%'
	AND pu.master_unit IS NULL
	AND pu.pl_id IN (SELECT pl_id FROM #Temp_LinesParam)
	AND (v.var_desc_global = @Var_Desc OR v.var_desc_local = @Var_Desc)

DROP TABLE #Temp_LinesParam


SET NOCOUNT OFF
