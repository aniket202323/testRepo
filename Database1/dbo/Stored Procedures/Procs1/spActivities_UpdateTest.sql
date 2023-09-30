
CREATE PROCEDURE dbo.spActivities_UpdateTest @VarId        INT, 
                                             @UserId       INT, 
                                             @Canceled     INT, 
                                             @NewResult    nvarchar(25), 
                                             @ResultOn     DATETIME, 
                                             @CommentId    INT, 
                                             @ArrayId      INT, 
                                             @EventId      INT, 
                                             @TestId       BIGINT, 
                                             @SecondUserId INT         = NULL, 
                                             @SignatureId  INT         = NULL, 
                                             @Locked       TINYINT     = NULL
											 ,@ActivityId	Int = NULL

AS
    BEGIN


        DECLARE @DataTypeId INT, @IsCalculated INT
        SET @IsCalculated = 0
        SELECT @ResultOn = dbo.fnServer_CmnConvertToDbTime(@ResultOn, 'UTC')
		
		Declare @GraceTimeToEdit int,@ActivityStatus int, @ActivityEndTime Datetime,@UserAccess int, @SheetId int, @Sheet_Group_Id int
		Select @GraceTimeToEdit =( Select case when  value is null then 0 else cast(value as int) end from Site_PArameters Where Parm_Id = 614)


        Select  @SheetId = Sheet_Id, @ActivityStatus = Activity_Status,@ActivityEndTime = Case when Activity_Status in (3,4) Then End_Time Else NULL End from Activities where Activity_id  = @ActivityId
        Select @Sheet_Group_Id = Group_Id from sheets  where sheet_id = @SheetId
        SELECT @UserAccess = Access_Level from User_Security WHere User_Id =@UserId And ((Access_Level = 4 and Group_Id =1 ) OR (@Sheet_Group_Id= Group_Id AND Access_Level=4))

        IF @UserAccess <> 4 AND Dateadd(minute,@GraceTimeToEdit ,@ActivityEndTime) < Getdate() AND  @ActivityStatus in (3,4)
		BEGIN
			SELECT Code = 'InsufficientPermission', 
                               Error = 'Invalid - Not having access to Edit', 
                               ErrorType = 'UserAccess', 
                               PropertyName1 = 'Activity_Status', 
                               PropertyName2 = 'ActivityEndTime', 
                               PropertyName3 = '', 
                               PropertyName4 = '', 
                               PropertyValue1 = @ActivityStatus, 
                               PropertyValue2 = @ActivityEndTime, 
                               PropertyValue3 = '', 
                               PropertyValue4 = ''
            RETURN
		END

       --
        -- Make sure Result value is the correct Data Type
        --
        SELECT @DataTypeId = v.Data_Type_Id, 
               @IsCalculated = CASE
                                   WHEN Calculation_Id IS NOT NULL
                                   THEN 1
                                   ELSE 0
                               END
               FROM Variables AS v
                    JOIN Data_Type AS d ON d.Data_Type_Id = v.Data_Type_Id
               WHERE Var_Id = @VarId

        IF @DataTypeId IN(1, 2) -- Integer,Float
            BEGIN
                IF @NewResult IS NOT NULL
                   AND ISNUMERIC(@NewResult) = 0
                    BEGIN
                        SELECT Code = 'InvalidData', 
                               Error = 'Invalid - Value is invalid', 
                               ErrorType = 'InvalidDataType', 
                               PropertyName1 = 'VariableId', 
                               PropertyName2 = 'DataTypeId', 
                               PropertyName3 = '', 
                               PropertyName4 = '', 
                               PropertyValue1 = @VarId, 
                               PropertyValue2 = @DataTypeId, 
                               PropertyValue3 = '', 
                               PropertyValue4 = ''
                        RETURN
                END
        END
            ELSE
            BEGIN
                IF @DataTypeId = 4 --Logical
                    BEGIN
                        IF @NewResult IS NOT NULL
                           AND @NewResult NOT IN('0', '1')
                            BEGIN
                                SELECT Code = 'InvalidData', 
                                       Error = 'Invalid - Value is invalid', 
                                       ErrorType = 'InvalidDataType', 
                                       PropertyName1 = 'VariableId', 
                                       PropertyName2 = 'DataTypeId', 
                                       PropertyName3 = '', 
                                       PropertyName4 = '', 
                                       PropertyValue1 = @VarId, 
                                       PropertyValue2 = @DataTypeId, 
                                       PropertyValue3 = '', 
                                       PropertyValue4 = ''
                                RETURN
                        END
                END
        END
        --ELSE IF (@DataTypeId in (6,7,8)) --Array Type
        --BEGIN
        --	--Not currently handled...
        --	SELECT Code = 'InvalidData', Error = 'Data type is not supported', ErrorType = 'InvalidDataType', PropertyName1 = 'VariableId', PropertyName2 = 'DataType', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Var_Id, PropertyValue2 = @DataType, PropertyValue3 = '', PropertyValue4 = ''
        --	RETURN
        --END
	/*
	Change made by DP:
	If variable is of type calculation and we haven't changed the value for the same Then we are not supposed fire update for the same variable. 
	We are restricting users to update 
	calculation variable even if the value is not changed.

	*/

        IF (NOT(@IsCalculated = 1
               AND EXISTS(SELECT 1 FROM Tests WHERE Test_Id = @TestId
                                                    AND CAST(Result AS FLOAT) - CAST(@NewResult AS FLOAT) = 0)) OR (@TestId IS NOT NULL AND @Canceled IS NOT NULL))
            BEGIN
                EXECUTE spServer_DBMgrUpdTest2 @VarId, @UserId, @Canceled, @NewResult, @ResultOn, NULL, @CommentId, @ArrayId, @EventId, NULL, @TestId OUTPUT, NULL, @SecondUserId, NULL, @SignatureId, @Locked
            END

        EXECUTE spActivities_GetTest @TestId
    END

