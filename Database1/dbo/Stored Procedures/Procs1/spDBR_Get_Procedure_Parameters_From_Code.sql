Create Procedure dbo.spDBR_Get_Procedure_Parameters_From_Code
@procName varchar(100)
AS
 	 create table #spProc_Params
 	 (
 	  	 paramname varchar(100)
 	 )
 	 
 	 declare @id int
 	 declare @procText nvarchar(4000)
 	 set @id = (select id from sysobjects where name = @procName)
 	 set @procText = (select text from syscomments where id = @id and number = 1 and colid = 1)
 	 declare @paramCount int 	 
 	 declare @currentParameter int 	 
 	 set @paramCount = (select distinct(input) from Client_SP_Prototypes where Command_Text = @procName)
 	 set @currentParameter = (1)
 	 
 	 declare @index int
 	 declare @endvariable int
 	 declare @endindex int
 	 
 	 
 	 
 	 set @index = (select charindex('@', @procText, 0))
 	 
 	 while (@currentParameter <= @paramCount) 
 	 begin
 	  	 set @endvariable = (select charindex(' ', @procText, @index))
 	  	 if (@endvariable > @index and @endvariable <> 0 and @index <> 0)
 	  	 begin
 	  	  	 insert into #spProc_Params select substring(@procText, @index, @endvariable-@index)
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #spProc_Params values (' ')
 	  	 end
 	  	 set @index = (select charindex('@', @procText, @index+1))
 	  	 
 	  	 set @currentParameter = (@currentParameter + 1)
 	 end
 	 /*set @endvariable = (select charindex(' ',@procText, @index))
 	 
 	 insert into #spProc_Params select substring(@procText, @index, @endvariable-@index)
 	 */
 	 
 	 select * from #spProc_Params 	 
 	 
 	 drop table #spProc_Params
