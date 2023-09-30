













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Log_ProductionGroup]
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
Created By	:	Rick Perreailt, Solutions et Technologies Industrielles Inc.
On				:	19-Dec-02	
Version		:	1.0.0
Purpose		:	This SP gets variables logs from Local_PG_PCMT_log_variables
					Replaced #Users temp table by @Users Table variable
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@dtmStartTime	datetime = NULL,
@dtmEndTime		datetime = NULL,
@intUserId		integer = NULL

AS
SET NOCOUNT ON

DECLARE @Users TABLE
(
[user_id]		integer
)

--If user is not specified, then look for all users
IF @intUserId IS NULL
  INSERT @Users ([user_id])
  SELECT DISTINCT [user_id]
  FROM dbo.Local_PG_PCMT_Log_ProductionGroups
ELSE
  INSERT @Users ([user_id]) VALUES(@intUserId)

SELECT CONVERT(VARCHAR,lp.[timestamp],120) AS [Entry On], 
	u.username AS [User], 
	Type, 
	pl.pl_desc AS Line,
	pu.pu_desc AS Unit,
        lp.pug_desc AS [Production Group]
FROM	dbo.Local_PG_PCMT_Log_ProductionGroups lp
	LEFT JOIN dbo.Users u		ON (u.[user_id] = lp.[user_id])
	LEFT JOIN dbo.Prod_Units pu 	ON (pu.pu_id = lp.pu_id)
	LEFT JOIN dbo.Prod_Lines pl 	ON (pl.pl_id = pu.pl_id)
WHERE lp.[timestamp] >= ISNULL(@dtmStartTime,'01-Jan-1900') AND
      lp.[timestamp] < ISNULL(@dtmEndTime,GETDATE()) AND
      lp.[user_id] IN (SELECT [user_id] FROM @Users)
ORDER BY lp.[timestamp]

SET NOCOUNT OFF















