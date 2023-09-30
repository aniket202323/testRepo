
-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Log_DataTypes]
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
					Replaced #Users temp table with @Users table variable
					PCMT Version 5.0.3
-------------------------------------------------------------------------------------------------
Created By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	19-Dec-02	
Version		:	1.0.0
Purpose		:	This SP gets specifications logs from Local_PG_PCMT_log_specifications
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@dtmStartTime	datetime=NULL,
@dtmEndTime		datetime=NULL,
@intUserId		integer=NULL

AS
SET NOCOUNT ON

DECLARE @Users TABLE(
	[user_id]	INTEGER
)

--If user is not specified, then look for all users
IF @intUserId IS NULL
  INSERT @Users ([user_id])
  SELECT DISTINCT [user_id1]
  FROM dbo.Local_PG_PCMT_Log_DataTypes
ELSE
  INSERT @Users ([user_id]) VALUES(@intUserId)


SELECT	
        CONVERT(VARCHAR,ls.[timestamp],120) AS [Entry On], 
		  u.username AS [User], 
		  Type, 
		  Data_Type_Desc AS [Data Type],
		  Phrase_Value AS [Phrase], 
		  Phrase_Order AS [Phrase Order]
FROM	dbo.Local_PG_PCMT_Log_DataTypes ls
        LEFT JOIN dbo.Users u	ON (u.[user_id] = ls.[user_id1])
WHERE ls.[timestamp] >= ISNULL(@dtmStartTime,'01-Jan-1900') AND
      ls.[timestamp] < ISNULL(@dtmEndTime,GETDATE()) AND
      ls.[user_id1] IN (SELECT [user_id] FROM @Users)
ORDER BY ls.[timestamp]

SET NOCOUNT OFF
















