

















-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Log_Users]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_Get_Log_Users
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP duplicates a user.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@dtmStartTime	datetime=NULL,
@dtmEndTime		datetime=NULL,
@intUserId		integer=NULL

AS

SET NOCOUNT ON

DECLARE @Users TABLE
(
[user_id]		INTEGER
)

--If user is not specified, then look for all users
IF @intUserId IS NULL BEGIN
	INSERT @Users ([user_id])
  	SELECT DISTINCT [user_id1]
  	FROM dbo.Local_PG_PCMT_Log_Users END
ELSE BEGIN
  	INSERT @Users ([user_id]) VALUES(@intUserId)
END

SELECT	
        CONVERT(VARCHAR,ls.[timestamp],120) AS [Entry On], 
		  u.username AS [Responsible], 
		  CASE 
				WHEN ls.type = 1 THEN 'ADD'
				WHEN ls.type = 2 THEN 'EDIT'
				ELSE 'OBSOLETE'
		  END AS [Type],
		  ls.user_name AS [User Name],
		  ls.user_desc AS [Description],
		  ls.User_id AS [User ID]
FROM	dbo.Local_PG_PCMT_Log_Users ls
        LEFT JOIN dbo.Users u		ON (u.[user_id] = ls.[user_id1])
WHERE ls.[timestamp] >= ISNULL(@dtmStartTime,'01-Jan-1900') AND
      ls.[timestamp] < ISNULL(@dtmEndTime,GETDATE()) AND
      ls.[user_id1] IN (SELECT [user_id] FROM @Users)
ORDER BY ls.[timestamp]

SET NOCOUNT OFF



















