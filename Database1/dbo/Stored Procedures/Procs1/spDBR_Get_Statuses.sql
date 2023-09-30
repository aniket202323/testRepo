Create Procedure dbo.spDBR_Get_Statuses
@searchstring varchar(50)
AS 	 
 	 if (@searchstring = '')
 	 begin
 	  	 select ProdStatus_ID, ProdStatus_Desc from Production_Status where ProdStatus_ID > 0 order by prodstatus_desc
 	 end
 	 else
 	 begin
 	  	 set @SearchString = '%' + @SearchString + '%'
 	  	 select ProdStatus_ID, ProdStatus_Desc from Production_Status where ProdStatus_ID > 0 and ProdStatus_Desc like @SearchString order by prodstatus_desc
 	 end
