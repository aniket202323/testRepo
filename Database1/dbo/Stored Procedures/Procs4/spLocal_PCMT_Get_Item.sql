
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Item]
/*
-------------------------------------------------------------------------------------------------
											PCMT Version 5.1.1
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2005-10-31
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	13-Nov-2002	
Version		: 	1.0.0
Purpose		: 	This sp return the item transalation of given item.
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@vcrItem	varchar(50)

AS

SET NOCOUNT ON

SELECT [Translation]
FROM dbo.Local_PG_PCMT_Translations t
     JOIN dbo.Local_PG_PCMT_Languages l ON (t.lang_id = l.lang_id)
     JOIN dbo.Local_PG_PCMT_Items i ON (t.item_id = i.item_id)
WHERE i.item = @vcrItem AND l.is_active = 1

SET NOCOUNT OFF















