Create Procedure dbo.spDBR_Get_Reason_Description
@erc_id int
as
 	 insert into #sp_name_results select ERC_desc from Event_Reason_Catagories where ERC_id = @erc_id
