-- execute spcmn_WasteData 7,1
Create Procedure dbo.spcmn_WasteData
 	 @PU_Id  	  	  	 Int,
    @Language_Id  	 Int,
 	 @DecimalSep     nvarchar(2) = '.',
 	 @StartDate 	  	 DateTime = null
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
        @SQL                    nvarchar(2000),
 	  	 @AmountStr 	  	  	  	 nvarchar(50)
If @DecimalSep != '.' 
  Select @AmountStr = 'Replace(Amount,''.'',''' + @DecimalSep + ''')'
Else 
  Select @AmountStr = 'Amount'
--If Required Prompt is not found, substitute the English prompt
 Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24105
 Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24124
 Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24119
 Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24120
 Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24121
 Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24122
 Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24125
If @StartDate is Null
   Begin
 	 DECLARE @timeTable table (RRDId Int,PDesc nvarchar(100),PromptId Int,StartTime Datetime,EndTime DateTime)
 	 DECLARE @TZ nvarchar(200)
 	 SELECT @TZ = dbo.fnServer_GetTimeZone(@PU_Id)
 	 Insert Into @timeTable(RRDId ,PDesc ,PromptId ,StartTime ,EndTime)
 	  	 EXECUTE dbo.spGE_GetRelativeDates @TZ
    	 SELECT @StartDate = StartTime FROM @timeTable Where RRDId = 30
   End
select [TIMECOLUMNS] = @Col1
If (Select Count(*)
 From Waste_Event_Details wed
 Where wed.PU_ID = @PU_Id and TimeStamp >= @StartDate and wed.Reason_Level4 is not null) > 0
    Begin
      Select @SQL = 'Select TimeStamp as [' + @Col1 + '],
                     WET_Name as [' + @Col2 + '],
                     er1.Event_Reason_Name as [' + @Col3 + '],
                     er2.Event_Reason_Name as [' + @Col4 + '],
                     er3.Event_Reason_Name as [' + @Col5 + '],
                     er4.Event_Reason_Name as [' + @Col6 + '],' +
                     @AmountStr + ' as [' + @Col7 + ']
                  From Waste_Event_Details wed
 	           Left Join Waste_Event_Type wet ON wed.WET_Id = wet.WET_Id
 	           Left Join Event_Reasons er1 on er1.Event_Reason_Id = wed.Reason_Level1
 	           Left  Join Event_Reasons er2 on er2.Event_Reason_Id = wed.Reason_Level2
 	           Left  Join Event_Reasons er3 on er3.Event_Reason_Id = wed.Reason_Level3
 	           Left  Join Event_Reasons er4 on er4.Event_Reason_Id = wed.Reason_Level4
 	           Where wed.PU_ID = ' + Convert(nVarChar(5),@PU_Id) + ' and (TimeStamp >= ' + '''' + Convert(nVarChar(40),@StartDate) + '''' + ')
 	           order by TimeStamp desc'
       exec (@SQL)
    End
Else If (Select Count(*)
 From Waste_Event_Details wed
 Where wed.PU_ID = @PU_Id and TimeStamp >= @StartDate and wed.Reason_Level3 is not null) > 0
    Begin
      Select @SQL = 'Select TimeStamp as [' + @Col1 + '],
                     WET_Name as [' + @Col2 + '],
                     er1.Event_Reason_Name as [' + @Col3 + '],
                     er2.Event_Reason_Name as [' + @Col4 + '],
                     er3.Event_Reason_Name as [' + @Col5 + '],' +
                     @AmountStr + ' as [' + @Col7 + ']
                  From Waste_Event_Details wed
 	           Left Join Waste_Event_Type wet ON wed.WET_Id = wet.WET_Id
 	           Left Join Event_Reasons er1 on er1.Event_Reason_Id = wed.Reason_Level1
 	           Left  Join Event_Reasons er2 on er2.Event_Reason_Id = wed.Reason_Level2
 	           Left  Join Event_Reasons er3 on er3.Event_Reason_Id = wed.Reason_Level3
 	           Where wed.PU_ID = ' + Convert(nVarChar(5),@PU_Id) + ' and (TimeStamp >= ' + '''' + Convert(nVarChar(40),@StartDate) + '''' + ')
 	           order by TimeStamp desc'
       exec (@SQL)
    End
Else If (Select Count(*)
 From Waste_Event_Details wed
 Where wed.PU_ID = @PU_Id and TimeStamp >= @StartDate and wed.Reason_Level2 is not null) > 0
    Begin
      Select @SQL = 'Select TimeStamp as [' + @Col1 + '],
                     WET_Name as [' + @Col2 + '],
                     er1.Event_Reason_Name as [' + @Col3 + '],
                     er2.Event_Reason_Name as [' + @Col4 + '],' +
                     @AmountStr + ' as [' + @Col7 + ']
                  From Waste_Event_Details wed
 	           Left Join Waste_Event_Type wet ON wed.WET_Id = wet.WET_Id
 	           Left Join Event_Reasons er1 on er1.Event_Reason_Id = wed.Reason_Level1
 	           Left  Join Event_Reasons er2 on er2.Event_Reason_Id = wed.Reason_Level2
 	           Where wed.PU_ID = ' + Convert(nVarChar(5),@PU_Id) + ' and (TimeStamp >= ' + '''' + Convert(nVarChar(40),@StartDate) + '''' + ')
 	           order by TimeStamp desc'
       exec (@SQL)
    End
Else
      Select @SQL = 'Select TimeStamp as [' + @Col1 + '],
                     WET_Name as [' + @Col2 + '],
                     er1.Event_Reason_Name as [' + @Col3 + '],' +
                     @AmountStr + ' as [' + @Col7 + ']
                  From Waste_Event_Details wed
 	           Left Join Waste_Event_Type wet ON wed.WET_Id = wet.WET_Id
 	           Left Join Event_Reasons er1 on er1.Event_Reason_Id = wed.Reason_Level1
 	           Where wed.PU_ID = ' + Convert(nVarChar(5),@PU_Id) + ' and (TimeStamp >= ' + '''' + Convert(nVarChar(40),@StartDate) + '''' + ')
 	           order by TimeStamp desc'
       exec (@SQL)
set nocount off
