













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_SamplingOffset]
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
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	13-Nov-2002	
Version		: 	1.0.0
Purpose		: 	This sp return all the sampling interval that have been insert
               on the Process Audit unit.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

AS

SET NOCOUNT ON

DECLARE
@Item	varchar(50)

--Get the translate item value
SELECT @Item = [Translation]
FROM dbo.Local_PG_PCMT_Translations t
     JOIN dbo.Local_PG_PCMT_Languages l ON (t.lang_id = l.lang_id)
     JOIN dbo.Local_PG_PCMT_Items i ON (t.item_id = i.item_id)
WHERE i.item = 'RTT Unit' AND l.is_active = 1

SET @Item = ''

SELECT DISTINCT v.sampling_offset
FROM dbo.Variables v
     JOIN dbo.Prod_Units pu ON (v.pu_id = pu.pu_id)
     JOIN dbo.Event_Types et ON (v.event_type = et.et_id)
WHERE pu.pu_desc LIKE '%' + @Item + '%' AND 
      et.et_desc = 'Time' AND
      v.sampling_offset IS NOT NULL
ORDER BY v.sampling_offset

SET NOCOUNT OFF















