















-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_ProductionUnit]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_ProductionUnit

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Alexandre Turgeon, Solutions et Technologies Industrielles inc.
Date created	:	17-May-2006
Version			: 	1.0.0
SP Type			:	Function
Called by		:	Excel file
Description		: 	This sp returns the converter production unit and its slaves for PCMT.
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what
-------------------------------------------------------------------------------------------------
*/
@txtUserId			INTEGER,
@txtPUFilter		VARCHAR(50) = NULL

AS

SET NOCOUNT ON

DECLARE
@intUserId			INTEGER,
@vcrPUFilter		VARCHAR(50)

SET @intUserId		= @txtUserId
SET @vcrPUFilter 	= ISNULL(@txtPUFilter,'')
SET @vcrPUFilter 	= LTRIM(RTRIM(@vcrPUFilter))
SET @vcrPUFilter  = CASE WHEN @vcrPUFilter = '[Enter unit filter]' THEN '' ELSE @vcrPUFilter END

--Getting objects IDs on which user as sufficient rights.
CREATE TABLE #PCMTPUIDs(Item_Id INTEGER)
INSERT #PCMTPUIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'prod_units', 'pu_id', @intUserId

-- filtered units
SELECT DISTINCT MIN(pu.pu_id) AS [pu_id], RTRIM(LTRIM(REPLACE(REPLACE(pu_desc, pl.pl_desc, ''), '  ', ' '))) AS [pu_desc]
FROM 
	dbo.prod_units pu
--	LEFT JOIN dbo.Local_PG_PCMT_PlantModelSelections pm ON (pu.pl_id = pm.pl_id)
	LEFT JOIN dbo.prod_lines pl ON (pu.pl_id = pl.pl_id),
	#PCMTPUIDs pu2
WHERE 
	pu.pu_id != 0 AND pu.pu_desc LIKE '%' + @vcrPUFilter + '%'
	AND pu.pu_id = pu2.item_id
	AND pu.master_unit IS NULL
GROUP BY RTRIM(LTRIM(REPLACE(REPLACE(pu_desc, pl.pl_desc, ''), '  ', ' ')))
ORDER BY RTRIM(LTRIM(REPLACE(REPLACE(pu_desc, pl.pl_desc, ''), '  ', ' ')))

DROP TABLE #PCMTPUIDs

/*
IF @Item = 1
BEGIN
	-- get RTT units only
	SELECT DISTINCT pu.pu_desc
	FROM dbo.prod_units pu
	  JOIN dbo.variables v ON v.pu_id = pu.pu_id
	  JOIN dbo.event_subtypes es ON v.event_subtype_id = es.event_subtype_id
	WHERE es.event_subtype_Desc LIKE '%%' and pu.pu_id != 0
	ORDER BY pu.pu_desc
END
ELSE IF @Item = 0
BEGIN
	-- get all units
	SELECT DISTINCT pu_desc
	FROM dbo.prod_units
	WHERE pu_id != 0
	ORDER BY pu_desc	
END
*/

SET NOCOUNT OFF




















