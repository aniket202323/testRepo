CREATE FUNCTION dbo.fnPO_UserAccessLevel(@Path_Id int, @User_Id int, @Sheet_Id int)
    RETURNS int
AS

    BEGIN
        DECLARE @UsersSecurity Int,@Usersecuritygrouplevel Int, @NoGroup INT
        SELECT @UsersSecurity = 0
        SELECT @NoGroup = 0
        IF NOT EXISTS (SELECT 1 FROM User_Security WHERE User_Id = @User_Id  and Group_Id = 1 and Access_Level = 4)
            BEGIN
                IF EXISTS(SELECT 1 FROM Sheets s
                                            Left Join Sheet_Unit su on su.sheet_Id = s.sheet_Id
                                            Left Join Sheet_Paths sp on sp.sheet_Id = s.sheet_Id
                                            join Sheet_Groups sg on s.Sheet_Group_Id = sg.Sheet_Group_Id
                          WHERE
                                  s.Is_Active = 1 AND
                              ((Sheet_Type = 17  and sp.Path_Id = @Path_Id))
                            AND s.Group_Id Is Null AND sg.Group_Id Is Null AND s.Sheet_Id = @Sheet_Id)
                    BEGIN
                        IF NOT EXISTS ( SELECT 1 from User_Security where User_Id = @User_Id and Group_Id = 1 and Access_Level > 1)
                            BEGIN
                                      SELECT  @UsersSecurity = 3
                            end
                        ELSE
                            BEGIN
                                Select @UsersSecurity = 4
                            end
                        -- sheet with no group -- then every one will have manager level access, but user from admininstrator group with more than read permissions will have admin acess
                    END
                ELSE
                    BEGIN
                        --get security at display level
                        Select @UsersSecurity = min(u.Access_Level)
                        from Sheets s
                                 Join User_Security u on u.Group_Id = s.Group_Id and u.User_Id = @User_Id
                                 Left Join Sheet_Paths sp on sp.sheet_Id = s.sheet_Id
                        WHERE
                                s.Is_Active = 1 AND Sheet_Type = 17  and sp.Path_Id = @Path_Id AND s.Sheet_Id = @Sheet_Id

                        --get security at display group level if any other display is configured for same unit
                        Select  @Usersecuritygrouplevel =min(u.Access_Level)
                        from Sheets s
                                 join Sheet_Groups sg on s.Sheet_Group_Id = sg.Sheet_Group_Id
                                 Join User_Security u on u.Group_Id = sg.Group_Id and u.User_Id = @User_Id
                                 Left Join Sheet_Paths sp on sp.sheet_Id = s.sheet_Id
                        WHERE
                                s.Is_Active = 1 AND Sheet_Type = 17  and sp.Path_Id = @Path_Id
                          and s.Group_Id is  null AND s.Sheet_Id = @Sheet_Id
                        SELECT @UsersSecurity = Coalesce(@UsersSecurity,0)
                        SELECT @Usersecuritygrouplevel = Coalesce(@Usersecuritygrouplevel,0)
                        SELECT @UsersSecurity = CASE when @UsersSecurity > @Usersecuritygrouplevel THEN @UsersSecurity
                                                     WHEN  @UsersSecurity <  @Usersecuritygrouplevel THEN @Usersecuritygrouplevel
                                                     ELSE @UsersSecurity END

                    END
            END
        ELSE
            BEGIN
                SELECT @UsersSecurity = 4
            END
        RETURN @UsersSecurity
    END
