Create Procedure dbo.spDBR_Get_Test_Names
@PU_ID int = '2',
@searchstring varchar(50) = '%'
AS 	 
 	 set @SearchString = '%' + @SearchString + '%'
 	 
/* 	 select distinct(Var_Desc) from Variables where Var_Desc like @SearchString and Var_ID > 0 and PU_ID = @PU_ID and PU_ID > 0 order by Var_desc
*/
select Var_Desc = coalesce(Test_Name, Var_Desc) 
  from Variables 
  where coalesce(Test_Name, Var_Desc) like  @SearchString and 
        Var_ID > 0 and 
        PU_ID = @PU_ID and 
        PU_ID > 0 
  order by coalesce(Test_Name, Var_Desc)
