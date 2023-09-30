CREATE PROCEDURE dbo.spBF_calUpdateNonProductive
        @Id integer,
        @startTime datetime,
        @endTime datetime,
        @machineId int,
        @reasonId int,
        @commentText text,
 	  	 @ModifyUserId Int = 1,
 	  	 @IsTreeId 	 Int = 0
AS
BEGIN
 	 SET @IsTreeId =Isnull(@IsTreeId,0)
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
 	 DECLARE @TreeId int;
 	 DECLARE @now datetime = GETUTCDATE();
 	 DECLARE @ERTDataId int;
 	 DECLARE @ret int;
 	 DECLARE @OldCommentId 	 Int
 	 DECLARE @level1 int
 	 DECLARE @level2 int
 	 DECLARE @level3 int
 	 DECLARE @level4 int
 	 IF @ModifyUserId IS NULL SET @ModifyUserId  = 1
 	  BEGIN TRY
     BEGIN TRANSACTION
 	  IF @IsTreeId = 1
 	  BEGIN
 	  	 Select @level1=Level1_Id, @level2=Level2_Id, @level3=Level3_Id,@level4=Level4_Id 
 	  	   From Event_Reason_Tree_Data 
 	  	   Where Event_Reason_Tree_Data_Id = @reasonId
 	  	 SELECT @ERTDataId = @reasonId
  	  END
 	  ELSE
 	  BEGIN
 	  	 Select @level1=@reasonId,@ERTDataId = Null
 	  END
 	 SELECT @OldCommentId = Comment_Id from NonProductive_Detail where NPDet_Id = @Id ;
 	 
 	 EXECUTE dbo.spBF_UpdateComment  @OldCommentId  Output,@commentText
    exec @ret = dbo.spServer_DBMgrUpdNonProductiveTime @NPDetId=@Id,
                @PUId=@machineId, 	 @StartTime=@startTime,@EndTime=@endTime,
                @ReasonLevel1=@level1,@ReasonLevel2=@level2, @ReasonLevel3=@level3,@ReasonLevel4=@level4,
                @TransactionType=2,@TransNum=2, @UserId=@ModifyUserId,
                @CommentId=@OldCommentId,@ERTDataId=@ERTDataId,@EntryOn=@now;
          COMMIT
  	 END TRY
 	 BEGIN CATCH
 	  	 IF @@TRANCOUNT > 0
      BEGIN
 	  	  	   ROLLBACK;
      END
 	 END CATCH
  SELECT te.NPDet_Id,te.Start_Time,te.End_Time,te.Reason_Level1,r1.Event_Reason_Name_Local,te.PU_Id,u.PU_Desc, c.Comment as comment
    from NonProductive_Detail te
      left join Event_Reasons r1 on te.Reason_Level1 = r1.Event_Reason_Id 
      left join comments c on c.Comment_Id = te.Comment_Id
      join Prod_Units u on u.PU_Id = te.PU_Id
  where te.NPDet_Id = @Id ;
END
