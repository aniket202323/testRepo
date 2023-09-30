
CREATE FUNCTION dbo.fnMES_GetDowntimeAvailableUnits(@UserId int)
 	 RETURNS  @SecurityUnits Table (PU_Id Int)
AS 
BEGIN
	IF Exists(SELECT 1 FROM User_Security WHERE User_Id = @UserId  AND Group_Id =1 and Access_Level = 4) -- admin to admin
	BEGIN
		INSERT INTO @SecurityUnits(PU_Id)
			SELECT Distinct PU_Id From EVENT_Configuration WHERE ET_Id = 2
		RETURN
	END
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT a.Master_Unit
		FROM Sheets a
		JOIN  User_Security c on c.Group_Id = a.Group_Id AND c.User_Id = @UserId 
		WHERE a.Sheet_Type = 5
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT a.Master_Unit
		FROM Sheets a
		WHERE a.Group_Id Is Null AND a.Sheet_Type = 5
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT a.PU_Id 
		FROM Sheet_Unit  a
		JOIN Sheets b on b.Sheet_Id = a.Sheet_Id  AND b.Sheet_Type In (15,28)
		JOIN  User_Security c on c.Group_Id = b.Group_Id AND c.User_Id = @UserId 
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT a.PU_Id
		FROM Sheet_Unit  a
		JOIN Sheets b on b.Sheet_Id = a.Sheet_Id  AND b.Sheet_Type In (15,28)
		WHERE b.Group_Id Is Null
	INSERT INTO @SecurityUnits(PU_Id)
		SELECT a.PU_Id
		FROM Prod_Units_Base  a
		Left Join Sheets b on b.Master_Unit = a.PU_Id  AND b.Sheet_Type = 5
		Left Join Sheet_Unit c on c.PU_Id  = a.PU_Id  
		Left Join Sheets d on  d.Sheet_Id  = c.sheet_id and d.sheet_type in (15,28) 
		JOIN Event_Configuration e on e.PU_Id = a.pu_id and ET_Id = 2
		WHERE b.Sheet_Id Is Null and d.Sheet_Id is null
	RETURN
END


