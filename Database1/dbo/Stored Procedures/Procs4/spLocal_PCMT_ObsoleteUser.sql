
CREATE PROCEDURE [dbo].[spLocal_PCMT_ObsoleteUser]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_ObsoleteUser
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:				ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP is...

Called by:  			PCMT.xls

Revision Date			Who								What
========	==========	=================== 			=============================================
1.0.1		2007-08-31	Vincent Rouleau, STI			Add role-based security
2.0			2014-07-02	Facundo Sosa (Arido Software)   Send Parameters @UseSSO and @SSOUserId to spEM_PutUserData in PPA6

begin transaction
exec spLocal_PCMT_ObsoleteUser 139, 'z_obs_NewUser3', 1
rollback transaction

*****************************************************************************************************************
*/
@cboUser			INTEGER,
@txtUserName		VARCHAR(30),
@txtUserId			INTEGER

AS

SET NOCOUNT ON

DECLARE
@intUserId			INTEGER,
@vcrUserName		VARCHAR(30),
@RoleBased			INTEGER

SET @intUserId		= @cboUser
SET @vcrUserName	= @txtUserName

--Get the role-based security
SET @RoleBased = (SELECT Role_Based_Security FROM dbo.users WHERE user_id = @intUserId)

EXECUTE spem_renameuser @intUserId, @vcrUserName, @txtUserId
EXECUTE spem_putuserdata @intUserId, NULL, NULL, 0, NULL, NULL, @txtUserId, @RoleBased, 0, 0, 0, null


SELECT @intUserId

INSERT Local_PG_PCMT_Log_Users
(	Timestamp, User_id1, Type, User_id, Mixed_Mode_Login, 
	Password, Role_Based_Security, User_Desc, User_Name, 
	View_Id, WindowsUserInfo, Active
)
VALUES
(	GETDATE(), @txtUserId, 3, @intUserId, 0, 
	NULL, 0, NULL, @vcrUserName, 
	NULL, NULL, 0
)

SET NOCOUNT OFF
