
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_Dispense
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
 
CREATE VIEW [dbo].[vMPWS_Dispense]
AS
SELECT     e.Event_Id AS DispEventId, e.Event_Num AS DispEventNum, pp.PP_Id AS DispPPId, pp.Process_Order AS DispPONum, pu.PU_Id AS DispPUId, 
                      pu.PU_Desc AS DispPUDesc, pu.Equipment_Type AS DispEquipmentType, p.Prod_Id AS DispMaterialId, p.Prod_Code AS DispMaterialCode, 
                      p.Prod_Desc AS DispMaterialDesc, ps.ProdStatus_Desc AS DispStatus, ed.Final_Dimension_X AS DispQuantity, t1.Result AS DispUOM, t2.Result AS DispBomfiId, 
                      t3.Result AS DispRecFlag, t4.Result AS DispMethod, t5.Result AS DispScale, t6.Result AS DispTareQuantity, t7.Result AS DispReturnReason, 
                      ul.Location_Id AS DispLocationId, ul.Location_Code AS DispLocationCode, ul.Location_Desc AS DispLocationDesc
FROM         dbo.Event_Details AS ed INNER JOIN
                      dbo.Events AS e ON ed.Event_Id = e.Event_Id INNER JOIN
                      dbo.Prod_Units_Base AS pu ON pu.PU_Id = e.PU_Id AND pu.Equipment_Type = 'Dispense Station' INNER JOIN
                      dbo.Variables_Base AS v1 ON v1.PU_Id = e.PU_Id AND v1.Test_Name = 'MPWS_DISP_DISPENSE_UOM' LEFT OUTER JOIN
                      dbo.Tests AS t1 ON t1.Result_On = e.TimeStamp AND t1.Var_Id = v1.Var_Id INNER JOIN
                      dbo.Variables_Base AS v2 ON v2.PU_Id = e.PU_Id AND v2.Test_Name = 'MPWS_DISP_BOMFIId' LEFT OUTER JOIN
                      dbo.Tests AS t2 ON t2.Result_On = e.TimeStamp AND t2.Var_Id = v2.Var_Id INNER JOIN
                      dbo.Variables_Base AS v3 ON v3.PU_Id = e.PU_Id AND v3.Test_Name = 'MPWS_DISP_REC_FLAG' LEFT OUTER JOIN
                      dbo.Tests AS t3 ON t3.Result_On = e.TimeStamp AND t3.Var_Id = v3.Var_Id INNER JOIN
                      dbo.Variables_Base AS v4 ON v4.PU_Id = e.PU_Id AND v4.Test_Name = 'MPWS_DISP_DISPENSE_METHOD' LEFT OUTER JOIN
                      dbo.Tests AS t4 ON t4.Result_On = e.TimeStamp AND t4.Var_Id = v4.Var_Id INNER JOIN
                      dbo.Variables_Base AS v5 ON v5.PU_Id = e.PU_Id AND v5.Test_Name = 'MPWS_DISP_SCALE' LEFT OUTER JOIN
                      dbo.Tests AS t5 ON t5.Result_On = e.TimeStamp AND t5.Var_Id = v5.Var_Id INNER JOIN
                      dbo.Variables_Base AS v6 ON v6.PU_Id = e.PU_Id AND v6.Test_Name = 'MPWS_DISP_TARE_QUANTITY' LEFT OUTER JOIN
                      dbo.Tests AS t6 ON t6.Result_On = e.TimeStamp AND t6.Var_Id = v6.Var_Id INNER JOIN
                      dbo.Variables_Base AS v7 ON v7.PU_Id = e.PU_Id AND v7.Test_Name = 'MPWS_DISP_RETURN_REASON' LEFT OUTER JOIN
                      dbo.Tests AS t7 ON t7.Result_On = e.TimeStamp AND t7.Var_Id = v7.Var_Id INNER JOIN
                      dbo.Production_Status AS ps ON e.Event_Status = ps.ProdStatus_Id INNER JOIN
                      dbo.Products_Base AS p ON p.Prod_Id = e.Applied_Product LEFT OUTER JOIN
                      dbo.Production_Plan AS pp ON ed.PP_Id = pp.PP_Id LEFT OUTER JOIN
                      dbo.Unit_Locations AS ul ON ul.Location_Id = ed.Location_Id AND ul.PU_Id = e.PU_Id
 
 
 
