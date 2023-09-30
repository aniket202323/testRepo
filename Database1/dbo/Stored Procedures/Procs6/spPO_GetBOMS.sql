
CREATE Procedure [dbo].[spPO_GetBOMS]
@Prod_Id bigint,
@Path_Id bigint
  AS
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
IF NOT EXISTS(SELECT 1 FROM Products_Base WHERE Prod_Id = @Prod_Id )
BEGIN
	--SELECT  Error = 'ERROR: Valid User Required'
		SELECT Error = 'ERROR: Valid Prod Id Required', Code = 'ResourceNotFound', ErrorType = 'ProdNotFound', PropertyName1 = 'prodId', PropertyName2 = @Prod_Id, PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

IF (NOT EXISTS( select 1 from Prdexec_Paths  where Path_Id = @Path_Id))
    BEGIN
        SELECT Error = 'ERROR: Valid Path_Id required', Code = 'ResourceNotFound', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Path_Id', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Path_Id, PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END



DECLARE @tBOMFormulations TABLE (
                                    BOMFormulationId bigint,
                                    BOMFormulationDesc nvarchar(50),
                                    MasterBOMFormulationId bigint
                                )

Insert @tBOMFormulations (
    BOMFormulationId,
    BOMFormulationDesc,
    MasterBOMFormulationId)
SELECT distinct bomf.BOM_Formulation_Id,
                bomf.BOM_Formulation_Desc,
                bomf.Master_BOM_Formulation_Id
FROM Bill_Of_Material_Formulation bomf
         JOIN Bill_Of_Material_Product bomp on bomp.BOM_Formulation_Id = bomf.BOM_Formulation_Id
         join PrdExec_Path_Units ppu on (ppu.PU_Id=bomp.PU_Id and ppu.Path_Id=@Path_Id and ppu.Is_Schedule_Point=1) or bomp.PU_Id is null
WHERE bomp.Prod_Id = @Prod_Id
--select * from @tBOMFormulations

Insert @tBOMFormulations (
    BOMFormulationId,
    BOMFormulationDesc,
    MasterBOMFormulationId)
SELECT distinct BOM_Formulation_Id,
                BOM_Formulation_Desc,
                Master_BOM_Formulation_Id
FROM Bill_Of_Material_Formulation bomf
         JOIN @tBOMFormulations bomf2 on bomf2.MasterBOMFormulationId = bomf.BOM_Formulation_Id
WHERE bomf2.MasterBOMFormulationId is NOT NULL
  AND BOM_Formulation_Id NOT IN (SELECT BOMFormulationId FROM @tBOMFormulations)
SELECT BOMFormulationId AS 'Id', BOMFormulationDesc AS 'Name'
FROM @tBOMFormulations


