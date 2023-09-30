Create Procedure dbo.spDBR_Get_Reasons
@searchstring varchar(50) = ''
AS 	 
 	 if (@searchstring = '')
 	 begin
 	  	 select ERC_ID, ERC_Desc from Event_Reason_Catagories where ERC_ID > 0 order by ERC_desc
 	 end
 	 else
 	 begin
 	  	 set @SearchString = '%' + @SearchString + '%'
 	  	 select ERC_ID, ERC_Desc from Event_Reason_Catagories where ERC_ID > 0 and ERC_Desc like @SearchString order by ERC_desc 	  	 
 	 end
