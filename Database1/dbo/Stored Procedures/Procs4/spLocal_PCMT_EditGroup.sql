













CREATE PROCEDURE [dbo].[spLocal_PCMT_EditGroup]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_EditGroup
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP edits group description.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@cboGroup			INTEGER,
@txtGroupDesc		VARCHAR(50),
@txtUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@intGroupId			INTEGER,
@vcrGroupDesc		VARCHAR(50)

SET @intGroupId	= @cboGroup
SET @vcrGroupDesc = @txtGroupDesc

EXECUTE spem_renameusergroup @intGroupId, @vcrGroupDesc, @txtUserId

SELECT @intGroupId

INSERT Local_PG_PCMT_Log_Groups
(	Timestamp, User_id1, Type, Group_id, Group_Desc)
VALUES
(	GETDATE(), @txtUserId, 2, @intGroupId, @vcrGroupDesc)

SET NOCOUNT OFF























