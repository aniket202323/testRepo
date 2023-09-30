

-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Line]
/*
-------------------------------------------------------------------------------------------------
Stored Procedure: spLocal_PCMT_Get_Line

											PCMT Version 5.0.0 (P3 and P4)
-------------------------------------------------------------------------------------------------
Author			: 	Rick Perreault, Solutions et Technologies Industrielles inc.
Date created	:	12-Nov-2002	
Version			: 	1.0.0
SP Type			:	Function
Called by:		:	Excel file
Description		: 	This sp return the list of the lines on the server.
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
Date			:	2006-06-09
Version		:	2.0.0
Purpose		: 	Optional filter on RTT units
-------------------------------------------------------------------------------------------------
*/
@intType	integer

AS

SET NOCOUNT ON

IF @intType = 1
BEGIN
	SELECT DISTINCT pl.pl_id, pl.pl_desc
	FROM dbo.Prod_Lines pl
	  JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
	  JOIN dbo.Variables v ON v.pu_id = pu.pu_id
     JOIN dbo.event_subtypes es ON v.event_subtype_id = es.event_subtype_id
	WHERE pl.pl_id <> 0 AND es.event_subtype_Desc LIKE '%%'
	ORDER BY pl.pl_desc
END
ELSE
BEGIN
	SELECT DISTINCT pl.pl_id, pl.pl_desc
	FROM dbo.Prod_Lines pl
	  JOIN dbo.Prod_Units pu ON (pu.pl_id = pl.pl_id)
	WHERE pl.pl_id <> 0
	ORDER BY pl.pl_desc
END

SET NOCOUNT OFF
