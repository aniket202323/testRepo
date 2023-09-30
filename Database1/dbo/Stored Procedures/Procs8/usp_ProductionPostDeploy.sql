CREATE PROCEDURE [dbo].[usp_ProductionPostDeploy]
@Debug	BIT = 0,  -- when 1 print debug statements
@Test	BIT = 0   -- when 1 do not make any changes
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'ProdSeg' AND TABLE_SCHEMA = 'dbo')
	BEGIN
		RETURN
	END

	-- Initialize IsVisible to be the same is IsReusable.  If IsReusable is NULL, then set to 1
	UPDATE [dbo].ProdSeg SET 
	IsReusable = COALESCE(IsReusable,1), 
	IsVisible = COALESCE(IsReusable,1)
	WHERE IsVisible IS NULL; -- IsVisible will only be NULL on an upgrade just after it has been added to the table
END