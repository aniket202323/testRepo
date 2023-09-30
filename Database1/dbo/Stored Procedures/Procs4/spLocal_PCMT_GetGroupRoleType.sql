





CREATE PROCEDURE [dbo].[spLocal_PCMT_GetGroupRoleType]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetGroupRoleType
Author:					Vincent Rouleau (STI)
Date Created:			2007-08-30
SP Type:					ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP returns the Role-Based type of the users

Called by:  			PCMT.xls

Revision Date			Who						What
========	==========	=================== 	=============================================

spLocal_PCMT_GetGroupRoleType 136, 'Operator'
*****************************************************************************************************************
*/
@GroupId				INTEGER,
@GroupName			VARCHAR(25)

AS

SET NOCOUNT ON

--Get the Role-Based setting of the user
IF EXISTS (SELECT User_Id FROM dbo.users WHERE User_Id = @GroupId AND Username = @GroupName AND Is_Role = 1)
BEGIN
	SELECT 1
END
ELSE
BEGIN
	SELECT 0
END

SET NOCOUNT OFF















