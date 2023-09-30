Create Procedure dbo.spDBR_Get_Priority_Levels
AS 	 
 	 create table #levels
 	 (
 	  	 Priority_Desc varchar(100),
 	  	 Priority_ID int
 	 )
 	 insert into #levels values ('Low',1)
 	 insert into #levels values ('Medium',2)
 	 insert into #levels values ('High',3)
 	 select * from #levels
