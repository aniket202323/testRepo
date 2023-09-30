














-------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Get_Log_User]
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
Created By	:	Rick Perreault, Solutions et Technologies Industrielles Inc.
On				:	19-Dec-02	
Version		:	1.0.0
Purpose		:	This SP get the list users in the log type table
					PCMT Version 2.1.0 and 3.0.0
-------------------------------------------------------------------------------------------------
*/

@intLogType	SMALLINT

AS

SET NOCOUNT ON

--Data Type Group Log Users
IF  @intLogType = 1
	SELECT DISTINCT lp.[User_id1], u.username
	FROM dbo.Local_PG_PCMT_Log_DataTypes lp
	JOIN dbo.Users u ON (lp.[user_id1] = u.[user_id])
	ORDER BY u.username
 
--Production Group Log Users
IF  @intLogType = 2
	SELECT DISTINCT lp.[User_id], u.username
	FROM dbo.Local_PG_PCMT_Log_ProductionGroups lp
	JOIN dbo.Users u ON (lp.[user_id] = u.[user_id])
	ORDER BY u.username

--Security Group Log Users
IF  @intLogType = 3
	SELECT DISTINCT lp.[User_id1], u.username
	FROM dbo.Local_PG_PCMT_Log_Groups lp
	JOIN dbo.Users u ON (lp.[user_id1] = u.[user_id])
	ORDER BY u.username

--Specification Log Users
IF  @intLogType = 4
	SELECT DISTINCT ls.[User_id], u.username
	FROM dbo.Local_PG_PCMT_Log_Specifications ls
	JOIN dbo.Users u ON (ls.[user_id] = u.[user_id])
	ORDER BY u.username

--User Log Users
IF  @intLogType = 5
	SELECT DISTINCT lp.[User_id1], u.username
	FROM dbo.Local_PG_PCMT_Log_Users lp
	JOIN dbo.Users u ON (lp.[user_id1] = u.[user_id])
	ORDER BY u.username

--Variable Log Users
IF  @intLogType = 6
	SELECT DISTINCT lv.[User_id], u.username
	FROM dbo.Local_PG_PCMT_Log_Variables lv
	JOIN dbo.Users u ON (lv.[user_id] = u.[user_id])
	ORDER BY u.username

SET NOCOUNT OFF
















