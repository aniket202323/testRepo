

/*Step B Creation Of SP*/
CREATE  PROCEDURE [dbo].spLocal_BDAT_OrderHistoryDetails

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_BDAT_OrderHistoryDetails
Author				:		Pratik Patil
Date Created		:		08-28-2023
SP Type				:		BDAT
Editor Tab Spacing  :       3
	
Description:
=========
This stored procedure provide details of process order status, Users who changed it. 


CALLED BY:  BDAT Tool

Revision 		Date			Who					   What
========		=====			====				   =====
1.0.0			28-Aug-2023	    Pratik Patil		   Creation of SP

Test Code:
Declare @Process_Order varchar(30) ='000909841170'
EXEC spLocal_BDAT_OrderHistoryDetails @Process_Order
*/

@Process_Order varchar(30)
AS

SELECT pph.Entry_On, pps.PP_Status_Desc, ub.Username FROM production_plan_history pph
JOIN production_plan_statuses pps on pph.pp_status_id = pps.pp_status_id
JOIN Users_Base ub ON pph.User_Id = ub.User_Id
WHERE process_order = @Process_Order ORDER BY pph.Entry_On DESC;

