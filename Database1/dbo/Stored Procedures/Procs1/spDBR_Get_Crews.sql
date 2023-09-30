CREATE Procedure dbo.spDBR_Get_Crews
AS
 	 select distinct crew_desc from crew_schedule order by crew_desc
