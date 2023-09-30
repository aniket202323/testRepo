



CREATE PROCEDURE [dbo].[spLocal_PCMT_GetUserRoleType]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_GetUserRoleType
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

spLocal_PCMT_GetUserRoleType 62
*****************************************************************************************************************
*/
@cboUser					INTEGER

AS

SET NOCOUNT ON

--Get the Role-Based setting of the user
SELECT Role_Based_Security FROM dbo.Users WHERE user_id = @cboUser

SET NOCOUNT OFF















