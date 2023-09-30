CREATE      PROCEDURE dbo.spServer_DBMgrUpdDefectDetail
@DefectDetailId int OUTPUT,
@DefectTypeId int,
@TransType int,
@TransNum int,
@Cause1 int,
@Cause2 int,
@Cause3 int,
@Cause4 int,
@CauseCommentId int,
@Action1 int,
@Action2 int,
@Action3 int,
@Action4 int,
@ActionCommentId int,
@ResearchStatusId int,
@ResearchCommentId int,
@ResearchUserId int,
@EventId int,
@SourcePUId int,
@PUId int,
@EventSubtypeId int,
@UserId int,
@Severity int,
@Repeat int,
@DimensionX float,
@DimensionY float,
@DimensionZ float,
@DimensionA float,
@Amount float,
@StartCoordinateX float,
@StartCoordinateY float,
@StartCoordinateZ float,
@StartCoordinateA float,
@ResearchOpenDate datetime,
@ResearchCloseDate datetime,
@StartTime datetime,
@EndTime datetime,
@EntryOn datetime OUTPUT
AS
Declare @ShouldUpdate  	  	 Int,
 	 @TmpDefectDetailId 	 Int,
 	 @RetCode 	  	 Int
  --
  -- Return Values:
  --
  --   (-100)  Error.
  --   (   1)  Success: New record added.
  --   (   2)  Success: Existing record modified.
  --   (   3)  Success: Existing record deleted.
  --   (   4)  Success: No action taken.
If (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
if (@TransNum is NULL)
  Begin
    Select @TransNum = 0
  End
If @TransNum Not In (0,2)
  Return(-2)
If (@UserId Is NULL)
  Return(-100)
If (@TransType = 3) And (@DefectDetailId Is NULL)
  Return(-100)
Select @RetCode = -1
Select @EntryOn = dbo.fnServer_CmnGetDate(getUTCdate())
Select @ShouldUpdate = 0
If (@TransType = 2)
  Select @ShouldUpdate = 1
If (@TransType = 1) 
  Begin
    Select @TmpDefectDetailId = NULL
    If @DefectDetailId Is not Null
      Select @TmpDefectDetailId = Defect_Detail_Id  From Defect_Details Where (Defect_Detail_Id = @DefectDetailId)
    If (@TmpDefectDetailId Is Not NULL)
            Select @ShouldUpdate = 1
    Else
      Begin
       Insert Into Defect_Details (Defect_Type_Id,Cause1,Cause2,Cause3,Cause4,Cause_Comment_Id,
 	  	  	  	     Action1,Action2,Action3,Action4,Action_Comment_Id,
 	  	  	  	     Research_Status_Id,Research_Comment_Id,Research_User_Id,Event_Id,Source_PU_Id,
 	  	  	  	     PU_ID,Event_Subtype_Id,User_Id,Severity,Repeat,
 	  	  	  	     Dimension_X,Dimension_Y,Dimension_Z,Dimension_A,Amount,
 	  	  	  	     Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Coordinate_A,
 	  	  	  	     Research_Open_Date,Research_Close_Date,Start_Time,
 	  	  	  	     End_Time,Entry_On)
         Values(@DefectTypeId,@Cause1,@Cause2,@Cause3,@Cause4,@CauseCommentId,
 	  	 @Action1,@Action2,@Action3,@Action4,@ActionCommentId,
 	  	 @ResearchStatusId,@ResearchCommentId,@ResearchUserId,@EventId,@SourcePUId,
 	  	 @PUId,@EventSubtypeId,@UserId,@Severity,@Repeat,
 	  	 Coalesce(@DimensionX,0), Coalesce(@DimensionY,0), Coalesce(@DimensionZ,0), Coalesce(@DimensionA,0),@Amount,
 	  	 Coalesce(@StartCoordinateX,0), Coalesce(@StartCoordinateY,0), Coalesce(@StartCoordinateZ,0), Coalesce(@StartCoordinateA,0),
 	  	 @ResearchOpenDate,@ResearchCloseDate,@StartTime,
 	  	 @EndTime,@EntryOn)
 	 Select @DefectDetailId = Scope_Identity()
 	 Select @RetCode = 1
      End      
  End
If (@ShouldUpdate = 1)
  Begin
   	 If @TransNum = 0
   	   Begin
          Select @DefectTypeId = Coalesce(@DefectTypeId,Defect_Type_Id),
          @CauseCommentId = Coalesce(@CauseCommentId,Cause_Comment_Id),
          @Cause1 = Coalesce(@Cause1,Cause1),
          @Cause2 = Coalesce(@Cause2,Cause2),
          @Cause3 = Coalesce(@Cause3,Cause3),
          @Cause4 = Coalesce(@Cause4,Cause4),
          @Action1 = Coalesce(@Action1,Action1),
          @Action2 = Coalesce(@Action2,Action2),
          @Action3 = Coalesce(@Action3,Action3),
          @Action4 = Coalesce(@Action4,Action4),
          @ActionCommentId = Coalesce(@ActionCommentId,Action_Comment_Id),
          @ResearchStatusId = Coalesce(@ResearchStatusId,Research_Status_Id),
          @ResearchCommentId = Coalesce(@ResearchCommentId,Research_Comment_Id),
          @ResearchUserId = Coalesce(@ResearchUserId,Research_User_Id),
          @EventId = Coalesce(@EventId,Event_Id),
          @SourcePUId = Coalesce(@SourcePUId,Source_PU_Id),
          @PUId = Coalesce(@PUId,PU_Id),
          @EventSubtypeId = Coalesce(@EventSubtypeId,Event_Subtype_Id),
          @Severity = Coalesce(@Severity,Severity),
          @Repeat = Coalesce(@Repeat,Repeat),
          @DimensionX = Coalesce(@DimensionX,Dimension_X),
          @DimensionY = Coalesce(@DimensionY,Dimension_Y),
          @DimensionZ = Coalesce(@DimensionZ,Dimension_Z),
          @DimensionA = Coalesce(@DimensionA,Dimension_A),
          @Amount = Coalesce(@Amount,Amount),
          @StartCoordinateX = Coalesce(@StartCoordinateX,Start_Coordinate_X) ,
          @StartCoordinateY = Coalesce(@StartCoordinateY,Start_Coordinate_Y),
          @StartCoordinateZ = Coalesce(@StartCoordinateZ,Start_Coordinate_Z),
          @StartCoordinateA = Coalesce(@StartCoordinateA,Start_Coordinate_A),
          @ResearchOpenDate = Coalesce(@ResearchOpenDate,Research_Open_Date),
          @ResearchCloseDate = Coalesce(@ResearchCloseDate,Research_Close_Date),
          @StartTime = Coalesce(@StartTime,Start_Time),
          @EndTime = Coalesce(@EndTime,End_Time)
         From Defect_Details 
         Where  Defect_Detail_Id= @DefectDetailId
      End
     	 Update Defect_Details 	 Set Defect_Type_Id = @DefectTypeId,
     	  	  	  	 Cause1 = @Cause1,
 	  	  	  	 Cause2 = @Cause2,
 	  	  	  	 Cause3 = @Cause3,
 	  	  	  	 Cause4 = @Cause4,
 	  	  	  	 Cause_Comment_Id = @CauseCommentId,
 	  	  	  	 Action1 = @Action1,
 	  	  	  	 Action2 = @Action2,
 	  	  	  	 Action3 = @Action3,
 	  	  	  	 Action4 = @Action4,
 	  	  	  	 Action_Comment_Id = @ActionCommentId,
 	  	  	  	 Research_Status_Id = @ResearchStatusId,
 	  	  	  	 Research_Comment_Id = @ResearchCommentId,
 	  	  	  	 Research_User_Id = @ResearchUserId,
 	  	  	  	 Event_Id = @EventId,
 	  	  	  	 Source_PU_Id = @SourcePUId,
 	  	  	  	 PU_ID = @PUId,
 	  	  	  	 Event_Subtype_Id = @EventSubtypeId,
 	  	  	  	 Severity = @Severity,
 	  	  	  	 Repeat = @Repeat,
 	  	  	  	 Dimension_X = Coalesce(@DimensionX, 0),
 	  	  	  	 Dimension_Y = Coalesce(@DimensionY, 0),
 	  	  	  	 Dimension_Z = Coalesce(@DimensionZ, 0),
                                Dimension_A = Coalesce(@DimensionA, 0),
 	  	  	  	 Amount = @Amount,
 	  	  	  	 Start_Coordinate_X = Coalesce(@StartCoordinateX, 0),
 	  	  	  	 Start_Coordinate_Y = Coalesce(@StartCoordinateY, 0),
 	  	  	  	 Start_Coordinate_Z = Coalesce(@StartCoordinateZ, 0),
 	  	  	  	 Start_Coordinate_A = Coalesce(@StartCoordinateA, 0),
 	  	  	  	 Research_Open_Date = @ResearchOpenDate,
 	  	  	  	 Research_Close_Date = @ResearchCloseDate,
 	  	  	  	 Start_Time = @StartTime,
 	  	  	  	 End_Time = @EndTime
 	  	  	  Where (Defect_Detail_Id = @DefectDetailId)
 	     Select @RetCode = 2
   End
If (@TransType = 3) And (@DefectDetailId Is Not NULL)
  Begin
   Delete From Defect_Details Where  Defect_Detail_Id= @DefectDetailId
   Select @RetCode = 3
  End
If @RetCode = -1 
 Select @RetCode = 4
 return(@RetCode)
