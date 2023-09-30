CREATE PROCEDURE dbo.spBF_CopyNPTRecords
        @from_Time datetime,
        @to_Time datetime,
        @treeId integer,
 	  	 @UnitList 	 nvarchar(max) = Null,
 	  	 @PLId 	  	 Int = Null,
 	  	 @UserId 	  	 Int = null,
 	  	 @CopyType 	 Int = 1  --1 Week, 2 Day
AS
IF @UserId Is Null
  	  SET @UserId = 1
--Cursor variables
DECLARE @Comment_Id Int,@Start_Time datetime,@End_Time datetime,@PUId Int,@NewGroupId Int
DECLARE @reason1Id Int,@reason2Id Int,@reason3Id Int,@reason4Id Int
DECLARE @treeDataId Int,@oldId Int,@OldGroupId Int
DECLARE @newId Int
DECLARE @counter Int = 0
DECLARE @fromMonday datetime, @toMonday datetime
DECLARE @fromWeek Int
DECLARE @now datetime
DECLARE @ret Int
DECLARE @Hour  	  Int
DECLARE @Minute Int
DECLARE @StartOfWeek Int
DECLARE @DayOfWeek  Int
DECLARE @DayDiff Int
DECLARE @EndFrom DateTime
DECLARE @Start  	  Int
DECLARE @End  	  Int
DECLARE @DSTOffset Int
DECLARE @MaxGroupId Int
DECLARE @GroupingDesc nVarChar(100)
DECLARE @DupDesc Int
DECLARE @RecordsToCopy Table(Id Int Identity(1,1),StartTime Datetime,EndTime DateTime,ERTDId Int,Level1 Int,
  	    	    	    	    	    	    	  Level2 Int,Level3 Int,Level4 Int,CommentId Int,NPDetId Int,
  	    	    	    	    	    	    	  PUId Int,OldGroupId Int,NewGroupId Int)
DECLARE @Units Table(id Int Identity(1,1),PUId Int)
DECLARE @DepartmentTimeZone nvarchar(255)
SET NOCOUNT ON
INSERT INTO @Units(PUId) 
  	  SELECT PUId FROM dbo.fnBF_CreateUnitList(@PLId,@UnitList)
IF Not Exists(SELECT 1 FROM @Units)
BEGIN
  	  SELECT Error = 'Error: No units found to update'
  	  RETURN  	    	  
END
SELECT @DepartmentTimeZone = Min(Time_Zone)
  	  FROM Departments a
  	  Join Prod_Lines b on b.Dept_Id = a.Dept_Id 
  	  JOIN Prod_Units c on c.PL_Id = b.PL_Id
  	  JOIN @Units d on d.PUId = c.PU_Id
IF  @DepartmentTimeZone Is Null
BEGIN
  	  SELECT @DepartmentTimeZone = Min(Time_Zone)
  	  From Departments a
END
SELECT  @DepartmentTimeZone = isnull(@DepartmentTimeZone,'UTC')
/* Hard Code to Monday for now   do not use site parameter for now */
SET DATEFIRST 1 -- 1 = Monday
IF @CopyType = 1
BEGIN
  	  SELECT @from_Time = dbo.fnBF_ConvertToSartOfWeek(@from_Time,1,@DepartmentTimeZone)
  	  SELECT @To_Time = dbo.fnBF_ConvertToSartOfWeek(@To_Time,1,@DepartmentTimeZone)
  	  SET @EndFrom = DATEADD(Day,7,@from_Time)
END
ELSE
BEGIN
  	  SELECT @from_Time = dbo.fnBF_ConvertToSartOfWeek(@from_Time,0,@DepartmentTimeZone)
  	  SELECT @To_Time = dbo.fnBF_ConvertToSartOfWeek(@To_Time,0,@DepartmentTimeZone)
  	  SET @EndFrom = DATEADD(Day,1,@from_Time)
END
SET @DayDiff = DATEDIFF(Day,@from_Time,@To_Time)
SET @DSTOffset = DATEPart(hour,@To_Time) - DATEPart(hour,@from_Time) 
IF @from_Time = @To_Time
BEGIN
  	  SELECT Error = 'Error: Copy to and From must be different.'
  	  RETURN  	  
END
IF @UserId is Null
BEGIN
  	  SELECT Error = 'Error: User Id is required'
  	  RETURN  	  
END
IF @treeId > 0
BEGIN
  	  INSERT INTO @RecordsToCopy(StartTime,EndTime,ERTDId,Level1,Level2,
  	    	    	    	    	    	    	    	  Level3,Level4,CommentId,NPDetId,PUId,OldGroupId)
  	    	  SELECT  te.Start_Time,te.End_Time,te.Event_Reason_Tree_Data_Id,te.Reason_Level1,
  	    	    	    	  te.Reason_Level2,te.Reason_Level3,te.Reason_Level4,te.Comment_Id,te.NPDet_Id,te.PU_Id,te.NPT_Group_Id 
  	    	  FROM NonProductive_Detail te
  	    	  JOIN @Units b on b.PUId = te.PU_Id 
  	    	  WHERE te.Event_Reason_Tree_Data_Id = @treeId 
  	    	    	  and Start_Time Between @from_Time and @EndFrom 
  	    	  ORDER BY pu_id,te.Start_Time
  	  SET @End = @@ROWCOUNT 
END
ELSE
BEGIN
  	  INSERT INTO @RecordsToCopy(StartTime,EndTime,ERTDId,Level1,Level2,
  	    	    	    	    	    	    	    	  Level3,Level4,CommentId,NPDetId,PUId,OldGroupId )
  	    	  SELECT  te.Start_Time,te.End_Time,te.Event_Reason_Tree_Data_Id,te.Reason_Level1,
  	    	    	    	  te.Reason_Level2,te.Reason_Level3,te.Reason_Level4,te.Comment_Id,te.NPDet_Id,te.PU_Id,te.NPT_Group_Id 
  	    	  FROM NonProductive_Detail te
  	    	  JOIN @Units b on b.PUId = te.PU_Id 
  	    	  WHERE Start_Time >=  @from_Time and Start_Time < @EndFrom 
  	    	  ORDER BY pu_id,te.Start_Time
  	  SET @End = @@ROWCOUNT 
END
SET @Start = 1
WHILE @Start <= @End
BEGIN
  	  SELECT @Comment_Id = a.CommentId,@reason1Id= a.Level1,@reason2Id= a.Level2,@reason3Id= a.Level3,@reason4Id= a.Level4,
  	    	    	  @End_Time= DateAdd(Hour,@DSTOffset,DateAdd(day,@DayDiff,a.EndTime)),
 	  	  	  @oldId = a.NPDetId ,
  	    	    	  @treeDataId = a.ERTDId ,
 	  	  	  @Start_Time = DateAdd(Hour,@DSTOffset,DateAdd(day,@DayDiff,a.StartTime)),
  	    	    	  @PUId = PUId,@OldGroupId = a.OldGroupId,@NewGroupId = a.NewGroupId  
  	    	  FROM @RecordsToCopy a
  	    	  WHERE a.Id = @Start 
  	  IF NOT Exists(SELECT 1 FROM NonProductive_Detail WHERE Start_Time < @End_Time and End_Time > @Start_Time and PU_Id = @PUId)
  	  BEGIN
  	    	  if @Comment_Id is not NULL
  	    	  BEGIN
  	    	    	  insert into Comments(comment,comment_Text,Modified_On,ShouldDelete,User_Id) 
  	    	    	    	  select c.comment,comment_Text,dbo.fnserver_cmnConverttodbtime(getutcdate(),'UTC')  ,c.ShouldDelete,c.User_Id 
  	    	    	    	  from Comments c  
  	    	    	    	  where c.Comment_Id = @Comment_Id
  	    	    	  set @Comment_Id = SCOPE_IDENTITY() 
  	    	  END
  	    	  IF @OldGroupId IS NOT NULL and @NewGroupId Is Null
  	    	  BEGIN
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
  	    	    	  SELECT @NewGroupId = NPT_Group_Id FROM NPT_Detail_Grouping WHERE NPT_Group_Desc = @GroupingDesc
  	    	    	  UPDATE @RecordsToCopy SET NewGroupId = @NewGroupId WHERE OldGroupId = @OldGroupId 
  	    	  END
  	    	  EXECUTE  dbo.spServer_DBMgrUpdNonProductiveTime Null,@PUId,@Start_Time,@End_Time,@reason1Id,
  	    	    	    	    	  @reason2Id, @reason3Id,@reason4Id,1,0, 
  	    	    	    	    	  @UserId,@Comment_Id,@treeDataId,Null,@NewGroupId
  	  END
  	  SET @Start = @Start + 1
END
SELECT @End
