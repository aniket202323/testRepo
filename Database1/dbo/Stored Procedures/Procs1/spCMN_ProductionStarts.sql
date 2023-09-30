-- Execute spCMN_ProductionStarts 7,1
Create Procedure dbo.spCMN_ProductionStarts
 	 @PU_Id int,
        @Language_Id    Int,
 	 @StartDate 	 DateTime =   '08/14/2000'
  AS
If @StartDate is null select @StartDate = '08/14/2000'
Declare @Col1 nvarchar(50),
        @Col2 nvarchar(50),
        @Col3 nvarchar(50),         
        @Col4 nvarchar(50),
        @Col5 nvarchar(50),
        @SQL  nvarchar(2000)
--If Required Prompt is not found, substitute the English prompt
 Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24108
 Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24061
 Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24113
 Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24114
 Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24115
DECLARE @TT Table  (TIMECOLUMNS nvarchar(50))
Insert Into @TT  (TIMECOLUMNS) Values (@Col3)
Insert Into @TT  (TIMECOLUMNS) Values (@Col4)
select * from @TT
Select @SQL = 'Select Top 20 Prod_Code as [' + @Col1 + '], Case When End_Time Is Null Then ''In-Process'' Else ''Complete'' End as [' + @Col2 + '],
                Start_Time as [' + @Col3 + '], Case When End_Time is Null Then ''In-Process'' Else Convert(nvarchar(25),End_Time) End as [' + @Col4 + '],              
                case When End_Time is Null Then DateDiff(mi,Start_time,dbo.fnServer_CmnGetDate(getutcDate())) Else  	 DateDiff(mi,Start_time,End_Time) End as [' + @Col5 + '] 
                FROM Production_starts ps
                Join  products p on p.Prod_Id = ps.prod_Id
                   where pu_id = ' + Convert(nVarChar(5), @PU_Id) + ' and Start_Time > = ' + '''' + Convert(nVarChar(40),@StartDate) + '''' +'
                   order by Start_time desc'
exec (@SQL)
