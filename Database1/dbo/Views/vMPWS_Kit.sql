
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_Kit
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
CREATE VIEW [dbo].[vMPWS_Kit]
AS
SELECT DISTINCT 
                      e.Event_Id AS KitEventId, e.Event_Num AS KitEventNum, ps.ProdStatus_Desc AS KitStatus, pu.PU_Id AS KitPUId, pu.PU_Desc AS KitPUDesc, 
                      pu.Equipment_Type AS KitEquipmentType, t.Result AS KitPONum, ul.Location_Id AS KitLocationId, ul.Location_Code AS KitLocationCode, 
                      ul.Location_Desc AS KitLocationDesc
FROM         dbo.Event_Details AS ed INNER JOIN
                      dbo.Events AS e ON ed.Event_Id = e.Event_Id INNER JOIN
                      dbo.Production_Status AS ps ON e.Event_Status = ps.ProdStatus_Id INNER JOIN
                      dbo.Prod_Units_Base AS pu ON pu.PU_Id = e.PU_Id AND pu.Equipment_Type = 'Kitting Station' INNER JOIN
                      dbo.Variables_Base AS v ON v.PU_Id = e.PU_Id AND v.Test_Name = 'MPWS_KIT_PO_NUM' LEFT OUTER JOIN
                      dbo.Tests AS t ON t.Var_Id = v.Var_Id AND t.Result_On = e.TimeStamp LEFT OUTER JOIN
                      dbo.Unit_Locations AS ul ON ul.Location_Id = ed.Location_Id AND ul.PU_Id = e.PU_Id
 
 
