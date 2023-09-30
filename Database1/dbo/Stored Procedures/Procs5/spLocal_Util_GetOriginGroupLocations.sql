------------------------------------------------------------ --------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetOriginGroupLocations]
					@OriginGroup	nvarchar(255)

--WITH ENCRYPTION
AS
	SET NOCOUNT ON


	DECLARE	@tOGLocations	table(
			Id				int identity(1,1),
			Location		nvarchar(255),
			LocationPUId	nvarchar(255))

	DECLARE @TableFields	table (
			id				int identity (1,1),
			TableId			int,
			TableFieldId	int)

	INSERT	@TableFields(
			TableId,
			TableFieldId)
	SELECT	tf.TableId,
			tf.Table_Field_Id
	FROM	dbo.Table_Fields tf WITH (NOLOCK)
	join	dbo.tables tt WITH (NOLOCK) on tf.TableId = tt.TableId
	WHERE	upper(tt.TableName)			= 'PRDEXEC_INPUTS'			
	and		upper(tf.Table_Field_Desc)	= 'ORIGIN GROUP'	


	INSERT				@tOGLocations	(
						Location,
						LocationPUId)
	SELECT  DISTINCT	x.Foreign_Key	as Location, 
						x.Actual_Id		as LocationPUId 
	FROM				dbo.Data_Source_XRef x	WITH (NOLOCK)
	join				dbo.Data_Source ds WITH (NOLOCK) on x.DS_Id						= ds.DS_Id 
	join				dbo.tables t WITH (NOLOCK) on x.Table_Id						= t.TableId
	join				dbo.Prod_Units_Base pu WITH (NOLOCK) on x.Actual_Id				= pu.pu_id 
	join				dbo.PrdExec_Input_Sources pexis WITH (NOLOCK) on x.Actual_Id	= pexis.PU_Id
	join				dbo.Table_Fields_Values tfv WITH (NOLOCK) on pexis.PEI_Id		= tfv.KeyId
	join				dbo.PU_Products pup WITH (NOLOCK) on x.actual_id				= pup.PU_Id
	join				@TableFields tf on tfv.TableId = tf.TableId and
						tf.TableFieldId = tfv.Table_Field_Id
	WHERE				upper(ds.DS_Desc)	= 'OPEN ENTERPRISE'			 
	and					upper(t.TableName)	= 'PROD_UNITS'				
	and					tfv.value = @OriginGroup				
	ORDER BY			x.Foreign_Key

	SELECT	Location,
			LocationPUId 
	FROM	@tOGLocations

RETURN

SET NOcount OFF