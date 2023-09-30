
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_DispenseToRMC
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
CREATE VIEW [dbo].[vMPWS_DispenseToRMC]
AS
SELECT
	DispToRMC.Event_Id DispEventId,
	DispToRMC.Source_Event_Id RMCEventId
FROM dbo.Event_Components DispToRMC
	JOIN dbo.Events AS eDisp ON eDisp.Event_Id = DispToRMC.Event_Id 
	JOIN dbo.Prod_Units_Base AS puDisp ON puDisp.PU_Id = eDisp.PU_Id 
		AND puDisp.Equipment_Type = 'Dispense Station'
	JOIN dbo.Events eRMC ON eRMC.Event_Id = DispToRMC.Source_Event_Id 
	JOIN dbo.Prod_Units_Base puKit ON puKit.PU_Id = eRMC.PU_Id 
		AND puKit.Equipment_Type = 'Receiving Station'
 
