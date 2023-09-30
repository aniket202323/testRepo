
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_CarrierSection
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
CREATE VIEW [dbo].[vMPWS_CarrierSection]
AS
SELECT     e.Event_Id AS CSecEventId, e.Event_Num AS CSecEventNum, ps.ProdStatus_Desc AS CSecStatus, pu.PU_Id AS CSecPUId, pu.PU_Desc AS CSecPUDesc, 
                      pu.Equipment_Type AS CSecEquipmentType
FROM         dbo.Event_Details AS ed INNER JOIN
                      dbo.Events AS e ON ed.Event_Id = e.Event_Id INNER JOIN
                      dbo.Production_Status AS ps ON e.Event_Status = ps.ProdStatus_Id INNER JOIN
                      dbo.Prod_Units_Base AS pu ON pu.PU_Id = e.PU_Id AND pu.Equipment_Type = 'Carrier Section'
 
 
