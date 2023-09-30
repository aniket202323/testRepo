Create PROCEDURE [dbo].[spRS_GetTimeOptions_New]
@Option_Id int =null,
@InTimezone varchar(200) =null
AS
Declare @TimeOptions as Table (Option_Id int, Date_Type_Id int,Description varchar(50),Start_Time datetime,End_Time datetime)
Declare @sqlstr varchar(300)
 If (@Option_Id IS NULL)
 BEGIN
 	 SELECT @sqlstr = 'spRS_GetTimeOptions null,' + '''' + @InTimezone + ''''
 	 PRINT @sqlstr
 	 insert into @TimeOptions  EXEC(@sqlstr)
 	 select Option_Id as Id,Start_Time,End_Time From @TimeOptions where Option_Id Between 25 and 31
 	 order by Option_Id
 	 END
 Else
 BEGIN
 SELECT @sqlstr = 'spRS_GetTimeOptions' + ''''+ convert(varchar(3),@Option_Id) + ''',' + '''' + @InTimezone + ''''
 	 PRINT @sqlstr
 	 insert into @TimeOptions  EXEC(@sqlstr)
 	 select Option_Id as Id,Start_Time,End_Time From @TimeOptions where Option_Id=@Option_Id
 	 order by Option_Id
 END
