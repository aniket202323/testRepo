
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_CarrierSectionToDispense
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
 
 
 
CREATE VIEW [dbo].[vMPWS_CarrierSectionToDispense]
AS
SELECT     
	CSecToDisp.Event_Id AS CSecEventId,
	CSecToDisp.Source_Event_Id AS DispEventId
FROM dbo.Event_Components AS CSecToDisp 
	JOIN dbo.Events AS eCSec ON eCSec.Event_Id = CSecToDisp.Event_Id 
	JOIN dbo.Prod_Units_Base AS puCSec ON puCSec.PU_Id = eCSec.PU_Id 
		AND puCSec.Equipment_Type = 'Carrier Section'
	JOIN dbo.Events AS eDisp ON eDisp.Event_Id = CSecToDisp.Source_Event_Id 
	JOIN dbo.Prod_Units_Base AS puDisp ON puDisp.PU_Id = eDisp.PU_Id 
		AND puDisp.Equipment_Type = 'Dispense Station'
 
 
