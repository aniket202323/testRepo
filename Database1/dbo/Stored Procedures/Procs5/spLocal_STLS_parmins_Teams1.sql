











/*
--------------------------------------------------------------
Name: spLocal_STLS_parmins_Teams1
Purpose: Adds new teams.
--------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 12-Feb-2008
Change: maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------
Date: 11/12/2001
--------------------------------------------------------------
*/


CREATE  PROCEDURE spLocal_STLS_parmins_Teams1 

	@strteams VARCHAR(100)
 
AS
			DECLARE	@last_comma INT,
			@current_comma INT,
			@strname VARCHAR(10),
			@delimeter CHAR(1),
			@iCount INT


	SET @last_comma = 1
	SET @delimeter = ','
	SET @strteams = @strteams + ','
	SET @iCount = 1
	
	WHILE(@last_comma < LEN(@strteams))
	BEGIN
		SET @current_comma = CHARINDEX(@delimeter,@strteams,@last_comma)
		SET @strname = SUBSTRING(@strteams,@last_comma,@current_comma - @last_comma)

		SELECT * 
		FROM Local_PG_Teams
		WHERE TeamName = @strname

		IF @@ROWCOUNT > 0 
			BEGIN
			RETURN @iCount
			END

		INSERT INTO Local_PG_Teams (TEAMNAME) 
		VALUES(@strname)

		SET @last_comma = @current_comma + 1
		SET @iCount = @iCount + 1
	END



IF @@ERROR > 0
	BEGIN
	RAISERROR('INSERT TEAMS FAILED', 16,1)
	RETURN 99
	END



RETURN 0














