
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_Rmc
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
CREATE VIEW [dbo].[vMPWS_Rmc]
AS
SELECT     e.Event_Id AS RmcEventId, e.Event_Num AS RmcEventNum, pu.PU_Id AS RmcPUId, pu.PU_Desc AS RmcPUDesc, pu.Equipment_Type AS RmcEquipmentType, 
                      p.Prod_Id AS RmcMaterialId, p.Prod_Code AS RmcMaterialCode, p.Prod_Desc AS RmcMaterialDesc, ps.ProdStatus_Desc AS RmcStatus, 
                      ed.Alternate_Event_Num AS RmcULID, ed.Initial_Dimension_X AS RmcInitialQuantity, ed.Final_Dimension_X AS RmcCurrentQuantity, ul.Location_Id AS RmcLocationId,
                       ul.Location_Code AS RmcLocationCode, ul.Location_Desc AS RmcLocationDesc, t1.Result AS RmcUOM, t2.Result AS RmcRecFlag, t3.Result AS RmcQaStatus, 
                      t4.Result AS RmcSAPLot
FROM         dbo.Event_Details AS ed INNER JOIN
                      dbo.Events AS e ON ed.Event_Id = e.Event_Id INNER JOIN
                      dbo.Prod_Units_Base AS pu ON pu.PU_Id = e.PU_Id AND pu.Equipment_Type = 'Receiving Station' INNER JOIN
                      dbo.Variables_Base AS v1 ON v1.PU_Id = e.PU_Id AND v1.Test_Name = 'MPWS_INVN_RMC_UOM' LEFT OUTER JOIN
                      dbo.Tests AS t1 ON t1.Result_On = e.TimeStamp AND t1.Var_Id = v1.Var_Id INNER JOIN
                      dbo.Variables_Base AS v2 ON v2.PU_Id = e.PU_Id AND v2.Test_Name = 'MPWS_INVN_REC_FLAG' LEFT OUTER JOIN
                      dbo.Tests AS t2 ON t2.Result_On = e.TimeStamp AND t2.Var_Id = v2.Var_Id INNER JOIN
                      dbo.Variables_Base AS v3 ON v3.PU_Id = e.PU_Id AND v3.Test_Name = 'MPWS_INVN_QA_STATUS' LEFT OUTER JOIN
                      dbo.Tests AS t3 ON t3.Result_On = e.TimeStamp AND t3.Var_Id = v3.Var_Id INNER JOIN
                      dbo.Variables_Base AS v4 ON v4.PU_Id = e.PU_Id AND v4.Test_Name = 'MPWS_INVN_SAP_LOT' LEFT OUTER JOIN
                      dbo.Tests AS t4 ON t4.Result_On = e.TimeStamp AND t4.Var_Id = v4.Var_Id INNER JOIN
                      dbo.Production_Status AS ps ON e.Event_Status = ps.ProdStatus_Id INNER JOIN
                      dbo.Products_Base AS p ON p.Prod_Id = e.Applied_Product LEFT OUTER JOIN
                      dbo.Unit_Locations AS ul ON ul.Location_Id = ed.Location_Id AND ul.PU_Id = e.PU_Id
