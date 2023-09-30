CREATE   PROCEDURE [dbo].[spDBR_GetRSTimeOptions] 
@Option_Id int = Null
AS
-------------------------------------
-- LOCAL VARIABLES
-------------------------------------
Declare @h varchar(3)
declare @m varchar(3)
Declare @t varchar(7)
Declare @optionName varchar(10)
Declare @Description varchar(20)
Declare @Start_Time datetime
Declare @End_Time datetime
Declare @s varchar(1000)
Declare @e varchar(1000)
Declare @x varchar(1000)
----------------------------------------------------------
-- Initialize Mill Start Time from Site_Parameters Table
----------------------------------------------------------
select @h = convert(varchar(2),Value) from site_parameters where parm_Id = 14
select @m = convert(varchar(2),Value) from site_parameters where parm_Id = 15
if Len(@M) = 1 Select @m = '0' + @m
select @t = @h + ':' +  @m  + ':00'
Create table #t(
  Option_id int,
  Description varchar(20),
  Start_Time varchar(30),
  End_Time varchar(30)
)
------------------------------------------------
-- Date_Type_Id = 3 are Start->End Time Ranges
------------------------------------------------
insert into #t(Option_Id, Description)
select RRD_Id, Default_Prompt_Desc from report_Relative_Dates where Date_Type_Id = 3 order by rrd_Id
Declare @MyId int
Declare MyCursor INSENSITIVE CURSOR
  For (
       Select option_Id
       From #t
      )
  For Read Only
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
      Select @s = Start_Date_SQL, @e = End_Date_SQL from Report_Relative_Dates where RRD_id = @MyId
      --------------------------
      -- Character Replacement
      --------------------------
      Select @s = replace(@s,'@t', '''' + @t + '''')
      Select @e = replace(@e,'@t', '''' + @t + '''')
      Select @e = replace(@e,'@H01', '''' + '-01 ' + '''')
      Select @e = replace(@e,'@H', '''' + '-' + '''')
      Select @s = 'update #t set Start_Time = ' + @s + ' where Option_Id = ' + convert(varchar(5), @MyId)
      Select @e = 'update #t set End_Time = ' + @e + ' where Option_Id = ' + convert(varchar(5), @MyId)
      -----------------------------------------
      -- Fill #t with the start and end times
      -----------------------------------------
      exec(@s)
      exec(@e)
      Goto MyLoop1
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd
myEnd:
Close MyCursor
Deallocate MyCursor
------------------------------------------
-- Select From #t the appropriate values
------------------------------------------
If @Option_Id is null
  Select Option_Id, Description, Start_Time, End_Time 
  From #t
Else
  Select Option_Id, Description, Start_Time, End_Time 
  From #t
  Where Option_Id = @Option_Id
drop table #t
