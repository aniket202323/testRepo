 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetRMContainersByDispStationAndMaterial]
		@ErrorCode					INT				OUTPUT,
		@ErrorMessage				VARCHAR(500)	OUTPUT,
		@DispenseStationId			INT,				-- dispense station PU Id
		@Material					VARCHAR(50)			-- product code
AS	
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Returns a list of raw material container events for the specified material and in 
-- the receiving area for the dispense station preweigh area with the status of "Checked In"
-- and final weight of greater than zero.
 
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetRMContainersByDispStationAndMaterial @ErrorCode OUTPUT, @ErrorMessage OUTPUT,4317,'10045237'
select @ErrorCode, @ErrorMessage
 
 
*/
-- Date				Version		Build	Author  
-- 06-June-2016		001			001		Susan Lee(GE Digital)  Initial development
-- 10-May-2017		001			002		Susan Lee(GE Digital)	Changed "Inventory" status to "Checked In"
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
-- for checking ifix without being able to run profiler
--INSERT dbo.Local_Debug ([Timestamp],[CallingSP],[Message],[Msg])
--	VALUES (GETDATE(), 'spLocal_MPWS_DISP_GeRMContainersByDispStationAndMaterial', '@DispenseStationId=' + CAST(ISNULL(@DispenseStationId, '*NULL*') AS VARCHAR(8)) + ', @Material=' + ISNULL(@Material, '*NULL*'), '');
 
DECLARE	@tOutput	TABLE
	(
	Id						INT			IDENTITY(1,1),
	RMCNumber				VARCHAR(50)
	)
 
DECLARE	@ReceivingPUId	INT	,
		@ProdId			INT
 
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
 
SELECT	@ErrorCode		=	0,
		@ErrorMessage	=	'Initialized'
		
-------------------------------------------------------------------------------
-- Validate Parameters
-------------------------------------------------------------------------------
 
-------------------------------------------------------------------------------
--Get receiving unit PU Id
-------------------------------------------------------------------------------
SELECT	@ReceivingPUId	= r_pu.PU_Id
FROM	dbo.Prod_Units_Base	d_pu	WITH (NOLOCK)
JOIN	dbo.Prod_Units_Base	r_pu	WITH (NOLOCK)
	ON		r_pu.PL_Id = d_pu.PL_Id
WHERE	r_pu.PU_Desc like '%Receiving%'
	AND d_pu.PU_Id = @DispenseStationId  --3372
 
-------------------------------------------------------------------------------
--Get Prod Id
-------------------------------------------------------------------------------
SELECT	@ProdId		=	Prod_Id
FROM	dbo.Products_Base	WITH (NOLOCK)
Where	Prod_Code	=	@Material
 
--------------------------------------------------------------------------------
-- Get valid raw material container events
-- must be in the same production line as the dispense unit
-- must have "Checked In" status
-- must have weight > 0
--------------------------------------------------------------------------------
INSERT INTO @tOutput
SELECT	e.Event_Num--,e.Event_Id,p.prod_code, ps.ProdStatus_Desc,ps.ProdStatus_Id,ed.Initial_Dimension_X,ed.final_dimension_x 
FROM	dbo.[Events]		e	WITH (NOLOCK)
JOIN	Products_Base			p	WITH (NOLOCK)
	ON		p.Prod_Id			=	e.Applied_Product 
JOIN	Event_Details		ed	WITH (NOLOCK)
	ON		ed.Event_Id			=	e.Event_Id
JOIN	Production_Status	ps	WITH (NOLOCK) 
	ON		ps.ProdStatus_Id	=	e.Event_Status
WHERE	e.PU_Id = @ReceivingPUId 
	AND ps.ProdStatus_Desc = 'Checked In'
	AND ed.final_dimension_x > 0
	AND	e.Applied_Product = @ProdId
	
-------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
SELECT	@ErrorCode=1,
		@ErrorMessage = 'Success'
 
SELECT	RMCNumber	AS	RawMaterialContainer
FROM	@tOutput
ORDER BY RMCNumber
		
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_DISP_GeRMContainersByDispStationAndMaterial] TO [public]
 
 
 
 
 
