
CREATE FUNCTION dbo.fnActivities_CheckSheetSecurityForActivities(@SheetId         INT,
                                                                 @DisplayOptionId INT,
                                                                 @DefaultLevel    INT,
                                                                 @UnitId          INT,
                                                                 @UserId          INT)
RETURNS INT
BEGIN
/*
Declare @UserId int=53
--Exec spCC_GetSheets 1,N'8001091'
declare @p1 int
declare @p5 int
Exec spCC_GetSheetSecurity @UserId,N'APE',@p5 output
select @p1, @p5
 

Select dbo.fnActivities_CheckSheetSecurityForActivities(46,8,2,49,@UserId)
*/
    DECLARE @UsersSecurity INT, @SheetType INT, @Usersecuritygrouplevel INT, @GroupId INT
    SELECT @UsersSecurity = 0
    DECLARE @CurrentLevel INT= NULL
    DECLARE @OKay INT
    SELECT @SheetType = Sheet_Type FROM Sheets WHERE Sheet_Id = @SheetId
	SET @OKay = 0
	IF EXISTS(SELECT 1 FROM User_Security WHERE User_Id = @UserId AND Group_Id = 1 AND Access_Level = 4)
	BEGIN 
 
		SET @OKay = 1
		SET @UsersSecurity = 4
	END
	ELSE
	BEGIN
		
		
		SELECT @GroupId=coalesce(s.Group_Id, sg.Group_Id) from Sheets AS s LEFT OUTER JOIN Sheet_Groups AS sg ON s.Sheet_Group_Id = sg.Sheet_Group_Id WHERE Sheet_Id = @SheetId
		IF @GroupId IS NULL--sheet has no security group assigned then allow access
		Begin
			SELECT @UsersSecurity = 4
		End
		ELSE --Sheet has security group assigned
		BEGIN
			Select @UsersSecurity = Coalesce(Access_Level, 0) From User_Security where User_Id = @UserId and Group_Id = @GroupId
		END
	END

	  SET @CurrentLevel = COALESCE
								(
									(
										SELECT 
											Value 
										FROM 
											Sheet_Display_Options 
										WHERE 
											Sheet_Id = @SheetId AND Display_Option_Id = @DisplayOptionId
									), 
									(
										SELECT 
											Display_Option_Default
										FROM 
											Sheets AS S
											JOIN Sheet_Type_Display_Options AS STDO ON STDO.Display_Option_Id = @DisplayOptionId AND STDO.Sheet_Type_Id = S.Sheet_Type
										WHERE
											S.Sheet_Id = @SheetId
									)
									, @DefaultLevel
								)

		Select @OKay = Case When @UsersSecurity >= @CurrentLevel Then 1 Else 0 End

    RETURN @OKay
END


