Create Procedure dbo.spDBR_Search_Lines
@SearchString varchar(50)
AS 	 
 	 set @SearchString = '%' + @SearchString + '%'
 	 
 	 select PL_ID, PL_Desc from Prod_Lines where PL_Desc like @SearchString and PL_ID > 0 order by pl_desc
