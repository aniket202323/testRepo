
CREATE PROCEDURE dbo.spMES_GetNonProductiveTime
		 @TimeSelection Int 
		,@StartTime DateTime = Null
		,@EndTime	DateTime = Null
		,@PUIds	nvarchar(max) = null
		,@LineIds	nvarchar(max) = Null
		,@UserId	Int
		,@NptEventId	Int = Null
AS


IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	SELECT Code = 'InvalidData', Error = 'ERROR: Valid User Required', ErrorType = 'InvalidParameterValue', PropertyName1 = 'UserId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @UserId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

DECLARE @DisplayOptions Table (UnitId Int,AddSecurity Int,EditSecurity Int)

DECLARE @Unspecified nvarchar(100)
DECLARE @AllUnits Table (PU_Id Int,HasTree Int,LineId Int)
DECLARE @AllLines Table (PL_Id Int)
DECLARE @OneLineId Int
DECLARE @SecurityUnits Table (PU_Id Int)


INSERT INTO @DisplayOptions (UnitId,AddSecurity,EditSecurity) 
	SELECT PU_Id,AddSecurity,EditSecurity 
	FROM dbo.fnMES_GetNonProductiveTimeSecurity( @PUIds,@LineIds,@UserId)

IF NOT EXISTS(SELECT 1 FROM @DisplayOptions)
BEGIN
	SELECT Code = 'InvalidData', Error = 'ERROR: No Valid Units Found', ErrorType = 'InvalidParameterValue', PropertyName1 = 'PUIds', PropertyName2 = 'LineIds', PropertyName3 = 'UserId', PropertyName4 = '', PropertyValue1 = @PUIds, PropertyValue2 = @LineIds, PropertyValue3 = @UserId, PropertyValue4 = ''
	RETURN
END

INSERT INTO @AllUnits(PU_Id) 
	SELECT DISTINCT UnitId FROM @DisplayOptions


IF @NptEventId  is Null
BEGIN
	IF @StartTime Is Null OR @EndTime Is  Null
	BEGIN
		EXECUTE dbo.spBF_CalculateOEEReportTime @OneLineId,@TimeSelection ,@StartTime  Output,@EndTime  Output, 1
	END
	IF @StartTime Is Null OR @EndTime Is Null
	BEGIN 
		SELECT Code = 'InvalidData', Error = 'ERROR: Could not Calculate Date', ErrorType = 'InvalidParameterValue', PropertyName1 = 'OneLineId', PropertyName2 = 'TimeSelection', PropertyName3 = 'StartTime', PropertyName4 = '', PropertyValue1 = @OneLineId, PropertyValue2 = @TimeSelection, PropertyValue3 = @StartTime, PropertyValue4 = ''
		RETURN
	END
END


SELECT @PUIds = ''
	SELECT @PUIds =  @PUIds + CONVERT(nVarChar(10),PU_Id) + ',' 
			FROM @AllUnits



Declare @NPTData table (
	DetailId int,UnitId int,StartTime datetime ,	EndTime datetime ,Reason1Id int null,
	Reason2Id int null,	Reason3Id int null,	Reason4Id int null,	ReasonsCompleted int Null,CommentId Int null,
	EntryOn DateTime,UserId Int,EventReasonTreeDataId Int
	
)
IF @NptEventId Is NULL
BEGIN
	INSERT INTO @NPTData(DetailId ,UnitId ,StartTime,EndTime,Reason1Id,
						Reason2Id,Reason3Id,Reason4Id,CommentId,UserId,
						EntryOn,EventReasonTreeDataId )
		SELECT	NPDet_Id,PU_Id,Start_Time,End_Time,Reason_Level1,
				Reason_Level2,Reason_Level3,Reason_Level4,Comment_Id,User_Id,
				Entry_On,Event_Reason_Tree_Data_Id 
		FROM NonProductive_Detail
		WHERE Start_Time <= @EndTime and End_Time >= @StartTime 
END
ELSE
BEGIN
	INSERT INTO @NPTData(DetailId ,UnitId ,StartTime,EndTime,Reason1Id,
						Reason2Id,Reason3Id,Reason4Id,CommentId,UserId,
						EntryOn,EventReasonTreeDataId )
		SELECT	NPDet_Id,PU_Id,Start_Time,End_Time,Reason_Level1,
				Reason_Level2,Reason_Level3,Reason_Level4,Comment_Id,User_Id,
				Entry_On,Event_Reason_Tree_Data_Id 
		FROM NonProductive_Detail
		WHERE NPDet_Id = @NptEventId
END 

SELECT   DetailId = d.DetailId 
		,DepartmentId = dpt.Dept_Id , Department = dpt.Dept_Desc
		,LineId = pl.PL_Id , Line = pl.PL_Desc 
		, LocationId = UnitId, Location = pu.PU_Desc
		, [StartTime] = dbo.fnServer_CmnConvertFromDbTime(D.StartTime,'UTC') 
		, [EndTime] = dbo.fnServer_CmnConvertFromDbTime(D.EndTime,'UTC') 
		, Reason1Id	, Reason1 = er1.Event_Reason_Name 
		, Reason2Id	, Reason2 = er2.Event_Reason_Name 
		, Reason3Id	, Reason3 = er3.Event_Reason_Name 
		, Reason4Id , Reason4 = er4.Event_Reason_Name 
		, EventReasonTreeDataId
		, CommentId
		, EntryOn = dbo.fnServer_CmnConvertFromDbTime(EntryOn,'UTC') 
		, UserId , UserName = u.Username 
		, ReasonsCompleted = Coalesce(ert.Bottom_Of_Tree ,0)
	FROM  @NPTData D
	Join Prod_Units_Base pu on pu.pu_id = D.UnitId 
	Join Prod_Lines_Base pl on pl.pl_id = pu.pl_id
	Join Departments_Base dpt on dpt.Dept_Id  = pl.Dept_Id
	Left JOIN Event_Reasons er1 on er1.Event_Reason_Id = Reason1Id 
	Left JOIN Event_Reasons er2 on er2.Event_Reason_Id = Reason2Id 
	Left JOIN Event_Reasons er3 on er3.Event_Reason_Id = Reason3Id 
	Left JOIN Event_Reasons er4 on er4.Event_Reason_Id = Reason4Id 
	Left JOIN Event_Reason_Tree_Data ert on Ert.Event_Reason_Tree_Data_Id = EventReasonTreeDataId
	Left Join Users u on u.User_Id = d.UserId  
	ORDER BY D.StartTime ,pu.PU_Desc

