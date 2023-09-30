











-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_UnitDesc_for_PUProduct]
/*
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-05
Version		:	1.3.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					Replaced #tblLines temp table by @tblLines TABLE variable.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Modified by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	23-Mar-2004
Version		: 	1.2.0
Purpose		:	Change the WHERE clauses to fit both FC and BF lines
-------------------------------------------------------------------------------------------------
Modified by	: 	Clement Morin, Solutions et Technologies Industrielles inc.
On				:	07-Jul-2003
Version		: 	1.1.0
Purpose		:	Make the single line or multi line edit possible
-------------------------------------------------------------------------------------------------
Created by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	05-Mar-2003
Version		: 	1.0.0
Purpose		: 	Return all unit descriptions for a given product ID for all PU_Products instances
-------------------------------------------------------------------------------------------------
*/

@intProdId		INT,
@vcrLineDesc	varchar(500) = NULL,
@intsingleline	INT = NULL

AS

SET NOCOUNT ON

DECLARE
@intBegPos	INT,
@intEndPos	INT,
@vcrLine		varchar(50)

DECLARE @tblLines TABLE
(
Line	varchar(50)
)

SET @intBegPos = 1
	
WHILE @intBegPos <= LEN(@vcrLineDesc) 
	BEGIN
		SET @intEndPos = CHARINDEX('[REC]', @vcrLineDesc, @intBegPos)
		SET @vcrLine = SUBSTRING(@vcrLinedesc, @intBegPos, @intEndPos - @intBegPos)
		
	   INSERT @tblLines(Line) VALUES (@vcrLine)
	   
		SET @intBegPos = @intEndPos + 5
	END

IF @intsingleline = 1
	BEGIN
		SELECT	pu_desc
		FROM		dbo.pu_products pup,
					dbo.Prod_Lines pl
		JOIN		dbo.Prod_Units pu ON (pl.pl_id = pu.pl_id)
		WHERE		pu.master_unit IS NULL
		AND		--charindex(pl_desc,pu_desc) <> 0 and
	      		--len(pl_desc) <> len(pu_desc) and 
					pup.pu_id = pu.pu_id
		AND		pup.prod_id = @intProdId
		AND		EXISTS	(
								SELECT	Line
								FROM		@tblLines
								WHERE		Line = pl.pl_desc
								)
		ORDER BY	PU_Desc
	END 
ELSE
	BEGIN
 		SELECT	SUBSTRING(pu_desc,LEN(pl_desc)+2,LEN(pu_desc)-(LEN(pl_desc)+1))
		FROM		dbo.pu_products pup,
					dbo.Prod_Lines pl
		JOIN		dbo.Prod_Units pu ON (pl.pl_id = pu.pl_id)
		WHERE		pu.master_unit IS NULL
		AND		--charindex(pl_desc,pu_desc) <> 0 and
	      		--len(pl_desc) <> len(pu_desc) and 
					pup.pu_id = pu.pu_id
		AND		pup.prod_id = @intProdId
		AND		EXISTS	(
								SELECT	Line
								FROM		@tblLines
								WHERE		Line = pl.pl_desc
								)
		ORDER BY	PU_Desc 
	END

SET NOCOUNT OFF













