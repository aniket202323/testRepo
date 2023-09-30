




CREATE PROCEDURE [dbo].[spLocal_Centerline_SaveTask]

/*
Stored Procedure		:		spLocal_Centerline_SaveTask
Author					:		Shashank Das
Date Created			:		November 8th 2022
SP Type					:		CL
Editor Tab Spacing		:		3

Description:
===========
Save the New Result of a Task

CALLED BY				:  OpsHub


Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			07-Nov-2022		Shashank Das         	Creation of SP

																		
Test Code:
Declare @Msg varchar(200), @IsInShift bit
EXEC spLocal_Centerline_SaveTask 24432537, '2009-02-27 15:00:00', 'Ok', 58, 'My Comment', @IsInShift OUTPUT, @Msg OUTPUT	-- Error Example
SELECT @Msg
*/
@TestId				BIGINT,
@CurrentResult		VARCHAR(50),
@UserId				INT,
@CommentText		VARCHAR(500),
@ErrorMessage		VARCHAR(1000)	OUTPUT

AS


DECLARE
@CommentId				INT,
@PUId					INT,
@MasterUnit				INT,
@Var_Id					INT,
@ErrorCode				INT=0,
@Now					DATETIME,
@OriginalTime			DATETIME,
@CurrentShiftEnd		DATETIME,
@STLSUnitId				INT,
@CurrentValue			VARCHAR(25),
@LastModifiedBy			VARCHAR(50),
@LastModifiedOn			DATETIME,
@UserLanguageId			INT,
@SPCategoryName			VARCHAR(100),
@DataConcurrencyMsg		VARCHAR(200),
@ModifiedByMsg			VARCHAR(100),
@TimeMsg				VARCHAR(100),
@RefreshListMsg			VARCHAR(200)

DECLARE @ErrorsTable TABLE
(
ErrorCode		INT,
ErrorMessage	VARCHAR(1000)
)

/* -- Creates the list of possible errors */
INSERT @ErrorsTable (ErrorCode, ErrorMessage) VALUES (0, NULL)
INSERT @ErrorsTable (ErrorCode, ErrorMessage) VALUES (1, 'Error while updating the comment')
INSERT @ErrorsTable (ErrorCode, ErrorMessage) VALUES (2, 'Error while updating the test table')

/* -- Initially, no error*/
/* SET @ErrorCode = 0 */

SET @Now = getdate()

/* -- Retrieves the existing informations from the Test table */
SELECT	@Var_Id = t.Var_Id,
			@CommentId = t.Comment_Id,
			@PUId = v.PU_Id,
			@OriginalTime = t.Result_On,
			@CurrentValue = t.Result,
			@LastModifiedOn = t.Entry_On,
			@LastModifiedBy = u.Username
FROM		dbo.Tests t				
JOIN		dbo.Variables_Base v		ON t.Var_Id = v.Var_Id
JOIN		dbo.Users_Base     u		ON t.Entry_By = u.[User_Id]
WHERE		Test_Id = @TestId

/* -- Beginning of the transaction */
BEGIN TRANSACTION

/* -- Comment Update/Create section */
IF (@CommentText IS NULL) OR (LTRIM(RTRIM(@CommentText)) = '')
	/* -- Means no comment or deleted comment */
	BEGIN
		IF @CommentId IS NOT NULL
			/* -- Comment exists */
			BEGIN
				/* -- The user erased the comment. We have to delete it from comments table */
				DELETE FROM dbo.Comments WHERE Comment_Id = @CommentId
				
				/* -- This will reset the comment_Id for the update in the Tests table */
				SET @CommentId = NULL			
			END
	END
ELSE
	/* -- Existing comment or new comment */
	BEGIN
		IF @CommentId IS NULL
			/* -- New comment */
			BEGIN
				INSERT dbo.Comments	(
											Comment_Text,
											Comment,
											[User_Id],
											Modified_On
											)
					VALUES	(
								@CommentText,
								@CommentText,
								@UserId,
								@Now
)
				
				IF @@ERROR <> 0
					BEGIN
						SET @ErrorCode = 1
						GOTO ErrorExitTrans
					END
					
				SET @CommentId = @@IDENTITY
			END
		ELSE
			/* -- Existing comment */
			BEGIN
				UPDATE	dbo.Comments
				SET		Comment_Text = @CommentText,
							Comment = @CommentText,
							[User_Id] = @UserId,
							Modified_On = @Now
				WHERE		Comment_Id = @CommentId
				
				IF @@ERROR <> 0
					BEGIN
						SET @ErrorCode = 1
						GOTO ErrorExitTrans
					END
			END
	END

/* -- The update is necessary because the spServer will not update a NULL Comment_Id
-- and will not update a test if the Result_On is changed.
-- The spServer uses the Result_On - Var_Id to do the update regardless of the Test_Id.
-- We need to change the Result_On when postponing a task. */
UPDATE	dbo.Tests
SET		Entry_By = @UserId,
			Entry_On = @Now,
			Result = @CurrentResult,
			Comment_Id = @CommentId
WHERE		Test_Id = @TestId

IF @@ERROR <> 0
	BEGIN
		SET @ErrorCode = 2
		GOTO ErrorExitTrans
	END


COMMIT TRANSACTION
SET @ErrorMessage = (SELECT ErrorMessage FROM @ErrorsTable WHERE ErrorCode = @ErrorCode)
RETURN @ErrorCode

ErrorExitTrans:
/* -- Rollback the transaction */
ROLLBACK

ErrorExit:
SET @ErrorMessage = (SELECT ErrorMessage FROM @ErrorsTable WHERE ErrorCode = @ErrorCode)
RETURN @ErrorCode

SET NOCOUNT OFF
