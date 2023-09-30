














CREATE PROCEDURE [dbo].[spLocal_PCMT_DuplicateGroup]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_DuplicateGroup
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP duplicates group.

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

*****************************************************************************************************************
*/
@txtGroupDesc			VARCHAR(50),
@txtUserId				INTEGER

AS

SET NOCOUNT ON

DECLARE
@vcrGroupDesc			VARCHAR(50),
@intGroupId				INTEGER

SET @vcrGroupDesc		= @txtGroupDesc

--Duplicate user group
EXECUTE spem_createusergroup @vcrGroupDesc, @txtUserId, @intGroupId OUTPUT

SELECT @intGroupId

INSERT Local_PG_PCMT_Log_Groups
(	Timestamp, User_id1, Type, Group_id, Group_Desc)
VALUES
(	GETDATE(), @txtUserId, 1, @intGroupId, @vcrGroupDesc)

SET NOCOUNT OFF






















