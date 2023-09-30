 
 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_INVN_GetInitialParameters]
		@SecurityGroup			VARCHAR(255),
		@ErrorCode				INT				OUTPUT,
		@ErrorMessage			VARCHAR(255)	OUTPUT	
AS	
-------------------------------------------------------------------------------
-- Get initial information for the Inventory display
/*
exec  spLocal_MPWS_INVN_GetInitialParameters 'Pre-Weigh01-Area'
*/
-- Date         Version Build Author  
-- 24-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
--DECLARE	@tFeedback			TABLE
--(
--	Id						INT					IDENTITY(1,1)	NOT NULL,
--	ErrorCode				INT									NULL,
--	ErrorMessage			VARCHAR(255)						NULL
--)
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	DeptId					INT									NULL,
	DeptDesc				VARCHAR(255)						NULL,
	PLId					INT									NULL,
	PLDesc					VARCHAR(255)						NULL,
	PUId					INT									NULL,
	PUDesc					VARCHAR(255)						NULL,
	DefaultLocId			INT									NULL,
	DefaultLocDesc			VARCHAR(255)						NULL
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
		@ClassName OUTPUT,  'Class Names.Receiving'	
-------------------------------------------------------------------------------
-- Find PA Department, production line and execution path for the SOA production
-- line associated to the passed in LDAP security group via the 
-- 'Pre-Weigh.PLAN' property
-------------------------------------------------------------------------------		
INSERT	@tOutput	(DeptId, DeptDesc, PLId, PLDesc, PUId, PUDesc)				
		SELECT	D.Dept_Id, D.Dept_Desc, PL.PL_Id, PL.PL_Desc, PU.PU_Id,
				PU.PU_Desc 				
				FROM	dbo.Property_Equipment_EquipmentClass PEC	WITH(NOLOCK) 
				JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH(NOLOCK)
				ON		PEC.EquipmentId					= PAS.Origin1EquipmentId
				AND		PEC.Name						= 'Security Group'
				AND		CONVERT(VARCHAR(255), PEC.Value)= 		@SecurityGroup
				JOIN	dbo.Prod_Lines_Base PL							WITH (NOLOCK)
				ON		PL.PL_Id						= PAS.PL_Id
				JOIN	dbo.Departments_Base D							WITH (NOLOCK)
				ON		D.Dept_Id						= PL.Dept_Id
				JOIN	dbo.Prod_Units_Base PU							WITH (NOLOCK)
				ON		PL.PL_Id						= PU.PL_Id
				JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS2	WITH(NOLOCK)
				ON		PU.PU_Id						=  PAS2.PU_Id
				JOIN	dbo.EquipmentClass_EquipmentObject EE		WITH (NOLOCK)
				ON		EE.EquipmentId					= PAS2.Origin1EquipmentId
				AND		EE.EquipmentClassName			= @ClassName
									
IF		@@ROWCOUNT	> 0
 
		SELECT	@ErrorCode = 1,
				@ErrorMessage = 'Success'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (1, 'Success')
ELSE
		SELECT	@ErrorCode = -1,
				@ErrorMessage = 'Pre Weigh Area Not Found for Security Group: ' + @SecurityGroup
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-1, 'Pre Weigh Area Not Found for Security Group: ' + @SecurityGroup)
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
/*SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback*/
		
SELECT	Id						Id,
		DeptId					DeptId,
		DeptDesc				DeptDesc,
		PLId					PLId,
		PLDesc					PLDesc,
		PUId					PUId,
		PUDesc					PUDesc,
		DefaultLocId			DefaultLocId,
		DefaultLocDesc			DefaultLocDesc
		FROM	@tOutput
		ORDER
		BY		Id
 
 
-- GRANT EXECUTE ON [dbo].[spLocal_MPWS_INVN_GetInitialParameters] TO [public]
 
 
 
 
 
