 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetMaterialGCASList]
		@PathId			INT,
		@PPStatusIdMask	VARCHAR(8000)= NULL,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT,
		@AllFlag		INT = 0
		
AS	
-------------------------------------------------------------------------------
-- Get finish good products of the process orders that belong to the passed in 
-- path and has one of the passed in PO statuses
/*
exec  spLocal_MPWS_PLAN_GetMaterialGCASList 14, '1,2,3,4,5,6,7,8,9','','',0
exec  spLocal_MPWS_PLAN_GetMaterialGCASList 14 
EXEC spLocal_MPWS_PLAN_GetProcessOrders 29, '','','PO14,PO12',1
 
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
 
DECLARE	@tPPStatusId		TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	PPStatusId				INT									NULL,
	PPStatusDesc			VARCHAR(255)						NULL
)				
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ProdId					INT									NULL,
	ProdCode				VARCHAR(50)							NULL,
	ProdDesc				VARCHAR(255)						NULL
)
 
DECLARE	@StatusCount		INT	
-------------------------------------------------------------------------------
--  Parse PP status id string and into a table variable and get their description
-------------------------------------------------------------------------------
INSERT	@tPPStatusId (PPStatusId)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@PPStatusIdMask,',')
 
SELECT	@StatusCount = @@ROWCOUNT		
		
IF		@StatusCount > 0		
		UPDATE	T
				SET	PPStatusDesc = PPS.PP_Status_Desc
					FROM	@tPPStatusId T
					JOIN	dbo.Production_Plan_Statuses PPS			WITH (NOLOCK)
					ON		T.PPStatusId = PPS.PP_Status_Id
------------------------------------------------------------------------------
--  Get process orders 
-------------------------------------------------------------------------------
IF		@StatusCount IS NULL
		OR	@StatusCount = 0
		------------------------------------------------------------------------------
		--  Get process orders for the passed in execution path and statuses
		-------------------------------------------------------------------------------	
		INSERT	@tOutput (ProdId, ProdCode, ProdDesc)
				SELECT	DISTINCT PP.Prod_Id, P.prod_Code, P.Prod_Desc
						FROM	dbo.Production_Plan PP				WITH (NOLOCK)
						JOIN	dbo.Products_Base P						WITH (NOLOCK)
						ON		PP.Prod_Id		= P.Prod_Id
						AND		PP.Path_Id		= @PathId
						ORDER
						BY		P.Prod_Code	
ELSE		
		------------------------------------------------------------------------------
		--  Get process orders for the passed in execution path and statuses
		-------------------------------------------------------------------------------
		INSERT	@tOutput (ProdId, ProdCode, ProdDesc)
				SELECT	DISTINCT PP.Prod_Id, P.prod_Code, P.Prod_Desc
						FROM	dbo.Production_Plan PP				WITH (NOLOCK)
						JOIN	dbo.Products_Base P						WITH (NOLOCK)
						ON		PP.Prod_Id		= P.Prod_Id
						AND		PP.Path_Id		= @PathId
						JOIN	@tPPStatusId S
						ON		PP.PP_Status_Id = S.PPStatusId
						ORDER
						BY		P.Prod_Code
 
IF		@@ROWCOUNT > 0	
		SELECT	@ErrorCode = 1,
				@ErrorMessage = 'Success'			
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (1, 'Success')
ELSE
		SELECT	@ErrorCode = -1,
				@ErrorMessage = 'Process Orders not found for this execution path and passed status'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-1, 'Process Orders not found for this execution path and passed status')
				
 -------------------------------------------------------------------------------
-- Insert A 'ALL'  dummy  record   
 -------------------------------------------------------------------------------							
		IF (@AllFlag =1)
		BEGIN				
		INSERT	@tOutput (ProdId,ProdCode,ProdDesc)
				VALUES (0,'ALL','ALL')
		END				
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
 
      
		
SELECT	Id						Id,
		ProdId					ProdId,
		ProdCode				ProdCode,
		ProdDesc				ProdDesc
		FROM	@tOutput
		ORDER
		BY		ProdCode  
 
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_PLAN_GetMaterialGCASList] TO [public]
 
 
 
 
