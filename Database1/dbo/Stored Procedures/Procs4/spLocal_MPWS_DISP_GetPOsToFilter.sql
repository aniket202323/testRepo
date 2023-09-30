 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetPOsToFilter]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@Statuses		VARCHAR(255)			,	-- comma delimited list of statuses
		@PathId			INT			-- = 29			
AS	
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Get list of process orders in passed in statuses
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetPOsToFilter @ErrorCode, @ErrorMessage,'Released,Dispensing',29
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 06-Oct-2015  001     001   Susan Lee (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
DECLARE		@ProcessOrders			TABLE
(
	PPId			INT,
	ProcessOrder	VARCHAR(50)
)
 
DECLARE		@tStatus				TABLE
(
	Id				INT	IDENTITY(1,1)	NOT NULL	,
	Status			VARCHAR(255)		NULL
)
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	0,
		@ErrorMessage	=	'Initialized'
		
-------------------------------------------------------------------------------
-- Parse status
-------------------------------------------------------------------------------
 
INSERT @tStatus (Status)
SELECT *
FROM dbo.fnLocal_CmnParseListLong(@Statuses,',')
 
-------------------------------------------------------------------------------
-- <Actions>
-------------------------------------------------------------------------------
INSERT INTO	@ProcessOrders
 
SELECT	pp.PP_Id			,
		pp.Process_Order	
FROM	Production_Plan				pp	WITH (NOLOCK) 
JOIN	Production_Plan_Statuses	pps	WITH (NOLOCK)
	ON	pp.PP_Status_Id = pps.PP_Status_Id
JOIN	@tStatus					s
	ON	s.Status		= pps.PP_Status_Desc
WHERE	pp.Path_Id		= @PathId
 
-------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
SELECT
		PPId			AS	POId	,
		ProcessOrder	AS	ProcessOrder	
FROM	@ProcessOrders
ORDER BY ProcessOrder
 
 
 
 
 
 
 
