 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetInitialParameters]
		@SecurityGroup			VARCHAR(255),
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT	
AS	
-------------------------------------------------------------------------------
-- Get initial information for the Planning display
/*
exec  spLocal_MPWS_PLAN_GetInitialParameters 'Pre-Weigh01-Area'
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
	PathId					INT									NULL,
	PathCode				VARCHAR(255)						NULL,
	DefaultPOPriority		INT									NULL
)	
 
DECLARE	@ClassName			VARCHAR(255)	
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Find PA Department, production line and execution path for the SOA production
-- line associated to the passed in LDAP security group via the 
-- 'Pre-Weigh.PLAN' property
-------------------------------------------------------------------------------		
INSERT	@tOutput	(DeptId, DeptDesc, PLId, PLDesc, PathId, PathCode)				
		SELECT	D.Dept_Id, D.Dept_Desc, PL.PL_Id, PL.PL_Desc, PA.Path_Id, 
				PA.Path_Code 				
				FROM	dbo.Property_Equipment_EquipmentClass PEC	WITH(NOLOCK) 
				JOIN	dbo.PAEquipment_Aspect_SOAEquipment PAS		WITH(NOLOCK)
				ON		PEC.EquipmentId	= PAS.Origin1EquipmentId
				AND		PEC.Name						 = 'Security Group'
				AND		CONVERT(VARCHAR(255), PEC.Value) = 		@SecurityGroup
				JOIN	dbo.Prod_Lines_Base PL							WITH (NOLOCK)
				ON		PL.PL_Id						 = PAS.PL_Id
				JOIN	dbo.Departments_Base D							WITH (NOLOCK)
				ON		D.Dept_Id						 = PL.Dept_Id
				JOIN	dbo.Prdexec_Paths PA						WITH (NOLOCK)
				ON		PL.PL_Id						 = PA.PL_Id
			
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
------------------------------------------------------------------------------
--  GET SiteWide class name
------------------------------------------------------------------------------
EXEC	dbo.spLocal_MPWS_GENL_GetSiteProperty NULL,NULL, 
		@ClassName OUTPUT,  'Class Names.SiteWide'	
-------------------------------------------------------------------------------	
-- Get preweigh-wide properties
-------------------------------------------------------------------------------	
UPDATE	@tOutput
		SET	DefaultPOPriority				= CONVERT(INT, PEEC.Value)
			FROM	dbo.Property_Equipment_EquipmentClass PEEC		WITH (NOLOCK)
			JOIN	dbo.EquipmentClass_EquipmentObject EEO			WITH (NOLOCK)
			ON		EEO.EquipmentId			= PEEC.EquipmentId
			AND		PEEC.Name				= 'Planning.Default Process Order Priority'
			AND		EEO.EquipmentClassName	=  @ClassName	
--select Top 10 * from EquipmentClass_EquipmentObject where EquipmentClassName='Pre-Weigh - SiteWide'
--select * from Equipment where EquipmentId ='A03B2252-9C90-41DF-A67A-920EB381783B'
--select * from Property_Equipment_EquipmentClass where EquipmentId  ='A03B2252-9C90-41DF-A67A-920EB381783B' and Name = 'Planning.Default Process Order Priority'
 
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
		PathId					PathId,
		PathCode				PathCode,
		DefaultPOPriority		DefaultPOPriority
		FROM	@tOutput
		ORDER
		BY		Id
 
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_PLAN_GetInitialParameters] TO [public]
 
 
 
 
