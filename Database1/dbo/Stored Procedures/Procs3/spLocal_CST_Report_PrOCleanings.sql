
--------------------------------------------------------------------------------------------------
-- Table function: spLocal_CST_Report_PrOCleanings
--------------------------------------------------------------------------------------------------
-- Author				: U.Lapierre
-- Date created			: 2023-04-26
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Report
-- Description			: cleanign relted to a Process Order
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2023-04-26		U.Lapierre				Initial Release 
-- 1.1		2023-05-18		U.Lapierre				At time to the date in the process order detail
-- 1.2		2023-09-08		U.Lapierre				Return two more P8O detail field:  CSTREPORTID and CSTVERSIONID (Product UDP)
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXECUTE spLocal_CST_Report_PrOCleanings NULL,'G202302204' ,NULL

EXECUTE spLocal_CST_Report_PrOCleanings NULL, NULL,'C220908002'

EXECUTE spLocal_CST_Report_PrOCleanings 16044, NULL,NULL


*/


CREATE   PROCEDURE [dbo].[spLocal_CST_Report_PrOCleanings]
(
@ProcessOrderId			INTEGER,
@Batch					varchar(50) = NULL,
@ProcessOrder			varchar(50) = NULL

)
AS
BEGIN
	DECLARE 	@TableIdProdUnit						INTEGER,
				@tfIdApplianceType						INTEGER,
				@tfIdLocationType						INTEGER,
				@tfIdLocationSerial						INTEGER,
				@LocationCleaningUDESubTypeId			INTEGER,
				@ApplianceCleaningUDESubTypeId			INTEGER,
				@POSTartTime							DATETIME,
				@POEndTime								DATETIME,
				@PUID									INTEGER,
				@varIdCleaningProcedure					INTEGER,				
				@VarIdSanitizer_serial					INTEGER,			
				@VarIdDetergent_serial					INTEGER,
				@Now									DATETIME,
				@UDPIdVersionId							INT,
				@UDPIdReportId							INT,
				@VersionId								Varchar(50),
				@ReportId								Varchar(100),
				@TableId								INT

	DECLARE @ValidPaths TABLE (
	pathId			int
	)

	DECLARE @ProcessOrderDetail TABLE(
	Product					VARCHAR(100),
	ProdCode				VARCHAR(50),
	ProdDesc				VARCHAR(100),
	Line					VARCHAR(100),
	ProcessOrder			VARCHAR(100),
	Batch					VARCHAR(100),
	DateCreated				DATETIME,
	CST_VersionId			VARCHAR(50),
	CST_ReportId			VARCHAR(100)
	)

	DECLARE @CleaningDetails	TABLE (
	id							INT IDENTITY,
	AreaRecurso					VARCHAR(100),
	CleaningType				VARCHAR(50),
	CleaningDate				DATETIME,
	CompleteUser				VARCHAR(100),
	ApproveUser					VARCHAR(100),
	DetergentBatch				VARCHAR(100),
	SanitizerBatch				VARCHAR(100),
	SOP							VARCHAR(100)
	)

	DECLARE @Appliance_transitions	TABLE(
	T_Id						INTEGER IDENTITY(1,1),
	Appliance_PE_Id				INTEGER,
	Appliance_Serial			VARCHAR(25),
	Appliance_Type				VARCHAR(50),
	Transition_PE_Id			INTEGER,
	Transition_PE_Time			DATETIME,
	Transition_PE_PU_Id			INTEGER,
	Transition_PE_PU_Desc		VARCHAR(50)
	)


	/* ==================================================
	Ability to deal with several inputs (pp_id, batch, process_order)
	====================================================*/
	IF @ProcessOrderId IS NULL 
	BEGIN
		INSERT @ValidPaths (pathId)
		SELECT path_id
		FROM dbo.prdExec_Paths WITH(NOLOCK)
		WHERE path_code LIKE 'CTS_%'
			OR path_code LIKE 'CST_%';

		IF @ProcessOrder IS NOT NULL
		BEGIN
			IF ( SELECT CHARINDEX('-CTS',@ProcessOrder,0) +  CHARINDEX('-CST',@ProcessOrder,0)) > 1
			BEGIN
				SET @ProcessOrderId = (	SELECT TOP 1 pp.pp_id 
										FROM dbo.production_plan pp		WITH(NOLOCK) 
										JOIN @ValidPaths vp								ON pp.path_id = vp.pathid
										WHERE pp.process_order = @ProcessOrder
										);
			END
			ELSE
			BEGIN
				SET @ProcessOrder = @ProcessOrder + '-CTS';
				SET @ProcessOrderId = (	SELECT TOP 1 pp.pp_id 
										FROM dbo.production_plan pp		WITH(NOLOCK) 
										JOIN @ValidPaths vp								ON pp.path_id = vp.pathid
										WHERE pp.process_order = @ProcessOrder
										);
				IF @ProcessOrderId IS NULL
				BEGIN
					SET @ProcessOrder = @ProcessOrder + '-CST';
					SET @ProcessOrderId = (	SELECT TOP 1 pp.pp_id 
											FROM dbo.production_plan pp		WITH(NOLOCK) 
											JOIN @ValidPaths vp								ON pp.path_id = vp.pathid
											WHERE pp.process_order = @ProcessOrder
											);

				END
			END
		END
		IF @Batch IS NOT NULL AND @ProcessOrderId IS NULL
		BEGIN
			SET @ProcessOrderId = (	SELECT TOP 1 pp.pp_id 
									FROM dbo.production_plan pp		WITH(NOLOCK) 
									JOIN @ValidPaths vp								ON pp.path_id = vp.pathid
									WHERE pp.User_General_1 = @Batch
									);
		END

	END

	SET @Now = GETDATE();
	SET @NOW = DATEADD(ms,-1*DATEPART(ms,@NOW),@NOW)


	/* ==================================================
	Get process order details
	====================================================*/
	SET @TableId		= (SELECT tableId			FROM dbo.tables						WHERE tablename = 'Products')

	SET @UDPIdReportId	= (SELECT table_field_id	FROM dbo.table_fields WITH(NOLOCK)	WHERE table_field_desc = 'CST_ReportId' AND TABLEId = @TableId)
	SET @UDPIdVersionId = (SELECT table_field_id	FROM dbo.table_fields WITH(NOLOCK)	WHERE table_field_desc = 'CST_VersionId' AND TABLEId = @TableId)



	INSERT @ProcessOrderDetail (	Product					,
									ProdCode				,
									ProdDesc				,
									Line					,
									ProcessOrder			,
									Batch					,
									DateCreated				,
									CST_ReportId			,
									CST_VersionId			
										)
	SELECT	p.Prod_Desc	,
			p.prod_code	,
			RIGHT(p.Prod_Desc,LEN(p.Prod_Desc)-CHARINDEX(':',p.Prod_Desc,0)),
			pep.path_code,
			pp2.process_order,
			pp2.user_general_1,
			@Now,									
			COALESCE(tfv1.value,'Unknown'),
			COALESCE(tfv2.value,'Unknown')
	FROM dbo.production_plan pp				WITH(NOLOCK)
	JOIN dbo.products_base p				WITH(NOLOCK)	ON pp.prod_id =p.prod_id
	JOIN dbo.production_plan pp2			WITH(NOLOCK)	ON pp.source_pp_id = pp2.pp_id
	JOIN dbo.prdexec_paths	pep				WITH(NOLOCK)	ON pep.path_id = pp2.path_id
	LEFT JOIN dbo.table_fields_Values tfv1	WITH(NOLOCK)	ON tfv1.keyid = p.prod_id 
																AND tfv1.table_field_id = @UDPIdReportId
																AND tfv1.TableId = @TableId
	LEFT JOIN dbo.table_fields_Values tfv2	WITH(NOLOCK)	ON tfv2.keyid = p.prod_id 
																AND tfv2.table_field_id = @UDPIdVersionId
																AND tfv2.TableId = @TableId
	WHERE pp.pp_id = @ProcessOrderId;


	

	
	
	/* ==================================================
	Get Cleaning details
	====================================================*/

	/*Get PPA ids */
	SET @TableIdProdUnit				= (	SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Products'	);
	SET @tfIdLocationSerial				= (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Location serial number');
	SET @tfIdApplianceType				= (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Appliance type');
	SET @tfIdLocationType				= (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location type');
	SET @LocationCleaningUDESubTypeId	= (	SELECT EST.event_Subtype_Id	FROM dbo.event_subtypes EST WITH(NOLOCK) WHERE	EST.event_Subtype_Desc = 'CTS Location Cleaning');
	SET @ApplianceCleaningUDESubTypeId	= (	SELECT EST.Event_Subtype_Id	FROM dbo.event_subtypes EST WITH(NOLOCK) WHERE	EST.Event_Subtype_Desc = 'CTS Appliance Cleaning');



	/*Get MAKING unit pu_id */
	SET @PUID = (	SELECT pepu.pu_id
					FROM dbo.production_plan pp			WITH(NOLOCK)
					JOIN dbo.prdExec_path_units pepu	WITH(NOLOCK) ON pp.path_id = pepu.path_id
																		AND pepu.is_schedule_point = 1
					WHERE pp.pp_id = @ProcessOrderId);

	/* cleaning var_id for location*/
	SET @VarIdDetergent_serial			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @PUID AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Detergent batch:serial')	;
	SET @VarIdSanitizer_serial			=	(	SELECT var_id 	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @PUID AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Sanitizer batch:serial')	;
	SET @varIdCleaningProcedure			=	(	SELECT var_id	FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @PUID AND event_subtype_id = @LocationCleaningUDESubTypeId AND Test_Name = 'Cleaning:procedure');


	/*Get PrO time boundaries*/
	SELECT	@POSTartTime	= start_time,
			@POEndTime		= end_time
	FROM dbo.production_Plan_starts WITH(NOLOCK)
	WHERE pp_id = @ProcessOrderId
		AND pu_id = @PUID;


	INSERT @CleaningDetails (	AreaRecurso		,
								CleaningType	,
								CleaningDate	,
								CompleteUser	,
								ApproveUser		,
								DetergentBatch	,
								SanitizerBatch	,
								SOP		)		
	SELECT	pu.pu_desc + '-' + tfv.value, 
			SUB.CleaningType,
			SUB.CleaningDate,
			SUB.CompleteUser,
			SUB.ApproveUser,
			COALESCE(t1.result,'NA'),
			COALESCE(t2.result,'NA'),
			COALESCE(t3.result,'NA')
	FROM dbo.prod_units_Base pu			WITH(NOLOCK)	
	JOIN (	SELECT TOP 1	ude_id		AS 'UDE_ID',
							@PUID		AS 'PUID',
							type		AS 'CleaningType',
							End_Time	AS 'CleaningDate',
							Completion_ES_Username AS 'CompleteUser',
							Approver_ES_Username AS 'ApproveUser'
			FROM  fnLocal_CTS_Location_Cleanings(@PUID, NULL, @POSTartTime)) SUB ON pu.pu_id = SUB.PUID
	JOIN dbo.table_fields_values tfv	WITH(NOLOCK) ON tfv.keyid = pu.pu_id AND tfv.table_field_id = @tfIdLocationSerial
	LEFT JOIN dbo.tests t1				WITH(NOLOCK) ON t1.var_id = @VarIdDetergent_serial	AND t1.result_on = SUB.CleaningDate		
	LEFT JOIN dbo.tests t2				WITH(NOLOCK) ON t2.var_id = @VarIdSanitizer_serial	AND t2.result_on = SUB.CleaningDate	
	LEFT JOIN dbo.tests t3				WITH(NOLOCK) ON t3.var_id = @varIdCleaningProcedure	AND t3.result_on = SUB.CleaningDate	
	WHERE pu.pu_id = @PUID;

	

	--select * from events where pu_id = @PUID and timestamp >=@POSTartTime and timestamp < @POEndTime

	INSERT @Appliance_transitions	(
	Appliance_PE_Id				,
	Appliance_Serial			,
	Transition_PE_Id			,
	Transition_PE_Time			,
	Transition_PE_PU_Id			
	)
	SELECT ed.event_id,ed.alternate_event_num, etrans.event_id,ec.timestamp, @puid
	FROM dbo.events ETRANS			WITH(NOLOCK)
	JOIN dbo.event_components ec	WITH(NOLOCK)	ON ec.event_id = ETRANS.event_id
	JOIN dbo.events eApp			WITH(NOLOCK)	ON ec.source_event_id = eApp.event_id
	JOIN dbo.event_details ed		WITH(NOLOCK)	ON ed.event_id = eApp.event_id
	WHERE ETRANS.pu_id = @PUID
		AND ETRANS.Start_time >= @POSTartTime 
		AND (ETRANS.Start_time < @POEndTime)



	/* Get appliance cleaning */
	INSERT @CleaningDetails (	AreaRecurso		,
								CleaningType	,
								CleaningDate	,
								CompleteUser	,
								ApproveUser		,
								DetergentBatch	,
								SanitizerBatch	,
								SOP		)	
	SELECT	Appliance_Serial,
			A.CleaningType, 
			A.CleaningTime, 
			A.CompleteUser, 
			A.ApproveUser, 
			COALESCE(t1.result, 'NA'), 
			COALESCE(t2.result, 'NA'), 
			COALESCE(t3.result, 'NA')
	FROM @Appliance_transitions AppT
	CROSS APPLY  (	SELECT	Type					AS 'CleaningType',
					end_time				AS 'CleaningTime',
					location_Id				AS 'CleaningPUID',
					Completion_ES_UserName	AS 'CompleteUser', 
					Approver_ES_Username	AS 'ApproveUser'
			FROM fnLocal_CTS_Appliance_Cleanings(Appliance_PE_Id, NULL, Transition_PE_Time)
			)A
	JOIN dbo.variables_Base v1		WITH(NOLOCK)	ON v1.pu_id = A.CleaningPUID	AND v1.test_name = 'Detergent batch:serial' AND v1.event_subtype_id = @ApplianceCleaningUDESubTypeId
	LEFT JOIN dbo.tests t1			WITH(NOLOCK)	ON t1.var_id = v1.var_id	AND t1.result_on = A.CleaningTime
	JOIN dbo.variables_Base v2		WITH(NOLOCK)	ON v2.pu_id = A.CleaningPUID	AND v2.test_name = 'Sanitizer batch:serial' AND v2.event_subtype_id = @ApplianceCleaningUDESubTypeId
	LEFT JOIN dbo.tests t2			WITH(NOLOCK)	ON t2.var_id = v2.var_id	AND t2.result_on = A.CleaningTime
	JOIN dbo.variables_Base v3		WITH(NOLOCK)	ON v3.pu_id = A.CleaningPUID	AND v3.test_name = 'Cleaning:procedure' AND v3.event_subtype_id = @ApplianceCleaningUDESubTypeId
	LEFT JOIN dbo.tests t3			WITH(NOLOCK)	ON t3.var_id = v3.var_id	AND t3.result_on = A.CleaningTime
	ORDER BY Appt.Transition_PE_Time






	/* ==================================================
	Return results
	====================================================*/
	/*Process order detail*/
	SELECT	Product					AS 'FULLPRODUCT',
			ProdCode				AS 'PRODCODE',
			ProdDesc				AS 'PRODDESC',
			Line					AS 'LINE',
			ProcessOrder			AS 'PROCESSORDER',
			Batch					AS 'BATCH',
			DateCreated				AS 'DATECREATED',
			CST_ReportId			AS 'CSTREPORTID',
			CST_VersionId			AS 'CSTVERSIONID'
	FROM @ProcessOrderDetail

	/*Cleaning details*/
	SELECT 	AreaRecurso				AS 'LOCATION',
			CleaningType			AS 'CLEANINGTYPE',
			CleaningDate			AS 'CLEANINGDATE',
			CompleteUser			AS 'COMPLETEUSER',
			ApproveUser				AS 'APPROVEUSER',
			DetergentBatch			AS 'DETERGENT',
			SanitizerBatch			AS 'SANITIZER',
			SOP						AS 'SOP'
	FROM @CleaningDetails
	ORDER BY Id


END
