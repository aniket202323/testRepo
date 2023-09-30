 
 
/*
	Utility stored procedure to set Preweigh Extended Info for stored procedure documenting.
	
 
exec dbo.spLocal_MPWS_GENL_SetSprocExtProps
	@SprocName		= 'spLocal_MPWS_GENL_SetSprocExtProps',
	@Description	= 'Utility stored procedure to set Preweigh Extended Info for stored procedure documenting.',
	@WhereUsed		= '',
	@Status			= 'Done',
	@Version		= '1.0'
 
SELECT object_name(major_id) SProc, name [Ext Prop], Value 
FROM sys.Extended_Properties 
WHERE object_name(major_id) = N'spLocal_MPWS_GENL_SetSprocExtProps'
 
*/
 
CREATE PROCEDURE [dbo].[spLocal_MPWS_GENL_SetSprocExtProps]
	@SprocName		VARCHAR(255),
	@Description	VARCHAR(255),
	@WhereUsed		VARCHAR(255),
	@Status			VARCHAR(255),
	@Version		VARCHAR(255)
	
AS
 
DECLARE
	@L1Type NVARCHAR(50) = CASE WHEN SUBSTRING(@SprocName, 1, 2) = 'sp' THEN N'PROCEDURE' ELSE N'FUNCTION' END;
	
IF NOT EXISTS (SELECT value FROM sys.Extended_Properties WHERE major_id = OBJECT_ID(@SprocName) AND name = N'MPWS_Description' AND minor_id = 0)
BEGIN
 
	EXEC sys.sp_addextendedproperty 
		@level0type = N'SCHEMA',		@level0name = N'dbo', 
		@level1type = @L1Type,			@level1name = @SprocName, 
		@name = N'MPWS_Description',	@value = @Description
 
END
ELSE
BEGIN
 
	EXEC sys.sp_updateextendedproperty 
		@level0type = N'SCHEMA',		@level0name = N'dbo', 
		@level1type = @L1Type,			@level1name = @SprocName, 
		@name = N'MPWS_Description',	@value = @Description
 
END
 
IF NOT EXISTS (SELECT value FROM sys.Extended_Properties WHERE major_id = OBJECT_ID(@SprocName) AND name = N'MPWS_WhereUsed' AND minor_id = 0)
BEGIN
 
	EXEC sys.sp_addextendedproperty 
		@level0type = N'SCHEMA',		@level0name = N'dbo', 
		@level1type = @L1Type,			@level1name = @SprocName, 
		@name = N'MPWS_WhereUsed',		@value = @WhereUsed
 
END
ELSE
BEGIN
 
	EXEC sys.sp_updateextendedproperty 
		@level0type = N'SCHEMA',		@level0name = N'dbo', 
		@level1type = @L1Type,			@level1name = @SprocName, 
		@name = N'MPWS_WhereUsed',		@value = @WhereUsed
 
END
 
IF NOT EXISTS (SELECT value FROM sys.Extended_Properties WHERE major_id = OBJECT_ID(@SprocName) AND name = N'MPWS_Status' AND minor_id = 0)
BEGIN
 
	EXEC sys.sp_addextendedproperty 
		@level0type = N'SCHEMA',		@level0name = N'dbo', 
		@level1type = @L1Type,			@level1name = @SprocName, 
		@name = N'MPWS_Status',			@value = @Status
 
END
ELSE
BEGIN
 
	EXEC sys.sp_updateextendedproperty 
		@level0type = N'SCHEMA',		@level0name = N'dbo', 
		@level1type = @L1Type,			@level1name = @SprocName, 
		@name = N'MPWS_Status',			@value = @Status
 
END
 
IF NOT EXISTS (SELECT value FROM sys.Extended_Properties WHERE major_id = OBJECT_ID(@SprocName) AND name = N'MPWS_Version' AND minor_id = 0)
BEGIN
 
	EXEC sys.sp_addextendedproperty 
		@level0type = N'SCHEMA',		@level0name = N'dbo', 
		@level1type = @L1Type,			@level1name = @SprocName, 
		@name = N'MPWS_Version',		@value = @Version
 
END
ELSE
BEGIN
 
	EXEC sys.sp_updateextendedproperty 
		@level0type = N'SCHEMA',		@level0name = N'dbo', 
		@level1type = @L1Type,			@level1name = @SprocName, 
		@name = N'MPWS_Version',		@value = @Version
 
END
 
/*
 
exec dbo.spLocal_MPWS_GENL_SetSprocExtProps
	@SprocName		= 'spLocal_MPWS_KIT_GetCarriers',
	@Description	= 'Get a list of carriers',
	@WhereUsed		= '',
	@Status			= 'Done',
	@Version		= '1.4'
 
 
SELECT object_name(major_id) SProc, name [Ext Prop], value FROM sys.Extended_Properties WHERE name = N'MPWS_Description'
 
*/

GO
EXECUTE sp_addextendedproperty @name = N'MPWS_Description', @value = N'Utility stored procedure to set Preweigh Extended Info for stored procedure documenting.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = N'spLocal_MPWS_GENL_SetSprocExtProps';


GO
EXECUTE sp_addextendedproperty @name = N'MPWS_Status', @value = N'Done', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = N'spLocal_MPWS_GENL_SetSprocExtProps';


GO
EXECUTE sp_addextendedproperty @name = N'MPWS_Version', @value = N'1.0', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = N'spLocal_MPWS_GENL_SetSprocExtProps';


GO
EXECUTE sp_addextendedproperty @name = N'MPWS_WhereUsed', @value = N'', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'PROCEDURE', @level1name = N'spLocal_MPWS_GENL_SetSprocExtProps';

