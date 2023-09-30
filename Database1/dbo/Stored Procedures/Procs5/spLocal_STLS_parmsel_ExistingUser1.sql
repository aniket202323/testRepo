









/*
--------------------------------------------------------------------------------------------------------------------------------------
Name: spLocal_STLS_parmsel_ExistingUser1
Purpose: Verify remote user is active in the Proficy User table
Date: 6/18/2003
--------------------------------------------------------------------------------------------------------------------------------------
Modified by	Vinayak Pate
Date		02/22/08
Build #8
Change		Store Sucessgul Logins
		
--------------------------------------------------------------------------------------------------------------------------------------
Modified by 	Rajnkant Kapadia
Modified On	On 13-Jan-06
Change : 	Changed SP to also have STLS site access to  users who are in "STLS Access" group in  Proficy irrespective of their access
		privileges (Refer Change UID 1 in STLSChangeList.xls)	
--------------------------------------------------------------------------------------------------------------------------------------
Modified by 	Rajnkant Kapadia
Modified On	On 06-Sep-05
Change : 	Changed SP to have STLS site access to only users who are administrator in Proficy irrespective of their access
		privileges (Refer Change UID 1 in STLSChangeList.xls)	
---------------------------------------------------------------------------------------------------------------------------------------
*/

CREATE   PROCEDURE spLocal_STLS_parmsel_ExistingUser1
	--Parameters
	@Username VARCHAR(30)
AS


DECLARE @Security_Check BIT,
	@User_Id INT

SET @Security_Check =	
	(
	SELECT distinct active 
	FROM Users u JOIN user_security us on u.User_ID = us.User_ID JOIN security_groups sg on us.group_ID = sg.group_ID and
 	Upper(RTrim(LTrim(sg.Group_Desc))) in ('ADMINISTRATOR','STLS ACCESS')
	WHERE username = @Username
	)

If @Security_Check = 1
	BEGIN

	SET @USER_ID = (Select [User_Id] from USERS where Username = @Username)

	DELETE FROM LOCAL_PG_STLS_LOGINS		-- Delete login data older than 60 days
	WHERE Login_Datetime < getdate()-60

	INSERT INTO LOCAL_PG_STLS_LOGINS		-- Insert recent login
	VALUES (GETDATE(), @USER_ID) 

	END

SELECT @Security_Check as Active



--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('Select User Failed.', 16, 1)
	RETURN 99
	END

RETURN 0










