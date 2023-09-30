
CREATE FUNCTION dbo.fnMES_GetNonProductiveTimeAvailableUnits(@UserId int)
 	 RETURNS  @SecurityUnits Table (PU_Id Int)
AS 
BEGIN
	IF Exists(SELECT 1 FROM User_Security WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4) -- admin to admin
	BEGIN
		INSERT INTO @SecurityUnits(PU_Id)
			SELECT Distinct PU_Id 
			FROM Sheets a
			Join Prod_Units_Base pub on pub.PL_Id = a.PL_Id AND (pub.Master_Unit = pub.PU_Id or pub.Master_Unit Is Null)
			 WHERE Sheet_Type = 27
		INSERT INTO @SecurityUnits(PU_Id)
			SELECT a.PU_Id
			FROM Sheet_Unit  a
			JOIN Sheets b on b.Sheet_Id = a.Sheet_Id  AND b.Sheet_Type = 27
		RETURN
	END
		/* by Line */
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT pub.pu_id
		FROM Sheets a
		Join Prod_Units_Base pub on pub.PL_Id = a.PL_Id AND (pub.Master_Unit = pub.PU_Id or pub.Master_Unit Is Null)
		JOIN  User_Security c on c.Group_Id = a.Group_Id AND c.User_Id = @UserId 
		WHERE a.Sheet_Type = 27
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT pub.pu_id
		FROM Sheets a
		Join Prod_Units_Base pub on pub.PL_Id = a.PL_Id AND (pub.Master_Unit = pub.PU_Id or pub.Master_Unit Is Null)
		WHERE a.Group_Id Is Null AND a.Sheet_Type = 27
	/* By Unit */
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT a.PU_Id 
		FROM Sheet_Unit  a
		JOIN Sheets b on b.Sheet_Id = a.Sheet_Id  AND b.Sheet_Type = 27
		JOIN  User_Security c on c.Group_Id = b.Group_Id AND c.User_Id = @UserId 
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT a.PU_Id
		FROM Sheet_Unit  a
		JOIN Sheets b on b.Sheet_Id = a.Sheet_Id  AND b.Sheet_Type = 27
		WHERE b.Group_Id Is Null
	RETURN
END

