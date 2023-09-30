
CREATE PROCEDURE [dbo].[spLocal_PCMT_DeleteChar]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_DeleteChar
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
@cboChar					INTEGER,
@txtUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intCharId				INTEGER

SET @intCharId 		= @cboChar

--Creates user group
EXECUTE spEM_DropChar @intCharId, @txtUserId

SELECT @intCharId

/*
INSERT Local_PG_PCMT_Log_Groups
(	Timestamp, User_id1, Type, Group_id, Group_Desc)
VALUES
(	GETDATE(), @txtUserId, 1, @intGroupId, @vcrGroupDesc)
*/

SET NOCOUNT OFF














