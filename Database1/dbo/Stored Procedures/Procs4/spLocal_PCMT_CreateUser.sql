
CREATE PROCEDURE [dbo].[spLocal_PCMT_CreateUser]
/*
*****************************************************************************************************************
Stored Procedure:		spLocal_PCMT_CreateUser
Author:					Marc Charest (STI)
Date Created:			2006-11-14
SP Type:				ADO or SDK Call
Editor Tab Spacing:	3

Description:
=========
This SP creates a new user.

Called by:  			PCMT.xls

Revision	Date		Who									What
========	==========	=================== 				=============================================
2.1			2015-01-15	Pablo Galanzini	(Arido Software)	Send Parameters @UseSSO and @SSOUserId to spEM_PutUserData in PPA6
*****************************************************************************************************************
*/
@txtUserName		VARCHAR(30),
@txtUserDesc		VARCHAR(255),
@txtPassword		VARCHAR(30),
@txtWinUserInfo		VARCHAR(200),
@cboView			INTEGER,
@chkActive			INTEGER,
@chkIsRole			INTEGER,
@chkMixMode			INTEGER,
@txtUserId			INTEGER,
@cboLanguage		INTEGER

AS

SET NOCOUNT ON

DECLARE
@vcrUserName			VARCHAR(30),
@vcrUserDesc			VARCHAR(255),
@vcrPassword			VARCHAR(30),
@vcrWinUserInfo		VARCHAR(200),
@intViewId				INTEGER,
@intActive				INTEGER,
@intIsRole				INTEGER,
@intUserId				INTEGER,
@intMixMode				INTEGER,
@intLanguageId			INTEGER,
@intLanguageParmId	INTEGER

SET @vcrUserName		= @txtUserName
SET @vcrUserDesc		= @txtUserDesc
SET @vcrPassword		= @txtPassword
SET @vcrWinUserInfo	= @txtWinUserInfo
SET @intViewId			= @cboView
SET @intActive			= @chkActive
SET @intIsRole			= @chkIsRole
SET @intMixMode		= @chkMixMode
SET @intLanguageId	= @cboLanguage

--Creating user
EXECUTE spem_createuser @vcrUserName, @txtUserId, @intUserId OUTPUT
--Updating new user with values
EXECUTE spem_putuserdata @intUserId, @vcrUserDesc, @vcrPassword, @intActive, @intViewId, @vcrWinUserInfo, @txtUserId, @intIsRole, @intMixMode, 0, 0, null

--Adding default language
IF @intLanguageId IS NOT NULL BEGIN
	SET @intLanguageParmId	= (SELECT parm_id FROM dbo.parameters WHERE parm_name = 'LanguageNumber')
	INSERT dbo.user_parameters (HostName, Parm_Id, Parm_Required, User_Id, Value)
	VALUES ('', @intLanguageParmId, 0, @intUserId, CAST(@intLanguageId AS VARCHAR(3)))
END

SELECT @intUserId

INSERT Local_PG_PCMT_Log_Users
(	Timestamp, User_id1, Type, User_id, Mixed_Mode_Login, 
	Password, Role_Based_Security, User_Desc, User_Name, 
	View_Id, WindowsUserInfo, Active
)
VALUES
(	GETDATE(), @txtUserId, 1, @intUserId, @intMixMode, 
	@vcrPassword, @intIsRole, @vcrUserDesc, @vcrUserName, 
	@intViewId, @vcrWinUserInfo, @intActive
)


SET NOCOUNT OFF
