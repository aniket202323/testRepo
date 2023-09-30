Create Procedure dbo.spDBR_Get_Resource_Levels
AS 	 
 	 create table #levels
 	 (
 	  	 Level_Desc varchar(100),
 	  	 Level_ID int
 	 )
 	 insert into #levels values ('Department',1)
 	 insert into #levels values ('Line',2)
 	 insert into #levels values ('Unit',3)
 	 select * from #levels
