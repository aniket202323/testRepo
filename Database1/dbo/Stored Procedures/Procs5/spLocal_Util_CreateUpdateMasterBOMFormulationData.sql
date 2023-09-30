--------------------------------------------------------------------------------
CREATE PROCEDURE		[dbo].[spLocal_Util_CreateUpdateMasterBOMFormulationData]
						@ErrCode					int output,
						@ErrMessage					nvarchar(255) output,
						@MasterBOMFormulationId		int output,
						@DefaultBOMFamilyDesc		nvarchar(255),
						@DefaultBOMDesc				nvarchar(255),
						@BOMFormulationData			nvarchar(max)
			
--WITH ENCRYPTION
AS
SET NOCOUNT ON

	DECLARE	@UserId					int,
			@MasterBOMFamilyId		int,
			@MasterBOMId			int,
			@RC						int,
			@ProdId					int,
			@xml					xml,
			@BOMFormulationId		int,
			@BOMFormulationCode		nvarchar(255),                                                                                                                                                                                                                                            
			@BOMFormulationDesc		nvarchar(255),                                                                                                                                                                                                                                            
			@BOMId					int,    
			@CommentId				int, 
			@Comment				nvarchar(max) ,                                                                                                                                                                                                                                                     
			@EffectiveDate			datetime,      
			@UOMId					int,
			@UOMDesc				nvarchar(255),                                                                                                                                                                                                                                               
			@ExpirationDate			datetime,                                                                                                                                                                                                                                            
			@QuantityPrecision		int,
			@StandardQuantity		float ,
			@UserName				nvarchar(255)

	DECLARE @ii						int,
			@User					int,
			@Alias					varchar(50),
			@UseComponents			bit,
			@Scrap					float,
			@qty					float,
			@altqty					float,
			@qtyprec				int,
			@lowert					float,
			@uppert					float,
			@ltprec					int,
			@utprec					int,
			@eu						int,
			@alteu					int,
			@Unit					int,
			@Location				int,
			@Formulation			int,
			@Lot					varchar(50),
			@Product				varchar(25),
			@BOMFormulationItemId	int,
			@AltProdId				int,			
			@Conversion				float,
			@Order					int,
			@BOMSubstituationId		int,
			@Removed				nvarchar(255)
			
	DECLARE	@tMasterBOMFormulation	table (
			Id						int	identity(1,1),
			BOMFormulationId		int,
			BOMFormulationCode		nvarchar(255),
			BOMFormulationDesc		nvarchar(255),
			BOMId					int,
			CommentId				int,
			Comment					nvarchar(max),
			EffectiveDate			nvarchar(255),
			UOMId					int,
			UOMDesc					nvarchar(255),
			ExpirationDate			nvarchar(255),
			QuantityPrecision		int,
			StandardQuantity		float,
			UserName				nvarchar(255))

	DECLARE	@tMasterBOMFormulationItems TABLE(
			Id							int IDENTITY (1,1),
			MasterBOMFormulationItemId	int Null,
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
			Removed						nvarchar(255))
			
	SELECT	@xml = convert(xml, @BOMFormulationData)

	INSERT	@tMasterBOMFormulation(
			BOMFormulationId,
			BOMFormulationDesc,
			BOMId,
			CommentId,
			Comment,
			EffectiveDate,
			UOMId,
			UOMDesc,
			ExpirationDate,
			QuantityPrecision,
			StandardQuantity,
			UserName)
	SELECT	b.value('@BOMFormulationId', 'int'),
			b.value('@BOMFormulationDesc', 'nvarchar(255)'),
			b.value('@BOMId', 'int'),
			b.value('@CommentId', 'int'),
			b.value('@Comment', 'nvarchar(255)'),
			b.value('@EffectiveDate', 'nvarchar(255)'),
			--, b.value('xs:dateTime(@EffectiveDate)', 'datetime')
			b.value('@EngUnitId', 'int'),
			b.value('@EngUnitDesc', 'nvarchar(255)'),
			b.value('@ExpirationDate', 'nvarchar(255)'),
			--,b.value('xs:dateTime(@ExpirationDate)', 'datetime')
			b.value('@QuantityPrecision', 'int'),
			b.value('@StandardQuantity', 'float'),
			b.value('@User', 'nvarchar(255)')
	FROM	@xml.nodes('/BOMFormulation') as a(b) 

	INSERT	@tMasterBOMFormulationItems(
			MasterBOMFormulationItemId,
			OriginGroup,
			ProdId,
			ProdCode,
			ProdDesc,
			Qty,
			UOMId,
			UOMDesc,
			ScrapFactor,
			PUId,
			Location,		
			AltProdId,
			AltProdCode,
			AltProdDesc,
			AltQty,
			AltUOMId,
			AltUOMDesc,
			Removed)
	SELECT	b.value('@MasterBOMFormulationItemId', 'int'),
			b.value('@OriginGroup', 'nvarchar(255)') ,
			b.value('@ProdId', 'int'),
			b.value('@ProdCode', 'nvarchar(255)') ,
			b.value('@ProdDesc', 'nvarchar(255)'),
			b.value('@Qty', 'float'),
			b.value('@UOMId', 'int'),
			b.value('@UOMDesc', 'nvarchar(255)'),
			b.value('@ScrapFactor', 'float'),
			b.value('@PUId', 'int'),
			b.value('@Location', 'nvarchar(255)')	,
			b.value('@AltProdId', 'int'),
			b.value('@AltProdCode', 'nvarchar(255)'),
			b.value('@AltProdDesc', 'nvarchar(255)'),
			b.value('@AltQty', 'float'),
			b.value('@AltUOMId', 'int'),
			b.value('@AltUOMDesc', 'nvarchar(255)'),
			b.value('@Removed', 'nvarchar(255)')
	FROM	@xml.nodes('/BOMFormulation/BOMFormulationItems/BOMFormulationItem') as a(b) 

	UPDATE	@tMasterBOMFormulationItems 
	SET		MasterBOMFormulationItemId = Null 
	WHERE	MasterBOMFormulationItemId = 0

	SELECT	@BOMFormulationId		= tbomf.BOMFormulationId,
			@BOMFormulationCode		= tbomf.BOMFormulationCode,
			@BOMFormulationDesc		= tbomf.BOMFormulationDesc,
			@BOMId					= tbomf.BOMId,
			@CommentId				= tbomf.CommentId,
			@Comment				= tbomf.Comment,
			@EffectiveDate			= convert(datetime,tbomf.EffectiveDate,121),
			@UOMId					= tbomf.UOMId,
			@UOMDesc				= tbomf.UOMDesc,
			@ExpirationDate			= convert(datetime,tbomf.ExpirationDate,121),
			@QuantityPrecision		= tbomf.QuantityPrecision,
			@StandardQuantity		= tbomf.StandardQuantity,
			@UserName				= tbomf.UserName
			FROM	@tMasterBOMFormulation tbomf

	SELECT	@ErrCode = 0,
			@ErrMessage = 'No Error'

	-- Validations
	SELECT	@UserId = Null
	SELECT	@UserId = ub.User_Id
	FROM	dbo.Users_Base ub WITH (NOLOCK)
	WHERE	ub.Username = @UserName
	

	IF @UserId is Null
	BEGIN
		SELECT	@UserId = ub.User_Id
		FROM	dbo.Users_Base ub WITH (NOLOCK)
		WHERE	ub.Username = 'comxclient'
	END

	IF @UserId is Null
	BEGIN
		SELECT	@ErrCode = -100,
				@ErrMessage = 'Invalid User'
		GOTO	EXITPROC
	END

	SELECT	@MasterBOMFamilyId = Null
	SELECT	@MasterBOMFamilyId = f.BOM_Family_Id
	FROM	dbo.Bill_Of_Material_Family f WITH (NOLOCK)
	WHERE	f.BOM_Family_Desc = @DefaultBOMFamilyDesc

	IF @MasterBOMFamilyId is Null
	BEGIN
		SELECT	@ErrCode = -200,
				@ErrMessage = 'Invalid BOM Family'
		GOTO	EXITPROC
	END

	SELECT	@MasterBOMId	= Null
	SELECT	@MasterBOMId	= bom.BOM_Id
	FROM	dbo.Bill_Of_Material bom WITH (NOLOCK)
	WHERE	bom.BOM_Desc		= @DefaultBOMDesc
	and		bom.BOM_Family_Id	= @MasterBOMFamilyId

	IF @MasterBOMId is Null
	BEGIN
		SELECT	@ErrCode = -300,
				@ErrMessage = 'Invalid BOM'
		GOTO	EXITPROC
	END

	SELECT	@UOMId = Null
	SELECT	@UOMId = eu.Eng_Unit_Id
	FROM	dbo.Engineering_Unit eu WITH (NOLOCK)
	WHERE	eu.Eng_Unit_Desc = @UOMDesc

	IF @UOMId is Null
	BEGIN
		SELECT	@ErrCode = -400,
				@ErrMessage = 'Invalid Eng Unit'
		GOTO	EXITPROC
	END


	SELECT	@ProdId		= Null
	SELECT	@ProdId		= p.Prod_Id
	FROM	dbo.products_base p WITH (NOLOCK)
	WHERE	p.prod_code = @BOMFormulationDesc

	IF @ProdId is Null
	BEGIN
		SELECT	@ErrCode = -500,
				@ErrMessage = 'BOM Formulation Description should Match Product Code'
		GOTO	EXITPROC
	END

	--Find whether BOM Formulation Exists
	SELECT	@MasterBOMFormulationId = Null
	SELECT	@MasterBOMFormulationId = bomfor.BOM_Formulation_Id
	FROM	dbo.Bill_Of_Material_Formulation bomfor WITH (NOLOCK)
	join	dbo.Bill_Of_Material bom				WITH (NOLOCK) on bomfor.BOM_Id = bom.BOM_Id
	join	dbo.Bill_Of_Material_Family bomf		WITH (NOLOCK) on bom.BOM_Family_Id = bomf.BOM_Family_Id
	WHERE	bomfor.BOM_Formulation_Desc = @BOMFormulationDesc
	and		bom.BOM_Id = @MasterBOMId
	and		bomf.BOM_Family_Id = @MasterBOMFamilyId

	--Create or Update BOM Formulation
	EXECUTE @RC = [dbo].[spEM_BOMSaveFormulation] 
			@MasterBOMId,
			@EffectiveDate,
			@ExpirationDate,
			@StandardQuantity,
			@QuantityPrecision,
			@UOMId,
			@Comment,
			Null,
			@UserId,
			@BOMFormulationDesc,
			@MasterBOMFormulationId OUTPUT

	IF @RC < 0
	BEGIN
		SELECT	@ErrCode	= -600,
				@ErrMessage = 'Failed to execute spEM_BOMSaveFormulation. Error: ' + convert(varchar(50), @RC)
		GOTO	EXITPROC
	END		
	
	--	Deal with Formulation Items
	--	Find Existing Formulation Items matching the input data
	UPDATE	tbd
	SET		tbd.MasterBOMFormulationItemId	= bomfi.BOM_Formulation_Item_Id
	FROM	@tMasterBOMFormulationItems tbd
	join	dbo.Bill_Of_Material_Formulation_Item bomfi on tbd.ProdId = bomfi.Prod_id 
	and		bomfi.BOM_Formulation_Id = @MasterBOMFormulationId

	-- Loop Through Formulation Items
	SELECT @ii = Null
	SELECT @ii =		min (id) FROM @tMasterBOMFormulationItems
	IF ISNULL(@ii,0) > 0
	WHILE @ii <=	(select max(id) FROM @tMasterBOMFormulationItems)
	BEGIN
		SELECT	@User					=	@UserId,
				@alias					=	null,
				@usecomponents			=	0,
				@scrap					=	tbmd.ScrapFactor,
				@qty					=	tbmd.Qty,
				@altqty					=	tbmd.AltQty,
				@qtyprec				=	2,
				@lowert					=	Null,
				@uppert					=	Null,
				@ltprec					=	0,
				@utprec					=	0,
				@Comment				=	'',
				@eu						=	tbmd.UOMId,
				@alteu					=	tbmd.AltUOMId,
				@Unit					=	tbmd.PUId,
				@Location				=	Null,--tbmd.Location,
				@Formulation			=	@MasterBOMFormulationId,
				@Lot					=	Null,
				@Product				=	tbmd.ProdCode,
				@AltProdId				=	tbmd.AltProdId,
				@BOMFormulationItemId	=	tbmd.MasterBOMFormulationItemId,
				@Removed				=	tbmd.Removed
		FROM	@tMasterBOMFormulationItems tbmd
		WHERE	tbmd.id = @ii

		-- Find whether item to be deleted
		IF upper(IsNUll(@Removed,'False')) = 'TRUE'
		BEGIN
			IF IsNull(@BOMFormulationItemId,0) <> 0 -- formulation Item Exists
			BEGIN
				--delete substitutions
				DELETE 
				FROM	dbo.Bill_Of_Material_Substitution
				WHERE	BOM_Formulation_Item_Id = @BOMFormulationItemId
				
				-- delete BOM Formulation Item
				DELETE 
				FROM	dbo.Bill_Of_Material_Formulation_Item
				WHERE	BOM_Formulation_Item_Id = @BOMFormulationItemId
			END
		END
		ELSE
		BEGIN		
			-- Create/update Formulation Item		
			EXECUTE	@RC = [dbo].[spEM_BOMSaveFormulationItem] 
					@User,
					@Alias,
					@UseComponents,
					@Scrap,
					@qty,
					@qtyprec,
					@lowert,
					@uppert,
					@ltprec,
					@utprec,
					@Comment,
					@eu,
					@Unit,
					@Location,
					@Formulation,
					@Lot,
					@Product,
					@BOMFormulationItemId OUTPUT
			
			IF @RC < 0
			BEGIN
				SELECT	@ErrCode	= -700,
						@ErrMessage = 'Failed to execute spEM_BOMSaveFormulationItem. Error: ' + convert(varchar(50), @RC)
				GOTO	EXITPROC
			END
		
		
			--substitutions	

			--2020-02-05 Delete all existing Substitutions regardless whther we have substitution or not
			--2020-01-07
			-- limit to single substitution per BOM Formulation Item
			--delete all existing substitutions
			DELETE	FROM dbo.Bill_Of_Material_Substitution
			WHERE	BOM_Formulation_Item_Id = @BOMFormulationItemId


			SELECT	@Conversion = 1,
					@Order = -1,				
					@BOMSubstituationId = Null


		
			IF (@AltProdId <> 0) and (@alteu <> 0)
			BEGIN
				/*
				IF exists (	SELECT	euc.Slope
							FROM	dbo.Engineering_Unit_Conversion euc
							WHERE	euc.From_Eng_Unit_Id	= @eu
							and		euc.To_Eng_Unit_Id		= @alteu)
				BEGIN
					SELECT	@Conversion = euc.Slope
					FROM	dbo.Engineering_Unit_Conversion euc WITH (NOLOCK)
					WHERE	euc.From_Eng_Unit_Id	= @eu
					and		euc.To_Eng_Unit_Id		= @alteu
				END
				select @Conversion as conversion 

				-- 1.6			05-Feb-2020
				IF (IsNull(@altqty,0) <> 0) and (IsNull(@qty,0) <> 0) and (IsNull(@Conversion,0) <> 0)
				BEGIN
					--SELECT @Conversion = @Conversion * @qty/@altqty
					SELECT @Conversion = @Conversion * @altqty/@qty
					--SELECT   @Conversion = (1/@Conversion) * @altqty/@qty
				END
				*/
				SELECT @Conversion = @Conversion * @altqty/@qty
				
				/*				
				--2020-01-07
				-- limit to single substitution per BOM Formulation Item
				--delete all existing substitutions
				DELETE	FROM dbo.Bill_Of_Material_Substitution
				WHERE	BOM_Formulation_Item_Id = @BOMFormulationItemId
				*/
				/*
				--Find existing Substitution
				SELECT	@BOMSubstituationId = boms.BOM_Substitution_Id
				FROM	dbo.Bill_Of_Material_Substitution boms with (nolock)
				WHERE	boms.BOM_Formulation_Item_id = @BOMFormulationItemId and boms.Prod_Id = @AltProdId

				-- delete existing substitustion
				IF @BOMSubstituationId is Not Null
				BEGIN
					DELETE	FROM dbo.Bill_Of_Material_Substitution
					WHERE	BOM_Substitution_Id = @BOMSubstituationId
				END
				*/

				SELECT @BOMSubstituationId = Null
					
				EXECUTE @RC = [dbo].[spEM_BOMSaveSubstitution] 
						@BOMFormulationItemId,
						@Conversion, 
						@alteu,
						@Order,
						@AltProdId,
						@BOMSubstituationId   OUTPUT

				IF @RC < 0
				BEGIN
					SELECT	@ErrCode	= -800,
							@ErrMessage = 'Failed to execute spEM_BOMSaveSubstitution. Error: ' + convert(varchar(50), @RC)
					GOTO	EXITPROC
				END
			END
		END
		-- next BOM Formulation Item
		SELECT @ii = @ii + 1
	END

	
	EXITPROC:


		SELECT	bomfor.BOM_Formulation_Id			as	BOM_Formulation_Id,
				bomfor.BOM_Formulation_Desc			as	BOM_Formulation_Desc,	
				bomfor.BOM_Id						as	BOM_Id,
				bomfor.Comment_Id					as	Comment_Id,
				c.Comment							as	Comment,
				bomfor.Effective_Date				as	Effective_Date,
				bomfor.Eng_Unit_Id					as	Eng_Unit_Id,
				eu.Eng_Unit_Desc					as	Eng_Unit_Desc,
				bomfor.Expiration_Date				as	Expiration_Date,
				bomfor.Quantity_Precision			as	Quantity_Precision,
				bomfor.Standard_Quantity			as	Standard_Quantity			
	FROM		dbo.Bill_Of_Material_Formulation bomfor with (nolock)
	join		dbo.Engineering_Unit eu WITH (NOLOCK) on bomfor.Eng_Unit_Id = eu.Eng_Unit_Id
	left join	dbo.Comments c WITH (NOLOCK) on bomfor.Comment_Id = c.Comment_Id
	WHERE		bomfor.BOM_Formulation_Id = @MasterBOMFormulationId

	SELECT		bomfi.BOM_Formulation_Id		as	BOM_Formulation_Id,
				bomfi.BOM_Formulation_Item_Id	as	BOM_Formulation_Item_Id,
				bomfi.BOM_Formulation_Order		as	BOM_Formulation_Order,
				bomfi.Comment_Id				as	Comment_Id,
				bomfi.Eng_Unit_Id				as	Eng_Unit_Id,
				eu.Eng_Unit_Desc				as	Eng_Unit_Desc,
				bomfi.Location_Id				as	Location_Id,
				bomfi.Lot_Desc					as	Lot_Desc,
				bomfi.Prod_Id					as	Prod_Id,
				p.Prod_Code						as	Prod_Code,
				p.Prod_Desc						as	Prod_Desc,
				bomfi.PU_Id						as	PU_Id,
				bomfi.Quantity					as	Quantity,
				bomfi.Quantity_Precision		as	Quantity_Precision,
				bomfi.Scrap_Factor				as	Scrap_Factor,
				boms.BOM_Substitution_Id		as	BOM_Substitution_Id,
				boms.BOM_Substitution_Order		as	BOM_Substitution_Order,
				boms.Conversion_Factor			as	Conversion_Factor,
				boms.Prod_Id					as	Alt_Prod_Id,
				p1.Prod_Code					as	Alt_Prod_Code,
				p1.Prod_Desc					as	Alt_Prod_Desc,	
				boms.Eng_Unit_Id				as	Alt_Eng_Unit_Id,
				eu1.Eng_Unit_Desc				as	Alt_Eng_Unit_Desc
	FROM		dbo.Bill_Of_Material_Formulation_Item bomfi
	join		dbo.Products_Base p WITH (NOLOCK) on bomfi.prod_id = p.prod_id
	join		dbo.Engineering_Unit eu WITH (NOLOCK) on bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
	left join	dbo.Bill_Of_Material_Substitution boms WITH (NOLOCK) on bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
	left join	dbo.products_base p1 WITH (NOLOCK) on boms.Prod_Id = p1.Prod_Id
	left join	dbo.Engineering_Unit eu1 WITH (NOLOCK) on boms.Eng_Unit_Id = eu1.Eng_Unit_Id
	WHERE		bomfi.BOM_Formulation_Id = @MasterBOMFormulationId
		
RETURN
SET NOCOUNT OFF