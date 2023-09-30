CREATE  PROCEDURE [dbo].spLocal_CmnWFGetUnitAndPathFromGUId
	@GUID				varchar(36),
	@puid				int OUTPUT,
	@S95ID				varchar(100) OUTPUT,
	@pathid				int OUTPUT,
	@pathCode			varchar(20) OUTPUT
 

AS
SET NOCOUNT ON



SET @S95ID = (SELECT TOP 1 S95ID FROM dbo.equipment WITH(NOLOCK) WHERE equipmentId = @GUID)

IF @S95ID IS NULL
	SET @S95ID = 'INVALID'

--Get pu_id using aspecting
SET @puid = (SELECT pu_id FROM dbo.PAEquipment_Aspect_SOAEquipment WITH(NOLOCK) WHERE Origin1EquipmentId = @GUID)
IF @puid IS NULL 
BEGIN
	SET @puid = 0
	SET @pathid = 0
	SET @pathCode =  'INVALID'
	RETURN
END


--Get path.  Option 1 is the Unit is a production unit of the path
SELECT	TOP 1	@pathId = pepu.path_id,
				@pathCode = pep.path_code
FROM dbo.prdExec_path_units pepu	WITH(NOLOCK)
JOIN dbo.prdExec_paths pep			WITH(NOLOCK)	ON pepu.path_id = pep.path_id
WHERE pepu.pu_id = @puid


--Get path.	 Option 2 is the Unit storage location used by the path
IF @pathId = 0 OR @pathId IS NULL
BEGIN
	SELECT	TOP 1	@pathId = pepu.path_id,
					@pathCode = pep.path_code
	FROM dbo.prdExec_input_sources peis	WITH(NOLOCK)
	JOIN dbo.prdExec_inputs pei			WITH(NOLOCK)	ON pei.pei_id	= peis.PEI_Id
	JOIN dbo.prdExec_path_units pepu	WITH(NOLOCK)	ON pepu.pu_id	= pei.pu_id
	JOIN dbo.prdExec_paths pep			WITH(NOLOCK)	ON pepu.path_id = pep.path_id
	WHERE peis.pu_id = @puid

END




SELECT @S95ID as 'S95ID', @puid as 'pu_id', @pathid as 'Path_Id', @pathCode as 'Path_Code'

SET NOCOUNT OFF
RETURN