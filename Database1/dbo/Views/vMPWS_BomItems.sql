
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_BomItems
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
 
 
 
 
CREATE VIEW [dbo].[vMPWS_BomItems]
AS
SELECT     bomfi.BOM_Formulation_Item_Id, pp.BOM_Formulation_Id, pp.PP_Id, p.Prod_Id AS BomfiProdId, p.Prod_Code AS BomfiProdCode, p.Prod_Desc AS BomfiProdDesc, 
                      COALESCE(oq.Value, bomfi.Quantity) AS BomfiQuantity, bomfi.Quantity AS SAPQuantity, eu.Eng_Unit_Desc AS BomfiUOM, tfv1.Value AS BOMItemStatusId, pps.PP_Status_Desc AS BOMItemStatusDesc, 
                      tfv2.Value AS DispenseStationId, pu.PU_Desc AS DispenseStationDesc,
			ISNULL(CAST(propDef.Value AS INT), 0) AS CanOverrideQty
FROM         dbo.Production_Plan AS pp INNER JOIN
                      dbo.Bill_Of_Material_Formulation_Item AS bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id INNER JOIN
                      dbo.Products_Base AS p ON bomfi.Prod_Id = p.Prod_Id INNER JOIN
                      dbo.Engineering_Unit AS eu ON eu.Eng_Unit_Id = bomfi.Eng_Unit_Id INNER JOIN
                      dbo.Tables AS t ON t.TableName = 'Bill_Of_Material_Formulation_Item' INNER JOIN
                      dbo.Table_Fields AS tf1 ON tf1.Table_Field_Desc = 'BOMItemStatus' AND tf1.TableId = t.TableId LEFT OUTER JOIN
                      dbo.Table_Fields_Values AS tfv1 ON tfv1.KeyId = bomfi.BOM_Formulation_Item_Id AND tfv1.TableId = t.TableId AND 
                      tfv1.Table_Field_Id = tf1.Table_Field_Id LEFT OUTER JOIN
                      dbo.Production_Plan_Statuses AS pps ON pps.PP_Status_Id = tfv1.Value INNER JOIN
                      dbo.Table_Fields AS tf2 ON tf2.Table_Field_Desc = 'DispenseStationId' AND tf2.TableId = t.TableId LEFT OUTER JOIN
                      dbo.Table_Fields_Values AS tfv2 ON tfv2.KeyId = bomfi.BOM_Formulation_Item_Id AND tfv2.TableId = t.TableId AND 
                      tfv2.Table_Field_Id = tf2.Table_Field_Id LEFT OUTER JOIN
                      dbo.Prod_Units_Base AS pu ON pu.PU_Id = tfv2.Value INNER JOIN
                      dbo.Prdexec_Paths AS pep ON pep.Path_Id = pp.Path_Id INNER JOIN
                      dbo.Prod_Lines_Base AS pl ON pl.PL_Id = pep.PL_Id INNER JOIN
                      dbo.Departments_Base AS d ON d.Dept_Id = pl.Dept_Id AND d.Dept_Desc = 'Pre-weigh'
			OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
			LEFT JOIN dbo.Products_Aspect_MaterialDefinition prodDef ON prodDef.Prod_Id = bomfi.Prod_Id
			LEFT JOIN dbo.Property_MaterialDefinition_MaterialClass propDef ON propDef.MaterialDefinitionId = prodDef.Origin1MaterialDefinitionId
				AND propDef.Class = 'Pre-Weigh'
				AND propDef.Name = 'CanOverrideQty'
 
 
