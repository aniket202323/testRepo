

--------------------------------------------------------------------------------------------------
-- Stored Procedure: splocal_CTS_Get_Cleaning_Matrix
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-08-12
-- Version 				: Version 1.0
-- SP Type				: WEB
-- Caller				: WEB SERVICE
-- Description			: Get the cleaning matrix from SQL table
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-08-12		F. Bergeron				Initial Release 
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXECUTE [splocal_CTS_Get_Cleaning_Matrix] NULL, NULL, 1
*/

CREATE   PROCEDURE [dbo].[splocal_CTS_Get_Cleaning_Matrix]
@Start_time DATETIME = NULL,
@End_time DATETIME = NULL,
@OnlyActive BIT = 1



AS
BEGIN
	SET NOCOUNT ON;
	-- SP Variables

	DECLARE
	@Output TABLE
	(
	CPTCM_id			INTEGER,
	From_Product_id		INTEGER,
	From_Product_code	VARCHAR(50),
	From_Product_desc	VARCHAR(50),
	To_Product_id		INTEGER,
	To_Product_code		VARCHAR(50),
	To_Product_desc		VARCHAR(50),
	Location_id			INTEGER,
	Location_desc		VARCHAR(50),
	CT_id				INTEGER,
	CT_Code				VARCHAR(25),
	CT_Description		VARCHAR(25),
	Start_Time			DATETIME,
	End_Time			DATETIME
	)

	INSERT INTO @Output(
	CPTCM_id,
	From_Product_id,
	From_Product_Desc,
	From_Product_Code,
	To_Product_id,
	To_Product_Desc,
	To_Product_Code,
	Location_id,
	Location_desc,
	CT_id,
	CT_Code,
	CT_Description,
	Start_Time,
	End_Time)
	SELECT	PTCM.CPTCM_id,
			PTCM.From_Product_id,
			PBFRM.Prod_desc,
			PBFRM.Prod_code,
			PTCM.To_Product_id,
			PBTO.Prod_desc,
			PBTO.Prod_code,
			PTCM.location_id,
			PUB.pu_desc,
			CM.CCM_id,
			CM.Code,
			CM.Description,
			PTCM.start_time,
			PTCM.end_time

	FROM	dbo.Local_CTS_Product_Transition_Cleaning_Methods PTCM WITH(NOLOCK) 
			JOIN dbo.Local_CTS_Cleaning_Methods CM 
				ON CM.CCM_id = PTCM.CCm_id
			LEFT JOIN dbo.prod_units_Base PUB
				ON PUB.pu_id = PTCM.location_id
			JOIN dbo.products_base PBFRM WITH(NOLOCK)
				ON PBFRM.prod_id = PTCM.From_Product_id
			JOIN dbo.products_base PBTO WITH(NOLOCK)
				ON PBTO.prod_id = PTCM.To_Product_id


IF @Start_time IS NOT NULL
	DELETE @Output
	WHERE Start_time < @Start_time
IF @End_time IS NOT NULL
	DELETE @Output
	WHERE End_time > @End_time

IF @OnlyActive = 1
	DELETE @Output
	WHERE End_time IS NOT NULL


	SELECT	CPTCM_id,
			From_Product_id,-- 'From product id',
			From_Product_Desc,-- 'From product desc',
			From_Product_Code,-- 'From product code',
			To_Product_id,-- 'To product id',
			To_Product_Desc,-- 'To product desc',
			To_Product_Code,-- 'To product code',
			Location_id,-- 'Location id',
			Location_desc,-- 'Location desc',
			CT_id,-- 'Cleaning type id',
			CT_Code,-- 'Cleaning type code',
			CT_Description,-- 'Cleaning type code',
			Start_Time,-- 'Rule activation',
			End_Time-- 'Rule Expiration'
	FROM	@output
	SET NOCOUNT OFF;

END

