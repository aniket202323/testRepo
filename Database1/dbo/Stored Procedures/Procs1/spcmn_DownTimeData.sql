--- spcmn_DownTimeData 7,1
Create Procedure dbo.spcmn_DownTimeData 
 	 @PU_Id int,
    @Language_Id int,
 	 @DecimalSep     nvarchar(2) = '.',
 	 @StartDate 	 DateTime = Null
  AS
set nocount on
Select @DecimalSep = coalesce(@DecimalSep,'.')
Declare @Col1                   nvarchar(50),
        @Col2                   nvarchar(50),
        @Col3                   nvarchar(50),         
        @Col4                   nvarchar(50),
        @Col5                   nvarchar(50),
        @Col6                   nvarchar(50), 
        @Col7                   nvarchar(50),
        @SQL                    nvarchar(2000)
--If Required Prompt is not found, substitute the English prompt
 Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24116
 Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24117
 Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24118
 Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24119
 Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24120
 Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24121
 Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24122
If @StartDate is Null
   Begin
 	 DECLARE @timeTable table (RRDId Int,PDesc nvarchar(100),PromptId Int,StartTime Datetime,EndTime DateTime)
 	 DECLARE @TZ nvarchar(200)
 	 SELECT @TZ = dbo.fnServer_GetTimeZone(@PU_Id)
 	 Insert Into @timeTable(RRDId ,PDesc ,PromptId ,StartTime ,EndTime)
 	  	 EXECUTE dbo.spGE_GetRelativeDates @TZ
    	 Select @StartDate =StartTime FROM @timeTable Where RRDId = 30
   End
DECLARE @TT Table (TIMECOLUMNS nvarchar(50))
Insert Into @TT  (TIMECOLUMNS) Values (@Col1)
Insert Into @TT  (TIMECOLUMNS) Values (@Col2)
select * from @TT
If (Select Count(*)
 From Timed_Event_Details ted
 Where ted.PU_ID = @PU_Id and (Start_Time >= @StartDate or End_Time is null) and ted.Reason_Level4 is not null) > 0
    Begin
      Select @SQL = 'Select Start_Time as [' + @Col1 + '],
                     Case When End_Time is null Then ''<active>''
 	  	      Else Convert(nvarchar(25),End_Time)
 	  	      End as [' + @Col2 + '],
                     Coalesce(TEFault_Name, ''n/a'') as [' + @Col3 + '],
                     er1.Event_Reason_Name as [' + @Col4 + '],
                     er2.Event_Reason_Name as [' + @Col5 + '],
                     er3.Event_Reason_Name as [' + @Col6 + '],
                     er4.Event_Reason_Name as [' + @Col7 + ']
                  From Timed_Event_Details ted
                  Left Join Timed_Event_Fault tef ON ted.TEFault_Id = tef.TEFault_Id
 	           Left Join Event_Reasons er1 on er1.Event_Reason_Id = ted.Reason_Level1
 	           Left  Join Event_Reasons er2 on er2.Event_Reason_Id = ted.Reason_Level2
 	           Left  Join Event_Reasons er3 on er3.Event_Reason_Id = ted.Reason_Level3
 	           Left  Join Event_Reasons er4 on er4.Event_Reason_Id = ted.Reason_Level4
 	           Where ted.PU_ID = ' + Convert(nVarChar(5),@PU_Id) + ' and (Start_Time >= ' + '''' + Convert(nVarChar(40),@StartDate) + '''' + 'or End_Time is null)
 	           order by Start_time desc'
       exec (@SQL)
    End
Else If (Select Count(*)
 From Timed_Event_Details ted
 Where ted.PU_ID = @PU_Id and (Start_Time >= @StartDate or End_Time is null) and ted.Reason_Level3 is not null) > 0
    Begin
      Select @SQL = 'Select Start_Time as [' + @Col1 + '],
                     Case When End_Time is null Then ''<active>''
 	  	      Else Convert(nvarchar(25),End_Time)
 	  	      End as [' + @Col2 + '],
                     Coalesce(TEFault_Name, ''n/a'') as [' + @Col3 + '],
                     er1.Event_Reason_Name as [' + @Col4 + '],
                     er2.Event_Reason_Name as [' + @Col5 + '],
                     er3.Event_Reason_Name as [' + @Col6 + ']
                  From Timed_Event_Details ted
                  Left Join Timed_Event_Fault tef ON ted.TEFault_Id = tef.TEFault_Id
 	           Left Join Event_Reasons er1 on er1.Event_Reason_Id = ted.Reason_Level1
 	           Left  Join Event_Reasons er2 on er2.Event_Reason_Id = ted.Reason_Level2
 	           Left  Join Event_Reasons er3 on er3.Event_Reason_Id = ted.Reason_Level3
 	           Where ted.PU_ID = ' + Convert(nVarChar(5),@PU_Id) + ' and (Start_Time >= ' + '''' + Convert(nVarChar(40),@StartDate) + '''' + 'or End_Time is null)
 	           order by Start_time desc'
       exec (@SQL)
    End
Else If (Select Count(*)
 From Timed_Event_Details ted
 Where ted.PU_ID = @PU_Id and (Start_Time >= @StartDate or End_Time is null) and ted.Reason_Level2 is not null) > 0
    Begin
      Select @SQL = 'Select Start_Time as [' + @Col1 + '],
                     Case When End_Time is null Then ''<active>''
 	  	      Else Convert(nvarchar(25),End_Time)
 	  	      End as [' + @Col2 + '],
                     Coalesce(TEFault_Name, ''n/a'') as [' + @Col3 + '],
                     er1.Event_Reason_Name as [' + @Col4 + '],
                     er2.Event_Reason_Name as [' + @Col5 + ']
                  From Timed_Event_Details ted
                  Left Join Timed_Event_Fault tef ON ted.TEFault_Id = tef.TEFault_Id
 	           Left Join Event_Reasons er1 on er1.Event_Reason_Id = ted.Reason_Level1
 	           Left  Join Event_Reasons er2 on er2.Event_Reason_Id = ted.Reason_Level2
 	           Where ted.PU_ID = ' + Convert(nVarChar(5),@PU_Id) + ' and (Start_Time >= ' + '''' + Convert(nVarChar(40),@StartDate) + '''' + 'or End_Time is null)
 	           order by Start_time desc'
       exec (@SQL)
    End
Else
 	 BEGIN
      Select @SQL = 'Select Start_Time as [' + @Col1 + '],
                     Case When End_Time is null Then ''<active>''
 	  	      Else Convert(nvarchar(25),End_Time)
 	  	      End as [' + @Col2 + '],
                     Coalesce(TEFault_Name, ''n/a'') as [' + @Col3 + '],
                     er1.Event_Reason_Name as [' + @Col4 + ']
                  From Timed_Event_Details ted
                  Left Join Timed_Event_Fault tef ON ted.TEFault_Id = tef.TEFault_Id
 	           Left Join Event_Reasons er1 on er1.Event_Reason_Id = ted.Reason_Level1
 	           Where ted.PU_ID = ' + Convert(nVarChar(5),@PU_Id) + ' and (Start_Time >= ' + '''' + Convert(nVarChar(40),@StartDate) + '''' + 'or End_Time is null)
 	           order by Start_time desc'
       exec (@SQL)
 	 END
set nocount off
