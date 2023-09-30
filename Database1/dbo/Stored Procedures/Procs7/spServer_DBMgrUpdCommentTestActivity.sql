/* ##### spServer_DBMgrUpdCommentTestActivity #####
Description 	 : For every Comments to a test, if its the first comment added or the last Comment Deleted then does the following
              1.Updates activities percentage complete and pushes activities message if the test is of type Comment
 	  	  	   2.Send test Value message to notify about comment addition or deletion.
Creation Date 	 : 04/07/2018
Created By 	 : 212697290
#### Update History ####
DATE 	  	  	  Modified By 	  	 UserStory/Defect No 	  	 Comments 	 
---- 	  	  	  ----------- 	  	 ------------------- 	  	 --------
*/
CREATE PROCEDURE [dbo].[spServer_DBMgrUpdCommentTestActivity] 
 @TestId BigINT,
 @Type INT ,-- 0 for add and 1 for delete
 @UserId int
AS
BEGIN
 	 Declare @excecuteUpdate INT =0 -- is set to 1 if its the fist comment to be added or the last comment to be deleted
 	  
 	 IF @Type = 1 --deleting the comment, update activities / Publish the Variable Message only if the last comment has been deleted ie null comment id
 	  	 BEGIN
 	  	  SELECT @excecuteUpdate = 1 FROM Tests WHERE Test_Id = @TestId AND Comment_Id IS NULL 
 	  	 END 	 
 	  IF @Type = 0 -- while adding the comment
 	  	 BEGIN
 	  	 
          -- Selects when the first comment is added and has been mapped in the Tests table but have not reached
 	  	   -- the place in spCSS_InsertDeleteChainedComment which adds the TopOfChain_Id to itself
 	  	   -- TopOfChain_Id of the parent comment is never null after for second comment at the place where this sproc is called
          SELECT @excecuteUpdate = 1 FROM Comments C 
 	  	  	  	 WHERE Comment_Id = (SELECT Comment_Id FROM Tests WHERE Test_Id = @TestId) AND TopOfChain_Id IS NULL
 	  	  	  	  	  	  	  	  
 	  	 END
 	  	 -- If the given test is  of type Comment then update Activities percentage complete
 	  IF ( EXISTS(SELECT 1 FROM Tests T JOIN Variables V ON T.Var_Id = V.Var_Id AND V.Data_Type_Id =5
 	  	  	  	  	  	 WHERE T.Test_Id = @TestId)  AND @excecuteUpdate = 1)
        BEGIN
           EXEC spServer_DBMgrUpdActivitiesForTest @TestId 
        END
 	 IF @excecuteUpdate=1
 	  BEGIN
 	  	 --publish the test message if comment added for first time or deleted the last comment
 	  	  EXEC dbo.spServer_DBMgrUpdPendingResultSet null, 1, @TestId, 2, 1, 2, @UserId
 	  END
END
