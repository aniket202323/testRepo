﻿
CREATE PROCEDURE dbo.spMES_GetDowntime
		 @TimeSelection Int 
		,@StartTime DateTime = Null
		,@EndTime	DateTime = Null
		,@PUIds	nvarchar(max) = null
		,@LineIds	nvarchar(max) = Null
		,@UserId	Int
		,@DowntimeEventId	Int = Null
		,@CategoryIds		nvarchar(max) = ''
		,@LocationIds		nvarchar(max) = ''
		,@StatusIds			nvarchar(max) = '' /* 1= Open, 2= Closed and Active , 3 Closed and Complete*/
		,@NPTOnly			Int = 0
		,@MinDuration		Decimal(10,3) = 0
		,@MaxDuration		Decimal(10,3) = 0
		,@RuleToCheck       Int = 0

AS

IF @PUIds Is Null and @DowntimeEventId is Not Null
BEGIN
	SELECT @PUIds = Convert(nvarchar(10),pu_Id) FROM Timed_Event_Details   WHERE TEDet_Id = @DowntimeEventId
END

SELECT @CategoryIds = ltrim(rtrim(@CategoryIds))
SELECT @LocationIds = ltrim(rtrim(@LocationIds))
SELECT @StatusIds = ltrim(rtrim(@StatusIds))

IF @CategoryIds = '' SET @CategoryIds = Null
IF @LocationIds = '' SET @LocationIds = Null
IF @StatusIds = '' SET @StatusIds = Null

/*

 EXECUTE dbo.spMES_GetDowntime 7,'07/01/2016','07/03/2016',Null,Null,1

 EXECUTE dbo.spMES_GetDowntime 7,'2017-02-22','2017-02-23',Null,Null,1,Null,Null,null,Null
 
 */
IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	--SELECT  Error = 'ERROR: Valid User Required'
SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

DECLARE @AllUnits Table (PU_Id Int,HasTree Int,LineId Int,DeptTZ nVarChar(500))
DECLARE @OneLineId Int
DECLARE @DisplayOptions Table (PU_Id Int,AddSecurity Int,DeleteSecurity Int,
								CloseSecurity Int,OpenSecurity Int,EditStartTimeSecurity Int,
								AddComments Int,AssignReasons Int,ChangeComments Int,
								ChangeFault Int,ChangeLocation int,OverlapRecords Int,
								SplitRecords Int,[CopyPasteReasons&Fault] Int)

DECLARE @Locations Table (LocationId Int,Location nvarchar(100))
DECLARE @Categories Table (CategoryId Int,Category nvarchar(100),Number Int)
DECLARE @Statuses Table (StatusId Int,Status nvarchar(100))
DECLARE @MinDurationOut Decimal(10,1),@MaxDurationOut Decimal(10,1)
DECLARE @Ids Table (Id Int)
DECLARE @localpuid int
IF @RuleToCheck = 1
BEGIN
INSERT INTO @Ids (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@PUIds,',')
IF (Select count(*) from @Ids) > 1
	BEGIN
		SELECT Error = 'ERROR: Multiple Slave units Found', Code = 'InvalidData', ErrorType = 'ValidUnitsNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
	SELECT @localpuid = master_unit from dbo.Prod_Units_Base where pu_id = (Select Id from @Ids) and Master_Unit is not null
	IF @localpuid is not null
		BEGIN
			SET @PUIds =  CONVERT(nVarChar(10),@localpuid)
		END	
	DELETE FROM @Ids 
END

INSERT INTO @DisplayOptions (PU_Id,AddSecurity,DeleteSecurity,CloseSecurity,OpenSecurity,
							EditStartTimeSecurity,AddComments,AssignReasons,ChangeComments,ChangeFault,
							ChangeLocation,OverlapRecords,SplitRecords,[CopyPasteReasons&Fault]) 
	SELECT PU_Id,AddSecurity,DeleteSecurity,CloseSecurity,OpenSecurity,
								EditStartTimeSecurity,AddComments,AssignReasons,ChangeComments,ChangeFault,
								ChangeLocation,OverlapRecords,SplitRecords,[CopyPasteReasons&Fault]
	FROM dbo.fnMES_GetDowntimeSecurity( @PUIds,@LineIds,@UserId)


IF NOT EXISTS(SELECT 1 FROM @DisplayOptions)
BEGIN
	--SELECT  Error = 'ERROR: No Valid Units Found'
	SELECT Error = 'ERROR: User Does not have access to this unit.', Code = 'InsufficientPermission', ErrorType = 'ValidUnitsNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

INSERT INTO @AllUnits(PU_Id) 
	SELECT DISTINCT PU_Id FROM @DisplayOptions
UPDATE @AllUnits SET DeptTZ = d.Time_Zone,LineId = b.PL_Id 
		FROM @AllUnits a
		JOIN Prod_Units_Base b on b.PU_Id = a.PU_Id 
		JOIN Prod_Lines_Base c on c.PL_Id = b.PL_Id 
		JOIN Departments_Base d on d.Dept_Id = c.Dept_Id 
IF (SELECT COUNT(Distinct DeptTZ) FROM @AllUnits) <= 1
BEGIN
	SELECT @OneLineId  = MIN(LineId) FROM @AllUnits
END

IF @DowntimeEventId is Null
BEGIN
	IF @StartTime Is Null or @EndTime Is Null
	BEGIN
		EXECUTE dbo.spBF_CalculateOEEReportTime @OneLineId,@TimeSelection ,@StartTime  Output,@EndTime  Output, 1
	END
	IF @StartTime Is Null OR @EndTime Is Null
	BEGIN 
		--SELECT Error ='ERROR: Could not Calculate Date'
SELECT Error = 'ERROR: Could not Calculate Date', Code = 'InvalidData', ErrorType = 'ValidDatesNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

SELECT @PUIds = ''
	SELECT @PUIds =  @PUIds + CONVERT(nVarChar(10),PU_Id) + ',' 
			FROM @AllUnits


Insert Into @AllUnits (PU_Id)
	SELECT a.PU_Id 
		FROM Prod_Units_Base a 
		Join @AllUnits b on b.PU_Id = a.Master_Unit 
		WHERE a.PU_Id <> a.Master_Unit
UPDATE @AllUnits SET HasTree = 0
UPDATE @AllUnits SET HasTree = 1
	FROM @AllUnits a
	Join Prod_Events b on b.PU_Id = a.PU_Id and b.Event_Type = 2
	
Declare @DowntimeData table (
	EventId int,UnitEquipmentId uniqueidentifier,UnitId int,Unit nvarchar(100),StartTime datetime null,
	EndTime datetime null,Duration decimal(10,2) null,Uptime float null,LocationEquipmentId uniqueidentifier null,
	LocationId int null,Location nvarchar(100) null,FaultId int null,Fault nvarchar(100) null,
	StatusId int null,Status nvarchar(100) null,
	Reason1Id int null, Reason1 nvarchar(100) null,
	Reason2Id int null, Reason2 nvarchar(100) null,
	Reason3Id int null, Reason3 nvarchar(100) null,
	Reason4Id int null, Reason4 nvarchar(100) null,
	Action1Id int null, Action1 nvarchar(100) null,
	Action2Id int null, Action2 nvarchar(100) null,
	Action3Id int null, Action3 nvarchar(100) null,
	Action4Id int null, Action4 nvarchar(100) null,
	ReasonComment text null,
	ActionComment text null,
	ReasonsCompleted tinyint null,
	Operator nvarchar(255) null,
	IsOpen Int,
	NPTId Int,
	CategoryId Int,
	Category nvarchar(100) null,
	KeepRecord	Int, 
	EventStatusId int null, EventStatus nvarchar(100) null,
	SourceProductionUnitId int null,
	Action_Comment_Id INT,
	Cause_Comment_Id INT,
	Research_Comment_Id Int,Event_Reason_Tree_Data_Id int,
	Research_User_Id int,
	Research_Status_Id Int,
	Research_Open_Date Datetime,
	Research_Close_Date Datetime,
	signature_Id Int,User_Id Int
)
Declare @vStartTime datetime, @vEndtime Datetime
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,'UTC')
SELECT @Endtime = dbo.fnServer_CmnConvertToDBTime(@Endtime,'UTC')
 
IF @DowntimeEventId IS NULL
Begin
	INSERT INTO @DowntimeData(	
	EventId,UnitEquipmentId,UnitId,Unit,StartTime,EndTime,Duration,Uptime,LocationEquipmentId,LocationId,Location,FaultId,Fault,StatusId,Status,Reason1Id,Reason1,
	Reason2Id,Reason2,Reason3Id,Reason3,Reason4Id,Reason4,Action1Id,Action1,Action2Id,Action2,Action3Id,Action3,Action4Id,Action4,ReasonComment,
	ActionComment,ReasonsCompleted,Operator,SourceProductionUnitId,Action_Comment_Id,Cause_Comment_Id,Research_Comment_Id,Event_Reason_Tree_Data_Id,

	Research_User_Id,
	Research_Status_Id,
	Research_Open_Date,
	Research_Close_Date,
	signature_Id,User_Id
	)
	Select 
		d.TEDet_Id,null UnitEquipmentId,d.PU_Id UnitId,null Unit,d.Start_Time StartTime,d.End_Time EndTime,d.Duration Duration,d.Uptime Uptime,null LocationEquipmentId,
		isnull(d.Source_PU_Id,d.PU_Id) LocationId,
		null Location,d.TEFault_Id FaultId,null Fault,
		d.TEStatus_Id StatusId,null Status,d.Reason_Level1 Reason1Id,null Reason1,
	d.Reason_Level2 Reason2Id,null Reason2,d.Reason_Level3 Reason3Id,null Reason3,d.Reason_Level4 Reason4Id,null Reason4,
	d.Action_Level1 Action1Id,null Action1,d.Action_Level2 Action2Id,null Action2,d.Action_Level3 Action3Id,null Action3,
	d.Action_Level4 Action4Id,null Action4,null ReasonComment,
	null ActionComment,null ReasonsCompleted,null Operator,d.Source_PU_Id,d.Action_Comment_Id,d.Cause_Comment_Id,d.Research_Comment_Id,
	d.Event_Reason_Tree_Data_Id,Research_User_Id,
	Research_Status_Id,
	Research_Open_Date,
	Research_Close_Date,
	signature_Id,User_Id
	from
		Timed_Event_Details d  WITH (nolock) 
		Join @AllUnits u on u.PU_Id = d.PU_Id
	Where 
		d.Start_Time < @EndTime AND (d.End_Time > @StartTime OR d.End_Time Is NULL) 
END
ELSE
BEGIN
	INSERT INTO @DowntimeData(	
	EventId,UnitEquipmentId,UnitId,Unit,StartTime,EndTime,Duration,Uptime,LocationEquipmentId,LocationId,Location,FaultId,Fault,StatusId,Status,Reason1Id,Reason1,
	Reason2Id,Reason2,Reason3Id,Reason3,Reason4Id,Reason4,Action1Id,Action1,Action2Id,Action2,Action3Id,Action3,Action4Id,Action4,ReasonComment,
	ActionComment,ReasonsCompleted,Operator,SourceProductionUnitId,Action_Comment_Id,Cause_Comment_Id,Research_Comment_Id,Event_Reason_Tree_Data_Id,

	Research_User_Id,
	Research_Status_Id,
	Research_Open_Date,
	Research_Close_Date,
	signature_Id,User_Id
	)
	Select 
		d.TEDet_Id,null UnitEquipmentId,d.PU_Id UnitId,null Unit,d.Start_Time StartTime,d.End_Time EndTime,d.Duration Duration,d.Uptime Uptime,null LocationEquipmentId,
		isnull(d.Source_PU_Id,d.PU_Id) LocationId,
		null Location,d.TEFault_Id FaultId,null Fault,
		d.TEStatus_Id StatusId,null Status,d.Reason_Level1 Reason1Id,null Reason1,
	d.Reason_Level2 Reason2Id,null Reason2,d.Reason_Level3 Reason3Id,null Reason3,d.Reason_Level4 Reason4Id,null Reason4,
	d.Action_Level1 Action1Id,null Action1,d.Action_Level2 Action2Id,null Action2,d.Action_Level3 Action3Id,null Action3,
	d.Action_Level4 Action4Id,null Action4,null ReasonComment,
	null ActionComment,null ReasonsCompleted,null Operator,d.Source_PU_Id,d.Action_Comment_Id,d.Cause_Comment_Id,d.Research_Comment_Id,
	d.Event_Reason_Tree_Data_Id,Research_User_Id,
	Research_Status_Id,
	Research_Open_Date,
	Research_Close_Date,
	signature_Id,User_Id
	from
		Timed_Event_Details d   WITH (nolock) 
		Join @AllUnits u on u.PU_Id = d.PU_ID
	Where 
		d.TEDet_Id = @DowntimeEventId
END

Update d
set ReasonsCompleted = Coalesce(ertd.Bottom_Of_Tree, 0)
 from @DowntimeData d
 Left outer join Event_Reason_Tree_Data Ertd on ertd.Event_Reason_Tree_Data_Id = d.Event_Reason_Tree_Data_Id

;WITH CTE_REASONS AS (Select Event_Reason_Id,Event_Reason_Name from Event_reasons  WITH (nolock) )
,CTE_Comments As (Select Comment_Text,Comment_Id  From Comments  WITH (nolock) )
update @DowntimeData 
set 
	LocationEquipmentId = (select Origin1EquipmentId from PAEquipment_Aspect_SOAEquipment  WITH (nolock)  Where pu_id = LocationId),
	Unit = (Select pu_desc from Prod_Units_Base  WITH (nolock)  where pu_id = UnitId),
	Location = (Select pu_desc from Prod_Units_Base  WITH (nolock)  where pu_id = LocationId),
	Reason1 = (Select Event_Reason_Name from CTE_REASONS   Where Event_Reason_Id = Reason1Id),
	Reason2 = (Select Event_Reason_Name from CTE_REASONS   Where Event_Reason_Id = Reason2Id),
	Reason3 = (Select Event_Reason_Name from CTE_REASONS Where Event_Reason_Id = Reason3Id),
	Reason4 = (Select Event_Reason_Name from CTE_REASONS  Where Event_Reason_Id = Reason4Id),
	Action1 = (Select Event_Reason_Name from CTE_REASONS  Where Event_Reason_Id = Action1Id),
	Action2 = (Select Event_Reason_Name from CTE_REASONS  Where Event_Reason_Id = Action2Id),
	Action3 = (Select Event_Reason_Name from CTE_REASONS  Where Event_Reason_Id = Action3Id),
	Action4 = (Select Event_Reason_Name from CTE_REASONS  Where Event_Reason_Id = Action4Id),
	ReasonComment = (Select Comment_Text from CTE_Comments  where Comment_Id = Cause_Comment_Id),
	ActionComment = (Select Comment_Text from CTE_Comments  where Comment_Id = Action_Comment_Id),
	Status = (Select TEStatus_Name from Timed_Event_Status  WITH (nolock)  where TEStatus_Id = StatusId),
	Fault= (Select TEFault_Name From Timed_Event_Fault  WITH (nolock)  Where TEFault_Id = FaultId)
	
	;
WITH TZ AS (
SELECT StartTime Start_Time,
                EndTime End_Time,
                UTCbias Bias FROM TimeZoneTranslations WHERE TimeZone = (SELECT TOP 1 Value FROM site_parameters   WITH (nolock)  WHERE parm_id = 192))


	update @DowntimeData 
set StartTime = DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE StartTime >= TZ.Start_Time AND StartTime < TZ.End_Time), StartTime)
,EndTime = DATEADD(MINUTE, (SELECT TOP 1 Bias FROM TZ WHERE EndTime >= TZ.Start_Time AND EndTime < TZ.End_Time), EndTime)
	
update @DowntimeData set EventStatus = Status
 
UPDATE @DowntimeData SET IsOpen = Case when EndTime is null then 1 else 0 end,NPTId = 0 ,LocationId = COALESCE(LocationId,UnitId)

 
UPDATE @DowntimeData SET ReasonsCompleted = 1 
	FROM @DowntimeData a
	JOIN @AllUnits   b on b.PU_Id  =  a.LocationId 
	WHERE b.HasTree = 0


UPDATE @DowntimeData SET Uptime = 0	WHERE Uptime is Null

UPDATE @DowntimeData SET CategoryId = erc.ERC_Id,Category = ec.ERC_Desc 
	FROM @DowntimeData d
	--JOIN Timed_Event_Details ted on ted.TEDet_Id = d.EventId 
	LEFT JOIN Event_Reason_Category_Data erc  WITH (nolock)  on erc.Event_Reason_Tree_Data_Id = d.Event_Reason_Tree_Data_Id 
	LEFT JOIN Event_Reason_Catagories ec  WITH (nolock)  on ec.ERC_Id = erc.ERC_Id


INSERT INTO @Locations (LocationId ,Location)
	SELECT DISTINCT a.PU_Id,b.PU_Desc
	FROM @AllUnits a
	Join Prod_Units_Base b on a.PU_Id = b.PU_Id 

INSERT INTO @Categories  (CategoryId,Category,Number)
	SELECT  CategoryId,Category,count(*)
	FROM @DowntimeData
	WHERE CategoryId Is Not Null
	Group By CategoryId,Category

INSERT INTO @Categories  (CategoryId,Category,Number)
	SELECT  ERC_Id,ERC_Desc,0
	FROM Event_Reason_Catagories   WITH (nolock) 
	WHERE ERC_Id Not In (SELECT CategoryId FROM @Categories) and ERC_Id <> 100
	
INSERT INTO @Statuses  (StatusId ,Status) VALUES (1,'Open')
INSERT INTO @Statuses  (StatusId ,Status) VALUES (2,'Active')
INSERT INTO @Statuses  (StatusId ,Status) VALUES (3,'Complete')

SELECT @MinDurationOut = Min(Duration), @MaxDurationOut = Max(Duration) FROM  @DowntimeData WHERE Duration Is Not Null
if (@MinDurationOut is not null)
begin
	select @MinDurationOut = @MinDurationOut - 0.1
end
if (@MaxDurationOut is not null)
begin
	select @MaxDurationOut = @MaxDurationOut + 0.1
end
SELECT @MinDurationOut = Coalesce(@MinDurationOut,0), @MaxDurationOut = Coalesce(@MaxDurationOut,1000)

IF @LocationIds Is Not Null
BEGIN
	DELETE FROM @Ids 
	INSERT INTO @Ids (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@LocationIds,',')
	DELETE FROM @DowntimeData WHERE LocationId  Not In (SELECT ID FROM @Ids)
END


IF @StatusIds Is Not Null
BEGIN
	UPDATE @DowntimeData SET KeepRecord = 0
	/* 1= Open, 2= Closed and Active, 3 = Closed and Complete  */
	DELETE FROM @Ids 
	INSERT INTO @Ids (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable(Null,@StatusIds,',')
/*(1)*/
	IF EXISTS (SELECT 1 FROM @Ids WHERE Id = 1)
		UPDATE 	@DowntimeData SET KeepRecord = 1  WHERE IsOpen = 1
/*(2)*/	
	IF EXISTS (SELECT 1 FROM @Ids WHERE Id = 2)
		UPDATE 	@DowntimeData SET KeepRecord = 1  WHERE IsOpen = 0 And ReasonsCompleted = 0 
/*(3)*/	
	IF EXISTS (SELECT 1 FROM @Ids WHERE Id = 3)
		UPDATE 	@DowntimeData SET KeepRecord = 1  WHERE IsOpen = 0 And ReasonsCompleted = 1 
	DELETE FROM @DowntimeData WHERE KeepRecord = 0
END
IF @MinDuration != 0
BEGIN
	DELETE FROM @DowntimeData WHERE Duration < @MinDuration
END
IF @MaxDuration != 0
BEGIN
	DELETE FROM @DowntimeData WHERE Duration > @MaxDuration
END
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[User_Equipment_Assignment]') and OBJECTPROPERTY(id, N'IsTable') = 1)
	Begin
		UPDATE d
		SET Operator	= Coalesce(U.Username, 'Unknown')
		FROM @DowntimeData d
		Left Join [dbo].[User_Equipment_Assignment] ea on ea.EquipmentId = d.UnitId
				  and d.EndTime >= ea.StartTime and (d.EndTime < ea.EndTime or ea.EndTime IS NULL)
		Left Join [dbo].[Users] U on U.User_Id = ea.UserId
	End
Else
	Begin
		UPDATE @DowntimeData SET Operator = 'Unknown' Where Operator is null
	End

IF @CategoryIds Is Not Null
BEGIN
	DELETE FROM @Ids 
	INSERT INTO @Ids (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('Event_Reason_Catagories',@CategoryIds,',')
	DELETE FROM @DowntimeData WHERE CategoryId is Null
	DELETE FROM @DowntimeData WHERE CategoryId Not In (SELECT ID FROM @Ids)
END
UPDATE @DowntimeData SET NPTId = (SELECT Min(NPDet_id) FROM NonProductive_Detail np 
	WHERE  np.PU_id = d.UnitId	
	and np.Start_time = dbo.fnServer_CmnConvertToDbTime(d.StartTime,'UTC'))
	FROM @DowntimeData d

IF @NPTOnly != 0
BEGIN
	DELETE FROM @DowntimeData WHERE NPTId is null or NPTId = 0
END

SELECT   DetailId = D.EventId  
		, [StartTime] = D.StartTime 
		, [EndTime] = D.EndTime
		, D.Duration
		, D.Uptime
		, UnitId, Unit
		, LocationId, Location
		,DepartmentId = dpt.Dept_Id , Department = dpt.Dept_Desc
		,LineId = pl.PL_Id , Line = pl.PL_Desc 
		, Reason1Id	, Reason1
		, Reason2Id	, Reason2
		, Reason3Id	, Reason3 
		, Reason4Id , Reason4 
		, Action1Id  , Action1 
		, Action2Id , Action2
		, Action3Id , Action3
		, Action4Id	, Action4 
		, FaultId, FaultName = Fault,FaultValue = (select TEFault_Value from Timed_Event_Fault  WITH (nolock)  where TEFault_Id = D.FaultId)
		, StatusId	, Status
		, ReasonCommentId = Cause_Comment_Id,ReasonComment
		, ActionCommentId = Action_Comment_Id ,ActionComment
		, CategoryId,Category 
		, Operator
		, IsOpen
		, NptId
		, ReasonsCompleted
		, ResearchUserId = Research_User_Id
		, ResearchUser = u.UserName 
		, ResearchStatusId = D.Research_Status_Id
		, ResearchStatus =  rs.Research_Status_Desc 
		, ResearchCommentId = Research_Comment_Id
		, ResearchComment = SUBSTRING(c.Comment,1,255)
		, ResearchOpen = Research_Open_Date 
		, ResearchClose = Research_Close_Date
		, EventReasonTreeDataId = D.Event_Reason_Tree_Data_Id
		, eSignatureId = signature_Id
		, U1.UserName
		, UserId = D.User_Id
		,AddSecurity,DeleteSecurity,CloseSecurity,OpenSecurity,EditStartTimeSecurity
		,AddComments,AssignReasons,ChangeComments,ChangeFault,ChangeLocation
		,OverlapRecords,SplitRecords,[CopyPasteReasons&Fault]
		,EventStatusId,EventStatus

	FROM  @DowntimeData D
	JOIN @DisplayOptions do on do.PU_Id = d.UnitId
	--LEFT JOIN Timed_Event_Details ted on ted.TEDet_Id = d.EventId 
	--LEFT JOIN Timed_Event_Fault tef on tef.TEFault_Id = d.FaultId
	Left Join Users u  WITH (nolock)  on u.User_Id = D.Research_User_Id 
	Left Join Users u1  WITH (nolock)  on u1.User_Id = D.User_Id 
	Left Join Research_Status  rs  WITH (nolock)  on rs.Research_Status_Id  = D.Research_Status_Id
	Left Join Comments c  WITH (nolock)  on c.Comment_Id = D.Research_Comment_Id
	Join Prod_Units_Base pu  WITH (nolock)  on pu.pu_id = D.UnitId 
	Join Prod_Lines_Base pl  WITH (nolock)  on pl.pl_id = pu.pl_id
	Join Departments_Base dpt  WITH (nolock)  on dpt.Dept_Id  = pl.Dept_Id 
	ORDER BY D.StartTime Desc,IsOpen DESC,ReasonsCompleted Asc, D.Unit

SELECT  LocationId, Location
		,DepartmentId = dpt.Dept_Id , Department = dpt.Dept_Desc
		,LineId = pl.PL_Id , Line = pl.PL_Desc
	FROM @Locations loc
	Join Prod_Units_Base pu  WITH (nolock)  on pu.pu_id = loc.LocationId
	Join Prod_Lines_Base pl  WITH (nolock)  on pl.pl_id = pu.pl_id
	Join Departments_Base dpt  WITH (nolock)  on dpt.Dept_Id  = pl.Dept_Id 

SELECT  CategoryId,Category,Number
	FROM @Categories
	
SELECT StatusId ,Status FROM @Statuses

SELECT MinDuration = @MinDurationOut ,MaxDuration =  @MaxDurationOut 

