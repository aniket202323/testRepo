 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetLocationsByProductionUnit]
		@PUId			INT,
		@LocationId		INT	= NULL,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT,
		@AllFlag		INT =0 ,
		@LocationCode	VARCHAR(255) = NULL
 
		
AS	
 
-------------------------------------------------------------------------------
-- Get locations associated with the passed in production unit
/*
declare @ErrorCode int, @ErrorMessage varchar(50)
exec  spLocal_MPWS_GENL_GetLocationsByProductionUnit 3379, 3,@ErrorCode output,@ErrorMessage output,0
select @ErrorCode,@ErrorMessage
 
//exec  spLocal_MPWS_GENL_GetLocationsByProductionUnit 3379,null,@ErrorCode output,@ErrorMessage output
*/
-- Date         Version Build Author  
-- 14-Oct-2015  001     001   Alex Judkowicz (GEIP)  Initial development
-- 01-Jun-2017  001     002   Susan Lee (GE Digital) Added search by LocationCode	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
 
DECLARE @RowsFound INT
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	LocationId				INT									NULL,
	LocationCode			VARCHAR(255)						NULL,
	LocationDesc			VARCHAR(255)						NULL
)
-------------------------------------------------------------------------------
--  Initialize error codes
-------------------------------------------------------------------------------
SELECT @ErrorCode = -1	,
		@ErrorMessage = 'Initialized'
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
IF	 ( @LocationId	IS NULL OR	@LocationId = 0)
	AND
	( @LocationCode IS NULL OR @LocationCode = '')
BEGIN
		------------------------------------------------------------------------------
		-- Find locations associated with the passed PU
		-------------------------------------------------------------------------------		
		INSERT	@tOutput	(LocationId, LocationCode, LocationDesc)
				SELECT	Location_Id, Location_Code, Location_Desc
						FROM	dbo.Unit_Locations				WITH (NOLOCK)
						WHERE	PU_Id			= @PUId
						ORDER
						BY		Location_Code
						
		SELECT	@ErrorCode = 1,
				@ErrorMessage = 'Success'
								
END
ELSE
BEGIN
		------------------------------------------------------------------------------
		-- Find if passed location exists for passed PU
		-------------------------------------------------------------------------------	
		
		IF  (@LocationId	IS NULL OR	@LocationId = 0)	
		BEGIN
			------   Search by Location Code ------------------
			INSERT	@tOutput	(LocationId, LocationCode, LocationDesc)
			SELECT	Location_Id, Location_Code, Location_Desc
					FROM	dbo.Unit_Locations				WITH (NOLOCK)
					WHERE	PU_Id			= @PUId
					AND		Location_Code		= @LocationCode
			SET @RowsFound = @@ROWCOUNT
		END
		ELSE
		BEGIN
			------ Search By Location Id -------------------
			INSERT	@tOutput	(LocationId, LocationCode, LocationDesc)
					SELECT	Location_Id, Location_Code, Location_Desc
							FROM	dbo.Unit_Locations				WITH (NOLOCK)
							WHERE	PU_Id			= @PUId
							AND		Location_Id		= @LocationId
			SET @RowsFound = @@ROWCOUNT
		END
 
		-------  Set eror code and message -------------
		IF	@RowsFound		> 0
			SELECT	@ErrorCode = 1,
					@ErrorMessage = 'Success'
		ELSE
			SELECT	@ErrorCode = -1,
					@ErrorMessage = 'Location not found for production unit'
 
END		
 
-------------------------------------------------------------------------------
-- Insert A 'ALL'  dummy  record   
-------------------------------------------------------------------------------							
		IF (@AllFlag =1)
		BEGIN			
		INSERT	@tOutput (LocationId,LocationCode,LocationDesc)
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
		LocationId				LocationId,
		LocationCode			LocationCode,
		LocationDesc			LocationDesc
		FROM	@tOutput
		ORDER
		BY		Id DESC
 
 --GRANT EXECUTE ON [dbo].[spLocal_MPWS_GENL_GetLocationsByProductionUnit] TO [public]
 
 
 
 
 
