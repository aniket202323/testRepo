
CREATE PROCEDURE dbo.spActivities_GetHeader @ActivityId BIGINT


AS
BEGIN
    DECLARE @ActivityTypeId INT, @Activity_Desc NVARCHAR(1000), @KeyId1 INT, @StartTime DATETIME, @EndTime DATETIME, @PU_Id INT, @Sheet_Id INT, @Prod_Id INT, @Prod_Code NVARCHAR(100), @Prod_Desc NVARCHAR(510), @Start_Id INT, @Process_Order NVarchar(50), @KeyId DATETIME, @DisplayUnits BIT, @UserId INT, @User nvarchar(200), @IsLocked BIT, @IsAppliedProduct BIT;
	Declare @PP_Id int
-- Retrieve the Activity Type and some other values
    SELECT @ActivityTypeId = Activity_Type_Id,
           @Activity_Desc = Activity_Desc,
           @KeyId1 = KeyId1,
           @StartTime = Start_Time,
           @EndTime = End_Time,
           @PU_Id = PU_Id,
           @Sheet_Id = Sheet_id,
           @KeyId = KeyId,
           @UserId = UserId,
           @IsLocked = ISNULL(Locked, 0)
           FROM Activities
           WHERE Activity_Id = @ActivityId

    SELECT @User = Username FROM Users_Base WHERE User_Id = @UserId

--Retrieve Start Date
   /*This whole code is unnecessary as KeyId is already populated from these below columns only.*/
   /*
   IF @ActivityTypeId = 2 --Production Event
        BEGIN
            SELECT @KeyId = e.Timestamp FROM Events AS E
                                             JOIN Production_Status AS PS ON E.Event_Status = PS.ProdStatus_Id WHERE e.Event_Id = @KeyId1
        END
        ELSE
        BEGIN
            IF @ActivityTypeId = 3 --User Define Event
                BEGIN
                    SELECT @KeyId = e.End_Time FROM User_Defined_Events AS E
                                                    JOIN Production_Status AS PS ON E.Event_Status = PS.ProdStatus_Id WHERE e.UDE_Id = @KeyId1
                END
        END
		*/
--Retrieve Product Id
    EXECUTE spActivities_GetRunningGrade @PU_Id, @KeyId, 1, @Prod_Id OUTPUT, @Prod_Code OUTPUT, @Start_Id OUTPUT, NULL, @IsAppliedProduct OUTPUT

-- Get Product Description
    SELECT @Prod_Desc = Prod_Desc FROM Products WHERE Prod_Id = @Prod_Id
    SELECT @StartTime = CASE
                            WHEN @ActivityTypeId = 5
                            THEN ISNULL(@StartTime, @KeyId)
                            ELSE @StartTime
                        END
-- Get Process Order
    --SELECT @Process_Order = MIN(Process_Order)
    --       FROM Production_Plan AS pp
    --            JOIN Production_Plan_Starts AS pps ON pp.PP_Id = pps.PP_Id
    --       WHERE @KeyId > Start_Time
    --             AND (@KeyId <= End_Time
    --                  OR End_Time IS NULL)
    --             AND pps.PU_Id = @PU_Id
	/*Didn't het why we sorting on process order name and fetching the minimum one???*/
	Select Top 1 @PP_Id = PP_Id From 
	(
	SELECT PPS.PP_Id FROM  Production_Plan_Starts AS pps WHERE @KeyId > pps.Start_Time AND (@KeyId <= pps.End_Time OR End_Time IS NULL) AND pps.PU_Id = @PU_Id
	--UNION
	--SELECT PPS.PP_Id FROM  Production_Plan_Starts AS pps WHERE @KeyId > pps.Start_Time AND pps.End_Time IS NULL AND pps.PU_Id = @PU_Id
	) T --Order by 1 

	Select @Process_Order = Process_Order from Production_Plan where PP_Id = @PP_Id
	Select 
		 @Process_Order=PP_PP.Process_Order 
	From 
		Activities  A 
		JOIN User_defined_Events UDE on UDE.UDE_Id = a.keyid1 
		JOIN Event_Components EC on UDE.Event_Id = EC.Event_Id
		JOIN Event_Details ED ON EC.Source_Event_Id = ED.Event_Id 
		JOIN Production_Plan PP_PP ON PP_PP.PP_Id = ED.PP_Id
	Where A.Activity_Type_Id = 3 and Activity_Id in (@ActivityId) AND @ActivityTypeId = 3

-- Get Sheet Details
    SELECT @DisplayUnits = ISNULL(Display_EngU, 0) FROM Sheets WHERE Sheet_Id = @Sheet_Id

--Return Data
    IF COALESCE(@ActivityTypeId, 0) > 0 -- valid activity was found
        BEGIN
            SELECT ActivityId = @ActivityId,
                   Activity_Desc = @Activity_Desc,
                   SheetId = @Sheet_Id,
                   ProdDesc = @Prod_Desc,
                   HasAppliedProduct = @IsAppliedProduct,
                   StartTime = dbo.fnServer_CmnConvertFromDbTime(@StartTime, 'UTC'),
                   EndTime = dbo.fnServer_CmnConvertFromDbTime(@EndTime, 'UTC'),
                   ProcessOrder = @Process_Order,
                   KeyId = dbo.fnServer_CmnConvertFromDbTime(@KeyId, 'UTC'),
                   ActivityTypeId = @ActivityTypeId,
                   KeyId1 = @KeyId1,
                   DisplayUnits = @DisplayUnits,
                   UnitId = @PU_Id,
                   IsLocked = @IsLocked,
                   UserId = @UserId,
                   UserName = @User
        END
END
