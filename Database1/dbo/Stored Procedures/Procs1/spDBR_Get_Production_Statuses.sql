Create Procedure dbo.spDBR_Get_Production_Statuses
@pu_id int
AS 	 
select distinct s.prodstatus_id as StatusID, s.prodstatus_desc as StatusName
    from prdexec_trans t 
    join production_status s on s.prodstatus_id = t.to_prodstatus_id
    where t.pu_id = @pu_id 
