Create Procedure dbo.spDBR_Get_Time_Description
@code varchar(5) = 29,
@TimeFormula varchar(50) = ''
AS
 	 if (@code = 0)
 	 begin
 	  	 if (@TimeFormula = "")
 	  	 begin
 	  	  	 insert into #sp_name_results values ('User Defined')
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #sp_name_results values (@TimeFormula)
 	  	 end
 	 end
 	 else
 	 begin
 	  	 declare @sqlstmt  nvarchar(50)
 	  	 set @sqlstmt = N'spRS_gettimeoptions ' + Convert(nvarchar, @code)
 	  	 
 	  	 create table #Date
 	  	 ( 	 
 	  	  	 Option_ID int,
 	  	  	 Date_Type_ID int,
 	  	  	 Description varchar(50),
 	  	  	 Start_Time varchar(50),
 	  	  	 End_Time varchar(50)
 	  	 )
 	  	 insert into #Date execute sp_executesql @sqlstmt
 	  	 
 	  	 insert into #sp_name_results select Description from #Date  
 	  	 drop table #Date
 	 end
