

CREATE PROCEDURE [dbo].[spComment_GetCommentChangePermission]
		@SheetId INT,
		@RootId  INT,
		@TableId INT,
		@UserId  INT
 AS

IF @SheetId IS NOT NULL
	BEGIN
		SELECT dbo.fnCMN_GetCommentsSecurity(@SheetId,@UserId) AS security
	END
ELSE
	BEGIN
		DECLARE @UnitId INT
		DECLARE  @SheetPreferences TABLE([Preference] [int] NOT NULL, [Sheet_Id] [int] NOT NULL, [Sheet_Group_Id] [int] NULL, [Group_Id] [int] NULL)
		--TODO : Validations for @TableId and @RootId
		IF @TableId NOT IN(16, 17, 79) -- Currently ony these are supported
		OR @TableId IS NULL
        BEGIN
            SELECT ERROR = 'Comment table type not supported currently', CODE = 'CommentTypeNotSupported'
            RETURN
        END
		IF @TableId in (16, 17) --16 Downtime cause, 17 -- Downtime action	
			BEGIN
				--find the unit id where the downtime belongs to
				SELECT @UnitId = PU_Id FROM Timed_Event_Details WHERE TEDet_Id = @RootId
				--SELECT @UnitId = CASE WHEN Master_Unit IS NULL THEN pu_Id ELSE MAster_Unit END FROM Prod_Units WHERE Pu_Id = @UnitId
				IF @UnitId IS NULL
					BEGIN
					  SELECT ERROR = 'Downtime Id is not valid', CODE = 'InvalidRootId'
					RETURN
					END
				--From unitid find the sheet to check the permissions
				INSERT INTO  @SheetPreferences(Preference, Sheet_Id, Sheet_Group_Id, Group_Id) 
					(
					SELECT 1 Preference, SU.Sheet_Id, S.Sheet_Group_Id, S.Group_Id FROM Sheet_Unit SU JOIN Sheets S on SU.Sheet_Id = S.Sheet_Id AND S.Sheet_Type =28--Downtime+ View from sheet units
					WHERE SU.PU_Id = @UnitId AND S.Is_Active = 1
					UNION
					SELECT 2 Preference,S.Sheet_Id, S.Sheet_Group_Id, S.Group_Id FROM Sheets S WHERE S.Sheet_Type =5--Downtime Unit View from sheets
					AND S.Master_Unit = @UnitId AND S.Is_Active = 1
					UNION
					SELECT 3 Preference,SU.Sheet_Id, S.Sheet_Group_Id, S.Group_Id FROM Sheet_Unit SU JOIN Sheets S on SU.Sheet_Id = S.Sheet_Id AND S.Sheet_Type = 15--Downtime Line View from sheet units
					WHERE SU.PU_Id = @UnitId  AND S.Is_Active = 1
					)
			END
		ELSE IF @TableId = 79 -- NonProductiveDetail
			BEGIN
				--find the unit id where the npt belongs to
				SELECT @UnitId = PU_Id FROM NonProductive_Detail WHERE NPDet_Id = @RootId
				IF @UnitId IS NULL
					BEGIN
					  SELECT ERROR = 'NPT Id is not valid', CODE = 'InvalidRootId'
					RETURN
					END
				INSERT INTO  @SheetPreferences(Preference, Sheet_Id, Sheet_Group_Id, Group_Id) 
					(
					SELECT 1 Preference, SU.Sheet_Id, S.Sheet_Group_Id, S.Group_Id FROM Sheet_Unit SU JOIN Sheets S on SU.Sheet_Id = S.Sheet_Id AND S.Sheet_Type =27--NonProductiveDetail Sheet Type
					WHERE SU.PU_Id = @UnitId AND S.Is_Active = 1
					UNION
					SELECT 2 Preference,S.Sheet_Id, S.Sheet_Group_Id, S.Group_Id FROM Sheets S WHERE S.Sheet_Type =27--NonProductiveDetail Sheet Type
					AND S.PL_Id = (SELECT PL_Id FROM Prod_Units_Base WHERE PU_Id = @UnitId) AND S.Is_Active = 1 --Selecting sheets based on the units line 
					)
			END

	    -- ELSE IF @@TableId == Extend here for other table Id types
			--BEGIN
			--	SELECT 1
			--END

		--From the multiple sheet ids select the preferred one
		;WITH PreferredSheet AS (
		SELECT S.Sheet_Id, Coalesce(us_sheet.Access_level, us_sheetGroup.Access_level, 3) AS Access_level--If no security group is assigned to either sheet or sheet group, assume it as access level Manager (3)
		FROM @SheetPreferences S
		LEFT OUTER JOIN
		User_Security us_sheet ON us_sheet.Group_Id = s.Group_Id AND us_sheet.user_id = @UserId --Getting the sheet level access
		JOIN
		Sheet_Groups sg ON sg.Sheet_Group_Id=S.Sheet_Group_Id
		LEFT OUTER JOIN
		User_Security us_sheetGroup ON us_sheetGroup.Group_Id = sg.Group_Id AND us_sheetGroup.user_id = @UserId -- Getting sheet group level access
		WHERE S.Preference = (SELECT MIN(Preference) FROM @SheetPreferences)
		)

		-- Select the sheet with the minimum access level out of the selected sheets
		SELECT @SheetId = Sheet_Id FROM PreferredSheet WHERE Access_level = (SELECT MIN(Access_level) FROM PreferredSheet) order by Sheet_Id
		
		-- Get the comment update security 
		SELECT dbo.fnCMN_GetCommentsSecurity(@SheetId,@UserId) AS security
	END
