CREATE procedure [dbo].[spSDK_AU_ReasonTreeData]
@AppUserId int,
@Id int OUTPUT,
@BottomOfTree tinyint ,
@CommentRequired bit ,
@ERTDataOrder int ,
@ParentReason varchar(100) ,
@ParentReasonId int ,
@ParentReasonTreeDataId int ,
@Reason varchar(100) ,
@ReasonId int ,
@ReasonLevel int ,
@ReasonLevel1 varchar(100) ,
@ReasonLevel1Id int ,
@ReasonLevel2 varchar(100) ,
@ReasonLevel2Id int ,
@ReasonLevel3 varchar(100) ,
@ReasonLevel3Id int ,
@ReasonLevel4 varchar(100) ,
@ReasonLevel4Id int ,
@ReasonTreeId int ,
@ReasonTreeName nvarchar(50) 
AS
 	 IF @Id Is Not Null
 	 BEGIN
 	  	 SELECT 'Updates to reason tree data are not supported'
 	  	 RETURN(-100)
 	 END
 	 
 	 DECLARE @ReturnMessages TABLE (msg VarChar(100))
 	 INSERT INTO @ReturnMessages(msg)
 	  	  	 EXECUTE spEM_IEImportEventReasonTree @ReasonTreeName,@ReasonLevel1,@ReasonLevel2,@ReasonLevel3,@ReasonLevel4,'0',@AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT  msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 ELSE
 	 BEGIN
 	 
 	  	 If (@ReasonLevel2Id Is NULL)
 	  	  	 Select @Id = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data Where (Event_Reason_Id = @ReasonId) And (Level1_Id = @ReasonLevel1Id)
 	  	 Else If (@ReasonLevel3Id Is NULL)
 	  	  	 Select @Id = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data Where (Event_Reason_Id = @ReasonId) And (Level1_Id = @ReasonLevel1Id) And (Level2_Id = @ReasonLevel2Id)
 	  	 Else If (@ReasonLevel4Id Is NULL)
 	  	  	 Select @Id = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data Where (Event_Reason_Id = @ReasonId) And (Level1_Id = @ReasonLevel1Id) And (Level2_Id = @ReasonLevel2Id) And (Level3_Id = @ReasonLevel3Id)
 	  	 Else
 	  	  	 Select @Id = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data Where (Event_Reason_Id = @ReasonId) And (Level1_Id = @ReasonLevel1Id) And (Level2_Id = @ReasonLevel2Id) And (Level3_Id = @ReasonLevel3Id) And (Level4_Id = @ReasonLevel4Id)
 	  	  	 
 	  	 RETURN(1)
 	 END
