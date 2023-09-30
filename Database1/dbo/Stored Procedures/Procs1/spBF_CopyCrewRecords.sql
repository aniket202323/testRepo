-- =============================================
-- Author: 	  	 <502406286, Alfredo Scotto>
-- Create date: <Create Date,,>
-- Description: 	 <Description,,>
-- =============================================
CREATE PROCEDURE dbo.spBF_CopyCrewRecords
        @from_Time 	 datetime,
        @To_Time 	 datetime,
 	  	 @UnitList 	 nvarchar(max) = Null,
 	  	 @PLId 	  	 Int = Null,
 	  	 @UserId 	  	 Int = null,
 	  	 @CopyType   Int = 1 -- 1 week 2 Day
AS
IF @UserId Is Null
  	  SET @UserId = 1
declare @Comment_Id int 
declare @Crew_Desc nvarchar(10)
declare @End_Time datetime
declare @Shift_Desc nvarchar(10)
declare @Start_Time datetime
declare @NewCSId int
declare @oldId int
DECLARE @DSTOffset Int
DECLARE @StartOfWeek Int
DECLARE @DayOfWeek Int
DECLARE @Hour Int
DECLARE @Minute Int
DECLARE @EndFrom DateTime
DECLARE @DayDiff Int
DECLARE @Start INt
DECLARE @End Int
DECLARE @UnitId Int
DECLARE @DepartmentTimeZone nvarchar(255)
DECLARE @RecordsToCopy Table(Id Int Identity(1,1),StartTime Datetime,EndTime DateTime,CrewDesc nvarchar(50),ShiftDesc nvarchar(50),CommentId Int,CSId Int,PUId Int)
DECLARE @Units Table(id Int Identity(1,1),PUId Int)
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
  	  SELECT Error = 'Error: Copy to and from must be different weeks.'
  	  RETURN  	  
END
IF @UserId is Null
BEGIN
  	  SELECT Error = 'Error: User Id is required'
  	  RETURN  	  
END
INSERT INTO @RecordsToCopy (StartTime ,EndTime ,CrewDesc ,ShiftDesc ,CommentId ,CSId,PUId)
  	  SELECT Start_Time,End_Time,Crew_Desc,Shift_Desc,Comment_Id,CS_Id ,a.PU_Id
  	  FROM Crew_Schedule a
  	  JOIN @Units b on b.PUId = a.PU_Id 
  	  WHERE Start_Time < @EndFrom AND End_Time > @from_Time 
  	  Order by PU_Id,Start_Time 
SET @End = @@ROWCOUNT 
SET @Start = 1
WHILE @Start <= @End
BEGIN
  	  SELECT @Comment_Id = a.CommentId,
 	  	  	  @Crew_Desc= a.CrewDesc,
  	    	    	  @End_Time= DateAdd(Hour,@DSTOffset,DateAdd(day,@DayDiff,a.EndTime)),
 	  	  	  @oldId = a.CSId,
  	    	    	  @Shift_Desc = a.ShiftDesc ,
 	  	  	  @Start_Time =  DateAdd(Hour,@DSTOffset,DateAdd(day,@DayDiff,a.StartTime)),
  	    	    	  @UnitId = PUId
  	    	  FROM @RecordsToCopy a
  	    	  WHERE a.Id = @Start
 	 IF NOT Exists(SELECT 1 FROM Crew_Schedule WHERE Start_Time < @End_Time and End_Time > @Start_Time and PU_Id = @UnitId)
  	  	  BEGIN
  	    	  	  if @Comment_Id is not NULL
  	    	  	  BEGIN
  	    	    	  	  insert into Comments(comment,comment_Text,Modified_On,ShouldDelete,User_Id) 
  	    	    	    	  	  select c.comment,comment_Text,dbo.fnserver_cmnConverttodbtime(getutcdate(),'UTC')  ,c.ShouldDelete,c.User_Id 
  	    	    	    	  	  from Comments c  
  	    	    	    	  	  where c.Comment_Id = @Comment_Id
  	    	    	  	  set @Comment_Id = SCOPE_IDENTITY() 
  	    	  	  END
  	    	  	  insert into Crew_Schedule (Comment_Id,Crew_Desc,End_Time,PU_Id,Shift_Desc,Start_Time,User_Id ) 
  	    	    	  	  values ( @Comment_Id,@Crew_Desc,@End_Time,@UnitId,@Shift_Desc,@Start_Time,@UserId) 
  	    	  	  set @NewCSId = SCOPE_IDENTITY() 
  	    	  	  IF  EXISTS (select 1 from Shifts_Crew_schedule_mapping where Crew_Schedule_Id = @oldId )
  	    	  	  BEGIN
  	    	    	  	  insert into Shifts_Crew_schedule_mapping (Crew_Schedule_Id, Shift_Id ) 
  	    	    	    	  	  select @NewCSId,Shift_Id from Shifts_Crew_schedule_mapping 
  	    	    	    	    	  	  where Crew_Schedule_Id = @oldId 
  	    	  	  END
  	    	  	  IF EXISTS ( select 1 from CrewSchedule_Crew_Mapping where Crew_Schedule_Id = @oldId ) 
  	    	  	  BEGIN
  	    	    	  	  insert into CrewSchedule_Crew_Mapping (Crew_Schedule_Id, Crew_Id ) 
  	    	    	    	  	  select @NewCSId,Crew_Id from CrewSchedule_Crew_Mapping 
  	    	    	    	    	  	  where Crew_Schedule_Id = @oldId 
  	    	  	  END
  	  	  END
  	  SET @Start = @Start + 1
END
SELECT @End
