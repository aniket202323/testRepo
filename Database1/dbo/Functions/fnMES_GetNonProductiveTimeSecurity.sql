
CREATE Function dbo.fnMES_GetNonProductiveTimeSecurity(
		 @PUIds	nvarchar(max) = null
		,@LineIds	nvarchar(max) = Null
		,@UserId	Int)

RETURNS @DisplayOptions TABLE (Id Int Identity (1,1),PU_Id Int,AddSecurity Int,EditSecurity Int)

AS

BEGIN
	DECLARE @AllUnits Table (PU_Id Int)
	DECLARE @AllLines Table (PL_Id Int)
	DECLARE @SecurityUnits Table (PU_Id Int)




	If @LineIds Is Not NUll
	BEGIN
		INSERT INTO @AllLines(PL_Id) 
			SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Lines',@LineIds,',')
	END

	If EXISTS(SELECT 1 FROM @AllLines) 
	BEGIN
		INSERT INTO @AllUnits(PU_Id)
		SELECT a.PU_Id
		FROM Prod_Units_Base a
		JOIN @AllLines c on c.PL_Id = a.PL_Id 
		WHERE a.Non_Productive_Reason_Tree is Not Null
	END
	ELSE If @PUIds Is Not NUll
	BEGIN
		INSERT INTO @AllUnits(PU_Id) 
			SELECT DiSTINCT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@PUIds,',')
		IF NOT EXISTS(SELECT 1 FROM @AllUnits)
		BEGIN
			RETURN
		END
	END	

	INSERT INTO @SecurityUnits(PU_Id)
		SELECT DISTINCT PU_Id FROM dbo.fnMES_GetNonProductiveTimeAvailableUnits(@UserId)

	IF EXISTS(SELECT 1 FROM @AllUnits)
		DELETE FROM @AllUnits WHERE PU_Id NOT IN (SELECT PU_ID FROM @SecurityUnits)
	ELSE
		INSERT INTO @AllUnits(PU_Id)  SELECT DISTINCT PU_Id FROM @SecurityUnits

	IF NOT EXISTS(SELECT 1 FROM @AllUnits)
	BEGIN
		RETURN
	END
	/********  Currently No Granularity on NPT security    *********/
	INSERT INTO @DisplayOptions(PU_Id,AddSecurity,EditSecurity)
		SELECT Distinct PU_Id,1,1 FROM @AllUnits
	RETURN
END

