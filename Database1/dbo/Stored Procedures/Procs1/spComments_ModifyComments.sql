



CREATE PROCEDURE [dbo].[spComments_ModifyComments] @TopOfChainId    INT, --ThreadId
                                                 @CommentId       INT,
                                                 @UserId          INT,
                                                 @TableId         INT,
                                                 @UnitId          INT,
                                                 @CommentText     nvarchar(max),
                                                 @TransactionType INT,
                                                 @RootId          INT,
												 @EntityType      nvarchar(255),
												 @CommentType     nvarchar(50),
                                                 @AddlInfo        nvarchar(255)  = NULL, --Use for additional key info.
                                                 @AddlInfo2       nvarchar(255)  = NULL --Use for additional key info.
AS
BEGIN
    DECLARE @UsersSecurity INT, @ActualSecurity INT, @CurrentCommentUserId INT

	Declare @EntityId Int,@MappedTableId int,@CurrentTopOfChainId INT
    SELECT @CommentText = LTRIM(RTRIM(@CommentText))
	DECLARE @MaterialLotStatus Int
    IF @CommentText = ''
        BEGIN
            SELECT @CommentText = NULL
        END
    DECLARE @CommentLen int
    select @CommentLen = LEN(@CommentText)

    IF(@CommentLen > 7000)
        BEGIN
            SELECT ERROR = 'Comment text length is more than maximum specified limit of 7000', CODE = 'CommentTooLarge'
            RETURN
        END


    IF @TransactionType NOT IN(1, 2, 3)
       OR @TransactionType IS NULL
        BEGIN
            SELECT ERROR = 'Invalid - Transaction Type Required'
            RETURN
        END

    IF NOT EXISTS(SELECT 1 FROM Users WHERE User_Id = @UserId)
        BEGIN
            SELECT ERROR = 'User not found'
            RETURN
        END

    --IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @UnitId)
       --BEGIN
           --SELECT ERROR = 'Unit not found'
           --RETURN
        --END

    IF @TableId NOT IN(1, 4, 9, 13, 14, 16, 17, 18, 79, 80,81,82,83,84,85, 86, 87)
       OR @TableId IS NULL
        BEGIN
            SELECT ERROR = 'Target TableId not supplied'
            RETURN
        END

    IF @RootId IS NULL
        BEGIN
            SELECT ERROR = 'RootId not supplied'
            RETURN
        END

    IF @TransactionType IN(2, 3)
        BEGIN
			-- Not supporting the update and delete on esignature comments
			IF @TableId IN(86, 87)
                BEGIN
                    SELECT ERROR = 'Invalid - Attempt to Change Comment'
                    RETURN
                END
            IF @CommentId IS NULL
                BEGIN
                    SELECT ERROR = 'CommentId not supplied'
                    RETURN
                END
            IF NOT EXISTS(SELECT 1 FROM Comments WHERE Comment_Id = @CommentId)
                BEGIN
                    SELECT ERROR = 'Comment not found'
                    RETURN
                END
            SELECT @CurrentCommentUserId = User_Id FROM Comments WHERE Comment_Id = @CommentId
            IF @TableId IN(1, 4, 9, 13, 14, 80) AND @CurrentCommentUserId <> @UserId AND dbo.fnCMN_GetCommentsSecurity(@AddlInfo2, @UserId) = 0
                BEGIN
                    SELECT ERROR = 'Invalid - Attempt to Change Comment'
                    RETURN
                END
            IF @TableId = 1 AND NOT EXISTS(SELECT 1 FROM Tests WHERE Test_Id = @RootId AND Comment_Id = @TopOfChainId) OR @TableId = 80 AND NOT EXISTS(SELECT 1 FROM Activities WHERE Activity_Id = @RootId AND (Comment_Id = @TopOfChainId OR Overdue_Comment_Id = @TopOfChainId OR Skip_Comment_Id = @TopOfChainId))
                BEGIN
                    SELECT ERROR = 'Invalid -TopOfChainId is not valid'
                    RETURN
                END
			IF @CommentId !=  @TopOfChainId
				BEGIN
					IF  EXISTS(Select 1 FROM Comments WHERE Comment_Id =  @CommentId and TopOfChain_Id !=  @TopOfChainId)
					BEGIN
						SELECT ERROR = 'Comment Chain Not Correct';
						RETURN
					END
				END
		END

    IF @TransactionType = 1
        BEGIN
            IF @TopOfChainId IS NOT NULL
                BEGIN
                    IF NOT EXISTS(SELECT 1 FROM Comments WHERE Comment_Id = @TopOfChainId)
                        BEGIN
                            SELECT ERROR = 'Invalid -TopOfChainId is not valid'
                            RETURN
                        END
                END

            IF @CommentText IS NULL
                BEGIN
                    SELECT ERROR = 'No Comment Supplied'
                    RETURN
                END
			IF @TableId IN(16, 17, 18)   -- Downtime Add
                BEGIN
					Select @UnitId = CASE  WHEN Master_Unit IS NULL THEN pu_Id else Master_Unit END from Prod_Units where Pu_Id = @UnitId
                    SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId, @UserId, 1)
                    SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId,NULL,388,1,@UsersSecurity)
                    IF @ActualSecurity = 0
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Add Comment'
                            RETURN
                        END
                END
			 -- Added for handling the esignature comments 86 - performer comment and 87 - verifier comment	
			 IF @TableId IN(86, 87)
                BEGIN
				    -- For esignature comments there is only creation scenario no update or delete also there is no chained comment concept
					--Before creating the comment check if the user is same one as the one who made the signature 
					-- and the signature already doesn't have a comment
				    DECLARE @performUser int, @verifyUser int, @performComment int, @verifyComment int
					SELECT @performUser = Perform_User_Id, @verifyUser = Verify_User_Id, @performComment = COALESCE(Perform_Comment_Id,0), @verifyComment = COALESCE(Verify_Comment_Id,0) FROM ESignature WHERE Signature_Id = @RootId
					IF @TableId = 86 AND ((@UserId <> @performUser) OR ( @performComment > 0))
						BEGIN
							SELECT ERROR = 'Invalid - Attempt to Change Comment'
							RETURN
						END
					ELSE IF @TableId = 87 AND ((@UserId <> @verifyUser) OR ( @verifyComment > 0))
						BEGIN
							SELECT ERROR = 'Invalid - Attempt to Change Comment'
							RETURN
						END
				    --Insert the comment
					Insert Into Comments (Comment, Comment_Text, User_Id, Entry_On, CS_Id, Modified_On) -- for some reason CS_ID is inserted as 1 always for esig comments by PA strange but keeping the same gehaviour here as well
						values (@CommentText, @CommentText, @UserId, dbo.fnServer_CmnGetDate(getutcdate()), 1, dbo.fnServer_CmnGetDate(getutcdate()))
					
					SELECT @CommentId = Comment_Id , @TopOfChainId = Comment_Id FROM Comments WHERE Comment_Id = Scope_Identity()
					--For some reason top of chain id is required in the get call and needs to be valid so setting that
					UPDATE Comments SET TopOfChain_Id = @CommentId WHERE Comment_id = @CommentId
					--Now based on the comment type insert onto esignature table
					IF @TableId = 86
						BEGIN
							UPDATE ESignature SET Perform_Comment_Id = @CommentId WHERE Signature_Id = @RootId
						END
					ELSE
						BEGIN
							UPDATE ESignature SET Verify_Comment_Id = @CommentId WHERE Signature_Id = @RootId
						END
                END
             -- For all the other type of comments the below block would be executed -- leaving as is now as per review, but probabily need cleaning up when used extensively by all apps
			 ELSE
                BEGIN
					SET @MappedTableId = @TableId
					SET @EntityId = @RootId
					
					Select @RootId = PP_Id,@TableId = 35 from Workorder.workorders where Id = @RootId And @TableId =81
					;WITH S AS (
						Select M.Id MAterialLotActualId,[Status],M.LotIdentifier from WorkOrder.MaterialLotActuals M Where M.id = @RootId And @TableId = 83 
					)
					,S1 As (Select 'DISC:'+Cast(MAterialLotActualId as nvarchar) LotIdentifier_EventNum,[Status],LotIdentifier from S )
					Select @RootId= Event_Id ,@TableId=4,@MaterialLotStatus=[Status] from Events E Join S1 on   S1.LotIdentifier = E.lot_identifier AND E.Event_Num = S1.LotIdentifier_EventNum

					IF @MappedTableId IN (83) AND @MaterialLotStatus = 21
					Begin
						SELECT ERROR = 'Serial Number Not Started';
					    RETURN;
					End
					
					IF (@RootId IS NULL OR @RootId <=0) AND (@MappedTableId  IN (81) OR @MappedTableId  IN (83))
					Begin
						SELECT ERROR = 'Invalid EntityId'
					    RETURN;
					End

					IF ISNULL(@CommentType,'') <> ''
						SET @AddlInfo = @CommentType 	
						
					EXEC dbo.spCSS_InsertDeleteChainedComment @RootId, @TableId, @UserId, 1, @AddlInfo, NULL, @CommentId OUTPUT, @TopOfChainId OUTPUT
					UPDATE comments SET comment = @CommentText, comment_text = @CommentText, User_Id = @UserId, modified_on = dbo.fnServer_CmnGetDate(GETUTCDATE()) WHERE Comment_id = @CommentId
                END

			
        END
    IF @TransactionType = 2  -- Update 
        BEGIN
            IF @CommentText IS NULL
                BEGIN
                    SELECT ERROR = 'Comment not supplied'
                    RETURN
                END
				
	IF  NOT EXISTS(Select 1 FROM Comments WHERE Comment_Id =  @CommentId)
	BEGIN
		SELECT ERROR = 'Comment Not Found'
	END
            SELECT @CurrentCommentUserId = User_Id FROM Comments WHERE Comment_Id = @CommentId
            IF @CurrentCommentUserId IS NULL
                BEGIN
                    SELECT ERROR = 'Comment not found'
                    RETURN
                END
            IF @TableId IN(16, 17, 18)
               AND @CurrentCommentUserId != @UserId  -- ATTEMPT TO CHANGE OTHER USERS COMMENT
                BEGIN
					Select @UnitId = CASE WHEN Master_Unit IS NULL THEN pu_Id else MAster_Unit END from Prod_Units where Pu_Id = @UnitId
                    SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId, @UserId, 1)
                    SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId, NULL, 390, 3, @UsersSecurity)
                    IF @ActualSecurity = 0
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
                        END
                END

				IF @CommentId !=  @TopOfChainId
	BEGIN
		IF  EXISTS(Select 1 FROM Comments WHERE Comment_Id =  @CommentId and TopOfChain_Id !=  @TopOfChainId)
		BEGIN
			SELECT ERROR = 'Comment Chain Not Correct'
		END
	END


            UPDATE comments SET comment = @CommentText, comment_text = @CommentText, User_Id = @UserId, modified_on = dbo.fnServer_CmnGetDate(GETUTCDATE()) WHERE Comment_id = @CommentId

            IF @TopOfChainId IS NULL
                BEGIN
                    SELECT @TopOfChainId = TopOfChain_Id FROM Comments WHERE Comment_Id = @CommentId
                END
        END
    IF @TransactionType = 3  -- Delete
        BEGIN
        SET @MappedTableId = @TableId
			
			IF ISNULL(@CommentType,'') <> ''
				SET @AddlInfo = @CommentType 			
			
			Select @RootId = PP_Id,@TableId = 35 from Workorder.workorders where Id = @RootId And @TableId =81
			;WITH S AS (
				Select M.Id MAterialLotActualId,[Status],M.LotIdentifier from WorkOrder.MaterialLotActuals M Where M.id = @RootId And @TableId = 83 
			)
			,S1 As (Select 'DISC:'+Cast(MAterialLotActualId as nvarchar) LotIdentifier_EventNum,[Status],LotIdentifier from S )
			Select @RootId= Event_Id ,@TableId=4,@MaterialLotStatus=[Status] from Events E Join S1 on  S1.LotIdentifier = E.lot_identifier AND S1.LotIdentifier_EventNum = E.Event_Num
			
			IF @RootId IS NULL
				BEGIN
					SELECT ERROR='Invalid EntityId';
					RETURN;
				END

				SET @CurrentTopOfChainId=@TopOfChainId

				IF(@TopOfChainId=@CommentId)
				BEGIN
					SELECT @CurrentTopOfChainId=ct.NextComment_Id from Comments ct where ct.TopOfChain_Id=@TopOfChainId AND ct.Comment_Id=@CommentId
				END

            EXEC dbo.spCSS_InsertDeleteChainedComment @RootId, @TableId, @UserId, 1, @AddlInfo, NULL, @CommentId OUTPUT, @TopOfChainId OUTPUT
        END
    IF @TransactionType IN(1, 3)
        BEGIN
            IF @TableId IN(4, 9, 80)
                BEGIN
          	    DECLARE @ResultSetType INT
				SELECT @ResultSetType = CASE WHEN @TableId = 4 THEN 1 WHEN @TableId = 9 THEN 8 ELSE 4 END
                    EXEC dbo.spServer_DBMgrUpdPendingResultSet 300, @TableId, @RootId, 2, 1, @ResultSetType, @UserId
                END
        END
    IF @TransactionType IN(1, 2)
        BEGIN
            EXECUTE spComments_GetComments @TopOfChainId, @CommentId, @UserId, @TableId, @UnitId
        END

	IF @TransactionType=3 AND  @CurrentTopOfChainId IS NOT NULL
        BEGIN
            EXECUTE spComments_GetComments @CurrentTopOfChainId, NULL, @UserId, @TableId, @UnitId
        END
END

