
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_Carrier
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
CREATE VIEW [dbo].[vMPWS_Carrier]
AS
SELECT     e.Event_Id AS CarEventId, e.Event_Num AS CarEventNum, ps.ProdStatus_Desc AS CarStatus, e.Event_Status AS CarStatusID, pu.PU_Id AS CarPUId, 
                      pu.PU_Desc AS CarPUDesc, pu.Equipment_Type AS CarEquipmentType, ul.Location_Id AS CarLocationId, ul.Location_Code AS CarLocationCode, 
                      ul.Location_Desc AS CarLocationDesc, t1.Result AS CarMakingLine, t2.Result AS CarCarrierSection, t3.Result AS CarCarrierType
FROM         dbo.Events AS e INNER JOIN
                      dbo.Event_Details AS ed ON ed.Event_Id = e.Event_Id INNER JOIN
                      dbo.Variables_Base AS v1 ON v1.PU_Id = e.PU_Id AND v1.Test_Name = 'MPWS_CAR_MAKING_LINE' LEFT OUTER JOIN
                      dbo.Tests AS t1 ON t1.Result_On = e.TimeStamp AND t1.Var_Id = v1.Var_Id INNER JOIN
                      dbo.Variables_Base AS v2 ON v2.PU_Id = e.PU_Id AND v2.Test_Name = 'MPWS_CAR_CARRIER_SECTION' LEFT OUTER JOIN
                      dbo.Tests AS t2 ON t2.Result_On = e.TimeStamp AND t2.Var_Id = v2.Var_Id INNER JOIN
                      dbo.Variables_Base AS v3 ON v3.PU_Id = e.PU_Id AND v3.Test_Name = 'MPWS_CAR_CARRIER_TYPE' LEFT OUTER JOIN
                      dbo.Tests AS t3 ON t3.Result_On = e.TimeStamp AND t3.Var_Id = v3.Var_Id INNER JOIN
                      dbo.Production_Status AS ps ON e.Event_Status = ps.ProdStatus_Id INNER JOIN
                      dbo.Prod_Units_Base AS pu ON pu.PU_Id = e.PU_Id AND pu.Equipment_Type = 'Carrier' LEFT OUTER JOIN
                      dbo.Unit_Locations AS ul ON ul.Location_Id = ed.Location_Id AND ul.PU_Id = e.PU_Id
 
