
CREATE PROCEDURE dbo.spActivities_GenerateVariableValuesAndCloseActivities
  @NumActivitiesToClose Int = 20,
  @UserId Int = 1,
  @OutOfSpecRangeToInclude Int = 0,
  @LowerValueLimitWhenNoSpec Int = 5,
  @UpperValueLimitWhenNoSpec Int = 15


 AS

    DECLARE @ActivityStatus Int, @KeyId Datetime, @ActivityID int, @VarId Int, @NewResult nvarchar(25), @DataType Int, @VarPrecision Int, @UReject Float, @LReject Float
    DECLARE @Now datetime = GETDATE()

    DECLARE @Variables TABLE(VarId Int,VarOrder Int,Title nvarchar(50), Processed Bit)
    DECLARE @TempActivities TABLE(Id Int, KeyId Datetime, Processed Bit)
    Declare @Specs TABLE(VariableId int, U_Entry float, L_Entry float, U_Reject float, L_Reject float, U_Warning float,
       L_Warning float, U_User float, L_User float, U_Control float,L_Control float ,Target float,T_Control float,Test_Freq float, Data_Type_Id int)

    -- GET THE OLDEST OPEN ACTIVITIES
    INSERT INTO @TempActivities
    SELECT TOP (@NumActivitiesToClose) Activity_Id, KeyId, 0 from Activities where Activity_Status in (1,2) ORDER BY Activity_Id

    WHILE EXISTS (SELECT * FROM @TempActivities WHERE Processed = 0)
    BEGIN
           SELECT @ActivityID = Id,
                  @KeyId = dbo.fnServer_CmnConvertFromDbTime(KeyId,'UTC') -- WE NEED UTC TIME TO PASS INTO SPROCS
           FROM @TempActivities
           WHERE Processed = 0

           UPDATE Activities
        SET Activity_Status = 2,
            Start_Time = @Now,
            UserId = @UserId
           WHERE Activity_ID = @ActivityID
          AND Activity_Status = 1

           -- GET AUTOLOG VARIABLES FOR AN ACTIVITY
           DELETE @Variables
           INSERT INTO @Variables (VarId, VarOrder, Title, Processed)
        SELECT varId, VarOrder, Title, 0 FROM dbo.fnActivities_GetVariablesForActivity(@ActivityId)
           WHERE VarId IS NOT NULL

           WHILE EXISTS (SELECT * FROM @Variables WHERE Processed = 0)
           BEGIN
                  SET @UReject = NULL
                  SET @LReject = NULL

                  SELECT @VarId = VarId
                  FROM @Variables
                  WHERE Processed = 0

                  --GET VARIABLE DATA TYPE
                  SELECT @DataType = Data_Type_Id,
                         @VarPrecision = Var_Precision
                  FROM Variables_Base
                  WHERE Var_Id = @VarId

				  --ONLY PROCESS VARIABLES THAT HAVE A SUPPORTED TYPE
				  IF(@DataType NOT IN (1,2,4))
				  BEGIN
					  UPDATE @Variables
					  SET Processed = 1
					  WHERE VarId = @VarId

					  CONTINUE
				  END

                  --GET SPECS FOR THIS VARIABLE
                  DELETE @Specs
                  INSERT INTO @Specs
                  EXEC dbo.spActivities_GetVariableSpecs @VarId, @KeyId

                  --GET UPPER AND LOWER REJECTS
                  SELECT @UReject = U_Reject,
                         @LReject = L_Reject
                  FROM @Specs

                  -- Use specs if available, or default to specs passed in for floats
                  SET @LReject = COALESCE(@LReject,@LowerValueLimitWhenNoSpec) - @OutOfSpecRangeToInclude
                  SET @UReject = COALESCE(@UReject,@UpperValueLimitWhenNoSpec) + @OutOfSpecRangeToInclude

                  IF(@DataType = 1)
                  BEGIN
                         SET @NewResult = ROUND((RAND()*(@UReject - @LReject) + @LReject),0,0)
                  END
                  ELSE IF (@DataType = 2)
                  BEGIN
                         SET @NewResult = ROUND((RAND()*(@UReject - @LReject) + @LReject),@VarPrecision,0)
                  END
                  ELSE --LOGICAL OR SOMETHING NOT YET SUPPORTED
                  BEGIN
                         SELECT @NewResult = ROUND(RAND(),0)
                  END

                  --ADD/UPDATE TEST RECORD
                  EXEC dbo.spActivities_UpdateTest @VarId,@UserId,0,@NewResult,@KeyId,NULL,NULL,NULL,NULL,NULL,NULL

                  UPDATE @Variables
                  SET Processed = 1
                  WHERE VarId = @VarId
           END

           --REFRESH THE PERCENT COMPLETE
           EXEC dbo.spActivities_UpdateVariable 2,@ActivityID,NULL,1,NULL

           UPDATE Activities
        SET Activity_Status = 3,
            End_Time = GETDATE()
           WHERE Activity_ID = @ActivityID

           UPDATE @TempActivities
           SET Processed = 1
           WHERE Id = @ActivityID
    END

