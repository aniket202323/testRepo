
CREATE FUNCTION dbo.fnActivities_GetVariablesForActivity(@ActivityId INT)
RETURNS @Variables TABLE(varId    INT,
                         VarOrder INT,
                         Title    nvarchar(50))
AS
BEGIN
    DECLARE @ActivityTypeId INT, @KeyId1 INT, @Sheet_Id INT, @TitleActivities INT, @Title nvarchar(50), @TitleVarOrder INT, @EndVarOrder INT, @Sheet_Desc nvarchar(50), @KeyId DATETIME
    DECLARE @TitlesTable TABLE(title   nvarchar(50),
                               startId INT,
                               endId   INT)

	-- Retrieve the Activity Type and some other values
    SELECT @ActivityTypeId = a.Activity_Type_Id,
           @KeyId1 = a.KeyId1,
           @Sheet_Id = a.Sheet_Id,
           @Title = a.Title,
           @KeyId = a.KeyId
           FROM Activities AS a
                --LEFT JOIN Events AS e ON e.Event_Id = a.KeyId1
           WHERE Activity_Id = @ActivityId

	--Set the KeyId for Production Event
    IF @ActivityTypeId = 2 --Production Events
        BEGIN
		--Retrieve Start Date
            SELECT @KeyId = e.TimeStamp FROM Events e (nolock) WHERE e.Event_Id = @KeyId1
        END
	--Set the KeyId for User Define Event
        ELSE
        BEGIN
            IF @ActivityTypeId = 3 --User Define Event
                BEGIN
                    SELECT @KeyId = e.End_Time FROM User_Defined_Events e (nolock) WHERE e.UDE_Id = @KeyId1
                END
        END

	--Determine if Titles are being used for Activities
    SELECT @TitleActivities = Value FROM Sheet_Display_Options (nolock) WHERE Sheet_Id = @Sheet_Id
                                                                     AND Display_Option_Id = 445
    SELECT @TitleActivities = COALESCE(@TitleActivities, 0)

	--If Activities are using Titles, only return those variables that are under that Title
    IF @TitleActivities = 1
       AND @Title IS NOT NULL
        BEGIN
            SELECT @TitleVarOrder = Var_Order FROM Sheet_Variables AS sv (nolock) WHERE sv.Sheet_Id = @Sheet_Id
                                                                               AND sv.Title = @Title

            SELECT @EndVarOrder = MIN(Var_Order) FROM Sheet_Variables AS sv (nolock)  WHERE sv.Sheet_Id = @Sheet_Id
                                                                                  AND sv.Title IS NOT NULL
                                                                                  AND sv.Var_Order > @TitleVarOrder

            INSERT INTO @Variables( VarId,
                                    VarOrder,
                                    Title )
            SELECT Var_Id,
                   var_order,
                   @Title FROM Sheet_Variables AS sv (nolock) WHERE sv.Sheet_Id = @Sheet_Id
                                                           AND sv.Var_Order > @TitleVarOrder
                                                           AND (sv.Var_ORder < @EndVarOrder
                                                                OR @EndVarOrder IS NULL)
        END
        ELSE -- Activity doesn't use titles, so return all Variables for Sheet
        BEGIN
            INSERT INTO @TitlesTable( title,
                                      startId )
            SELECT sv.Title,
                   sv.Var_Order FROM Sheet_Variables AS sv (nolock) WHERE sv.Sheet_Id = @Sheet_Id
                                                                 AND sv.Title IS NOT NULL

            UPDATE t SET endId = (SELECT MIN(t2.startId) FROM @TitlesTable AS t2 WHERE t2.startId > t.startId) FROM @TitlesTable t

            INSERT INTO @Variables( VarId,
                                    VarOrder,
                                    Title )
            SELECT sv.Var_Id,
                   sv.var_order,
                   t.Title
                   FROM Sheet_Variables AS sv (nolock)
                        LEFT JOIN @TitlesTable AS t ON sv.Var_Order > t.startId
                                                       AND (sv.Var_Order < t.endId
                                                            OR t.endId IS NULL)
                   WHERE sv.Sheet_Id = @Sheet_Id
                         AND (Title_Var_Order_Id = 0
                              OR @TitleActivities = 0)
        END

    RETURN
END
