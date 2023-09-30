
CREATE PROCEDURE [dbo].[spActivities_PatchActivityRecord] @Activity_Id        BIGINT,
                                                 @TargetDuration    INT    = NULL,                                             
                                                 @UserId             INT

 AS
    BEGIN
		------------------------------------------Error Handling---------------------------------------------------
        IF @Activity_Id = ''
            BEGIN
                SET @Activity_Id = NULL
            END

        IF NOT EXISTS(SELECT 1 FROM Activities WHERE Activity_Id = @Activity_Id )
           OR @Activity_Id IS NULL
            BEGIN
                SELECT Code = 'ResourceNotFound',
                       Error = 'Activity Id is Invalid ',
                       ErrorType = 'InvalidParameterValue',
                       PropertyName1 = 'Activity Id',
                       PropertyName2 = '',
                       PropertyName3 = '',
                       PropertyName4 = '',
                       PropertyValue1 = @Activity_Id,
                       PropertyValue2 = '',
                       PropertyValue3 = '',
                       PropertyValue4 = ''
                RETURN
            END

			IF EXISTS(SELECT 1 FROM Activities WHERE Activity_Id = @Activity_Id and activity_status IN (3,4) )
         
            BEGIN
                SELECT Code = 'ActivityAlreadyCompleted',
                       Error = 'Activity Id is Already Completed ',
                       ErrorType = 'ActivityAlreadyCompleted',
                       PropertyName1 = 'Activity Id',
                       PropertyName2 = '',
                       PropertyName3 = '',
                       PropertyName4 = '',
                       PropertyValue1 = @Activity_Id,
                       PropertyValue2 = '',
                       PropertyValue3 = '',
                       PropertyValue4 = ''
                RETURN
            END
		-----------------------------------------------------------------------------------------------------------
     

        BEGIN
            --------Update Target_Duration  when status is Not Started/In progress---------------------------
            IF @Activity_Id IS not NULL 
                BEGIN
                     UPDATE Activities
 	  	  	  SET Target_Duration = (SELECT ISNULL(Target_Duration,0)+@TargetDuration from Activities where Activity_Id = @Activity_Id)
 	  	  	  WHERE Activity_Id = @Activity_Id and Activity_Status NOT IN (3,4)
                END
		  	--------Update Target_Duration  when status is Not Started/In progress---------------------------
            BEGIN
                EXEC dbo.spActivities_GetActivities @TransactionId = 1, @ActivityId = @Activity_Id, @StatusList = NULL
            END
			----------------------------------------------------------------------------------------------------
        END
    END

