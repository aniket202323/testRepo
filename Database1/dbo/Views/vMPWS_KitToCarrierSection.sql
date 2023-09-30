
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_KitToCarrierSection
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
 
 
CREATE VIEW [dbo].[vMPWS_KitToCarrierSection]
AS
SELECT     
	KitToCSec.Event_Id AS KitEventId,
	KitToCSec.Source_Event_Id AS CSecEventId
FROM dbo.Event_Components AS KitToCSec 
	JOIN dbo.Events AS eKit ON eKit.Event_Id = KitToCSec.Event_Id 
	JOIN dbo.Prod_Units_Base AS puKit ON puKit.PU_Id = eKit.PU_Id 
		AND puKit.Equipment_Type = 'Kitting Station'
	JOIN dbo.Events AS eCSec ON eCSec.Event_Id = KitToCSec.Source_Event_Id 
	JOIN dbo.Prod_Units_Base AS puCSec ON puCSec.PU_Id = eCSec.PU_Id 
		AND puCSec.Equipment_Type = 'Carrier Section'
 
 
