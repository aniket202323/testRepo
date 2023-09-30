











CREATE PROCEDURE [dbo].[spLocal_PCMT_MoveChar]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_MoveChar
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP creates a user group.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@txtParentChar			INTEGER,
@txtCharId				INTEGER,
@txtUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intParentCHarId		INTEGER,
@intCharId				INTEGER,
@vcrUserDesc			VARCHAR(255),
@intTransId				INTEGER,
@intTransType			INTEGER,
@intPUID					INTEGER,
@vcrUniqueDesc			VARCHAR(255),
@dtmServerTime			DATETIME

SET @intParentCharId = CASE WHEN @txtParentChar = 0 THEN NULL ELSE @txtParentChar END
SET @intCharId			= @txtCharId

SET @vcrUserDesc = (SELECT username FROM dbo.users WHERE user_id = @txtUserId)
SET @vcrUniqueDesc = @vcrUserDesc + ' with PCMT 0001 ' + CAST(GETDATE() AS VARCHAR(50))
EXECUTE spEM_GetTransactionSecurity NULL, @intTransType OUTPUT, @intPUID OUTPUT
EXECUTE spEM_CreateUniqueTransDesc @vcrUniqueDesc OUTPUT
EXECUTE spEM_CreateTransaction @vcrUniqueDesc, NULL, @intTransType, NULL, 1, @intTransId OUTPUT
EXECUTE spEM_PutTransCharLinks @intTransId, @intCharId, @intParentCharId, @txtUserId
EXECUTE spEM_GetServerTime @dtmServerTime OUTPUT
EXECUTE spEM_ApproveTrans @intTransId, @txtUserId, 1, @dtmServerTime, @dtmServerTime, @dtmServerTime


SELECT @intCharId AS [txtCharID]

/*
INSERT Local_PG_PCMT_Log_Groups
(	Timestamp, User_id1, Type, Group_id, Group_Desc)
VALUES
(	GETDATE(), @txtUserId, 1, @intGroupId, @vcrGroupDesc)
*/

SET NOCOUNT OFF













