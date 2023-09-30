CREATE PROCEDURE dbo.spServer_CmnGetSPParameterCount
@SPName nVarChar(255),
@ParameterCount int OUTPUT
 AS
select @ParameterCount = count(id) from syscolumns  where id = object_id(@SPName)
