Create Procedure dbo.spDBR_Get_Time_Value
@sp varchar(4000)
AS
 	 create table #Date
 	 (
 	  	 thedate varchar(100)
 	 )       
 	 EXECUTE sp_executesql @sp
 	 insert into #sp_name_results select thedate from #Date
 	 drop table #Date
