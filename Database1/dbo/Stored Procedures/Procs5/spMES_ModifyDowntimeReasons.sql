
CREATE  procedure [dbo].[spMES_ModifyDowntimeReasons]
		@TEDetIds		text = NULL	
		,@LocationId	Int
		,@FaultId		Int = Null
		,@Reason1Id		Int = Null
		,@Reason2Id		Int = Null
		,@Reason3Id		Int = Null
		,@Reason4Id		Int = Null		
		,@UserId		Int
AS

DECLARE @MasterUnit	Int
		,@UsersSecurity	Int		
		,@ActualSecurity	Int
		,@CurrentStart	DateTime
		,@CurrentEnd	DateTime
		,@CurrentMaster	Int
		,@CurrentReason1Id	Int
		,@CurrentReason2Id	Int
		,@CurrentReason3Id	Int
		,@CurrentReason4Id	Int
		,@CurrentFaultId	Int
		,@CurrentCommentId	Int
		,@CurrentLocationId	Int
		,@CurrStatus		Int
		,@CurrAction1		Int
		,@CurrAction2		Int
		,@CurrAction3		Int
		,@CurrAction4		Int
		,@ActionTreeId		Int
		,@CurrActionComment	Int
		,@CurrResearchComment	Int
		,@CurrResearchStatus	Int
		,@CurrResearchUser		Int
		,@CurrResearchOpen		Datetime
		,@CurrResearchClose		Datetime
		,@CurrSignatureId	    Int
		,@RecordChanged	Int = 0
		,@MaxRowCount	Int
		,@Itr	Int = 1
		,@TEDetId	Int		
		,@TreeId		Int
		,@retval	int
		,@Code	nvarchar(100)
		,@Error	nvarchar(1000)
		,@ErrorType	nvarchar(10)


DECLARE @DowntimeIdTable table(id int, val nvarchar(max), retVal nvarchar(max))

DECLARE @Outputtable table (TedetId int,Code nvarchar(100),Error nvarchar(max))

DECLARE @UpdatedTable table ([TEDet_Id] [int] ,
	[Action_Comment_Id] [int] NULL,	
	[Cause_Comment_Id] [int] NULL,
	[End_Time] [datetime] NULL,
	[Duration] decimal(10,2) NULL,
	[Event_Reason_Tree_Data_Id] [int] NULL,
	[PU_Id] [int] NOT NULL,
	[Location] nvarchar(100) NULL,
	[Reason1Id] [int], 
	[Reason1] nvarchar(1000),
	[Reason2Id]	[int], 
	[Reason2] nvarchar(1000),
	[Reason3Id]	[int], 
	[Reason3] nvarchar(1000),
	[Reason4Id] [int],
	[Reason4] nvarchar(1000),
	[Action1Id]  [int],
	[Action1] nvarchar(1000),
	[Action2Id] [int], 
	[Action2] nvarchar(1000),
	[Action3Id] [int], 
	[Action3] nvarchar(1000),
	[Action4Id]	[int], 
	[Action4] nvarchar(1000) ,
	[Research_Close_Date] [datetime] NULL,
	[Research_Comment_Id] [int] NULL,
	[Research_Open_Date] [datetime] NULL,
	[Research_Status_Id] [int] NULL,
	[Research_Status] nvarchar(100) null,
	[Research_User_Id] [int] NULL,
	[Signature_Id] [int] NULL,
	[Source_PU_Id] [int] NULL,
	[Start_Time] [datetime] NOT NULL,
	[Summary_Action_Comment_Id] [int] NULL,
	[Summary_Cause_Comment_Id] [int] NULL,
	[Summary_Research_Comment_Id] [int] NULL,
	[Uptime] [float] NULL,
	[User_Id] [int] NULL,
	[DepartmentId] [int],
	[Department] nvarchar(1000),
	[LineId] [int],
	[Line] nvarchar(1000),
	[FaultId] [int] NULL,
	[Fault] nvarchar(100) NULL,
	[StatusId] [int] NULL,
	[Status] nvarchar(100) NULL
)

INSERT INTO @DowntimeIdTable(id, val)
Select * from fnMESCore_Split(@TEDetIds, ',')

SELECT @MaxRowCount = count(*) from @DowntimeIdTable

WHILE @Itr <= @MaxRowCount
BEGIN

 SELECT @TEDetId = val from @DowntimeIdTable WHERE Id = @Itr

IF NOT EXISTS(SELECT 1 FROM Timed_Event_Details WHERE TEDET_Id = @TEDetId)
	BEGIN
		SELECT @Code = 'ResourceNotFound', @Error = 'Record not found', @ErrorType = ''--, PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		GOTO HANDLEError	
	END

	SELECT  @CurrentStart = a.Start_time
			,@CurrentEnd = a.End_Time
			,@CurrentMaster = a.PU_Id
			,@CurrentCommentId = a.Cause_Comment_Id
			,@CurrentReason1Id	= a.Reason_Level1 
			,@CurrentReason2Id	= a.Reason_Level2 
			,@CurrentReason3Id	= a.Reason_Level3 
			,@CurrentReason4Id	= a.Reason_Level4 
			,@CurrentFaultId    = a.TEFault_Id
			,@CurrentLocationId	= a.Source_PU_Id
			,@CurrStatus = a.TEStatus_Id
			,@CurrAction1 = a.Action_Level1
			,@CurrAction2 = a.Action_Level2
			,@CurrAction3 = a.Action_Level3
			,@CurrAction4 = a.Action_Level4
			,@CurrActionComment = a.Action_Comment_Id 
			,@CurrResearchComment	= a.Research_Comment_Id 
			,@CurrResearchStatus	= a.Research_Status_Id 
			,@CurrResearchUser		= a.Research_User_Id
			,@CurrResearchOpen = a.Research_Open_Date 
			,@CurrResearchClose = a.Research_Close_Date 
			,@CurrSignatureId = a.Signature_Id
		 FROM Timed_Event_Details a
		 WHERE TEDET_Id = @TEDetId

	SELECT @MasterUnit = Coalesce(Master_Unit,@LocationId) From Prod_Units_Base WHERE PU_Id = @LocationId
	Select @UsersSecurity = dbo.fnBF_CmnGetUserAccessLevel( @MasterUnit,@UserId,1)

	IF (@FaultId Is NULL AND @CurrentFaultId Is Not Null) OR (@FaultId Is Not Null AND @CurrentFaultId  != @FaultId) OR (@FaultId Is Not NULL AND @CurrentFaultId Is Null) 
	BEGIN
		SET @RecordChanged = 1
		IF  dbo.fnCMN_CheckSheetSecurity(@MasterUnit,null,400,2,@UsersSecurity) = 0
		BEGIN
			SELECT @Code = 'InsufficientPermission', @Error = 'Invalid - Attempt to Change Fault', @ErrorType = ''--, PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			GOTO HANDLEError
		END
		ELSE
		BEGIN
			IF @FaultId IS NOT NULL
			BEGIN
				IF NOT Exists (Select 1 FROM Timed_Event_Fault  WHERE TEFault_Id = @FaultId and PU_id = @MasterUnit And (Source_PU_Id = @CurrentLocationId Or @CurrentMaster = @MasterUnit))
				BEGIN
					SELECT @Code = 'InvalidData', @Error = 'Invalid - Fault Not Found', @ErrorType = 'ParameterResourceNotFound'--, PropertyName1 = 'FaultId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @FaultId, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
					GOTO HANDLEError
				END
			END
		END
	END
SELECT @ActualSecurity = 0
	SELECT @ActualSecurity = dbo.fnCMN_CheckSheetSecurity(@MasterUnit,null,389,2,@UsersSecurity) /* Reasons */
	Select @TreeId = Name_Id From Prod_Events where PU_Id = @CurrentLocationId  and Event_Type = 2
	IF  (@Reason1Id Is NULL AND @CurrentReason1Id Is Not Null) OR (@Reason1Id Is Not Null AND @CurrentReason1Id  != @Reason1Id) OR (@Reason1Id Is Not NULL AND @CurrentReason1Id Is Null) 
	BEGIN
		SET @RecordChanged = 1
		IF @ActualSecurity = 0
		BEGIN
			SELECT @Code = 'InsufficientPermission', @Error = 'Invalid - Attempt to Change Reason Level 1', @ErrorType = ''--, PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			GOTO HANDLEError
		END
		ELSE
		BEGIN
			If  @Reason1Id is not null
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data WHERE Level1_Id = @Reason1Id And Tree_Name_Id = @TreeId)
				BEGIN
					SELECT @Code = 'InvalidData', @Error = 'Invalid - Reason 1 Not Found On Location', @ErrorType = 'ParameterResourceNotFound'--, PropertyName1 = 'Cause1', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason1Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
					GOTO HANDLEError		
				END
			 END
		END
	END
	IF  (@Reason2Id Is NULL AND @CurrentReason2Id Is Not Null) OR (@Reason2Id Is Not Null AND @CurrentReason2Id  != @Reason2Id) OR (@Reason2Id Is Not NULL AND @CurrentReason2Id Is Null) 
	BEGIN
		SET @RecordChanged = 1
		IF @ActualSecurity = 0
		BEGIN
			SELECT @Code = 'InsufficientPermission', @Error = 'Invalid - Attempt to Change Reason Level 2', @ErrorType = ''--, PropertyName1 = ''--, PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			GOTO HANDLEError
		END
		ELSE
		BEGIN
			If  @Reason2Id is not null
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
								WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And Tree_Name_Id = @TreeId)
				BEGIN
					SELECT @Code = 'InvalidData', @Error = 'Invalid - Reason 2 Not Found On Location', @ErrorType = 'ParameterResourceNotFound'--, PropertyName1 = 'Cause2', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason2Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
					GOTO HANDLEError		
				END
			 END
		END
	END
	IF  (@Reason3Id Is NULL AND @CurrentReason3Id Is Not Null) OR (@Reason3Id Is Not Null AND @CurrentReason3Id  != @Reason3Id) OR (@Reason3Id Is Not NULL AND @CurrentReason3Id Is Null) 
	BEGIN
		SET @RecordChanged = 1
		IF @ActualSecurity = 0
		BEGIN
			SELECT @Code = 'InsufficientPermission', @Error = 'Invalid - Attempt to Change Reason Level 3', @ErrorType = ''--, PropertyName1 = ''--, PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			GOTO HANDLEError
		END
		ELSE
		BEGIN
			If  @Reason3Id is not null
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
								WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And  Level3_Id = @Reason3Id And Tree_Name_Id = @TreeId)
				BEGIN
					SELECT @Code = 'InvalidData', @Error = 'Invalid - Reason 3 Not Found On Location', @ErrorType = 'ParameterResourceNotFound'--, PropertyName1 = 'Cause3', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason3Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
					GOTO HANDLEError		
				END
			 END
		END
	END
	IF  (@Reason4Id Is NULL AND @CurrentReason4Id Is Not Null) OR (@Reason4Id Is Not Null AND @CurrentReason4Id  != @Reason4Id) OR (@Reason4Id Is Not NULL AND @CurrentReason4Id Is Null) 
	BEGIN
		SET @RecordChanged = 1
		IF @ActualSecurity = 0
		BEGIN
			SELECT @Code = 'InsufficientPermission', @Error = 'Invalid - Attempt to Change Reason Level 4', @ErrorType = ''--, PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
			GOTO HANDLEError
		END
		ELSE
		BEGIN
			If  @Reason4Id is not null
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM Event_Reason_Tree_Data 
								WHERE Level1_Id = @Reason1Id And  Level2_Id = @Reason2Id And  Level3_Id = @Reason3Id And  Level4_Id = @Reason4Id And Tree_Name_Id = @TreeId)
				BEGIN
					SELECT @Code = 'InvalidData', @Error = 'Invalid - Reason 4 Not Found On Location', @ErrorType = 'ParameterResourceNotFound'--, PropertyName1 = 'Cause4', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Reason4Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
					GOTO HANDLEError			
				END
			 END
		END
	END
	IF @RecordChanged = 1	
	BEGIN
		EXECUTE  spServer_DBMgrUpdTimedEvent @TEDetId OUTPUT,@CurrentMaster,@CurrentLocationId,@CurrentStart,@CurrentEnd
									,@CurrStatus,@FaultId,@Reason1Id,@Reason2Id,@Reason3Id
									,@Reason4Id,Null,Null,2,2
									,@UserId,@CurrAction1,@CurrAction2,@CurrAction3,@CurrAction4
									,@CurrActionComment,@CurrResearchComment,@CurrResearchStatus,@CurrentCommentId,Null
									,Null,Null,Null,Null,Null
									,Null,@CurrResearchOpen,@CurrResearchClose,@CurrResearchUser,Null
									,@CurrSignatureId,NULL

									Insert into @Outputtable (Tedetid,Code,Error) values(@TEDetId,'success','')

END
	Insert into	@UpdatedTable  ( 
	TEDet_Id,
	Action_Comment_Id,
	Cause_Comment_Id,
	End_Time,
	Duration,
	Event_Reason_Tree_Data_Id,
	PU_Id,
	Location,
	Reason1Id,
	Reason1,
	Reason2Id,
	Reason2,
	Reason3Id,
	Reason3,
	Reason4Id,
	Reason4,
	Action1Id,
	Action1,
	Action2Id,
	Action2,
	Action3Id,
	Action3,
	Action4Id,
	Action4,
	Research_Close_Date,
	Research_Comment_Id,
	Research_Open_Date,
	Research_Status_Id,
	Research_Status,
	Research_User_Id,
	Signature_Id,
	Source_PU_Id,
	Start_Time,
	Summary_Action_Comment_Id,
	Summary_Cause_Comment_Id,
	Summary_Research_Comment_Id,
	Uptime,
	User_Id,
	DepartmentId,
	Department,
	LineId,
	Line,
	FaultId,Fault,
	StatusId,
	Status
)

Select TEDet_Id,
	Action_Comment_Id,
	Cause_Comment_Id,
	End_Time,
	ted.Duration,
	ted.Event_Reason_Tree_Data_Id,
	TED.PU_Id,
	pu.PU_Desc,
	ted.reason_level1,
	r1.Event_Reason_Name,
	ted.reason_level2,
	r2.Event_Reason_Name,
	ted.reason_level3,
	r3.Event_Reason_Name,
	ted.reason_level4,
	r4.Event_Reason_Name,
	ted.Action_level1,
	a1.Event_Reason_Name,
	ted.Action_level2,
	a2.Event_Reason_Name,
	ted.Action_level3,
	a3.Event_Reason_Name,
	ted.Action_level4,
	a4.Event_Reason_Name,
	Research_Close_Date,
	Research_Comment_Id,
	Research_Open_Date,
	ted.Research_Status_Id,
	dt.ResearchStatus,
	Research_User_Id,
	Signature_Id,
	ted.Source_PU_Id,
	Start_Time,
	Summary_Action_Comment_Id,
	Summary_Cause_Comment_Id,
	Summary_Research_Comment_Id,	
	Uptime,
	User_Id,
	d.Dept_Id,
	d.Dept_Desc,
	pl.Pl_Id ,
	pl.Pl_desc,
	tef.TEFault_Id,
	tef.TEFault_Name,	
	dt.DowntimeStatusId,
	dt.DowntimeStatus
	From Timed_event_details ted join
	dbo.prod_units_base pu on ted.pu_id=pu.pu_id
	left join dbo.Prod_Lines_Base pl on pu.pl_id = pl.pl_id
	left join dbo.Departments_Base d on pl.dept_id = d.dept_id
	left join dbo.Timed_Event_Fault tef on ted.TEFault_Id = tef.TEFault_Id
	left join [dbo].[SDK_V_PADowntimeEvent] dt on ted.TEDet_Id = dt.DowntimeEventId
	left join Event_reasons r1 on ted.reason_level1=r1.Event_Reason_Id
	left join Event_reasons r2 on ted.reason_level2=r2.Event_Reason_Id
	left join Event_reasons r3 on ted.reason_level3=r3.Event_Reason_Id
	left join Event_reasons r4 on ted.reason_level4=r4.Event_Reason_Id
	left join Event_reasons a1 on ted.Action_level1=a1.Event_Reason_Id
	left join Event_reasons a2 on ted.Action_level2=a2.Event_Reason_Id
	left join Event_reasons a3 on ted.Action_level3=a3.Event_Reason_Id
	left join Event_reasons a4 on ted.Action_level4=a4.Event_Reason_Id
	where ted.tedet_id = @TEDetId

	GOTO NEXTSTEP

	HANDLEError:
	Insert into @Outputtable (Tedetid,Code,Error) values(@TEDetId,@Code,@Error)

	NEXTSTEP:
	 SET @Itr = @Itr + 1
END

Select 
TEDet_Id,
	Action_Comment_Id,
	Cause_Comment_Id,
	dbo.fnServer_CmnConvertFromDBTime(End_Time,'UTC'),
	Duration,
	Event_Reason_Tree_Data_Id,
	PU_Id,
	Location,
	Reason1Id,
	Reason1,
	Reason2Id,
	Reason2,
	Reason3Id,
	Reason3,
	Reason4Id,
	Reason4,
	Action1Id,
	Action1,
	Action2Id,
	Action2,
	Action3Id,
	Action3,
	Action4Id,
	Action4,
	Research_Close_Date,
	Research_Comment_Id,
	Research_Open_Date,
	Research_Status_Id,
	Research_Status,
	Research_User_Id,
	Signature_Id,
	Source_PU_Id,
	dbo.fnServer_CmnConvertFromDBTime(Start_Time,'UTC'),
	Summary_Action_Comment_Id,
	Summary_Cause_Comment_Id,
	Summary_Research_Comment_Id,
	Uptime,
	User_Id,
	DepartmentId,
	Department,
	LineId,
	Line,
	FaultId,Fault,
	StatusId,
	Status from @UpdatedTable

Select Tedetid,Code,Error from @Outputtable

