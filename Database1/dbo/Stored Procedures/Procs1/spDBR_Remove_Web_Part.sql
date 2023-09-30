Create Procedure dbo.spDBR_Remove_Web_Part
@webpartid int
AS
 	 delete from  Dashboard_Parts where dashboard_part_id = @webpartid
