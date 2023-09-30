 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetStatusList]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@PathId			INT,
	@AllFlag		INT=0
	
AS	
-------------------------------------------------------------------------------
-- Get valid status for Kitting Stations
/*
declare @errorcode int, @errormessage varchar(500)
exec  spLocal_MPWS_KIT_GetStatusList @errorcode output, @errormessage output, 29
select @errorcode, @errormessage
*/
-- Date         Version Build Author  
-- 20-Jun-2016	001     001   Chris Donnelly (GE Digital)  Initial development	
-- 08-Feb-2017	001		002		Jim Cameron (GE Digital)	Added @ErrorCode and @ErrorMessage OUTPUT params to standardize
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
				
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	StatusId				INT									NULL,
	StatusDesc				VARCHAR(255)						NULL,
	IsDefault				BIT									NOT NULL DEFAULT 0
)	
 
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
 
SELECT
	@ErrorCode	= 1,
	@ErrorMessage = 'Success';
	
-------------------------------------------------------------------------------
-- Get the configured status transitions for the passed in path and get their
-- distinct 'FROM' status 
-------------------------------------------------------------------------------	
INSERT	@tOutput (StatusId, StatusDesc, IsDefault)
	SELECT DISTINCT
			ps.ProdStatus_Id,
			ps.ProdStatus_Desc, 
			ISNULL(px.Is_Default_Status,0)
		FROM dbo.[Events] e
			Join Prod_Units pu on pu.PU_ID = e.PU_Id
			JOIN dbo.PrdExec_Status px	WITH (NOLOCK) on pu.PU_Id = px.PU_Id
			JOIN Production_Status ps on ps.ProdStatus_Id = px.Valid_Status
		WHERE pu.Equipment_Type = 'Kitting Station'
 
						
-------------------------------------------------------------------------------
-- Insert A 'ALL'  dummy  record   
-------------------------------------------------------------------------------							
		IF (@AllFlag =1)
		BEGIN				
		INSERT	@tOutput (StatusId,StatusDesc)
				VALUES (0,'ALL')						
		END
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
		
SELECT	--Id					Id,
		--StatusId			PPStatusId,
		StatusDesc			PPStatusDesc,
		IsDefault			IsDefault
		FROM	@tOutput
		ORDER
		BY		PPStatusDesc
 
 
 
 
 
