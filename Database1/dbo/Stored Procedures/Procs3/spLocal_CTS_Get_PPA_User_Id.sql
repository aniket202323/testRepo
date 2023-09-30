

--------------------------------------------------------------------------------------------------
-- Local Stored Procedure: spLocal_CTS_Get_PPA_User_Id
--------------------------------------------------------------------------------------------------
-- Author				:	Francois Bergeron (AutomaTech Canada)
-- Date created			:	2021-10-21
-- Version 				:	1.0
-- Description			:	The purpose of this query is to extract PPA user Id

-- Editor tab spacing	: 4 
--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2021-10-21		F.Bergeron				Initial Release 
-- 1.1			2022-06-01		F.Bergeron				Inactive user case



--------------------------------------------------------------------------------------------------
--Testing Code
--------------------------------------------------------------------------------------------------

-- EXECUTE spLocal_CTS_Get_PPA_User_Id 'na.pg.com\michel.ka'

CREATE   PROCEDURE [dbo].[spLocal_CTS_Get_PPA_User_Id]
@AD_Username	VARCHAR(100)


AS
BEGIN
	SET NOCOUNT ON;
	-- SP Variables
	DECLARE @PPA_Username VARCHAR(100)

	DECLARE
	@Output TABLE
	(
		C_User_id			INTEGER,
		C_Message			VARCHAR(500)
	)

	IF EXISTS	(
				SELECT	1 
				FROM	dbo.users_Base WITH(NOLOCK) 
				WHERE	WindowsUserInfo = @AD_Username 
						AND active = 1
				)
	BEGIN
		INSERT INTO @Output 
		(
			C_User_id,
			C_Message
		)
		SELECT 
				User_id, 
				'' 
		FROM	dbo.users_Base WITH(NOLOCK) 
		WHERE	WindowsUserInfo = @AD_Username 
		GOTO LAFIN
	END
	ELSE IF EXISTS	(
				SELECT	1 
				FROM	dbo.users_Base WITH(NOLOCK) 
				WHERE	WindowsUserInfo = @AD_Username 
						AND active = 0
				)
	BEGIN 

		INSERT INTO @Output 
		(
			C_User_id,
			C_Message
		)
		SELECT 
				'', 
				'Inactive user exists in PPA' 
		GOTO LAFIN		
	END
	
	ELSE 
	BEGIN 

		INSERT INTO @Output 
		(
			C_User_id,
			C_Message
		)
		SELECT 
				'', 
				'User does not exist in PPA' 
		GOTO LAFIN		
	END

	LAFIN:
	SELECT C_User_id, C_Message FROM @Output

END
