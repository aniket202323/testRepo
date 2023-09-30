CREATE FUNCTION dbo.fnServer_CmnGetSegRespProduct(
@SegRespId uniqueidentifier
) 
     RETURNS int
AS 
begin
IF @SegRespId IS Null
      RETURN Null
declare @ProdId int
set @ProdId = NULL
select @ProdId = Prod_Id from Products_Aspect_MaterialDefinition where Origin1MaterialDefinitionId = dbo.fnServer_CmnGetSegRespMaterial(@SegRespId)
return @ProdId
end
