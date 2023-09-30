-- =============================================
-- Author: 	  	 <502406286, Alfredo Scotto>
-- Create date: <Create Date,,>
-- Description: 	 <Description,,>
-- =============================================
CREATE PROCEDURE dbo.spBF_calCreateNonProductive
        @startTime datetime,
        @endTime datetime,
        @machineId int,
        @reasonId int,
        @commentText text,
 	  	 @ModifyUserId Int = 1,
 	  	 @IsReasonTreeData Int = 0
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
 	 declare @cid int = NULL;
 	 declare @nptid int = NULL;
 	 declare @now datetime;
 	 declare @ret int;
 	 declare @ERTDataId int;
 	 declare @TreeId int;
 	 declare @level1 int;
 	 declare @level2 int;
 	 declare @level3 int;
 	 declare @level4 int;
  IF @ModifyUserId Is Null SET @ModifyUserId =1
  select @now = GETUTCDATE();
 	  BEGIN TRY
     BEGIN TRANSACTION
  if @commentText is not null and DATALENGTH( @commentText ) > 0
    BEGIN
      insert into Comments(comment,Modified_On,ShouldDelete,User_Id) values (@commentText,@now,0,@ModifyUserId);
      set @cid = SCOPE_IDENTITY() ;
    END
 	 IF @IsReasonTreeData = 1
 	 BEGIN
 	  	 SELECT @ERTDataId = @reasonId
 	   	 Select @level1=Level1_Id, @level2=Level2_Id, @level3=Level3_Id,@level4=Level4_Id 
 	  	   From Event_Reason_Tree_Data 
 	  	   Where Event_Reason_Tree_Data_Id = @ERTDataId;
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select @TreeId = Non_Productive_Reason_Tree From Prod_Units_Base where PU_Id = @machineId;
 	  	 SELECT @level1 = @reasonId
 	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) 
 	  	  	 From Event_Reason_Tree_Data 
 	  	  	 Where  Level1_Id = @reasonId and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId;
 	 END
  exec @ret = dbo.spServer_DBMgrUpdNonProductiveTime @NPDetId=@nptid OUTPUT,
                @PUId=@machineId, 	 @StartTime=@startTime,@EndTime=@endTime,
                @ReasonLevel1=@level1,@ReasonLevel2=@level2, @ReasonLevel3=@level3,@ReasonLevel4=@level4,
                @TransactionType=1,@TransNum=0, @UserId=@ModifyUserId,
                @CommentId=@cid,@ERTDataId=@ERTDataId,@EntryOn=@now;
  SELECT te.NPDet_Id,te.Start_Time,te.End_Time,te.Reason_Level1,r1.Event_Reason_Name_Local,te.PU_Id,u.PU_Desc, c.Comment as comment
    from NonProductive_Detail te
      left join Event_Reasons r1 on te.Reason_Level1 = r1.Event_Reason_Id 
      left join comments c on c.Comment_Id = te.Comment_Id
      join Prod_Units u on u.PU_Id = te.PU_Id
  where te.NPDet_Id = @nptid;
        COMMIT
  	 END TRY
 	 BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber
     ,ERROR_SEVERITY() AS ErrorSeverity
     ,ERROR_STATE() AS ErrorState
     ,ERROR_PROCEDURE() AS ErrorProcedure
     ,ERROR_LINE() AS ErrorLine
     ,ERROR_MESSAGE() AS ErrorMessage;
  	  	 IF @@TRANCOUNT > 0
      BEGIN
 	  	  	   ROLLBACK;
      END
 	 END CATCH
END
