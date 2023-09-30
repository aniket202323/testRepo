CREATE PROCEDURE [dbo].[spMES_SplitDownTime]

@SplitDowntimeXml XML,
@UserId INT
AS
BEGIN
DECLARE @inputDowntimeTable table
		(Id				Int IDENTITY(1,1)
		,TEDetId		Int
		,StartTime		DateTime 
		,EndTime		DateTime
		,AssetId		Int
		,FaultId		Int
		,Reason1Id		Int
		,Reason2Id		Int
		,Reason3Id		Int
		,Reason4Id		Int
		,Action1Id		Int
		,Action2Id		Int
		,Action3Id		Int
		,Action4Id		Int
		,UserId		Int)

		--transform the xml into a table 
INSERT INTO @inputDowntimeTable 
		(TEDetId		
		,StartTime	 
		,EndTime
		,AssetId		
		,FaultId		
		,Reason1Id		
		,Reason2Id		
		,Reason3Id		
		,Reason4Id		
		,Action1Id		
		,Action2Id		
		,Action3Id		
		,Action4Id		
		,UserId)

SELECT 
	 x.y.value('@downtimeId','int')
	,x.y.value('@startTime','datetime')
	,x.y.value('@endTime','datetime')
	,x.y.value('@assetId','int')	
	,x.y.value('@faultId','int') 
	,x.y.value('@cause1Id','int')	 
	,x.y.value('@cause2Id','int')  
	,x.y.value('@cause3Id','int')  
	,x.y.value('@cause4Id','int') 
	,x.y.value('@action1Id','int')
	,x.y.value('@action2Id','int')
	,x.y.value('@action3Id','int')
	,x.y.value('@action4Id','int')
	,@UserId 
FROM @SplitDowntimeXml.nodes('DowntimeRecords/DowntimeRecord') AS x(y)

DECLARE @CurrentRow INT = 1
		,@MaxRow INT = 0
		,@TEDetId		Int  = Null
		,@StartTime		DateTime = Null 
		,@EndTime		DateTime = Null
		,@AssetId		Int
		,@FaultId		Int = Null
		,@Reason1Id		Int = Null
		,@Reason2Id		Int = Null
		,@Reason3Id		Int = Null
		,@Reason4Id		Int = Null
		,@Action1Id		Int = Null
		,@Action2Id		Int = Null
		,@Action3Id		Int = Null
		,@Action4Id		Int = Null
		,@User_Id		Int
		,@TransType		Int
		,@intErrorCode  Int
SET @MaxRow = (SELECT COUNT(*) FROM @inputDowntimeTable)
DECLARE @Code nvarchar(100),@Error nvarchar(1000),@tedet_id int, @RecordChanged int, @ErrorType nvarchar(max),
@PropertyName1 nvarchar(max), @PropertyName2 nvarchar(max), @PropertyName3 nvarchar(max), @PropertyName4 nvarchar(max),
@PropertyValue1 nvarchar(max),@PropertyValue2 nvarchar(max),@PropertyValue3 nvarchar(max),@PropertyValue4 nvarchar(max)

DECLARE @tedetidtable table (Id int identity(1,1),tedetid int)

BEGIN TRAN

WHILE (@CurrentRow <=@MaxRow)
BEGIN
	SET @TransType =0

	SELECT @TEDetId=TEDetId
		   ,@StartTime = StartTime
		   ,@EndTime = EndTime
		   ,@AssetId = AssetId
		   ,@FaultId = FaultId
		   ,@Reason1Id = Reason1Id
		   ,@Reason2Id = Reason2Id
		   ,@Reason3Id = Reason3Id
		   ,@Reason4Id = Reason4Id
		   ,@Action1Id = Action1Id
		   ,@Action2Id = Action2Id
		   ,@Action3Id = Action3Id
		   ,@Action4Id = Action4Id
		   ,@User_Id = UserId
		    FROM @inputDowntimeTable WHERE Id = @CurrentRow

	SET @TransType = CASE WHEN @TEDetId IS NOT NULL THEN 2 
						ELSE 1 END
DECLARE 
		 @MasterUnit int
		,@CurrentCommentId	Int
		/* Extra Fields needed for Update*/
		,@CurrStatus			Int
		,@CurrActionComment		Int
		,@CurrResearchComment	Int
		,@CurrResearchStatus	Int
		,@CurrResearchUser		Int
		,@CurrResearchOpen		Datetime
		,@CurrResearchClose		Datetime
		,@CurrSignatureId	    Int

	SELECT @tedet_id = TedDetId,@Code = code, @Error =error,@ErrorType = ErrorType, @PropertyName1 = PropertyName1, 
		   @PropertyName2 = PropertyName2, @PropertyName3 = PropertyName3, @PropertyName1 = PropertyName4, @PropertyValue1 = PropertyValue1, @PropertyValue2 = PropertyValue2, @PropertyValue3 = PropertyValue3, 
		   @PropertyValue4 = PropertyValue4, @RecordChanged = RecordChanged FROM  fnMES_ModifyDowntime(
		@TransType
		,@TEDetId
		,@StartTime
		,@EndTime
		,@AssetId
		,@FaultId
		,@Reason1Id
		,@Reason2Id
		,@Reason3Id
		,@Reason4Id
		,@Action1Id
		,@Action2Id
		,@Action3Id		
		,@Action4Id		
		,0	
		,@UserId		
		,NULL)		
		--IF (@tedet_id is null)
		--BEGIN
		--GOTO HANDLE_ERROR
		--END
		IF @RecordChanged=1
		BEGIN	
			SELECT @MasterUnit = COALESCE(Master_Unit,@AssetId) FROM Prod_Units_Base WHERE PU_Id = @AssetId
			IF (@TransType = 2)
		BEGIN
			SELECT   
				@CurrentCommentId = a.Cause_Comment_Id
				,@CurrStatus = a.TEStatus_Id
				,@CurrResearchComment	= a.Research_Comment_Id 
				,@CurrResearchStatus	= a.Research_Status_Id 
				,@CurrResearchUser		= a.Research_User_Id
				,@CurrResearchOpen = a.Research_Open_Date 
				,@CurrResearchClose = a.Research_Close_Date 
				,@CurrSignatureId = a.Signature_Id
			FROM Timed_Event_Details a
			 WHERE TEDET_Id = @TEDetId
		 END
		 ELSE 
			BEGIN
				SELECT   
				@CurrentCommentId = NULL
				,@CurrStatus = NULL
				,@CurrActionComment = NULL 
				,@CurrResearchComment	= NULL
				,@CurrResearchStatus	= NULL
				,@CurrResearchUser		= NULL
				,@CurrResearchOpen = NULL
				,@CurrResearchClose = NULL
				,@CurrSignatureId = NULL
			END
			SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,'UTC')
			SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,'UTC') 
			EXECUTE spServer_DBMgrUpdTimedEvent @TEDetId OUTPUT,@MasterUnit,@AssetId,@StartTime,@EndTime
								,@CurrStatus,@FaultId,@Reason1Id,@Reason2Id,@Reason3Id
								,@Reason4Id,Null,Null,@TransType,2
								,@UserId,@Action1Id,@Action2Id,@Action3Id,@Action4Id
								,@CurrActionComment,@CurrResearchComment,@CurrResearchStatus,@CurrentCommentId,Null
								,Null,Null,Null,Null,Null
								,Null,@CurrResearchOpen,@CurrResearchClose,@CurrResearchUser,Null
								,@CurrSignatureId,0 
		END

		IF (@TEDetId IS NULL OR @Code <> 'Success')
		BEGIN
		GOTO HANDLE_ERROR
		END
		ELSE
		BEGIN
		INSERT INTO @tedetidtable(TEDETID) VALUES (@TEDetId)
		END

		SET @CurrentRow = @CurrentRow + 1
END

COMMIT TRAN
GOTO SP_END

HANDLE_ERROR:
	SELECT @ERROR AS 'Error', @Code AS 'Code', @ErrorType AS 'ErrorType', @PropertyName1 AS 'PropertyName1', @PropertyName2 AS 'PropertyName2', @PropertyName3 AS 'PropertyName3', @PropertyName4 AS 'PropertyName4', @PropertyValue1 AS 'PropertyValue1', @PropertyValue2 AS 'PropertyValue2', @PropertyValue3 AS 'PropertyValue3', @PropertyValue4 AS 'PropertyValue4'
    ROLLBACK TRAN
	RETURN

SP_END:

SELECT TEDet_Id AS 'DetailId',
	Action_Comment_Id AS 'ActionCommentId',
	Cause_Comment_Id AS 'ReasonCommentId',
	dbo.fnServer_CmnConvertFromDBTime(End_Time,'UTC') as 'EndTime',
	ted.Duration AS 'Duration',
	ted.Event_Reason_Tree_Data_Id AS 'EventReasonTreeDataId',
	TED.PU_Id AS 'UnitId',
	pu.PU_Desc AS 'Unit',
	ted.reason_level1 AS 'Reason1Id',
	r1.Event_Reason_Name AS 'Reason1',
	ted.reason_level2 AS 'Reason2Id',
	r2.Event_Reason_Name AS 'Reason2',
	ted.reason_level3 AS 'Reason3Id',
	r3.Event_Reason_Name AS 'Reason3',
	ted.reason_level4 AS 'Reason4Id',
	r4.Event_Reason_Name AS 'Reason4',
	ted.Action_level1 AS 'Action1Id',
	a1.Event_Reason_Name AS 'Action1',
	ted.Action_level2 AS 'Action2Id',
	a2.Event_Reason_Name AS 'Action2',
	ted.Action_level3 AS 'Action3Id',
	a3.Event_Reason_Name AS 'Action3',
	ted.Action_level4 AS 'Action4Id',
	a4.Event_Reason_Name AS 'Action4',
	Research_Close_Date AS 'ResearchClose',
	Research_Comment_Id AS 'ResearchCommentId',
	Research_Open_Date AS 'ResearchOpen',
	ted.Research_Status_Id AS 'ResearchStatusId',
	dt.ResearchStatus AS 'ResearchStatus',
	Research_User_Id AS 'Research_User_Id',
	Signature_Id AS 'eSignatureId',
	COALESCE(ted.Source_PU_Id, TED.PU_Id) AS 'LocationId',
	COALESCE(sourcepu.PU_Desc, pu.PU_Desc) AS 'Location',
	dbo.fnServer_CmnConvertFromDBTime(Start_Time,'UTC') as 'StartTime',
	Summary_Action_Comment_Id AS 'Summary_Action_Comment_Id',
	Summary_Cause_Comment_Id AS 'Summary_Cause_Comment_Id',
	Summary_Research_Comment_Id AS 'Summary_Research_Comment_Id',	
	Uptime AS 'Uptime',
	ted.User_Id AS 'UserId',
	U1.UserName AS 'UserName',
	d.Dept_Id AS 'DepartmentId',
	d.Dept_Desc AS 'Department',
	pl.Pl_Id AS 'LineId',
	pl.Pl_desc AS 'Line',
	tef.TEFault_Id AS 'FaultId',
	tef.TEFault_Name AS 'FaultName',	
	dt.DowntimeStatusId AS 'StatusId',
	dt.DowntimeStatus AS 'Status',
	COALESCE(ertd.Bottom_Of_Tree, 0) AS 'ReasonsCompleted',
	CASE WHEN (ted.End_Time IS NULL) THEN 1 ELSE 0 END AS 'IsOpen',
	erc.ERC_Id AS 'CategoryId',
	ec.ERC_Desc AS 'Category',
	tes.TEStatus_Id AS 'EventStatusId', 
	tes.TEStatus_Name AS 'EventStatus',
	(SELECT MIN(NPDet_id) FROM NonProductive_Detail np 
	WHERE  np.PU_id = ted.PU_Id	
	AND np.Start_time = dbo.fnServer_CmnConvertToDbTime(ted.Start_Time,'UTC')) AS'NptId'
	FROM Timed_event_details ted
	JOIN dbo.prod_units_base pu ON ted.pu_id=pu.pu_id
	LEFT JOIN dbo.prod_units_base sourcepu ON ted.Source_PU_Id=sourcepu.pu_id
	LEFT JOIN dbo.Prod_Lines_Base pl ON pu.pl_id = pl.pl_id
	LEFT JOIN dbo.Departments_Base d ON pl.dept_id = d.dept_id
	LEFT JOIN dbo.Timed_Event_Fault tef ON ted.TEFault_Id = tef.TEFault_Id
	LEFT JOIN [dbo].[SDK_V_PADowntimeEvent] dt ON ted.TEDet_Id = dt.DowntimeEventId
	LEFT JOIN Event_reasons r1 ON ted.reason_level1=r1.Event_Reason_Id
	LEFT JOIN Event_reasons r2 ON ted.reason_level2=r2.Event_Reason_Id
	LEFT JOIN Event_reasons r3 ON ted.reason_level3=r3.Event_Reason_Id
	LEFT JOIN Event_reasons r4 ON ted.reason_level4=r4.Event_Reason_Id
	LEFT JOIN Event_reasons a1 ON ted.Action_level1=a1.Event_Reason_Id
	LEFT JOIN Event_reasons a2 ON ted.Action_level2=a2.Event_Reason_Id
	LEFT JOIN Event_reasons a3 ON ted.Action_level3=a3.Event_Reason_Id
	LEFT JOIN Event_reasons a4 ON ted.Action_level4=a4.Event_Reason_Id
	LEFT JOIN Users u1 ON u1.User_Id = ted.User_Id
	LEFT JOIN Event_Reason_Category_Data erc ON erc.Event_Reason_Tree_Data_Id = ted.Event_Reason_Tree_Data_Id
	LEFT JOIN Event_Reason_Catagories ec ON ec.ERC_Id = erc.ERC_Id
	LEFT JOIN [dbo].[Event_Reason_Tree_Data] ertd ON ertd.Event_Reason_Tree_Data_Id = ted.Event_Reason_Tree_Data_Id
	LEFT JOIN Timed_Event_Status tes on tes.TEStatus_Id = ted.TEStatus_Id
	WHERE ted.tedet_id IN (SELECT TEDETID FROM @tedetidtable)
END

