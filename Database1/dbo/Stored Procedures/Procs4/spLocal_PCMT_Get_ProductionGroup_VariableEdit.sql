
-------------------------------------------------------------------------------------------------
	
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_ProductionGroup_VariableEdit]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Author			: 	Alberto Ledesma, Arido Software
Date ALTERd		:	04-Nov-2010
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This SP returns the lines that meet the search requirements in the form to edit variables as production group
					PCMT Version 1.30
Editor tab spacing: 3
Example: EXEC [dbo].[spLocal_PCMT_Get_ProductionGroup_VariableEdit] '112,7'
-------------------------------------------------------------------------------------------------
*/	

@Units			NVARCHAR(4000)

AS
SET NOCOUNT ON

CREATE TABLE #Temp_UnitsParam(
								RecId	INT,
								PU_ID	INT	)

-- Search Units
INSERT INTO #Temp_UnitsParam 
EXEC SPCMN_ReportCollectionParsing @PRMCollectionString = @Units, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',', @PRMDataType01 = 'NVARCHAR(200)'

-- Search Production Groups
SELECT DISTINCT pug.pug_desc
--, pu.pu_id, pu.pu_desc, pl_desc
	FROM dbo.pu_groups pug
	JOIN dbo.prod_units pu ON PUG.pu_id = pu.pu_id
	JOIN dbo.prod_lines pl ON pl.pl_id=pu.pl_id
	WHERE pu.pu_id IN (SELECT pu_id FROM #Temp_UnitsParam)
	AND pug.pug_desc NOT LIKE 'z_obs%'
	AND pu.pu_desc NOT LIKE 'z_obs%'
	ORDER BY pug.pug_desc


DROP TABLE #Temp_UnitsParam
RETURN

