 
 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetProcessOrderDetails]
		@Action			INT				= NULL,
		@PPId			INT				= NULL,
		@ProcessOrder	VARCHAR(255)	= NULL,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
AS	
-------------------------------------------------------------------------------
-- Get PO details
/*
declare @e int, @m varchar(255)
exec  spLocal_MPWS_GENL_GetProcessOrderDetails null, 390775, null, @e output, @m output
select @e, @m
 
declare @e int, @m varchar(255)
exec  spLocal_MPWS_GENL_GetProcessOrderDetails null, null, '20151112083038', @e output, @m output
select @e, @m
 
*/
-- Date         Version Build Author  
-- 13-Nov-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE	@tFeedback			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ErrorCode				INT									NULL,
	ErrorMessage			VARCHAR(255)						NULL
)
DECLARE	@tPO1				TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	BOMFIId					INT									NULL,
	MAXBOMFOrder			INT									NULL
)
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		= 1,
		@ErrorMessage	= 'Success'
-------------------------------------------------------------------------------
-- Find products associated with the passed PU
-------------------------------------------------------------------------------
IF	@PPId IS NOT NULL
		INSERT	@tPO1 (BOMFIId)
				SELECT	BOM_Formulation_Id
						FROM	dbo.Production_Plan		WITH (NOLOCK)
						WHERE	PP_Id = @PPId	
ELSE
		INSERT	@tPO1 (BOMFIId)
				SELECT	BOM_Formulation_Id
						FROM	dbo.Production_Plan		WITH (NOLOCK)
						WHERE	Process_Order = @ProcessOrder	
						
IF		@@ROWCOUNT	= 0
BEGIN
		SELECT	@ErrorCode		= -1,
				@ErrorMessage	= 'Process Order Not Found'
		GOTO	ReturnData		
END
							
IF	EXISTS (SELECT	Id
					FROM	@tPO1
					WHERE	BOMFIId	IS NULL)
					
BEGIN
		SELECT	@ErrorCode		= -2,
				@ErrorMessage	= 'Process Order without BOM Formulation'
		GOTO	ReturnData		
END
 
UPDATE	T
		SET	T.MAXBOMFOrder	= S.MaxBOMFOrder
			FROM	@tPO1 T
			JOIN	(SELECT MAX(BOM_Formulation_Order) MaxBOMFOrder, BOM_Formulation_Id  BOMFIId
							FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI		WITH (NOLOCK)
							GROUP
							BY		BOMFI.BOM_Formulation_Id) S
			ON		T.BOMFIId = S.BOMFIId
		
ReturnData:
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	Id				Id,
		BOMFIId			BOMFIId,
		MAXBOMFOrder	MAXBOMFOrder
		FROM	@tPO1
		ORDER
		BY		Id
		
 
 
 
 
 
 
 
