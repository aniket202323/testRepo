 
 
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_MPWS_INT_Material_Movement_Upload
--------------------------------------------------------------------------------------------------
-- Author				: MKRAVCHENKO GE
-- Date created			: 16-Jan-17
-- Version 				: Version <1.0>
-- SP Type				: Workflow
-- Caller				: Called by the INT-Outbound_Material_Movement_Upload
-- Description			: Returns 1 resulteset Mat Move Upload Data
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
 
--------------------------------------------------------------------------------------------------

/****************************************************************************************************
NOTES:
 
 
1)	
2)	
3)  
 
4) Stored Procedure is Triggered by Event Status Change via WF Event
 
Options:
 
----------------------------------------------------------------------------------------------
Tab Spacing:	4
----------------------------------------------------------------------------------------------
DATE				BY						DESCRIPTION
18-Jan-17 001 002	MKravchenko				Original
15-Jov-17 001 003	Susan Lee (GE Digital)	updated storage locations, updates to trigger type 2 and 3
 

 exec spLocal_MPWS_INT_Material_Movement_Upload 'CA20171101_004', '', 1
 exec spLocal_MPWS_INT_Material_Movement_Upload  'DI20171102-23510000-0001','',2
 exec spLocal_MPWS_INT_Material_Movement_Upload  '','',3
------------------------------------------------------------------------------------------------------------------------
 
****************************************************************************************************/
CREATE   PROCEDURE [dbo].[spLocal_MPWS_INT_Material_Movement_Upload]
	@EventName		varchar(50),
	@EventStatusName	varchar(50), --for future use
	@MMoveTriggerID		int -- 1-'Ready for Production' Carrier; 2-'Returned To Preweigh' Material; 3-'Material reconciliation'
--WITH ENCRYPTION
AS
 
 
SET	NOCOUNT	ON
 
/****************************************************************************************************
*																									*
*					SECTION 0: INITIATION															*
*																									*
****************************************************************************************************/
-- SET ANSI_WARNINGS OFF 	 AHussain, DHaines DEC 14
--SET ARITHIGNORE ON 
-----------------------------------------------------------------------------------------------------
--  	  	  	  	  	  	  	  	 VARIABLE DECLARATIONS 	  	  	  	  	  	  	  	  	  	  	    --
-----------------------------------------------------------------------------------------------------
-- Constants
 
 
 
DECLARE @tMatMovement TABLE (         
							Id		INT IDENTITY,
                            ReferenceDoc                       varchar(100),
                            MaterialNumber                     varchar(255),
                            StorageLocation                     varchar(50),
                            BatchNumber                         varchar(100),
                            Quantity							varchar(100),
							UnitOfMeasure						varchar(100),
							ReceivingMaterialNumber				varchar(255),
							ReceivingStorageLocation			varchar(50),
							ReceivingBatchNumber				varchar(100)
									)
										
	
DECLARE @Dispense TABLE
					(
						DispensePPId		INT,
						DispenseEventId		INT,
						DispenseEventNum	VARCHAR(50),
						DispenseProdId		INT,
						DispenseQty			FLOAT,
						DispenseUOM			VARCHAR(50),
						BatchNum			VARCHAR(50),
						ProcessOrder		VARCHAR(50),
						Material			VARCHAR(50),
						StorageLocation     VARCHAR(50),
						ReceivingStorageLocation	VARCHAR(50)
					)	 

DECLARE @RMC TABLE
	(
	WEDId	INT,
	EventId INT,
	PUId INT,
	PLId INT,
	ProdCode varchar(50),
	SAPBatch varchar(50),
	LostQuantity float,
	UOM varchar(10),
	PreweighSAPLocation varchar(50),
	LostSAPLocation varchar(50)
	)

-----------------------------------------------------------------------------------------------------
-- PARAMETERS 	  	  	  	  	  	  	  	  	  	  	    --
-----------------------------------------------------------------------------------------------------
--sashaM 2012-01-23
--get subscriptions 
 
/* FOR TESTING ->>>

INSERT INTO @tMatMovement VALUES(
                                                'RefDoc-000910726622',
                                                '000000000099662220',
                                                'LTA1',
                                                'S8283',
                                                '44.000',
												'EA',
												'000000000099662220',
												'SCRT',
											'S8283')
 
INSERT INTO @tMatMovement VALUES(
                                                'RefDoc-000910726622',
                                                '000000000099662221',
                                                'LTA1',
                                                'S8284',
                                                '466.000',
												'EA',
												'000000000099662221',
												'SCRT',
												'S8283')
 */



-----------------------------------------------------------------------------------------------------
-- Type 1: Carrier Move	  	  	  	  	  	  	  	  	  	  	    --
-----------------------------------------------------------------------------------------------------

IF @MMoveTriggerID = 1 -- carrier is ready for production
BEGIN
 	 	INSERT INTO @Dispense
	(	DispensePPId,
		DispenseEventId, 
		DispenseEventNum,
		DispenseProdId,
		DispenseQty,
		DispenseUOM	
		,StorageLocation
		,ReceivingStorageLocation
	)
	SELECT DISTINCT 
		ded.pp_id,
		d.Event_Id,
		d.Event_Num ,
		d.Applied_Product,
		ded.Final_Dimension_X,
		t.Result
		,P.StorageLocation
		,ul.Location_Code
		--,P.ReceivingStorageLocation
	--c.Event_Num carrier,cs.Event_Num carriersection, d.Event_Num dispense,rmc.event_num rmc,
	FROM	dbo.Events					c		WITH (NOLOCK)
	JOIN	dbo.Event_Details			ced		WITH (NOLOCK)
		ON	ced.event_id = c.event_id
	JOIN	dbo.Unit_Locations ul				WITH (NOLOCK)
		ON	ul.Location_Id = ced.Location_Id
	JOIN	dbo.Event_Components		c_cs	WITH (NOLOCK)
		ON	c_cs.Source_Event_Id = c.Event_Id
	JOIN	dbo.Events					cs		WITH (NOLOCK)
		ON cs.Event_Id	=	c_cs.Event_Id
	JOIN	dbo.Prod_Units_Base			cspu	WITH (NOLOCK)
		ON	cspu.PU_Id	=	cs.PU_Id
		AND	cspu.Equipment_Type = 'Carrier Section'
	JOIN	dbo.Event_Components	cs_d		WITH (NOLOCK)
		ON	cs_d.Event_Id = cs.Event_Id
	JOIN	dbo.Events				d			WITH (NOLOCK)
		ON d.Event_Id	= cs_d.Source_Event_Id
	JOIN	dbo.Prod_Units_Base			dpu			WITH (NOLOCK)
		ON dpu.PU_Id = d.PU_Id
		AND dpu.Equipment_Type = 'Dispense Station'
	JOIN	dbo.Event_Details			ded		WITH (NOLOCK)
		ON	ded.Event_Id	= d.Event_Id
	JOIN	dbo.Variables_Base			v			WITH (NOLOCK)
		ON v.PU_Id = d.PU_Id 
		AND v.Test_Name = 'MPWS_DISP_DISPENSE_UOM'
	JOIN	dbo.Tests				t			WITH (NOLOCK)
		ON t.Var_Id = v.Var_Id 
		AND t.Result_On = d.[TimeStamp]
	CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(ded.PP_Id) P
	WHERE LTRIM(RTRIM(UPPER(c.Event_Num))) = LTRIM(RTRIM(UPPER(@EventName))) --@EventId 


	UPDATE d
	SET		d.ProcessOrder	=	pp.Process_Order,
			d.BatchNum		=	t.Result ,
			d.Material		=	dp.Prod_Code
	FROM @Dispense d
	JOIN	dbo.Production_Plan		pp			WITH (NOLOCK)
		ON	pp.PP_Id	= d.DispensePPId
	JOIN	dbo.Event_Components	d_rmc		WITH (NOLOCK)
		ON d_rmc.Event_Id = d.DispenseEventId
	JOIN	dbo.Events				rmc			WITH (NOLOCK)
		ON rmc.Event_Id = d_rmc.Source_Event_Id
	JOIN	dbo.Prod_Units_Base			rmcpu		WITH (NOLOCK)
		ON 	rmcpu.PU_Id	= rmc.PU_Id AND rmcpu.Equipment_Type = 'Receiving Station'
	JOIN	dbo.Products_Base			dp		WITH (NOLOCK)
		ON	dp.Prod_Id	= d.DispenseProdId
	JOIN	dbo.Variables_Base			v			WITH (NOLOCK)
		ON v.PU_Id = rmc.PU_Id 
		AND v.Test_Name = 'MPWS_INVN_SAP_LOT'
	JOIN	dbo.Tests				t			WITH (NOLOCK)
		ON t.Var_Id = v.Var_Id 
		AND t.Result_On = rmc.[TimeStamp]


 	 INSERT @tMatMovement (ReferenceDoc,
                           MaterialNumber,
                           StorageLocation,
                           BatchNumber,
						   Quantity,
						   UnitOfMeasure,
						   ReceivingMaterialNumber,
						   ReceivingStorageLocation,
						   ReceivingBatchNumber)

	SELECT	ProcessOrder		AS 'ProcessOrder',
			Material			AS 'MaterialNumber',
			StorageLocation		AS 'StorageLocation',
			BatchNum			AS 'BatchNumber',
			SUM(DispenseQty)	AS 'Quantity',
			DispenseUOM			AS 'UnitOfMeasure',
			Material			AS 'MaterialNumber',
			ReceivingStorageLocation	AS 'ReceivingStorageLocation',
			BatchNum			AS 'BatchNumber'
	FROM	@Dispense

	GROUP BY ProcessOrder,
			Material,
			BatchNum,
			DispenseUOM,
			StorageLocation,
			ReceivingStorageLocation
END

-----------------------------------------------------------------------------------------------------
-- Type 2: Return dispense container to Preweigh from making  	  	  	  	  	  	  	  	  	  	    --
-----------------------------------------------------------------------------------------------------
 
IF @MMoveTriggerID = 2 -- material returned to pre weigh
BEGIN

 	 	INSERT INTO @Dispense
	(	DispensePPId,
		DispenseEventId, 
		DispenseEventNum,
		DispenseProdId,
		DispenseQty,
		DispenseUOM	
		,ReceivingStorageLocation
	)
	SELECT DISTINCT 
		ded.pp_id,
		d.Event_Id,
		d.Event_Num ,
		d.Applied_Product,
		CASE WHEN ded.Final_Dimension_X =0 THEN ded.initial_dimension_x ELSE ded.Final_Dimension_X END,
		t.Result	
		,P.StorageLocation		-- moving material TO preweigh area

	FROM	dbo.Events				d			WITH (NOLOCK)
	JOIN	dbo.Prod_Units_Base			dpu			WITH (NOLOCK)
		ON dpu.PU_Id = d.PU_Id
		AND dpu.Equipment_Type = 'Dispense Station'
	JOIN	dbo.Event_Details			ded		WITH (NOLOCK)
		ON	ded.Event_Id	= d.Event_Id
	JOIN	dbo.Variables_Base			v			WITH (NOLOCK)
		ON v.PU_Id = d.PU_Id 
		AND v.Test_Name = 'MPWS_DISP_DISPENSE_UOM'
	JOIN	dbo.Tests				t			WITH (NOLOCK)
		ON t.Var_Id = v.Var_Id 
		AND t.Result_On = d.[TimeStamp]
	CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(ded.PP_Id) P
	WHERE LTRIM(RTRIM(UPPER(d.Event_Num))) = LTRIM(RTRIM(UPPER(@EventName))) --@EventId 


	UPDATE d
	SET  StorageLocation = Location_Code
	FROM @Dispense d
	JOIN dbo.Event_Detail_History dedh WITH (NOLOCK)
		ON dedh.Event_Id = d.DispenseEventId
	JOIN	dbo.Unit_Locations ul				WITH (NOLOCK)
		ON	ul.Location_Id = dedh.Location_Id AND ul.Location_Desc = 'Ready For Production'

	UPDATE d
	SET		d.ProcessOrder	=	pp.Process_Order,
			d.BatchNum		=	t.Result ,
			d.Material		=	dp.Prod_Code
	FROM @Dispense d
	JOIN	dbo.Production_Plan		pp				WITH (NOLOCK)
		ON	pp.PP_Id	= d.DispensePPId
	JOIN	dbo.Event_Components	d_rmc			WITH (NOLOCK)
		ON d_rmc.Event_Id = d.DispenseEventId
	JOIN	dbo.Events				rmc				WITH (NOLOCK)
		ON rmc.Event_Id = d_rmc.Source_Event_Id
	JOIN	dbo.Prod_Units_Base			rmcpu		WITH (NOLOCK)
		ON 	rmcpu.PU_Id	= rmc.PU_Id AND rmcpu.Equipment_Type = 'Receiving Station'
	JOIN	dbo.Products_Base			dp			WITH (NOLOCK)
		ON	dp.Prod_Id	= d.DispenseProdId
	JOIN	dbo.Variables_Base			v			WITH (NOLOCK)
		ON v.PU_Id = rmc.PU_Id 
		AND v.Test_Name = 'MPWS_INVN_SAP_LOT'
	JOIN	dbo.Tests				t				WITH (NOLOCK)
		ON t.Var_Id = v.Var_Id 
		AND t.Result_On = rmc.[TimeStamp]

	-- insert into material movement return table
 	 INSERT @tMatMovement (ReferenceDoc,
                           MaterialNumber,
                           StorageLocation,
                           BatchNumber,
						   Quantity,
						   UnitOfMeasure,
						   ReceivingMaterialNumber,
						   ReceivingStorageLocation,
						   ReceivingBatchNumber)

	SELECT	ProcessOrder		AS 'ProcessOrder',
			Material			AS 'MaterialNumber',
			StorageLocation		AS 'StorageLocation',
			BatchNum			AS 'BatchNumber',
			SUM(DispenseQty)	AS 'Quantity',
			DispenseUOM			AS 'UnitOfMeasure',
			Material			AS 'MaterialNumber',
			ReceivingStorageLocation	AS 'ReceivingStorageLocation',
			BatchNum			AS 'BatchNumber'
	FROM	@Dispense

	GROUP BY ProcessOrder,
			Material,
			BatchNum,
			DispenseUOM,
			StorageLocation,
			ReceivingStorageLocation
END

-----------------------------------------------------------------------------------------------------
-- Type 3: Report to SAP flag	  	  	  	  	  	  	  	  	  	  	    --
-----------------------------------------------------------------------------------------------------

IF @MMoveTriggerID = 3 -- Report to SAP, reconciliation
	BEGIN
		-- Get raw material containers with waste that has SAP flag in User_General_1
		INSERT INTO @RMC
			(
			WEDId,
			EventId ,
			PUId ,
			PLId,
			ProdCode ,
			SAPBatch ,
			LostQuantity ,
			UOM 
			)
		SELECT	wed.WED_Id,
				wed.Event_Id,
				wed.PU_Id,
				pu.PL_Id,
				rmcp.Prod_Code,
				rmctSAPBatch.Result,
				wed.Amount,
				rmctUOM.Result
		FROM	dbo.waste_event_details		wed		WITH (NOLOCK)
		JOIN	dbo.Prod_Units				pu		WITH (NOLOCK)
			ON	pu.PU_Id = wed.PU_Id
			AND pu.Equipment_Type = 'Receiving Station'
		JOIN	dbo.Events					rmc		WITH (NOLOCK)
			ON	wed.Event_Id = rmc.Event_Id
		JOIN	dbo.Event_Details			rmced	WITH (NOLOCK)
			ON	rmced.Event_Id = rmc.Event_Id
		JOIN	dbo.Products_Base			rmcp	WITH (NOLOCK)
			ON	rmcp.Prod_Id	=	rmc.Applied_Product
		JOIN	dbo.Variables_Base			rmcvUOM			WITH (NOLOCK)
						ON rmcvUOM.PU_Id = rmc.PU_Id 
		AND rmcvUOM.Test_Name = 'MPWS_INVN_RMC_UOM'
		JOIN	dbo.Tests				rmctUOM			WITH (NOLOCK)
						ON rmctUOM.Var_Id = rmcvUOM.Var_Id 
		AND rmctUOM.Result_On = rmc.[TimeStamp]

		JOIN	dbo.Variables_Base			rmcvSAPBatch			WITH (NOLOCK)
						ON rmcvSAPBatch.PU_Id = rmc.PU_Id 
		AND rmcvSAPBatch.Test_Name = 'MPWS_INVN_SAP_LOT'
		JOIN	dbo.Tests				rmctSAPBatch		WITH (NOLOCK)
						ON rmctSAPBatch.Var_Id = rmcvSAPBatch.Var_Id 
		AND rmctSAPBatch.Result_On = rmc.[TimeStamp]
		WHERE wed.User_General_1 = 'SAP'

		-- Get SAP location codes
		Update rmc
		SET PreweighSAPLocation = pwsaploc.Value,
			LostSAPLocation = lostsaploc.Value
		FROM	@RMC rmc
		JOIN dbo.prdexec_paths		pep	WITH (NOLOCK)
			ON pep.PL_Id = rmc.PLId
		OUTER APPLY fnLocal_MPWS_GetUDP(pep.Path_Id,'PE_RTCISSIM_Line','PrdExec_Paths') pwsaploc
		OUTER APPLY fnLocal_MPWS_GetUDP(pep.Path_Id,'PE_RTCISSIM_WHSE','PrdExec_Paths') lostsaploc

		-- Reset User_General_1
		UPDATE	wed
		SET		wed.User_General_1 = convert(varchar(255),getdate())
		FROM	@RMC	rmc
		JOIN	dbo.Waste_Event_Details	wed
			ON	wed.WED_Id = rmc.WEDId

		INSERT @tMatMovement (ReferenceDoc,
                           MaterialNumber,
                           StorageLocation,
                           BatchNumber,
						   Quantity,
						   UnitOfMeasure,
						   ReceivingMaterialNumber,
						   ReceivingStorageLocation,
						   ReceivingBatchNumber)
		SELECT	''							AS 'ProcessOrder',
				ProdCode					AS 'MaterialNumber',
				CASE WHEN Sum(LostQuantity)>0 THEN PreweighSAPLocation ELSE LostSAPLocation END	AS 'StorageLocation',
				SAPBatch					AS 'BatchNumber',
				ABS(Sum(LostQuantity))		AS 'Quantity',
				UOM							AS 'UnitOfMeasure',
				ProdCode					AS 'MaterialNumber',
				CASE WHEN Sum(LostQuantity)>0 THEN LostSAPLocation ELSE PreweighSAPLocation END	AS 'ReceivingStorageLocation',
				SAPBatch				AS 'BatchNumber'
		FROM @RMC
		GROUP BY ProdCode,PreweighSAPLocation,SAPBatch,UOM,LostSAPLocation
	END
 
SELECT * FROM @tMatMovement
 

 
SET NOCOUNT OFF
RETURN 0

