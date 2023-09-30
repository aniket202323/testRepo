
/*	---------------------------------------------------------------------------------------
	dbo.vMPWS_CarrierSectionToCarrier
	
	
	Date			Version		Build	Author  
	26-09-2017		001			001		Jim Cameron (GE Digital)		Initial development	 
---------------------------------------------------------------------------------------------*/
 
 
 
 
CREATE VIEW [dbo].[vMPWS_CarrierSectionToCarrier]
AS
SELECT     
	CSecToCar.Source_Event_Id CarEventId, 
	CSecToCar.Event_Id CSecEventId
FROM dbo.Event_Components CSecToCar 
	JOIN dbo.Events eCSec ON eCSec.Event_Id = CSecToCar.Event_Id 
	JOIN dbo.Prod_Units_Base puCSec ON puCSec.PU_Id = eCSec.PU_Id 
		AND puCSec.Equipment_Type = 'Carrier Section'
	JOIN dbo.Events eCar ON eCar.Event_Id = CSecToCar.Source_Event_Id 
	JOIN dbo.Prod_Units_Base puCar ON puCar.PU_Id = eCar.PU_Id 
		AND puCar.Equipment_Type = 'Carrier'
 
