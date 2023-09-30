


CREATE PROCEDURE [dbo].[spLocal_PCMT_GetPlantModel]
/*
---------------------------------------------------------------------------------------------------------------
											      PCMT Version 4.0.0 (P3 and P4)
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_Get_PlantModel
Author:					Rick Perreault(STI)
Date Created:			13-Nov-02
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
This sp return the plant model tree structure. PCMT Version 2.1.0 and 3.0.0

Called by:  			PCMT (VBA modules)
	
Revision	Date			Who									What
========	===========	==========================		===============================================================
2.0.2		23-Jun-08	Benoit Saenz de Ugarte (STI)	Production Group with the UDP PLANTMODELFILTER = 1 are filtered
2.0.1		24-Aug-07	Vincent Rouleau (STI)			The SP replaces global descriptions by local description if they
																	are not available.
2.0.0		23-May-06	Marc Charest (STI)				The SP brings back the whole plant model if @intFlagRTT 
																	parameter is not set (null) The SP returns only units that 
																	have RTT groups if @intFlagRTT parameter is set to 1
1.1.0		01-Noc-05	Normand Carbonneau (STI)		Compliant with Proficy 3 and 4.
																	Added [dbo] template when referencing objects.
																	Added registration of SP Version into AppVersions table.
																	PCMT Version 4.0.0
*/
@intUserId		INTEGER,
@intFlagRTT		INTEGER = NULL,
@intShowVars	INTEGER = NULL,
@bitGlobal		BIT = 1,
@bitFilter		BIT = 1

AS

SET NOCOUNT ON

DECLARE
@Item				VARCHAR(50),
@filter_udp_id	INT,
@Table_id		INT

--Getting objects IDs on which user as sufficient rights.
CREATE TABLE #PCMTPLIDs(Item_Id INTEGER)
CREATE TABLE #PCMTPUIDs(Item_Id INTEGER)
CREATE TABLE #PCMTPUGIDs(Item_Id INTEGER)
INSERT #PCMTPLIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'prod_lines', 'pl_id', @intUserId
INSERT #PCMTPUIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'prod_units', 'pu_id', @intUserId
INSERT #PCMTPUGIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'pu_groups', 'pug_id', @intUserId

--Get the translate item value
SELECT @Item = [Translation]
FROM dbo.Local_PG_PCMT_Translations t
     JOIN dbo.Local_PG_PCMT_Languages l ON (t.lang_id = l.lang_id)
     JOIN dbo.Local_PG_PCMT_Items i ON (t.item_id = i.item_id)
WHERE i.item = 'RTT Unit' AND l.is_active = 1

SELECT @Item = ''

--UDP id to filter Plant Model
SET @table_id = (SELECT tableid FROM tables WHERE tablename = 'PU_Groups')
SET @filter_udp_id = (SELECT table_field_id FROM table_fields WHERE table_field_desc = 'PLANTMODELFILTER')
IF (@filter_udp_id IS NOT NULL AND @table_id IS NOT NULL AND @bitFilter = 1)
	BEGIN
		PRINT 'Delete'
		DELETE FROM #PCMTPUGIDs WHERE Item_Id IN (SELECT keyid FROM table_fields_values WHERE table_field_id = @filter_udp_id AND tableid = @table_id AND value = 1)
	END

IF @intShowVars IS NULL BEGIN

	SELECT 
		pl.pl_id, 
		CASE WHEN @bitGlobal = 1 THEN COALESCE(pl.pl_desc_global, pl.pl_desc_local) ELSE pl.pl_desc_local END AS [pl_desc], 
		pu.pu_id, 
		CASE WHEN @bitGlobal = 1 THEN COALESCE(pu.pu_desc_global, pu.pu_desc_local) ELSE pu.pu_desc_local END AS [pu_desc], 
		pug.pug_id, 
		CASE WHEN @bitGlobal = 1 THEN COALESCE(pug.pug_desc_global, pug.pug_desc_local) ELSE pug.pug_desc_local END AS [pug_desc], 
		CASE WHEN pu.master_unit IS NULL THEN pu.pu_id ELSE pu.master_unit END AS [Rank],
		CASE WHEN pu.master_unit IS NULL THEN 'Master' ELSE 'Slave' END AS [UnitType],
		NULL, NULL
	FROM 
		dbo.Prod_Lines pl
		JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
		JOIN dbo.Pu_Groups pug ON (pug.pu_id = pu.pu_id),
		#PCMTPLIDs pl2, #PCMTPUIDs pu2, #PCMTPUGIDs pug2
	WHERE 
		pl.pl_id <> 0 AND ((pug_desc LIKE '%' + @Item + '%' AND @intFlagRTT = 1) OR (@intFlagRTT IS NULL))
		AND pl.pl_id = pl2.item_id AND pu.pu_id = pu2.item_id AND pug.pug_id = pug2.item_id
		AND pl.pl_desc_local IS NOT NULL
		AND pu.pu_desc_local IS NOT NULL
		AND pug.pug_desc_local IS NOT NULL
	ORDER BY pl.pl_desc, Rank, UnitType, pu.pu_desc, pug.pug_desc END
	
ELSE BEGIN

	SELECT 
		pl.pl_id, 
		CASE WHEN @bitGlobal = 1 THEN COALESCE(pl.pl_desc_global, pl.pl_desc_local) ELSE pl.pl_desc_local END AS [pl_desc], 
		pu.pu_id, 
		CASE WHEN @bitGlobal = 1 THEN COALESCE(pu.pu_desc_global, pu.pu_desc_local) ELSE pu.pu_desc_local END AS [pu_desc], 
		pug.pug_id, 
		CASE WHEN @bitGlobal = 1 THEN COALESCE(pug.pug_desc_global, pug.pug_desc_local) ELSE pug.pug_desc_local END AS [pug_desc], 
		CASE WHEN pu.master_unit IS NULL THEN pu.pu_id ELSE pu.master_unit END AS [Rank],
		CASE WHEN pu.master_unit IS NULL THEN 'Master' ELSE 'Slave' END AS [UnitType],
		v.var_id, 
		CASE WHEN @bitGlobal = 1 THEN v.var_desc_global ELSE v.var_desc_local END AS [var_desc]	
	FROM 
		dbo.Prod_Lines pl
		JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
		JOIN dbo.Pu_Groups pug ON (pug.pu_id = pu.pu_id)
		JOIN dbo.variables v ON (v.pug_id = pug.pug_id),
		#PCMTPLIDs pl2, #PCMTPUIDs pu2, #PCMTPUGIDs pug2
	WHERE 
		pl.pl_id <> 0 AND ((pug_desc LIKE '%' + @Item + '%' AND @intFlagRTT = 1) OR (@intFlagRTT IS NULL))
		AND pl.pl_id = pl2.item_id AND pu.pu_id = pu2.item_id AND pug.pug_id = pug2.item_id
		AND pl.pl_desc_local IS NOT NULL
		AND pu.pu_desc_local IS NOT NULL
		AND pug.pug_desc_local IS NOT NULL
		AND v.var_desc_global IS NOT NULL AND v.var_desc_local IS NOT NULL
	ORDER BY pl.pl_desc, Rank, UnitType, pu.pu_desc, pug.pug_desc, v.var_desc

END

DROP TABLE #PCMTPLIDs
DROP TABLE #PCMTPUIDs
DROP TABLE #PCMTPUGIDs

SET NOCOUNT OFF









