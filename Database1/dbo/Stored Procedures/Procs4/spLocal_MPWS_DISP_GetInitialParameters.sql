 
 
 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetInitialParameters]
		@ErrorCode				INT				OUTPUT,
		@ErrorMessage			VARCHAR(255)	OUTPUT,
		@ClientName				VARCHAR(255)	-- ClientName property of the dispense station equipment property
AS	
-------------------------------------------------------------------------------
-- Get initial information for the dispense display
/*
declare @e int, @m varchar(255)
exec  spLocal_MPWS_DISP_GetInitialParameters @e output, @m output, 'PW01DS01'
select @e, @m
 
*/
-- Date         Version Build Author  
-- 20-Nov-2015  001     001   Alex Judkowicz (GEIP)		Initial development
-- 12-May-2017  001		002	  Susan Lee (GE Digital)	Filter properties by equipment	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	DeptId					INT									NULL,
	DeptDesc				VARCHAR(255)						NULL,
	PLId					INT									NULL,
	PLDesc					VARCHAR(255)						NULL,
	PUId					INT									NULL,
	PUDesc					VARCHAR(255)						NULL,
	PathId					INT									NULL,
	PathCode				VARCHAR(255)						NULL,	
	DefaultLocId			INT									NULL,
	DefaultLocDesc			VARCHAR(255)						NULL,
	DispenseType			VARCHAR(50)							NULL,
	DispensePO				VARCHAR(50)							NULL,
	DispenseMaterial		VARCHAR(50)							NULL
)
 
DECLARE	@DefaultLocDesc		VARCHAR(255),
		@DefaultLocId		INT,
		@ClassName			VARCHAR(255)
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  GET SiteWide class name
------------------------------------------------------------------------------
EXEC	dbo.spLocal_MPWS_GENL_GetSiteProperty NULL,NULL, 
		@ClassName OUTPUT,  'Class Names.Dispense'	
-------------------------------------------------------------------------------
-- Find PA Department, production line and execution path for the SOA production
-- line associated to the passed in client Id
-------------------------------------------------------------------------------	
INSERT	@tOutput	(DeptId, DeptDesc, PLId, PLDesc, PUId, PUDesc, PathId, PathCode)
		SELECT	D.Dept_Id, D.Dept_Desc, PL.PL_Id, PL.PL_Desc, PU.PU_Id,
				PU.PU_Desc, PPA.Path_Id, PPA.Path_Code 	
				FROM	dbo.Property_Equipment_EquipmentClass PEC	WITH(NOLOCK) 
				JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH(NOLOCK)
				ON		PEC.EquipmentId					= PAS.Origin1EquipmentId
				AND		PEC.Class						= @ClassName
				AND		PEC.Name						= 'ClientName'
				AND		CONVERT(VARCHAR(255), PEC.Value)= @ClientName
				JOIN	dbo.Prod_Units_Base PU							WITH (NOLOCK)
				ON		PU.PU_Id						= PAS.PU_Id
				JOIN	dbo.Prod_Lines_Base PL							WITH (NOLOCK)
				ON		PL.PL_Id						= PU.PL_Id
				JOIN	dbo.Departments_Base D							WITH (NOLOCK)
				ON		D.Dept_Id						= PL.Dept_Id
				JOIN	dbo.PrdExec_Paths PPA						WITH (NOLOCK)
				ON		PPA.PL_Id						= PL.PL_Id
					
IF		@@ROWCOUNT	> 0
BEGIN
		SELECT	@ErrorCode		= 1, 
				@ErrorMessage	 = 'Success'
		UPDATE	@tOutput
		SET		DispenseType = CONVERT(VARCHAR(255), PEC.Value)
		FROM	dbo.Property_Equipment_EquipmentClass PEC	WITH(NOLOCK) 
				JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH(NOLOCK)
				ON		PEC.EquipmentId					= PAS.Origin1EquipmentId
				AND		PEC.Class						= @ClassName
				AND		PEC.Name						= 'DispenseType'
				JOIN	dbo.Equipment E WITH (NOLOCK)
				ON		E.EquipmentId = PEC.EquipmentId
				AND		E.S95Id = @ClientName
		UPDATE	@tOutput
		SET		DispensePO = CONVERT(VARCHAR(255), PEC.Value)
		FROM	dbo.Property_Equipment_EquipmentClass PEC	WITH(NOLOCK) 
				JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH(NOLOCK)
				ON		PEC.EquipmentId					= PAS.Origin1EquipmentId
				AND		PEC.Class						= @ClassName
				AND		PEC.Name						= 'DispensePO'
				JOIN	dbo.Equipment E WITH (NOLOCK)
				ON		E.EquipmentId = PEC.EquipmentId
				AND		E.S95Id = @ClientName
		UPDATE	@tOutput
		SET		DispenseMaterial = CONVERT(VARCHAR(255), PEC.Value)
		FROM	dbo.Property_Equipment_EquipmentClass PEC	WITH(NOLOCK) 
				JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH(NOLOCK)
				ON		PEC.EquipmentId					= PAS.Origin1EquipmentId
				AND		PEC.Class						= @ClassName
				AND		PEC.Name						= 'DispenseMaterial'
				JOIN	dbo.Equipment E WITH (NOLOCK)
				ON		E.EquipmentId = PEC.EquipmentId
				AND		E.S95Id = @ClientName						
END				
ELSE
		SELECT	@ErrorCode		= -1, 
				@ErrorMessage	 = 'Equipment not associated for this client Name'
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	@DefaultLocId	= Location_Id,
		@DefaultLocDesc = Location_Code
		FROM	dbo.Unit_Locations		WITH (NOLOCK)
		WHERE	Location_Id = (SELECT	MIN(Location_Id)
										FROM	dbo.Unit_Locations UL		WITH (NOLOCK)
										JOIN	@tOutput T
										ON		UL.PU_Id = T.PUId)
UPDATE	@tOutput
		SET	DefaultLocId	= @DefaultLocId,
			DefaultLocDesc	= @DefaultLocDesc
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	Id						Id,
		DeptId					DeptId,
		DeptDesc				DeptDesc,
		PLId					PLId,
		PLDesc					PLDesc,
		PUId					PUId,
		PUDesc					PUDesc,
		PathId					PathId,
		PathCode				PathCode,
		DefaultLocId			DefaultLocId,
		DefaultLocDesc			DefaultLocDesc,
		DispenseType			DispenseType,
		DispenseMaterial		DispenseMaterial,
		DispensePO				DispensePO
		FROM	@tOutput
		ORDER
		BY		Id
 
 
-- GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_GetInitialParameters] TO [public]
 
 
 
 
 
 
