CREATE PROCEDURE dbo.spEM_IEImportNonProductiveSchedule
 	 @PLDesc 	  	 nvarchar(50),
 	 @PUDesc 	  	 nvarchar(50),
 	 @sStartTime 	 nVarChar(100),
 	 @sEndTime 	  	 nVarChar(100),
 	 @ReasonTree 	 nVarChar(100),
 	 @ReasonL1 	  	 nVarChar(100),
 	 @ReasonL2 	  	 nVarChar(100),
 	 @ReasonL3 	  	 nVarChar(100),
 	 @ReasonL4 	  	 nVarChar(100),
 	 @Comment  	  	 nvarchar(255),
 	 @UserId 	  	 int,
 	 @TransType 	 nVarChar(1)
AS
Declare 	 @PLId  	  	  	 int,
 	  	 @PUId 	  	  	 int,
 	  	 @CommentId 	  	 int,
 	  	 @ExistingComment 	 nvarchar(255),
 	  	 @StartTime  	  	 datetime,
 	  	 @EndTime  	  	  	 datetime,
 	  	 @PrevET 	  	  	 DateTime,
 	  	 @NextST 	  	  	 DateTime,
 	  	 @NPDetId 	  	  	 int,
 	  	 @MyTransType 	  	 Int,
 	  	 @RL1 	  	  	  	 Int,
 	  	 @RL2 	  	  	  	 Int,
 	  	 @RL3 	  	  	  	 Int,
 	  	 @RL4 	  	  	  	 Int,
 	  	 @ERTDId 	  	  	 Int,
 	  	 @PERTDId 	  	  	 Int,
 	  	 @ReasonTreeId 	  	 Int
Select @PLId = Null
Select @PUId = Null
Select @NPDetId = Null
Select @CommentId = Null
------------------------------------------------------------------------------------------
-- Trim Parameters
------------------------------------------------------------------------------------------
Select @PLDesc = LTrim(RTrim(@PLDesc))
Select @PUDesc = LTrim(RTrim(@PUDesc))
Select @sStartTime = LTrim(RTrim(@sStartTime))
Select @sEndTime = LTrim(RTrim(@sEndTime))
Select @Comment = LTrim(RTrim(@Comment))
Select @ReasonTree = LTrim(RTrim(@ReasonTree))
Select @ReasonL1 = LTrim(RTrim(@ReasonL1))
Select @ReasonL2 = LTrim(RTrim(@ReasonL2))
Select @ReasonL3 = LTrim(RTrim(@ReasonL3))
Select @ReasonL4 = LTrim(RTrim(@ReasonL4))
If @PLDesc = '' Select @PLDesc = Null
If @PUDesc = '' Select @PUDesc = Null
If @sStartTime = '' Select @sStartTime = Null
If @sEndTime = '' Select @sEndTime = Null
If @ReasonTree = '' Select @ReasonTree = Null
If @ReasonL1 = '' Select @ReasonL1 = Null
If @ReasonL2 = '' Select @ReasonL2 = Null
If @ReasonL3 = '' Select @ReasonL3 = Null
If @ReasonL4 = '' Select @ReasonL4 = Null
If @Comment = '' Select @Comment = Null
-- Verify Arguments 
If @PLDesc IS NULL
 BEGIN
   Select 'Failed - Production Line Missing'
   Return(-100)
 END
If @PUDesc IS NULL 
 BEGIN
   Select 'Failed - Production Unit Missing'
   Return(-100)
 END
If @sStartTime IS NULL
 BEGIN
   Select 'Failed - Start Time Missing'
   Return(-100)
 END
If @sEndTime IS NULL
 BEGIN
   Select 'Failed - End Time Missing'
   Return(-100)
 END
If Len(@sStartTime)  <> 14 
BEGIN
 	 Select  'Failed - Start Time not valid'
 	 Return(-100)
END
SELECT @StartTime = 0
SELECT @StartTime = DateAdd(year,convert(int,substring(@sStartTime,1,4)) - 1900,@StartTime)
SELECT @StartTime = DateAdd(month,convert(int,substring(@sStartTime,5,2)) - 1,@StartTime)
SELECT @StartTime = DateAdd(day,convert(int,substring(@sStartTime,7,2)) - 1,@StartTime)
SELECT @StartTime = DateAdd(hour,convert(int,substring(@sStartTime,9,2)) ,@StartTime)
SELECT @StartTime = DateAdd(minute,convert(int,substring(@sStartTime,11,2)),@StartTime)
SELECT @StartTime = DateAdd(SECOND,convert(int,substring(@sStartTime,13,2)),@StartTime)
If Len(@sEndTime)  <> 14 
BEGIN
 	 Select  'Failed - End Time not valid'
 	 Return(-100)
END
SELECT @EndTime = 0
SELECT @EndTime = DateAdd(year,convert(int,substring(@sEndTime,1,4)) - 1900,@EndTime)
SELECT @EndTime = DateAdd(month,convert(int,substring(@sEndTime,5,2)) - 1,@EndTime)
SELECT @EndTime = DateAdd(day,convert(int,substring(@sEndTime,7,2)) - 1,@EndTime)
SELECT @EndTime = DateAdd(hour,convert(int,substring(@sEndTime,9,2)) ,@EndTime)
SELECT @EndTime = DateAdd(minute,convert(int,substring(@sEndTime,11,2)),@EndTime)
SELECT @EndTime = DateAdd(SECOND,convert(int,substring(@sEndTime,13,2)),@EndTime)
Select @PLId = PL_Id 
  From Prod_Lines
  Where PL_Desc = @PLDesc
If @PLId Is Null
  Begin
 	 Select 'Failed - Production Line not Found'
 	 Return(-100)
  End
Select @PUId = PU_Id 
  From Prod_Units 
  Where PU_Desc = @PUDesc And PL_Id = @PLId
If @PUId IS NULL
  Begin
 	 Select 'Failed - Production Unit not Found'
 	 Return(-100)
  End
If @ReasonTree is Not Null
BEGIN
 	 Select @ReasonTreeId = Tree_Name_Id From Event_Reason_Tree Where Tree_Name = @ReasonTree
 	 If @ReasonTreeId is Null
 	 BEGIN
 	  	 Select 'Failed - Reason Tree not Found'
 	  	 Return(-100)
 	 END
 	 If (Select Non_Productive_Reason_Tree From Prod_Units Where PU_Id = @PUId) is Null
 	    Update  Prod_Units Set Non_Productive_Reason_Tree = @ReasonTreeId Where PU_Id = @PUId
 	 Else
 	  	 If @ReasonTreeId <> (Select Non_Productive_Reason_Tree From Prod_Units Where PU_Id = @PUId)
 	  	 BEGIN
 	  	  	 Select 'Failed - Reason Tree does not match current tree'
 	  	  	 Return(-100)
 	  	 END
END
If @ReasonL1 is not Null
BEGIN
 	 Select @RL1 = Event_Reason_Id 	 From Event_Reasons 	 Where Event_Reason_Name = @ReasonL1
 	 If @RL1 Is Null
 	 BEGIN
 	  	 Select 'Failed - Reason level 1 not found'
 	  	 Return(-100)
 	 END
END
If @ReasonL2 is not Null
BEGIN
 	 Select @RL2 = Event_Reason_Id 	 From Event_Reasons 	 Where Event_Reason_Name = @ReasonL2
 	 If @RL2 Is Null
 	 BEGIN
 	  	 Select 'Failed - Reason level 2 not found'
 	  	 Return(-100)
 	 END
END
If @ReasonL3 is not Null
BEGIN
 	 Select @RL3 = Event_Reason_Id 	 From Event_Reasons 	 Where Event_Reason_Name = @ReasonL3
 	 If @RL3 Is Null
 	 BEGIN
 	  	 Select 'Failed - Reason level 3 not found'
 	  	 Return(-100)
 	 END
END
If @ReasonL4 is not Null
BEGIN
 	 Select @RL4 = Event_Reason_Id 	 From Event_Reasons 	 Where Event_Reason_Name = @ReasonL4
 	 If @RL4 Is Null
 	 BEGIN
 	  	 Select 'Failed - Reason level 4 not found'
 	  	 Return(-100)
 	 END
END
If @RL1 is not Null
BEGIN
 	 Select @ERTDId = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
 	  	  Where Tree_Name_Id = @ReasonTreeId And Event_Reason_Id = @RL1 and Parent_Event_R_Tree_Data_Id Is Null
 	 If @ERTDId is Null
 	 BEGIN
 	  	 Select 'Failed - Reason level 1 not found on given tree'
 	  	 Return(-100)
 	 END
END
If @RL2 is not Null and @ERTDId is not Null
BEGIN
 	 Select @PERTDId = @ERTDId,@ERTDId = Null
 	 Select @ERTDId = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
 	  	  Where Tree_Name_Id = @ReasonTreeId And Event_Reason_Id = @RL2 and Parent_Event_R_Tree_Data_Id = @PERTDId
 	 If @ERTDId is Null
 	 BEGIN
 	  	 Select 'Failed - Reason level 2 not found on given tree'
 	  	 Return(-100)
 	 END
END
If @RL3 is not Null and @ERTDId is not Null
BEGIN
 	 Select @PERTDId = @ERTDId,@ERTDId = Null
 	 Select @ERTDId = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
 	  	  Where Tree_Name_Id = @ReasonTreeId And Event_Reason_Id = @RL3 and Parent_Event_R_Tree_Data_Id = @PERTDId
 	 If @ERTDId is Null
 	 BEGIN
 	  	 Select 'Failed - Reason level 3 not found on given tree'
 	  	 Return(-100)
 	 END
END
If @RL4 is not Null and @ERTDId is not Null
BEGIN
 	 Select @PERTDId = @ERTDId,@ERTDId = Null
 	 Select @ERTDId = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
 	  	  Where Tree_Name_Id = @ReasonTreeId And Event_Reason_Id = @RL4 and Parent_Event_R_Tree_Data_Id = @PERTDId
 	 If @ERTDId is Null
 	 BEGIN
 	  	 Select 'Failed - Reason level 4 not found on given tree'
 	  	 Return(-100)
 	 END
END
------------------------------------------------------------------------------------------
--Insert or Delete NonProductive 	 
------------------------------------------------------------------------------------------
Select @NPDetId = NPDet_Id 
  from nonproductive_detail 
  where PU_Id = @PUId and Start_Time = @StartTime
Select @MyTransType = 1
If @TransType = 'D' 
 Begin
 	 If @NPDetId is null
 	   Begin
 	  	 Select 'Failed - StartTime for delete not found'
 	  	 Return(-100)
 	   End
 	 Delete From nonproductive_detail Where NPDet_Id =  @NPDetId
 	 Return(0)
 End
If @Comment IS NOT NULL 
  Begin
    Insert into Comments (Comment, User_Id, Modified_On, CS_Id) Values(@Comment,1,dbo.fnServer_CmnGetDate(getUTCdate()),3)
    Select @CommentId = Scope_Identity()
    If @CommentId IS NULL
        Select 'Warning - Unable to create comment'
  END
IF EXISTS(SELECT Start_Time FROM NonProductive_Detail WHERE PU_Id = @PUId AND Start_Time >= @StartTime AND Start_Time < @EndTime) -- (a) Start_Time = @End_Time is allowed
OR EXISTS(SELECT End_Time   FROM NonProductive_Detail WHERE PU_Id = @PUId AND End_Time > @StartTime AND End_Time <= @EndTime)     -- (b) End_Time   = @Start_Time is allowed
OR EXISTS(SELECT Start_Time FROM NonProductive_Detail WHERE PU_Id = @PUId AND Start_Time <= @StartTime AND End_Time >= @EndTime)  -- (c)
  BEGIN
    SELECT 'Failed - StartTime and/or EndTime Crosses existing record'
    Return(-100)
  END
INSERT INTO NonProductive_Detail(PU_Id, Start_Time, End_Time, Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4,User_Id, Event_Reason_Tree_Data_Id,Comment_Id,Entry_On)
 	   Select @PUId, @StartTime, @EndTime, @RL1, @RL2, @RL3,@RL4,@UserId,@ERTDId, @CommentId, dbo.fnServer_CmnGetDate(getUTCdate())
