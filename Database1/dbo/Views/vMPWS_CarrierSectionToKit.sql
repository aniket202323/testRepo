
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_CarrierSectionToKit
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
 
 
 
CREATE VIEW [dbo].[vMPWS_CarrierSectionToKit]
AS
SELECT     
	CSecToKit.Event_Id AS CSecEventId,
	CSecToKit.Source_Event_Id AS KitEventId
FROM dbo.Event_Components AS CSecToKit 
	JOIN dbo.Events AS eKit ON eKit.Event_Id = CSecToKit.Source_Event_Id 
	JOIN dbo.Prod_Units_Base AS puKit ON puKit.PU_Id = eKit.PU_Id 
		AND puKit.Equipment_Type = 'Kitting Station'
	JOIN dbo.Events AS eCSec ON eCSec.Event_Id = CSecToKit.Event_Id 
	JOIN dbo.Prod_Units_Base AS puCSec ON puCSec.PU_Id = eCSec.PU_Id 
		AND puCSec.Equipment_Type = 'Carrier Section'
 
 
