Create Procedure dbo.spDBR_Get_Sample_Time
@querycode int = 29,
@startendcode int = 1,
@TimeFormula varchar(50) = ''
AS
 	 
 	 if (@querycode = 0)
 	 begin
 	  	 insert into #sp_name_results execute spDBR_Shortcut_To_Time @TimeFormula
 	 end
 	 else
 	 begin
 	  	 declare @sqlstmt  nvarchar(50)
 	  	 set @sqlstmt = N'sprs_gettimeoptions ' + Convert(nvarchar, @querycode)
 	 
 	  	 create table #Date
 	  	 ( 	 
 	  	  	 Option_ID int,
 	  	  	 Date_Type_ID int,
 	  	  	 Description varchar(50),
 	  	  	 Start_Time varchar(50),
 	  	  	 End_Time varchar(50)
 	  	 )
 	  	 insert into #Date execute sp_executesql @sqlstmt
 	  	 if (@startendcode = 1)
 	  	 begin
 	  	  	 insert into #sp_name_results select Start_Time from #Date
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #sp_name_results select End_Time from #Date
 	  	 end
 	  	 drop table #Date
 	 end
