


















CREATE PROCEDURE [dbo].[spLocal_PCMT_CreateChar]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_CreateChar
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
1.1.0      Dec-04-2008 Jonathan Corriveau, STI  Added an Update to set the Global desc right after the EXECUTE spEM_CreateChar call

*****************************************************************************************************************
*/
@cboProperty			INTEGER,
@txtParentChar			INTEGER,
@txtCharDesc			VARCHAR(50),
@txtUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intPropId				INTEGER,
@intParentCHarId		INTEGER,
@vcrCharDesc			VARCHAR(50),
@intCharId				INTEGER,
@vcrUserDesc			VARCHAR(255),
@intTransId				INTEGER,
@intTransType			INTEGER,
@intPUID					INTEGER,
@vcrUniqueDesc			VARCHAR(255),
@dtmServerTime			DATETIME

SET @intPropId			= @cboProperty
SET @intParentCharId = @txtParentChar
SET @vcrCharDesc 		= @txtCharDesc

--Creates char
EXECUTE spEM_CreateChar @vcrCharDesc, @intPropId, @txtUserId, @intCharId OUTPUT
UPDATE dbo.characteristics SET char_desc_global = @vcrCharDesc WHERE Char_Id = @@Identity

SET @vcrUserDesc = (SELECT username FROM dbo.users WHERE user_id = @txtUserId)
SET @vcrUniqueDesc = @vcrUserDesc + ' with PCMT 0001 ' + CAST(GETDATE() AS VARCHAR(50))
EXECUTE spEM_GetTransactionSecurity NULL, @intTransType OUTPUT, @intPUID OUTPUT
EXECUTE spEM_CreateUniqueTransDesc @vcrUniqueDesc OUTPUT
EXECUTE spEM_CreateTransaction @vcrUniqueDesc, NULL, @intTransType, NULL, 1, @intTransId OUTPUT
EXECUTE spEM_PutTransCharLinks @intTransId, @intCharId, @intParentCharId, @txtUserId
--EXECUTE spEM_GetPPSpecData @intCharId, @intTransId
EXECUTE spEM_GetServerTime @dtmServerTime OUTPUT
EXECUTE spEM_ApproveTrans @intTransId, @txtUserId, 1, @dtmServerTime, @dtmServerTime, @dtmServerTime


SELECT @intCharId AS [txtCharID]

SET NOCOUNT OFF













