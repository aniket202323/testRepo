
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_KitToDispense
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
CREATE VIEW [dbo].[vMPWS_KitToDispense]
AS
SELECT
	KitToDisp.Event_Id AS KitEventId,
	KitToDisp.Source_Event_Id AS DispEventId
FROM dbo.Event_Components AS KitToDisp
	JOIN dbo.Events AS eKit ON eKit.Event_Id = KitToDisp.Event_Id 
	JOIN dbo.Prod_Units_Base AS puKit ON puKit.PU_Id = eKit.PU_Id 
		AND puKit.Equipment_Type = 'Kitting Station'
	JOIN dbo.Events AS eDisp ON eDisp.Event_Id = KitToDisp.Source_Event_Id 
	JOIN dbo.Prod_Units_Base AS puDisp ON puDisp.PU_Id = eDisp.PU_Id 
		AND puDisp.Equipment_Type = 'Dispense Station'
 
