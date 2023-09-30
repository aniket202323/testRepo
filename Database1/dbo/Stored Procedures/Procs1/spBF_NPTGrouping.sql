CREATE PROCEDURE [dbo].[spBF_NPTGrouping]
  @NPTGroupId Int,
  @StartDate DateTime,
  @EndDate DateTime,
  @UnitList nvarchar(max),
  @PLId Int,
  @EventReasonTreeDataId  Int,
  @TransNum Int,
  @TransType Int,
  @userId Int,
  @CommentText nvarchar(max)
  AS
/*
@TransType 
1 - Add
2 - Update
3 - Delete
@TransNum 
0 - Insert - Report any intersection errors... (abort insert if Errors)  
1 - Delete any intersection errors records
2 - Check... No Changes
3 - Insert/Update only non-Conflicting
*/
DECLARE @Reason1 Int,@Reason2 Int,@Reason3 Int,@Reason4 Int
DECLARE @NTDataId Int
DECLARE @NPTId Int
DECLARE @TreeId INT
DECLARE @Start Int,@End Int
DECLARE @Start1 Int,@TempStart1 Int,@End1 Int
DECLARE @PUId Int
DECLARE @CurrentDate DateTime
DECLARE @MyStartDate DateTime,@MyEndDate DateTime
DECLARE @GroupingDesc nVarChar(100)
DECLARE @MaxGroupId Int
DECLARE @OldStart DateTime,@OldEnd DateTime
DECLARE @CurrentGroupId Int
DECLARE @SkipAddUpdate Int
DECLARE @CmmtId Int
DECLARE @EntryOn DateTime
DECLARE @DupDesc Int
DECLARE @Units Table(id Int Identity(1,1),PUId Int)
DECLARE @InterferingRecords Table(id Int Identity(1,1),PUId Int,NPTId Int,StartTime DateTime,EndTime DateTime,NPTGroupId Int)
DECLARE @UpdateRecords Table(id Int Identity(1,1),PUId Int,NPTId Int,StartTime DateTime,EndTime DateTime,CommentId Int)
SET @CommentText = Ltrim(RTrim(@CommentText))
IF @CommentText = '' SET @CommentText = Null
SET @StartDate = DateAdd(millisecond,-datepart(millisecond,@StartDate),@StartDate)
SET @EndDate = DateAdd(millisecond,-datepart(millisecond,@EndDate),@EndDate)
SELECT @CurrentDate = GetUTCDate()
SELECT @CurrentDate = DateAdd(MINUTE,-10,@CurrentDate)
SELECT @EntryOn = GetUTCDate()
SET @EntryOn = dbo.fnServer_CmnConvertToDbTime(@EntryOn,'UTC')
SET @EntryOn = DateAdd(millisecond,-datepart(millisecond,@EntryOn),@EntryOn)
IF @StartDate < @CurrentDate
BEGIN
 	 SELECT Error = 'Error: Start Time must be greater than current time'
 	 RETURN 	 
END
IF @UserId is Null
BEGIN
 	 SELECT Error = 'Error: User Id is required'
 	 RETURN 	 
END
SET @StartDate = dbo.fnServer_CmnConvertToDbTime(@StartDate,'UTC')
SET @EndDate = dbo.fnServer_CmnConvertToDbTime(@EndDate,'UTC')
IF @TransType  Not In (1,2,3)
BEGIN
 	 SELECT Error = 'Error: Invalid Transaction Type'
 	 RETURN 	 
END
IF @TransType  In (2,3) and @NPTGroupId Is Null
BEGIN
 	 SELECT Error = 'Error: Group Id Required'
 	 RETURN 	 
END
SELECT @TreeId = Tree_Name_Id,@Reason1 = a.Level1_Id ,@Reason2 = a.Level2_Id,@Reason3 = a.Level3_Id,@Reason4 = a.Level4_Id
  FROM Event_Reason_Tree_Data a
  WHERE Event_Reason_Tree_Data_Id   = @EventReasonTreeDataId 
IF  @TransType  In (1,2)
BEGIN
IF @TreeId IS NULL 
 	 BEGIN
 	  	 SELECT Error = 'Error: Event Reason Tree Not Found'
 	  	 RETURN 	  	 
 	 END
 	 IF @PLId Is Null and @UnitList Is Null
 	 BEGIN
 	  	 SELECT Error = 'Error: Unit(s) or Line is Required'
 	  	 RETURN 	  	 
 	 END
END
IF @TransType  = 1
BEGIN
 	 IF @PLId Is Not Null
 	 BEGIN
 	  	 INSERT INTO @Units(PUId)
 	  	  	 SELECT PU_Id
 	  	  	  	 FROM Prod_Units
 	  	  	  	 WHERE PL_Id = @PLId and Non_Productive_Reason_Tree = @TreeId
 	 END
 	 IF @UnitList Is NOT Null
 	 BEGIN
 	  	 INSERT INTO @Units(PUId)
 	  	  	 SELECT Distinct Id 
 	  	  	 FROM fnCMN_IdListToTable( 'Prod_Units',@UnitList,',')
 	  	  	 WHERE Id Not In (SELECT PUId FROM @Units) 
 	  	 DELETE @Units
 	  	 FROM @Units a
 	  	 Join Prod_Units b on b.PU_Id = a.PUId 
 	  	 WHERE b.Non_Productive_Reason_Tree != @TreeId
 	 END
END
ELSE IF @TransType  = 2
BEGIN
 	  	 INSERT INTO @Units(PUId)
 	  	  	 SELECT Distinct PU_Id 
 	  	  	 FROM NonProductive_Detail
 	  	  	 WHERE NPT_Group_Id  = @NPTGroupId
 	  	 DELETE @Units
 	  	 FROM @Units a
 	  	 Join Prod_Units b on b.PU_Id = a.PUId 
 	  	 WHERE b.Non_Productive_Reason_Tree != @TreeId
END
IF @TransType = 3 -- DELETE BY Group ID
BEGIN
 	 IF EXISTS (SELECT 1 FROM @Units)
 	 BEGIN
 	  	 INSERT INTO @InterferingRecords(PUId,NPTId,StartTime,EndTime) -- All Records For Template
 	  	  	 SELECT PU_Id,NPDet_Id,Start_Time,End_Time  
 	  	  	  	 FROM NonProductive_Detail a
 	  	  	  	 JOIN @Units b on b.PUId = a.PU_Id 
 	  	  	  	 WHERE NPT_Group_Id  = @NPTGroupId
 	 END
 	 ELSE
 	 BEGIN
 	  	 INSERT INTO @InterferingRecords(PUId,NPTId,StartTime,EndTime) -- All Records For Template
 	  	  	 SELECT PU_Id,NPDet_Id,Start_Time,End_Time  
 	  	  	  	 FROM NonProductive_Detail 
 	  	  	  	 WHERE NPT_Group_Id  = @NPTGroupId
 	 END
 	 IF @TransNum = 2 
 	 BEGIN
 	  	 IF Exists (Select 1 FROM @InterferingRecords)
 	  	 BEGIN
 	  	  	 Select 'Success'
 	  	  	 RETURN
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 Select Error = 'Error No records found'
 	  	  	 RETURN
 	  	 END
 	 END
 	 SELECT @Start1 = Min(Id) FROM @InterferingRecords
 	 SELECT @End1 = Max(Id) FROM @InterferingRecords
 	 WHILE @Start1 <= @End1
 	 BEGIN
 	  	 SELECT @NPTId = NPTId,@PUId = PUId,@StartDate = StartTime,@EndDate = EndTime 
 	  	  	 FROM @InterferingRecords 
 	  	  	 WHERE Id = @Start1
 	  	 EXECUTE dbo.spServer_DBMgrUpdNonProductiveTime  @NPTId,@PUId,@StartDate,@EndDate,Null,Null,Null,Null,3,0,@userId, null,Null,null,Null 
 	  	 SET @TempStart1 = Null
 	  	 SELECT @TempStart1 = Min(id) FROM @InterferingRecords WHERE Id > @Start1
 	  	 IF @TempStart1 Is Null
 	  	 BEGIN
 	  	  	 SET @Start1 = @End1 + 1
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SET @Start1 = @TempStart1
 	  	 END
 	 END
 	 IF NOT Exists(Select 1 From NonProductive_Detail WHERE NPT_Group_Id  = @NPTGroupId)
 	 BEGIN
 	  	 DELETE FROM NPT_Detail_Grouping WHERE NPT_Group_Id  = @NPTGroupId
 	 END
 	 Select 'Success'
 	 RETURN
END
IF Not Exists(SELECT 1 FROM @Units)
BEGIN
 	 SELECT Error = 'Error: No units found to update'
 	 RETURN 	  	 
END
/* Fill Table With problem records   */
SELECT @End1 = Max(Id) FROM @Units
SELECT @Start1 = Min(Id) FROM @Units
WHILE @Start1 <= @End1
BEGIN
 	 SELECT @PUId = PuId FROM @Units WHERE Id = @Start1
 	 IF EXISTS(SELECT 1 FROM NonProductive_Detail WHERE PU_Id = @puId and Start_Time < @EndDate  and End_Time > @StartDate)
 	 BEGIN
 	  	 INSERT INTO @InterferingRecords(PUId,NPTId,StartTime,EndTime,NPTGroupId) -- All Problems
 	  	  	 SELECT @puId,NPDet_Id,Start_Time,End_Time,NPT_Group_Id
 	  	  	  	 FROM NonProductive_Detail 
 	  	  	  	 WHERE PU_Id = @puId and Start_Time < @EndDate and End_Time > @StartDate
 	 END
 	 SET @TempStart1 = Null
 	 SELECT @TempStart1 = Min(id) FROM @Units WHERE Id > @Start1
 	 IF @TempStart1 Is Null
 	 BEGIN
 	  	 SET @Start1 = @End1 + 1
 	 END
 	 ELSE
 	 BEGIN
 	  	 SET @Start1 = @TempStart1
 	 END
END
IF @TransType = 1 -- ADD
BEGIN
 	 IF  	 @TransNum = 2 or (Exists(Select 1 FROM @InterferingRecords) AND @TransNum = 0)
 	 BEGIN
 	  	 SELECT Error = 'Error: Existing record(s). [' + CONVERT(nvarchar(10), b.NPDet_Id) + '][ ' + PU_Desc + '][ ' + CONVERT(nvarchar(25), b.Start_Time) + ']'
 	  	  	 FROM @InterferingRecords a
 	  	  	 JOIN NonProductive_Detail b on a.NPTId = b.NPDet_Id 
 	  	  	 JOIN Prod_Units c on b.PU_Id = c.PU_Id
 	  	 RETURN
 	 END
 	 GOTO DeleteConflictingRecords
ReturnToAdd:
 	 -- DO Add(s)
 	 SET @NPTGroupId = Null
 	 SELECT @MaxGroupId = IDENT_CURRENT('NPT_Detail_Grouping')
 	 SET @MaxGroupId = Coalesce(@MaxGroupId,0) + 1
 	 SELECT @GroupingDesc =  '<' + Convert(nvarchar(10),@MaxGroupId) + '> NPTGroup'
 	 SET @DupDesc = 1
 	 WHILE EXISTS(SELECT 1 FROM NPT_Detail_Grouping WHERE NPT_Group_Desc = @GroupingDesc)
 	 BEGIN
 	  	 SELECT @GroupingDesc =  '<' + Convert(nvarchar(10),@MaxGroupId) + '> NPTGroup ('+ Convert(nvarchar(10),@DupDesc) +')'
 	  	 SET @DupDesc = @DupDesc + 1
 	  	 IF @DupDesc > 10
 	  	 BEGIN
 	  	  	 SELECT Error = 'Error: Unable to Create Grouping'
 	  	  	 RETURN 	  	  	 
 	  	 END
 	 END 	  	 
 	 INSERT INTO NPT_Detail_Grouping(NPT_Group_Desc) VALUES (@GroupingDesc)
 	 SELECT @NPTGroupId = NPT_Group_Id FROM NPT_Detail_Grouping WHERE NPT_Group_Desc = @GroupingDesc
 	 IF @NPTGroupId Is Null
 	 BEGIN
 	  	 SELECT Error = 'Error: Unable to Create Grouping'
 	  	 RETURN 	  	  	 
 	 END 	  	 
 	 SELECT @End1 = Max(Id) FROM @Units
 	 SELECT @Start1 = Min(Id) FROM @Units
 	 WHILE @Start1 <= @End1
 	 BEGIN
 	  	 SET @SkipAddUpdate = 0
 	  	 SELECT @PUId = PuId FROM @Units WHERE Id = @Start1
 	  	 IF @TransNum = 3 
 	  	 BEGIN
 	  	  	 IF EXISTS(SELECT 1   
 	  	  	 FROM NonProductive_Detail 
 	  	  	  	 WHERE PU_Id = @puId and Start_Time < @EndDate and End_Time > @StartDate)
 	  	  	 BEGIN
 	  	  	  	 SET @SkipAddUpdate = 1
 	  	  	 END
 	  	 END
 	  	 IF @SkipAddUpdate = 0
 	  	 BEGIN
 	  	  	 SET @CmmtId = Null
 	  	  	 IF @CommentText IS NOT NULL
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO Comments(Comment_Text,Comment,CS_Id,Entry_On,Modified_On,User_Id)
 	  	  	  	  	 SELECT @CommentText,@CommentText,1,@EntryOn,@EntryOn,@UserId
 	  	  	  	 SET @CmmtId = scope_Identity()
 	  	  	 END
 	  	  	 EXECUTE dbo.spServer_DBMgrUpdNonProductiveTime  null,@puId,@StartDate,@EndDate,@Reason1,@Reason2,@Reason3,@Reason4,1,0,@userId, @CmmtId,@EventReasonTreeDataId , null,@NPTGroupId
 	  	 END
 	  	 SET @TempStart1 = Null
 	  	 SELECT @TempStart1 = Min(id) FROM @Units WHERE Id > @Start1
 	  	 IF @TempStart1 Is Null
 	  	 BEGIN
 	  	  	 SET @Start1 = @End1 + 1
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SET @Start1 = @TempStart1
 	  	 END
 	 END
END
IF @TransType = 2 -- UPDATE
BEGIN
 	 IF NOT EXISTS(SELECT 1 FROM NPT_Detail_Grouping WHERE NPT_Group_Id = @NPTGroupId)
 	 BEGIN
 	  	 SELECT Error = 'Error: Unable to Find Grouping'
 	  	 RETURN
 	 END
 	 INSERT INTO @UpdateRecords(PUId,NPTId,StartTime,EndTime,CommentId) -- All Records
 	  	  	 SELECT PU_Id,NPDet_Id,Start_Time,End_Time,Comment_Id 
 	  	  	  	 FROM NonProductive_Detail 
 	  	  	  	 WHERE NPT_Group_Id = @NPTGroupId
 	 IF NOT EXISTS(SELECT 1 FROM @UpdateRecords)
 	 BEGIN
 	  	 SELECT Error = 'Error: Unable to Find Records to Update'
 	  	 RETURN
 	 END
 	 SELECT @OldStart = StartTime,@OldEnd = EndTime
 	  	 FROM @UpdateRecords a 
 	  	 WHERE Id = 1
 	 IF @OldStart != @StartDate Or @OldEnd != @EndDate -- If Dates Changed need to re-validate 
 	 BEGIN
 	  	 DELETE FROM @InterferingRecords WHERE NPTGroupId = @NPTGroupId 
 	  	 IF  	 @TransNum = 2  or (Exists(Select 1 FROM @InterferingRecords) AND @TransNum = 0)
 	  	 BEGIN
 	  	 SELECT Error = 'Error: Existing record prevent update(s). [' + CONVERT(nvarchar(10), b.NPDet_Id) + '][ ' + PU_Desc + '][ ' + CONVERT(nvarchar(25), b.Start_Time) + ']'
 	  	  	 FROM @InterferingRecords a
 	  	  	 JOIN NonProductive_Detail b on a.NPTId = b.NPDet_Id 
 	  	  	 JOIN Prod_Units c on b.PU_Id = c.PU_Id
 	  	  	 RETURN
 	  	 END
 	  	 GOTO DeleteConflictingRecords
 	  	 ReturnToUpdate:
 	 END
 	 SELECT @End1 = Max(Id) FROM @UpdateRecords
 	 SELECT @Start1 = Min(Id) FROM @UpdateRecords
 	 WHILE @Start1 <= @End1
 	 BEGIN
 	  	 SET @SkipAddUpdate = 0
 	  	 SET @CmmtId = Null
 	  	 SELECT @PUId = PuId,@NPTId = NPTId,@CmmtId=CommentId FROM @UpdateRecords WHERE Id = @Start1
 	  	 IF @TransNum = 3 
 	  	 BEGIN
 	  	  	 IF EXISTS(SELECT 1   
 	  	  	  	 FROM NonProductive_Detail 
 	  	  	  	 WHERE PU_Id = @puId and Start_Time < @EndDate and End_Time > @StartDate and NPT_Group_Id != @NPTGroupId)
 	  	  	 BEGIN
 	  	  	  	 SET @SkipAddUpdate = 1
 	  	  	 END
 	  	 END
 	  	 IF @SkipAddUpdate = 0
 	  	 BEGIN
 	  	  	 IF @CommentText IS NOT NULL
 	  	  	 BEGIN
 	  	  	  	 IF @CmmtId Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT INTO Comments(Comment_Text,Comment,CS_Id,Entry_On,Modified_On,User_Id)
 	  	  	  	  	  	 SELECT @CommentText,@CommentText,1,@EntryOn,@EntryOn,@UserId
 	  	  	  	  	 SET @CmmtId = scope_Identity()
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 IF (SELECT substring(Comment_Text,1,7000) FROM Comments WHERE Comment_Id = @CmmtId)  <> @CommentText
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 UPDATE Comments SET Comment_Text = @CommentText,Comment=@CommentText,Modified_On = @EntryOn,User_Id = @userId 
 	  	  	  	  	  	  WHERE Comment_Id = @CmmtId
 	  	  	  	  	 END
 	  	  	  	 END
 	  	  	 END
 	  	  	 EXECUTE dbo.spServer_DBMgrUpdNonProductiveTime  @NPTId,@puId,@StartDate,@EndDate,@Reason1,@Reason2,@Reason3,@Reason4,2,0,@userId, @CmmtId,@EventReasonTreeDataId ,null,@NPTGroupId
 	  	 END
 	  	 SET @TempStart1 = Null
 	  	 SELECT @TempStart1 = Min(id) FROM @UpdateRecords WHERE Id > @Start1
 	  	 IF @TempStart1 Is Null
 	  	 BEGIN
 	  	  	 SET @Start1 = @End1 + 1
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SET @Start1 = @TempStart1
 	  	 END
 	 END
END
Select 'Success'
RETURN
DeleteConflictingRecords:
 	 IF Exists(Select 1 FROM @InterferingRecords) AND @TransNum = 1 --- Delete any Records in the way
 	 BEGIN
 	  	 SELECT @Start1 = Min(Id) FROM @InterferingRecords
 	  	 SELECT @End1 = Max(Id) FROM @InterferingRecords
 	  	 WHILE @Start1 <= @End1
 	  	 BEGIN
 	  	  	 SELECT @NPTId = Null,@PUId = Null,@MyStartDate  = Null,@MyEndDate  = Null,@CurrentGroupId = Null
 	  	  	 SELECT @NPTId = NPTId,@PUId = PUId,@MyStartDate  = StartTime,@MyEndDate  = EndTime,@CurrentGroupId = a.NPTGroupId 
 	  	  	    FROM @InterferingRecords a
 	  	  	    WHERE Id = @Start1
 	  	  	 EXECUTE dbo.spServer_DBMgrUpdNonProductiveTime  @NPTId,@PUId,@MyStartDate,@MyEndDate,Null,Null,Null,Null,3,0,@userId, null,Null,null,Null 
 	  	  	 SET @TempStart1 = Null
 	  	  	 SELECT @TempStart1 = Min(Id) FROM @InterferingRecords WHERE Id > @Start1
 	  	  	 IF @TempStart1 Is Null
 	  	  	 BEGIN
 	  	  	  	 SET @Start1 = @End1 + 1
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 SET @Start1 = @TempStart1
 	  	  	 END
 	  	  	 IF @CurrentGroupId Is Not Null 	  /* Check for empty groups*/
 	  	  	 BEGIN
 	  	  	  	 IF NOT Exists(Select 1 From NonProductive_Detail WHERE NPT_Group_Id  = @CurrentGroupId)
 	  	  	  	 BEGIN
 	  	  	  	  	 DELETE FROM NPT_Detail_Grouping WHERE NPT_Group_Id  = @CurrentGroupId
 	  	  	  	 END
 	  	  	 END
 	  	 END
 	 END
IF @TransType = 1
 	 GOTO ReturnToAdd
ELSE
 	 GOTO ReturnToUpdate
