














CREATE    PROCEDURE [dbo].[spLocal_PCMT_EditChar]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_EditChar
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP creates a user group.

Called by:  			PCMT.xls

Revision	Date		Who						What
========	==========	=================== 	=============================================
1.3			2008/10/22	Vincent Rouleau, STI	Modify local and global description to ensure they both change
*****************************************************************************************************************
*/
@cboChar					INTEGER,
@txtParentChar			INTEGER,
@txtCharDesc			VARCHAR(50),
@txtUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intCharId				INTEGER,
@intParentCHarId		INTEGER,
@vcrCharDesc			VARCHAR(50)

SET @intCharId 		= @cboChar
SET @intParentCHarId = @txtParentChar
SET @vcrCharDesc 		= @txtCharDesc

--Creates user group
EXECUTE spEM_RenameChar @intCharId, @vcrCharDesc, @txtUserId

--Modify the global description if needed
IF (SELECT COALESCE(char_desc_global, '') FROM dbo.characteristics WHERE Char_Id = @intCharId) <> @vcrCharDesc
BEGIN
	UPDATE dbo.characteristics SET char_desc_global = @vcrCharDesc WHERE Char_Id = @intCharId
END

--Modify the local description if needed
IF (SELECT COALESCE(char_desc_local, '') FROM dbo.characteristics WHERE Char_Id = @intCharId) <> @vcrCharDesc
BEGIN
	UPDATE dbo.characteristics SET char_desc_local = @vcrCharDesc WHERE Char_Id = @intCharId
END

UPDATE dbo.characteristics SET derived_from_parent = @intParentCHarId WHERE char_id = @intCharId

SELECT @intCharId

/*
INSERT Local_PG_PCMT_Log_Groups
(	Timestamp, User_id1, Type, Group_id, Group_Desc)
VALUES
(	GETDATE(), @txtUserId, 1, @intGroupId, @vcrGroupDesc)
*/

SET NOCOUNT OFF




























