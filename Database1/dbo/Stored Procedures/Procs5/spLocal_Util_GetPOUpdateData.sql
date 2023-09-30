--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetPOUpdateData]
					@ErrorCode				int				OUTPUT,
					@ErrorMessage			varchar(1000)	OUTPUT,
					@ProcessOrder			varchar(255),
					@PathId					int		

--WITH ENCRYPTION
AS
SET NOCOUNT ON


	DECLARE	@tPODetails TABLE(
			Id							int IDENTITY (1,1),
			PPId						int,
			ProcessOrder				nvarchar(255),
			PPStatusId					int,
			PPStatusDesc				nvarchar(255),
			BOMFormulationId			int,
			BOMFormulationDesc	nvarchar(255),
			BOMId					int,
			BOMDesc					nvarchar(50),
			ProdId						int,
			ProdCode					nvarchar(255),
			ProdDesc					nvarchar(255),
			BatchNumber					nvarchar(255),
			Qty							float,
			UOMId						int,
			UOMDesc						nvarchar(255),
			StartDate					datetime,
			Duration					int,
			ExpirationDate				int)


			/*
			�	Batch Number 			Disabled +
			�	PO Status 			Disabled +
			�	Material			Disabled +
			�	Quantity 			Enabled +
			�	UOM				Disabled +
			�	Start Time			Enabled +
			�	Duration			Enabled +
			�	Expiration Date			Enabled
			�	Confirmed Quantity 		Enabled only if TECO checkbox is checked
			�	Comment			Enabled (Blank)
			�	BOM Grid			Disabled
			*/


	DECLARE	@tBOMDetails TABLE(
			Id							int IDENTITY (1,1),
			MasterBOMFormulationId		int,
			MasterBOMFormulationItemId	int,
			OriginGroup					nvarchar(255),
			ProdId						int,
			ProdCode					nvarchar(255),
			ProdDesc					nvarchar(255),
			Qty							float,
			UOMId						int,
			UOMDesc						nvarchar(255),
			ScrapFactor					float,
			PUId						int,
			Location					nvarchar(255),		
			AltProdId					int,
			AltProdCode					nvarchar(255),
			AltProdDesc					nvarchar(255),
			AltQty						float,
			AltUOMId					int,
			AltUOMDesc					nvarchar(255),
			FlgOGValid					bit)

	DECLARE	@tOG TABLE(
			OriginGroup nvarchar(255)
			)

	DECLARE @ThisTime		datetime,
			@YYYY			nvarchar(4),
			@YY				nvarchar(2),
			@MM				nvarchar(2),
			@DD				nvarchar(2),
			@HH				nvarchar(2),
			@MI				nvarchar(2),
			@SS				varchar(2),
			@BatchNumber	nvarchar(10),
			@BatchId		int,
			@ProdPointPUId	int,
			@PlannedDate	datetime,
			@ExpirationDate	nvarchar(8),
			@ProdId			int,
			@ProdCode		nvarchar(255),
			@MasterBOMFormulationDesc	nvarchar(255),
			@UniqueBatch	uniqueidentifier,
			@BatchEventId	int,
			@BOMOG			nvarchar(255),
			@ii				int,
			@PathCode		nvarchar(255),
			@FlgOGValid		bit,
			@UniquePO		uniqueidentifier,
			@PPId			int,
			@Location		nvarchar(255),
			@LocationPUId	int,
			@OriginGroup	nvarchar(255),
			@cnt			int


	DECLARE		@TableFields	table (
				id				int identity (1,1),
				TableId			int,
				TableFieldId	int)

	SET @ErrorCode = 1
	SET @ErrorMessage = 'No Error'
	
	/*
	SELECT	@PathCode = pex.Path_Code 
	FROM	dbo.Prdexec_Paths pex WITH (NOLOCK)
	WHERE	pex.Path_Id = @PathId

	IF @PathCode is Null
	BEGIN
		SET		@ErrorCode = -100
		SET		@ErrorMessage = 'Invalid Path'
		GOTO	SPOUTPUT
	END
	*/
	IF len(IsNull(@ProcessOrder,'')) <=0
	BEGIN
		SET		@ErrorCode = -100
		SET		@ErrorMessage = 'Process Order is Blank'
		GOTO	SPOUTPUT
	END

	SET		@cnt = Null
	SELECT	@cnt		= count(pex.Path_Id)
	FROM	dbo.Prdexec_Paths pex WITH (NOLOCK)
	WHERE	pex.Path_Id	=	@PathId

	IF isNUll(@cnt,0) <=0
	BEGIN
		SET		@ErrorCode = -200
		SET		@ErrorMessage = 'Invalid Path'
		GOTO	SPOUTPUT
	END	

	SET		@cnt = Null
	SELECT	@cnt = count(pp.PP_Id)
	FROM	dbo.production_plan pp WITH (NOLOCK)
	WHERE	upper(pp.Process_Order) = @ProcessOrder
	and		pp.Path_Id	=	@PathId
	
	IF isNUll(@cnt,0) <=0
	BEGIN
		SET		@ErrorCode = -300
		SET		@ErrorMessage = 'Invalid Process Order'
		GOTO	SPOUTPUT
	END


	-- Get the List of valid Origin Groups for the Path
	INSERT	@tOG (OriginGroup)
	SELECT	DISTINCT tfv.Value
	FROM	dbo.Table_Fields_Values tfv with (nolock)
	join	dbo.tables t				with (nolock) on tfv.TableId = t.TableId and upper(t.TableName) = 'PRDEXEC_INPUTS'
	join	dbo.Table_Fields tf			with (nolock) on tfv.Table_Field_Id = tf.Table_Field_Id and upper(tf.Table_Field_Desc) = 'ORIGIN GROUP'
	join	dbo.PrdExec_Inputs pexi		with (nolock) on tfv.KeyId = pexi.PEI_Id
	join	dbo.PrdExec_Path_Units pexu with (nolock) on pexi.PU_Id = pexu.PU_Id
	join	dbo.Prdexec_Paths pex		with (nolock) on pexu.Path_Id = pex.Path_Id
	WHERE	pex.Path_Id = @PathId

	INSERT	@tPODetails (
			PPId,
			ProcessOrder,
			PPStatusId,
			PPStatusDesc,
			BOMFormulationId,
			BOMFormulationDesc,
	        BOMId,
			ProdId,
			ProdCode,
			ProdDesc,
			BatchNumber,
			Qty,
			UOMId,
			UOMDesc,
			StartDate,
			ExpirationDate)
	
	SELECT	pp.pp_id,
			pp.Process_Order,
			pps.PP_Status_Id,
			pps.PP_Status_Desc,
			bomf.BOM_Formulation_Id,
			bomf.BOM_Formulation_Desc,
	        bomf.BOM_Id,
			p.Prod_Id,
			p.Prod_Code,
			p.Prod_Desc,
			pp.User_General_1,
			pp.Forecast_Quantity,
			bomf.Eng_Unit_Id,
			eu.Eng_Unit_Desc,
			pp.Forecast_Start_Date,
			pp.User_General_2

	FROM	dbo.production_plan pp
	join	dbo.Bill_Of_Material_Formulation bomf	WITH (NOLOCK) on pp.BOM_Formulation_Id = bomf.BOM_Formulation_Id
	join	dbo.Production_Plan_Statuses pps		WITH (NOLOCK) on pp.PP_Status_Id = pps.PP_Status_Id
	join	dbo.Products_Base p						WITH (NOLOCK) on pp.Prod_Id = p.Prod_Id
	join	dbo.Engineering_Unit eu					WITH (NOLOCK) on bomf.Eng_Unit_Id = eu.Eng_Unit_Id	
	WHERE	pp.Process_Order	=	@ProcessOrder
	and		pp.Path_Id			=	@PathId

	UPDATE		tpod
	SET			tpod.Duration = datediff(MINUTE,pp.Forecast_Start_Date, pp.Forecast_End_Date)
	FROM		@tPODetails tpod
	join		dbo.production_plan pp with (nolock) on tpod.PPId = pp.PP_Id
	

	
	INSERT	@tBOMDetails(
			MasterBOMFormulationId,
			MasterBOMFormulationItemId,
			ProdId,
			ProdCode,
			ProdDesc,
			Qty,
			UOMId,
			UOMDesc,
			ScrapFactor,
			PUId,
			FlgOGValid)
	SELECT	bomf.BOM_Formulation_Id,
			bomfi.BOM_Formulation_Item_Id,
			bomfi.Prod_Id,
			p.Prod_Code,
			p.Prod_Desc,
			bomfi.Quantity,
			bomfi.Eng_Unit_Id,
			eu.Eng_Unit_Desc,
			bomfi.Scrap_Factor,
			bomfi.PU_Id,
			0
	FROM	@tPODetails tpod
	join	dbo.Bill_Of_Material_Formulation bomf	WITH (NOLOCK) on tpod.BOMFormulationId = bomf.BOM_Formulation_Id
	join	dbo.Bill_Of_Material_Formulation_Item bomfi on bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id 
	join	dbo.products p on bomfi.Prod_Id = p.Prod_Id
	join	dbo.Engineering_Unit eu on bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
	

	UPDATE	tbd
	SET		tbd.OriginGroup = convert(nvarchar(255),pmdmc.Value)
	FROM	@tBOMDetails tbd
	join	dbo.Products_Base p									WITH (NOLOCK) on tbd.ProdId = p.Prod_Id
	join	dbo.Products_Aspect_MaterialDefinition pamd			WITH (NOLOCK) on p.Prod_Id = pamd.Prod_Id
	join	dbo.MaterialDefinition md							WITH (NOLOCK) on pamd.Origin1MaterialDefinitionId = md.MaterialDefinitionId
	join	dbo.Property_MaterialDefinition_MaterialClass pmdmc WITH (NOLOCK) on md.MaterialDefinitionId = pmdmc.MaterialDefinitionId 
	WHERE	upper(pmdmc.name) = 'ORIGIN GROUP' and upper(pmdmc.Class) = 'BASE MATERIAL LINKAGE'


	INSERT	@TableFields(
			TableId,
			TableFieldId)
	SELECT	tf.TableId,
			tf.Table_Field_Id
	FROM	dbo.Table_Fields tf with (nolock)
	join	dbo.tables tt with (nolock ) on tf.TableId = tt.TableId
	WHERE	upper(tt.TableName)			= 'PRDEXEC_INPUTS'			
	and		upper(tf.Table_Field_Desc)	= 'ORIGIN GROUP'
	
	



	SET		@ii = NULL
	SELECT	@ii = min(id) from @tBOMDetails
	WHILE	@ii <= (select max(id) from @tBOMDetails)
	BEGIN
		SET		@OriginGroup = Null
		set		@location = Null
		set		@LocationPUId = Null
		SELECT	@OriginGroup = tbom.OriginGroup
		FROM	@tBOMDetails tbom
		WHERE	tbom.Id = @ii
		-- get Location Matching origin Group
		-- LOcation will be Null if Origin Group dowsn't matvh the selected Path 
		SELECT			@location =  x.Foreign_Key,	
						@LocationPUId = 		x.Actual_Id		
		FROM			dbo.Data_Source_XRef x	with (nolock)
		join				dbo.Data_Source ds with (nolock)on x.DS_Id					= ds.DS_Id 
		join				dbo.tables t with (nolock) on x.Table_Id						= t.TableId
		join				dbo.Prod_Units_Base pu with (nolock) on x.Actual_Id				= pu.pu_id 
		join				dbo.PrdExec_Input_Sources pexis with (nolock) on x.Actual_Id	= pexis.PU_Id
		join				dbo.PrdExec_Inputs pei on pexis.PEI_Id = pei.PEI_Id
		--join				dbo.PrdExec_Inputs pei on x.Actual_Id = pei.PU_Id
		join				dbo.PrdExec_Path_Units pexu	on pei.PU_Id = pexu.PU_Id
		join				dbo.Prdexec_Paths pex on pex.Path_Id = pexu.Path_Id
		--join				dbo.Table_Fields_Values tfv with (nolock) on pexis.PEI_Id		= tfv.KeyId
		join				dbo.Table_Fields_Values tfv with (nolock) on pei.PEI_Id		= tfv.KeyId
		
		join				@TableFields tf on tfv.TableId = tf.TableId and
							tf.TableFieldId = tfv.Table_Field_Id
		WHERE				upper(ds.DS_Desc)	= 'OPEN ENTERPRISE'			 
		and					upper(t.TableName)	= 'PROD_UNITS'				
		and					tfv.value = @OriginGroup				
		and 				pex.Path_Id = @PathId
		
		UPDATE	tbd
		SET		tbd.Location =	@Location,
				tbd.PUId	=	@LocationPUId
		FROM	@tBOMDetails tbd
		WHERE	tbd.id = @ii
		SELECT	@ii = @ii+1
	END

	UPDATE	tbd
	SET		tbd.AltProdId = boms.Prod_Id,
			tbd.AltProdCode = p.Prod_code,
			tbd.AltProdDesc = p.Prod_Desc,
			tbd.AltQty		= tbd.Qty * boms.Conversion_Factor,
			tbd.AltUOMId = boms.Eng_Unit_Id,
			tbd.AltUOMDesc = eu.Eng_Unit_Desc
	FROM	@tBOMDetails tbd
	join	dbo.Bill_Of_Material_Substitution boms with (nolock) on tbd.MasterBOMFormulationItemId = boms.BOM_Formulation_Item_Id
	join	dbo.Products_Base p with (nolock) on boms.Prod_Id = p.Prod_Id
	join	dbo.Engineering_Unit eu with (nolock) on boms.Eng_Unit_Id = eu.Eng_Unit_Id


	UPDATE	tbd
	SET		tbd.FlgOGValid = 1
	FROM	@tBOMDetails tbd
	join	@tOG tog on tbd.OriginGroup = tog.OriginGroup

	/*
	IF exists (SELECT tbd.Id FROM @tBOMDetails tbd WHERE IsNUll(tbd.FlgOGValid,0) < 1)
	BEGIN
		SELECT	@ErrorCode = -300,
				@ErrorMessage = 'Origin Group(s): ' 
		SELECT	@ii = min(id) from @tBOMDetails
		WHILE	@ii <= (select max(id) from @tBOMDetails)
		BEGIN
			SELECT	@BOMOG		= tbd.OriginGroup,
					@FlgOGValid = tbd.FlgOGValid
			FROM	@tBOMDetails tbd
			WHERE	tbd.id = @ii
			if IsNull(@FlgOGValid,0) < 1
			BEGIN
				SELECT @ErrorMessage = @ErrorMessage + ' ' + @BOMOG + ', '
			END		
			SELECT @ii = @ii+1
		END
		SELECT @ErrorMessage = left(@ErrorMessage,len(@ErrorMessage)-1) + ' Not Valid for the Path: ' + @PathCode
	END
	*/
SPOUTPUT:		

SELECT * FROM @tPODetails		
SELECT * FROM @tBOMDetails


RETURN
SET NOcount OFF