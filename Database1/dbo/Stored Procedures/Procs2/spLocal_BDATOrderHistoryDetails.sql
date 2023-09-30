

/*Step B Creation Of SP*/
CREATE  PROCEDURE [dbo].spLocal_BDATOrderHistoryDetails

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_BDATOrderHistoryDetails
Author				:		Pratik Patil
Date Created		:		07-27-2023
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
EXEC spLocal_BDATOrderHistoryDetails @Process_Order
*/

@Process_Order varchar(30)
AS

select pph.Entry_On, pps.PP_Status_Desc, ub.Username from production_plan_history pph
join production_plan_statuses pps on pph.pp_status_id = pps.pp_status_id
join Users_Base ub on pph.User_Id = ub.User_Id
where process_order = @Process_Order order by pph.Entry_On desc

