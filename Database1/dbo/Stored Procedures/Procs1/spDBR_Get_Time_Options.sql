Create Procedure dbo.spDBR_Get_Time_Options
AS
 	 execute spdbr_gettimeoptions
/* 	 create table #options
 	 (
 	  	 id int
 	 )
 	 create table #Return_Data
 	 (
 	  	 id int,
 	  	 time_desc varchar(200),
 	  	 start_time varchar(200),
 	  	 end_time varchar(200),
 	  	 start_query varchar(3500),
 	  	 end_query varchar(3500)
 	 )
 	 create table #Date
 	 (
 	  	 thedate varchar(200)
 	 )
 	 
 	 insert into #options select Dashboard_Opt_ID from Dashboard_Time_Options
 	 
 	 declare @id int
 	 declare @desc varchar(200)
 	 declare @start varchar(200)
 	 declare @end varchar(200)
 	 declare @startquery nvarchar(4000)
 	 declare @endquery nvarchar(4000)
 	 
 	 set @id = (select min(id) from #options)
 	 
 	 while (Not @id is null)
 	 begin
 	  	 set @desc = (select Dashboard_Opt_Display from Dashboard_Time_Options where Dashboard_Opt_ID = @id)
 	  	 
 	  	 set @startquery = (select Dashboard_Opt_StartTime from Dashboard_Time_Options where Dashboard_Opt_ID = @id)
 	  	 set @endquery = (select Dashboard_Opt_EndTime from Dashboard_Time_Options where Dashboard_Opt_ID = @id)
 	  	 delete from #Date
 	  	 EXECUTE sp_executesql @startquery
 	  	 set @start = (select thedate from #Date) 
 	  	 delete from #Date
 	  	 EXECUTE sp_executesql @endquery
 	  	 set @end = (select thedate from #Date)
 	  	 
 	  	 insert into #Return_Data values (@id, @desc, @start, @end, @startquery, @endquery) 	 
 	  	 delete from #options where id=@id
 	  	 set @id = (select min(id) from #options) 	 
 	 end
 	 select * from #Return_Data
 	 
 	 drop table #options
 	 drop table #Return_Data
 	 
*/
