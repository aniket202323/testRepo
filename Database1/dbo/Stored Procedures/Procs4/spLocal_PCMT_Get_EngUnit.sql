















-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_EngUnit]
/*
-------------------------------------------------------------------------------------------------
Stored procedure: spLocal_PCMT_Get_EngUnit

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Rick Perreault, Solutions et Technologies Industrielles inc.
Date created	:	13-Nov-2002	
Version			: 	1.0.0
SP Type			: 	function
Called by		: 	Excel file
Description		: 	This sp return all the engineering units that have been insert
               	on the Process Audit unit.
						PCMT Version 2.1.0 and 3.0.0
Editor tab spacing: 3
-------------------------------------------------------------------------------------------------
Revision date who what
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Updated By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-05-29
Version		:	2.0.0
Purpose		: 	Now retreives engineering units using variable's event subtype
-------------------------------------------------------------------------------------------------
*/

AS
SET NOCOUNT ON

SELECT DISTINCT v.eng_units
FROM dbo.Variables v
  JOIN dbo.event_subtypes es ON v.event_subtype_id = es.event_subtype_id
WHERE v.eng_units IS NOT NULL AND es.event_subtype_Desc LIKE '%%'
ORDER BY v.eng_units

SET NOCOUNT OFF

















