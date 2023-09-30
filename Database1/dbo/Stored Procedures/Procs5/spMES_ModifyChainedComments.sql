
CREATE PROCEDURE dbo.spMES_ModifyChainedComments @TopOfChainId    INT, --ThreadId
                                                 @CommentId       INT,
                                                 @UserId          INT,
                                                 @TableId         INT,
                                                 @UnitId          INT,
                                                 @CommentText     VARCHAR(7000),
                                                 @TransactionType INT,
                                                 @RootId          INT,
                                                 @AddlInfo        VARCHAR(255)  = NULL, --Use for additional key info.
                                                 @AddlInfo2       VARCHAR(255)  = NULL --Use for additional key info.
AS
BEGIN
    DECLARE @UsersSecurity INT, @ActualSecurity INT, @CurrentCommentUserId INT


    SELECT @CommentText = LTRIM(RTRIM(@CommentText))
    IF @CommentText = ''
        BEGIN
            SELECT @CommentText = NULL
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

    IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @UnitId)
        BEGIN
            SELECT ERROR = 'Unit not found'
            RETURN
        END

    IF @TableId NOT IN(1, 4, 9, 13, 14, 16, 17, 18, 79, 80)
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
            IF @TableId IN(1, 4, 9, 13, 14, 80)
               AND @CurrentCommentUserId <> @UserId
               AND dbo.fnCMN_GetCommentsSecurity(@AddlInfo2, @UserId) = 0
                BEGIN
                    SELECT ERROR = 'Invalid - Attempt to Change Comment'
                    RETURN
                END
            IF @TableId = 1
               AND NOT EXISTS(SELECT 1 FROM Tests WHERE Test_Id = @RootId
                                                        AND Comment_Id = @TopOfChainId)
               OR @TableId = 80
               AND NOT EXISTS(SELECT 1 FROM Activities WHERE Activity_Id = @RootId
                                                             AND (Comment_Id = @TopOfChainId
                                                                  OR Overdue_Comment_Id = @TopOfChainId
                                                                  OR Skip_Comment_Id = @TopOfChainId))
                BEGIN
                    SELECT ERROR = 'Invalid -TopOfChainId is not valid'
                    RETURN
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
                    SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId, @UserId, 1)
                    SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId, 8, 388, 1, @UsersSecurity)
                    IF @ActualSecurity = 0
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Add Comment'
                            RETURN
                        END
                END
            EXEC dbo.spCSS_InsertDeleteChainedComment @RootId, @TableId, @UserId, 1, @AddlInfo, NULL, @CommentId OUTPUT, @TopOfChainId OUTPUT
            UPDATE comments SET comment = @CommentText, comment_text = @CommentText, User_Id = @UserId, modified_on = dbo.fnServer_CmnGetDate(GETUTCDATE()) WHERE Comment_id = @CommentId
        END
    IF @TransactionType = 2  -- Update 
        BEGIN
            IF @CommentText IS NULL
                BEGIN
                    SELECT ERROR = 'Comment not supplied'
                    RETURN
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
                    SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId, @UserId, 1)
                    SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId, NULL, 390, 3, @UsersSecurity)
                    IF @ActualSecurity = 0
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
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
            EXEC dbo.spCSS_InsertDeleteChainedComment @RootId, @TableId, @UserId, 1, @AddlInfo, NULL, @CommentId OUTPUT, @TopOfChainId OUTPUT
        END
    IF @TransactionType IN(1, 3)
        BEGIN
            IF @TableId = 80
                BEGIN
                    EXEC dbo.spServer_DBMgrUpdPendingResultSet 300, @TableId, @RootId, 2, 1, 4, @UserId
                END
        END
    IF @TransactionType IN(1, 2)
        BEGIN
            EXECUTE spMES_GetComments @TopOfChainId, @CommentId, @UserId, @TableId, @UnitId
        END
END
