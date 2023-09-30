
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_GetPOsForUpdate
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 25-Oct-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: This Stored Procedue returns list of Process Orders for the PO Update Screen
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			06-Nov-2020		A.Metlitski				Original

/*---------------------------------------------------------------------------------------------
Testing Code

EXECUTE	[dbo].[spLocal_Util_GetPOsForUpdate]
-----------------------------------------------------------------------------------------------*/

--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetPOsForUpdate]
					@ErrorCode		int				OUTPUT,
					@ErrorMessage	nvarchar(1000)	OUTPUT,
					@PathId			int,
					@PPStatusId		int

					

--WITH ENCRYPTION
AS
	SET NOCOUNT ON

	DECLARE @PrmFieldDelimiter	varchar(1),
			@PrmRecordDelimiter varchar(1),
			@PrmDataType01		nvarchar(255)

	DECLARE	@tOutput TABLE(
			Id							int	identity (1,1),
			PPId						int,
			ProcessOrder				nvarchar(255))	

	DECLARE	@IncludeCollection nvarchar(max)
	DECLARE	@tInclude	table	(
			RcdId	int,
			Field01 nvarchar(255))

	SET @ErrorCode = 1
	SET @ErrorMessage = 'No Error'

	IF not exists(SELECT pex.Path_Id FROM dbo.PrdExec_Paths pex WHERE pex.Path_Id = @PathId)
	BEGIN
		SELECT	@ErrorCode		=	-1,
				@ErrorMessage	=	'Invalid Path Id=' + convert(varchar(255), IsNUll(@PathId,-911))
		GOTO	RETURNOUTPUT
	END

	IF IsNull(@PPStatusId,0) <> 0
	BEGIN
		-- Single PP Status Passed
		IF not exists(SELECT pps.PP_Status_Id FROM dbo.Production_Plan_Statuses pps  WHERE pps.PP_Status_Id = @PPStatusId)
		BEGIN
			-- Invalid Status
			SELECT	@ErrorCode		=	-1,
					@ErrorMessage	=	'Invalid Production Plan Status Id=' + convert(varchar(255), IsNUll(@PPStatusId,-911))
			GOTO	RETURNOUTPUT
		END
		ELSE
		BEGIN
			--Valid Status
			INSERT @tOutput	(
					PPId,
					ProcessOrder)
			SELECT	pp.PP_Id,
					pp.Process_Order
			FROM	dbo.production_plan pp WITH (NOLOCK)
			WHERE	pp.Path_Id		= @PathId
			and		pp.PP_Status_Id = @PPStatusId
			ORDER  BY pp.Process_Order
		END
	END
	ELSE
	BEGIN
		-- PpStatusId==0 passed. 
		SET		@IncludeCollection	=	'Error|Pending|Next|Active|Complete|Overproduced|Underproduced|Planning|Closing|Initiate|Ready|SAPComplete|Confirmed|ConfirmToSAP|Initiated|Released|PreWeigh Hold|Dispensing|Dispensed|Kitted|Ready for Production|Cancelled|Staged|Fire|Reject|Good|Hold|Received|Kitting'
		SET		@PrmFieldDelimiter	=	Null
		SET		@PrmRecordDelimiter =	'|'
		SET		@PrmDataType01		=	'nVarChar(50)'
	
		INSERT	@tInclude (
				RcdId,
				Field01)
		EXEC	dbo.spLocal_PE_ReportCollectionParsing 
				@IncludeCollection,
				@PrmFieldDelimiter,
				@PrmRecordDelimiter,
				@PrmDataType01

		INSERT @tOutput	(
				PPId,
				ProcessOrder)
		SELECT	pp.PP_Id,
				pp.Process_Order
		FROM	dbo.production_plan pp
		join	dbo.Production_Plan_Statuses pps on pp.PP_Status_Id = pps.PP_Status_Id
		join	@tInclude ti on upper(pps.PP_Status_Desc) = upper(ti.Field01)
		WHERE	pp.Path_Id = @PathId
		ORDER  BY pp.Process_Order
	END

	
RETURNOUTPUT:
SELECT * FROM @tOutput order by id

RETURN


SET NOcount OFF

