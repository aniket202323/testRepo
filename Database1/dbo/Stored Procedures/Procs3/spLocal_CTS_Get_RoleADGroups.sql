


--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Get_RoleADGroups
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2022-01-24
-- Version 				: Version <1.0>
-- SP Type				: Web
-- Caller				: Called by CTS mobile application 
-- Description			: This stored procedure fetches the roles used by CTS
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-01-24		F.Bergeron				Initial Release 
-- 1.1		2022-02-01		F.Bergeron				Change input from role_id to role desc 
--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXEC [dbo].[spLocal_CTS_Get_RoleADGroups]  'Operator'

*/

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_RoleADGroups]
@Role_desc VARCHAR(50)



--WITH ENCRYPTION	
AS
SET NOCOUNT ON
DECLARE
@AD_Group	VARCHAR(100),
@Role_id	INTEGER

DECLARE @Output TABLE 
(
Role_id		INTEGER,
Role_Desc	VARCHAR(100),	
AD_Group	VARCHAR(200),
AD_Domain	VARCHAR(100)
)

IF EXISTS(SELECT user_id FROM dbo.users_base WHERE username = @Role_Desc AND is_role = 1)
BEGIN

	-- GET AD GROUPS
	INSERT INTO @Output
	(	
		Role_id,
		Role_Desc,
		AD_Group, 
		AD_Domain
	)
		SELECT	UB.User_Id,
				UB.username, 
				URS.groupName,
				URS.domain 
		FROM	dbo.user_role_security URS 
				JOIN users_base UB 
					ON UB.user_id = URS.role_user_id 
		WHERE	UB.Username = @Role_Desc
					AND URS.user_id IS NULL
END

SELECT	Role_id,
		Role_Desc,
		AD_Group, 
		AD_Domain
FROM	@output



