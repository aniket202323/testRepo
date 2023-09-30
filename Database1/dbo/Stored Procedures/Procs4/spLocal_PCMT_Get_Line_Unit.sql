

-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Line_Unit]
/*
-------------------------------------------------------------------------------------------------
Created by	: 	Jonathan Corriveau, STI
On				:	2008-11-17
Version		: 	1.5.0
Purpose		:  Return the unit name without the line name when multi line (add validation to know if the pl_desc is in the pu_desc)
-------------------------------------------------------------------------------------------------
Modified by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	10-Sep-2007
Version		: 	1.4.0
Purpose		:	We're no more looking at line name within unit name.
-------------------------------------------------------------------------------------------------
Updated By	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-01-03
Version		:	1.3.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					QSMT Version 10.0.0
-------------------------------------------------------------------------------------------------
Modified by	: 	Marc Charest, Solutions et Technologies Industrielles inc.
On				:	23-Mar-2004
Version		: 	1.2.0
Purpose		:	Change the WHERE clauses to fit both FC & BF lines
-------------------------------------------------------------------------------------------------
Modified by	: 	Clement Morin, Solutions et Technologies Industrielles inc.
On				:	07-Jul-2003
Version		: 	1.1.0
Purpose		:	Make the single line or multi line edit possible
-------------------------------------------------------------------------------------------------
Created by	: 	Rick Perreault, Solutions et Technologies Industrielles inc.
On				:	24-Feb-2003
Version		: 	1.0.0
Purpose		: 	Return the list of the master unit for a given line
-------------------------------------------------------------------------------------------------
*/

@intLine			INT,
@intSingleLine	INT = NULL

AS
SET NOCOUNT ON

IF @intSingleLine = 1
	BEGIN
		SELECT	pu_desc, pu_id
		FROM		dbo.Prod_Lines pl
		JOIN		dbo.Prod_Units pu ON (pl.pl_id = pu.pl_id)
		WHERE		(pu.master_unit IS NULL) --AND CHARINDEX(pl_desc,pu_desc) <> 0 AND
					--LEN(pl_desc) <> LEN(pu_desc) 
		AND		(pl.pl_id = @intLine)
		ORDER BY	PU_Desc 
	END
ELSE
	BEGIN
		SELECT	CASE WHEN(CHARINDEX(pl_desc, pu_desc) >0) THEN SUBSTRING(pu_desc, LEN(pl_desc) + 2, LEN(pu_desc) - (LEN(pl_desc) + 1)) ELSE pu_desc END C, pu_id
		FROM		dbo.Prod_Lines pl
		JOIN		dbo.Prod_Units pu ON (pl.pl_id = pu.pl_id)
		WHERE		(pu.master_unit IS NULL) --AND CHARINDEX(pl_desc,pu_desc) <> 0 AND
					--LEN(pl_desc) <> LEN(pu_desc)
		AND		(pl.pl_id = @intLine)
		ORDER BY	PU_Desc 
	END

SET NOCOUNT OFF
