CREATE FUNCTION dbo.fnCMN_GetCommentsSecurity(@SheetId INT,
                                              @UserId  INT)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT, @SheetGroupId INT, @SheetSecuriry INT, @AdminAccess INT, @GroupAccess INT, @Access INT
    SELECT @SheetGroupId = S.Sheet_Group_Id,
           @SheetSecuriry = ISNULL(S.Group_Id, SG.Group_Id)
           FROM Sheets AS S
                JOIN Sheet_Groups AS SG ON S.Sheet_Group_Id = SG.Sheet_Group_Id
           WHERE S.Sheet_Id = @SheetId
    SET @AdminAccess = ISNULL((SELECT SP.Value FROM Site_Parameters AS SP WHERE SP.Parm_Id = 93), 1)
    SET @GroupAccess = ISNULL((SELECT SP.Value FROM Site_Parameters AS SP WHERE SP.Parm_Id = 94), 1)
    SET @Access = CASE
                      WHEN @AdminAccess < @GroupAccess
                      THEN @GroupAccess
                      ELSE @AdminAccess
                  END
    DECLARE @UserAccess INT= ISNULL((SELECT MIN(US.Access_Level)
                                            FROM User_Security AS US
                                            WHERE US.User_Id = @UserId
                                                  AND US.Group_Id IN(1, ISNULL(@SheetSecuriry, 1))
                                     AND ((US.Group_Id = 1
                                          AND US.Access_Level >= @AdminAccess
                                          AND @AdminAccess <> 1)
                                          OR (@SheetSecuriry IS NOT NULL
                                             AND US.Access_Level >= @GroupAccess
                                             AND US.Group_Id = @SheetSecuriry
                                             AND @GroupAccess <> 1))), 1)
    SET @Result = CASE
                      WHEN @UserAccess IS NOT NULL
                           AND @UserAccess > 1
                      THEN 1
                      ELSE 0
                  END
    RETURN @Result
END
