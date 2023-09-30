 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetScales]
		@ErrorCode			INT				OUTPUT,
		@ErrorMessage		VARCHAR(255)	OUTPUT,
		@DispenseStation	VARCHAR(250) = NULL,
		@UOM				VARCHAR(10) = NULL
		
AS	
-------------------------------------------------------------------------------
-- Get a list of valid scales
/*
declare @e int, @m varchar(255)
EXEC spLocal_MPWS_DISP_GetScales @e output, @m output,NULL--, 'PW01DS01'
select @e, @m
 
declare @e int, @m varchar(255)
EXEC spLocal_MPWS_DISP_GetScales @e output, @m output, '', ''
 
EXEC spLocal_MPWS_DISP_GetScales @e output, @m output, 'PW01DS01', ''
 
EXEC spLocal_MPWS_DISP_GetScales @e output, @m output, 'PW01DS01', 'KG'
 
EXEC spLocal_MPWS_DISP_GetScales @e output, @m output, '', 'KG'
 
select @e, @m
 
 
*/
-- Date         Version Build Author  
-- 25-Sep-2015  001     001   MISHA KRAVCHENKO (GEIP)  Initial development	
 
 
SET NOCOUNT ON;
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
DECLARE	
	@ClassName			VARCHAR(255)
		
-------------------------------------------------------------------------------
--  Initialize output parameters
-------------------------------------------------------------------------------					
SELECT	@ErrorCode		= 1,
		@ErrorMessage	= 'Success'
 
------------------------------------------------------------------------------
--  GET Scales, Return data 
-------------------------------------------------------------------------------
 
SET @DispenseStation = NULLIF(@DispenseStation, '');
SET @UOM = NULLIF(@UOM, '');
 
;WITH ds AS
(
	SELECT
		pu.PU_Id ScalePUId,
		pu.PU_Desc ScaleDesc, 
		CAST(peec.Value AS VARCHAR) DispenseStationDesc,
		CAST(peec2.Value AS VARCHAR) WeightUOM
	FROM dbo.EquipmentClass_EquipmentObject eeo
		JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
		JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
		JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
		JOIN dbo.Property_Equipment_EquipmentClass peec2 ON eeo.EquipmentId = peec2.EquipmentId
	WHERE eeo.EquipmentClassName = 'Pre-Weigh - Scale'
		AND peec.Name = 'DispenseStation'
		AND peec2.Name = 'WeightUOM'
)
SELECT
	ScalePUId,
	ScaleDesc,
	WeightUOM
FROM ds
WHERE (DispenseStationDesc = @DispenseStation OR @DispenseStation IS NULL)
	AND (WeightUOM = @UOM OR @UOM IS NULL)
ORDER BY ScaleDesc
 
 
 
 
 
 
 
 
