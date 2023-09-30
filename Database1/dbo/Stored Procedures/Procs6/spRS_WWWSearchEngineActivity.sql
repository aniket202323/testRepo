CREATE PROCEDURE [dbo].[spRS_WWWSearchEngineActivity]
@Engine_Id int = Null, 
@ErrorLevel int = Null,
@Mask varchar(255) = Null,
@Range int
 AS
-----------------------------
-- LOCAL VARIABLES
-----------------------------
Declare @SQLStr varchar(1000)
Declare @StartDate datetime
-----------------------------
-- INITIALIZE
-----------------------------
Select @StartDate = DateAdd(day, -@Range, GetDate())
Select @SQLStr = 'Select Time, re.Engine_Name + ' + '''' + '-' + '''' +
 	 ' + re.Service_Name ' + '''' + 'Engine' + '''' + ', Message From Report_Engine_Activity rea ' +
 	 ' join report_engines re on re.engine_id = rea.engine_id' +
 	 ' Where Message like '
/*
Select @SQLStr = 'Select Time, Engine_Id, Message From Report_Engine_Activity Where Message like ' 
*/
If @Mask is null 
  Select @SQLStr = @SQLStr + '''' + '%' + ''''
Else
  Select @SQLStr = @SQLStr + '''' + '%' + @Mask + '%' + ''''
If @Engine_Id is not null
  Select @SQLStr = @SQLStr + ' AND RE.Engine_Id = ' + convert(varchar(5), @Engine_Id)
If @ErrorLevel is not null
  Select @SQLStr = @SQLStr + ' AND ErrorLevel = ' + convert(varchar(5), @ErrorLevel)
  Select @SQLStr = @SQLStr + ' AND Time > ' + '''' + convert(varchar(25), @StartDate) + ''''
 Select @SQLStr = @SQLStr + ' Order By Time Desc'
Exec(@SQLStr)
