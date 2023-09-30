CREATE PROCEDURE dbo.spRS_GetCOARejectCodes
 AS
select COA_Reject_Id, COA_Reject_Desc from coa_reject_code
