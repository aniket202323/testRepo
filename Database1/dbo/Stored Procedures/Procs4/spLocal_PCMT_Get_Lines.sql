

-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Lines]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-03
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	24-Feb-2003
Version		: 	1.0.0
Purpose		: 	Return the list of the line on the server.
-------------------------------------------------------------------------------------------------
*/
@intUserId		INTEGER

AS

SET NOCOUNT ON

CREATE TABLE #PCMTPLIDs(Item_Id INTEGER)
INSERT #PCMTPLIDs (Item_Id)
EXECUTE spLocal_PCMT_GetObjectIDs 'prod_lines', 'pl_id', @intUserId

SELECT		pl.pl_id, pl.pl_desc, 'xxx' --left(min(p.prod_desc),3)
FROM			dbo.Prod_Lines pl
JOIN			dbo.Prod_Units pu ON (pl.pl_id = pu.pl_id)
LEFT JOIN	dbo.PU_Products pup ON (pu.pu_id = pup.pu_id)
LEFT JOIN	dbo.Products p ON (pup.prod_id = p.prod_id),
				#PCMTPLIDs pl2
WHERE			pl.pl_id <> 0
				AND pl.pl_id = pl2.item_id
GROUP BY		pl.pl_id, pl.pl_desc
ORDER BY		pl_desc 

DROP TABLE #PCMTPLIDs

SET NOCOUNT OFF
