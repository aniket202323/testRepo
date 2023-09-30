











-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_PUProducts]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-05
Version		:	1.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Created by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	23-Oct-2003
Version		: 	1.0.0
Purpose		: 	Return pl_id and pl_desc if any pu_products exists for that given prod_id
					and line description
-------------------------------------------------------------------------------------------------
*/

@intProdID		INT,
@vcrLineDesc	varchar(50)

AS
SET NOCOUNT ON

SELECT DISTINCT	pl.pl_id, pl_desc
FROM					dbo.prod_Units pu,
						dbo.prod_lines pl
WHERE					pl.pl_id = pu.pl_id
AND					pu.pu_id IN	(
										SELECT	pu_id
										FROM		dbo.pu_products
										WHERE		prod_id = @intProdID
										AND		pu_id IN	(
																SELECT	pu_id
																FROM		dbo.prod_units
																WHERE		pl_id IN	(
																						SELECT	pl.pl_id
																						FROM		dbo.prod_lines pl
																						WHERE		pl.pl_desc = @vcrLineDesc
																						)
																AND		Master_Unit IS NULL
																)
										)
										
SET NOCOUNT OFF













