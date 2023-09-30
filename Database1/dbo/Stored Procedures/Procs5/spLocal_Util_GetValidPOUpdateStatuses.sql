
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_GetValidPOUpdateStatuses
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 25-Oct-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: This Stored Procedue returns list of PO Statuses Valid for the PO Update Screen
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
Declare	@ErrorCode				int,
		@ErrorMessage			nvarchar(1000)

EXECUTE	[dbo].[spLocal_Util_GetValidPOUpdateStatuses] @ErrorCode, ErrorMessage
-----------------------------------------------------------------------------------------------*/

--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetValidPOUpdateStatuses]
					@ErrorCode				int				OUTPUT,
					@ErrorMessage			nvarchar(1000)	OUTPUT
					

--WITH ENCRYPTION
AS
	SET NOCOUNT ON

	DECLARE @PrmFieldDelimiter	varchar(1),
			@PrmRecordDelimiter varchar(1),
			@PrmDataType01		nvarchar(255),
			@IncludeCollection	nvarchar(max)

	DECLARE	@tOutput TABLE(
			Id							int	identity (1,1),
			PPStatusId					int,
			PPStatusDesc				nvarchar(255))

	DECLARE	@tOutput1 TABLE(
			Id							int,
			PPStatusId					int,
			PPStatusDesc				nvarchar(255))

	DECLARE	@tInclude	table	(
			RcdId	int,
			Field01 nvarchar(255))

	SET @ErrorCode = 1
	SET @ErrorMessage = 'No Error'

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

	INSERT	@tOutput(
			PPStatusId,
			PPStatusDesc)
	SELECT	pps.PP_Status_Id,
			pps.PP_Status_Desc
	FROM	dbo.Production_Plan_Statuses pps WITH (NOLOCK)
	join	@tInclude ti on upper(pps.PP_Status_Desc) = upper(ti.Field01)
	order by	pps.PP_Status_Desc

	INSERT	@tOutput1(
			Id,
			PPStatusId,
			PPStatusDesc)
	SELECT	Id,
			PPStatusId,
			PPStatusDesc
	FROM	@tOutput
	
	INSERT	@tOutput1(
			Id,
			PPStatusId,
			PPStatusDesc)
	SELECT	0,
			0,
			'ALL'

	SELECT * FROM @tOutput1 order by id

	RETURN

SET NOCOUNT OFF

