Create Procedure dbo.spDBR_Get_Slave_Units
@MasterID int
AS 	 
 	 select PU_ID, PU_Desc from Prod_Units where master_unit = @MasterID or pu_id = @masterID and pu_id > 0 order by pu_desc
