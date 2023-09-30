------------------------------------------------------------ --------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetOriginGroupProducts]
					@OriginGroup	nvarchar(255)
--WITH ENCRYPTION
AS
SET NOCOUNT ON



	DECLARE	@tOGProducts table(
			Id						int identity(1,1),
			ProdId					nvarchar(255),
			ProdCode				nvarchar(255),
			ProdDesc				nvarchar(255),
			MaterialDefinitionId	nvarchar (255))
		


	INSERT	@tOGProducts (
			ProdId,
			ProdCode,
			ProdDesc,
			MaterialDefinitionId)
	SELECT	p.prod_id,
			p.Prod_Code,
			p.prod_desc,
			convert(nvarchar(255),md.MaterialDefinitionId)
	FROM	dbo.Products_Base p WITH (NOLOCK)
	join	dbo.Products_Aspect_MaterialDefinition pasmd WITH (NOLOCK) on p.Prod_Id = pasmd.Prod_Id
	join	dbo. Property_MaterialDefinition_MaterialClass pmdmc WITH (NOLOCK) on pasmd.Origin1MaterialDefinitionId = pmdmc.MaterialDefinitionId 
	join	dbo.MaterialDefinition md WITH (NOLOCK) on pmdmc.MaterialDefinitionId = md.MaterialDefinitionId
	join	dbo.MaterialClass mc WITH (NOLOCK) on pmdmc.Class = mc.MaterialClassName
	WHERE	upper(pmdmc.Name) = 'ORIGIN GROUP' and
			pmdmc.Value	= @OriginGroup
	ORDER BY p.Prod_Code

	SELECT	Id,
			ProdId,
			ProdCode,
			ProdDesc,
			MaterialDefinitionId
	FROM	@tOGProducts


	RETURN


SET NOcount OFF