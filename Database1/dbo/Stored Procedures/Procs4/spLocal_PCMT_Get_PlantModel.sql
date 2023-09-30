













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_PlantModel]
/*
---------------------------------------------------------------------------------------------------------------
											      PCMT Version 5.0.0 (P3 and P4)
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
	
Revision	Date			Who								What
========	===========	==========================	===============================================================
2.0.0		23-May-06	Marc Charest (STI)			The SP brings back the whole plant model if @intFlagRTT 
																parameter is not set (null) The SP returns only units that 
																have RTT groups if @intFlagRTT parameter is set to 1
1.1.0		01-Noc-05	Normand Carbonneau (STI)	Compliant with Proficy 3 and 4.
																Added [dbo] template when referencing objects.
																Added registration of SP Version into AppVersions table.
																PCMT Version 5.0.3
*/
@intFlagRTT		INTEGER = NULL

AS

SET NOCOUNT ON


SELECT pl.pl_id, pl.pl_desc, pu.pu_id, pu.pu_desc, pug.pug_id, pug.pug_desc
FROM dbo.Prod_Lines pl
     JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
     JOIN dbo.Pu_Groups pug ON (pug.pu_id = pu.pu_id)
WHERE pl.pl_id <> 0 --AND ((pug_desc LIKE '%RTT%' AND @intFlagRTT = 1) OR (@intFlagRTT IS NULL))
ORDER BY pl.pl_desc, pu.pu_desc, pug.pug_desc

SET NOCOUNT OFF















