
CREATE PROCEDURE dbo.spActivities_GetSheetUsers @SheetId    INT 

AS
BEGIN
	 IF NOT EXISTS(SELECT  Sheet_Id FROM sheets WHERE Sheet_Id = @SheetId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'sheet id not found',
                   ErrorType = 'InvalidParameterValue',
                   PropertyName1 = 'SheetId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @SheetId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
	DECLARE @GroupId INT = ISNULL((SELECT Group_Id FROM Sheets S WHERE Sheet_Id = @SheetId), 0)
	;WITH CTE_UserAccess AS(
    SELECT U.username,U.User_Id,
        US_Admin.Access_Level AS AdminAccess,
        US_SheetGroup.Access_Level AS GroupAccess,
        IIF(ISNULL(US_Admin.Access_Level, 99) < ISNULL(US_SheetGroup.Access_Level, 99), US_Admin.Access_Level, US_SheetGroup.Access_Level) AS Access
    FROM 
        Users U
        LEFT JOIN User_Security US_Admin ON US_Admin.User_Id = U.User_Id AND US_Admin.Group_Id = 1
        LEFT JOIN User_Security US_SheetGroup ON US_SheetGroup.User_Id = U.User_Id AND US_SheetGroup.Group_Id = @GroupId
    WHERE U.Is_Role=0 AND U.Active=1 AND (US_Admin.Access_Level IS NOT NULL OR US_SheetGroup.Access_Level IS NOT NULL)
	)
	SELECT UA.UserName AS UserName, UA.Access AS AccessLevelId, AL.AL_Desc AS AccessLevelName , SG.Group_Id AS GroupId, SG.Group_Desc AS GroupName
	FROM CTE_UserAccess UA
    JOIN Access_Level AL ON AL.AL_Id = UA.Access
    LEFT JOIN Security_Groups SG ON SG.Group_Id = IIF(UA.AdminAccess < UA.GroupAccess, 1, @GroupId)
	ORDER BY User_Id
END
