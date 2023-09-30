
CREATE PROCEDURE dbo.spComments_ModifyChainedCommentsV1 @TopOfChainId    INT, --ThreadId
                                                 @CommentId       INT,
                                                 @UserId          INT,
                                                 @TableId         INT,
                                                 @UnitId          INT,
                                                 @CommentText     nvarchar(max),
                                                 @TransactionType INT,
                                                 @RootId          INT,
                                                 @AddlInfo        nvarchar(255)  = NULL, --Use for additional key info.
                                                 @AddlInfo2       nvarchar(255)  = NULL --Use for additional key info.
AS
BEGIN
    DECLARE @UsersSecurity INT, @ActualSecurity INT, @CurrentCommentUserId INT, @OtherUserCommentSecurity int
        create table #POCommentSecurity
            (Path_Id int, Path_Desc nVarchar(1000), ReadSecurity int, AddSecurity int, DeleteSecurity int,
                EditSecurity int, ArrangeSecurity int,  CommentReadSecurity int, CommentAddSecurity int, CommentDeleteSecurity int,
                CommentEditSecurity int, OtherUsersCommentChangeSecurity int, UnbindSecurity int)

        If(@TableId = 35)
            BEGIN
                INSERT INTO #POCommentSecurity EXEC spPO_getPathSecurity @UserId, null, @RootId
            end

    SELECT @CommentText = LTRIM(RTRIM(@CommentText))
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

    -- @UnitId will be null with TableId = 35
    IF( @TableId != 35 AND NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @UnitId))
        BEGIN
            SELECT ERROR = 'Unit not found'
            RETURN
        END

    IF @TableId NOT IN(1, 4, 9, 13, 14, 16, 17, 18, 79, 80, 35, 20, 21, 22)
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

            IF @TableId IN(16,17,18,79) -- Downtime and NPT comments
                AND @CurrentCommentUserId <> @UserId
                BEGIN
                    DECLARE @CommentSecurity TABLE (ComSecurity int);
                    Declare @OtherUserCommentChangePermissionDowntime int
                    Insert into @CommentSecurity EXEC spComment_GetCommentChangePermission NULL,@RootId,@TableId,@UserId
                    select @OtherUserCommentChangePermissionDowntime =  ComSecurity  from @CommentSecurity
                    IF @OtherUserCommentChangePermissionDowntime != 1
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
                        end


                end

            IF(@TableId IN(16,17,18))
                BEGIN  -- Checking for downtime sheet security, for delete and edit
                    Select @UnitId = CASE  WHEN Master_Unit IS NULL THEN pu_Id else Master_Unit END from Prod_Units where Pu_Id = @UnitId
                    SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId, @UserId, 1)
                    SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId,NULL,390,1,@UsersSecurity)
                    IF @ActualSecurity = 0
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
                        end
                end


            IF @TableId IN(35) AND @CurrentCommentUserId <> @UserId
                BEGIN
                    DECLARE @OtherUsersCommentChangeSecurity INT;
                    select @OtherUsersCommentChangeSecurity = OtherUsersCommentChangeSecurity from #POCommentSecurity
                    IF(@OtherUsersCommentChangeSecurity = 0)
                        BEGIN
                            -- user does not have access to change other users comments
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
                        end
                end

            IF @TableId = 1
               AND NOT EXISTS(SELECT 1 FROM Tests WHERE Test_Id = @RootId
                                                        AND Comment_Id = @TopOfChainId)
               OR @TableId = 80
               AND NOT EXISTS(SELECT 1 FROM Activities WHERE Activity_Id = @RootId
                                                             AND (Comment_Id = @TopOfChainId
                                                                  OR Overdue_Comment_Id = @TopOfChainId
                                                                  OR Skip_Comment_Id = @TopOfChainId
																  OR ActivityDetail_Comment_Id = @TopOfChainId))
                OR @TableId = 35
                AND NOT EXISTS(SELECT 1 from Production_Plan WHERE PP_Id = @RootId AND @TopOfChainId = Comment_Id)
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
					Select @UnitId = CASE  WHEN Master_Unit IS NULL THEN pu_Id else Master_Unit END from Prod_Units where Pu_Id = @UnitId
                    SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId, @UserId, 1)
                    SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId,NULL,388,1,@UsersSecurity)
                    IF @ActualSecurity = 0
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Add Comment'
                            RETURN
                        END
                END
			ELSE IF @TableId IN(20, 21, 22)  -- Waste Add
               AND @CurrentCommentUserId != @UserId  -- ATTEMPT TO CHANGE OTHER USERS COMMENT
                BEGIN
					Select @UnitId = CASE WHEN Master_Unit IS NULL THEN pu_Id else MAster_Unit END from Prod_Units where Pu_Id = @UnitId
                    SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId, @UserId, 4)
                    SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId, NULL, 388, 3, @UsersSecurity)
                    IF @ActualSecurity = 0
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
                        END
                END	
            ELSE IF @TableId IN(35)
                BEGIN
                    DECLARE @commentAddSec INT;
                    select @commentAddSec = CommentAddSecurity from #POCommentSecurity
                    If(@commentAddSec = 0)
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Add Comment'
                            RETURN
                        end
                end
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
			ELSE IF @TableId IN(20, 21, 22)  -- Waste Update
               AND @CurrentCommentUserId != @UserId  -- ATTEMPT TO CHANGE OTHER USERS COMMENT
                BEGIN
					Select @UnitId = CASE WHEN Master_Unit IS NULL THEN pu_Id else MAster_Unit END from Prod_Units where Pu_Id = @UnitId
                    SELECT @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel(@UnitId, @UserId, 4)
                    SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@UnitId, NULL, 390, 4, @UsersSecurity)
                    		
					IF @ActualSecurity = 0
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
                        END
						
				      ;WITH OtherUsersComment AS (
                    Select ISNULL(s.Master_Unit,su.pu_id) as Master_Unit, MIN(CAST(dbo.fnCMN_GetCommentsSecurity(S.Sheet_Id,@UserId) as int)) Access from Sheets S
                              Left join Sheet_Unit su on su.sheet_id = S.sheet_Id 
                              where (S.Master_Unit=@UnitId or su.Pu_id =@UnitId ) and Is_Active = 1 and Sheet_Type in (4,26,29)
                              Group by ISNULL(s.Master_Unit,su.pu_id)
                    )

					Select @OtherUserCommentSecurity= Access from OtherUsersComment;
                    
					IF @OtherUserCommentSecurity = 0 and @CurrentCommentUserId <> @UserId
					Begin
						SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
					End		
                END	

            ELSE IF @TableId IN(35)
                BEGIN
                    DECLARE @commentEditSec INT;
                    select @commentEditSec = CommentEditSecurity from #POCommentSecurity
                    If(@commentEditSec = 0)
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
                        end
                end


            UPDATE comments SET comment = @CommentText, comment_text = @CommentText, User_Id = @UserId, modified_on = dbo.fnServer_CmnGetDate(GETUTCDATE()) WHERE Comment_id = @CommentId

            IF @TopOfChainId IS NULL
                BEGIN
                    SELECT @TopOfChainId = TopOfChain_Id FROM Comments WHERE Comment_Id = @CommentId
                END
        END
    IF @TransactionType = 3  -- Delete
        BEGIN
            IF @TableId IN(35)
                BEGIN
                    DECLARE @commentDeleteSec INT;
                    select @commentDeleteSec = CommentDeleteSecurity from #POCommentSecurity
                    If(@commentDeleteSec = 0)
                        BEGIN
                            SELECT ERROR = 'Invalid - Attempt to Change Comment'
                            RETURN
                        end
                end

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
            EXECUTE spMES_GetComments @TopOfChainId, @CommentId, @UserId, @TableId, @UnitId
        END
END
