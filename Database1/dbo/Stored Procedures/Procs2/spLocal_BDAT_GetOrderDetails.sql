

/*Step B Creation Of SP*/
CREATE  PROCEDURE [dbo].spLocal_BDAT_GetOrderDetails

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_BDAT_GetOrderDetails
Author				:		Pratik Patil
Date Created		:		08-28-2023
SP Type				:		BDAT
Editor Tab Spacing  :       3
	
Description:
=========
This Stored procedure will provide details of upload messages of process order and current status of PO.
CALLED BY:  BDAT Tool
Revision 		Date			Who					   What
========		=====			====				   =====
1.0.0			28-Aug-2023	    Pratik Patil		   Creation of SP
Test Code:
Declare @Process_Order varchar(30) ='000909841170'
EXEC spLocal_BDAT_GetOrderDetails @Process_Order
*/

@Process_Order VARCHAR(30)
AS

SELECT Id,MainData,Message,ProcessedDate,errormessage FROM Local_tblINTIntegrationMessages 
WHERE  MainData like '%' + @Process_Order + '%' and SystemSource = 'MES' ORDER BY InsertedDate DESC;


SELECT pps.pp_status_desc FROM production_plan pph
JOIN production_plan_statuses pps ON pph.pp_status_id = pps.pp_status_id
WHERE process_order = @Process_Order ORDER BY Entry_On DESC;

