
CREATE PROCEDURE [dbo].[spLocal_PCMT_CreateRoleMember]
/*
-------------------------------------------------------------------------------------------------
Created By	:	Benoit Saenz de Ugarte (STI)
Date			:	2008-06-24
Version		:	1.0.0
Purpose		: 	This SP creates a role member
-------------------------------------------------------------------------------------------------
Updated By	:	Juan Pablo Galanzini (ARIDO)
Date		:	2014-07-29
Version		:	2.0
Purpose		: 	Updated in PPA 6 to fix an error:  Missing the formal parameter "@Domain" 
-------------------------------------------------------------------------------------------------
*/
@intRoleId	INT,
@memberid	INT,
@username	VARCHAR(30),
@UserId		INT
AS

SET NOCOUNT ON

DECLARE	@intSecurityId	INT,
		@Domain			NVARCHAR(30)

SET @Domain = ''

--Creates role membership
EXECUTE dbo.spEM_CreateSecurityRoleMember 
	@intRoleId, @memberid, @username, @UserId, @Domain, @intSecurityId OUTPUT

--EXECUTE @RC = [GBDB].[dbo].[spEM_CreateSecurityRoleMember] 
--	@Role_User_Id, @User_Id_1, @Member_Desc, @User_Id, @Domain, @User_Role_Security_Id OUTPUT

SELECT @intSecurityId

SET NOCOUNT OFF

