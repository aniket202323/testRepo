Create Procedure dbo.spWD_GetHistory
@Id int,
@ET_Id int,
@Language_Id int = 0
AS
Create Table #T (TIMECOLUMNS nvarchar(50))
Declare @Col1 nvarchar(50),
        @Col2 nvarchar(50),
        @Col3 nvarchar(50),
        @Col4 nvarchar(50),
        @Col5 nvarchar(50),
        @Col6 nvarchar(50),
        @Col7 nvarchar(50),
        @Col8 nvarchar(50),
        @Col9 nvarchar(50),
        @Col10 nvarchar(50),
        @Col11 nvarchar(50),
        @Col12 nvarchar(50),
        @Col13 nvarchar(50),
        @Col14 nvarchar(50),
        @Col15 nvarchar(50),
        @Col16 nvarchar(50),
        @Col17 nvarchar(50),
        @Col18 nvarchar(50),
        @Col19 nvarchar(50),
        @Col20 nvarchar(50),
        @Col21 nvarchar(50),
        @Col22 nvarchar(50),
        @Col23 nvarchar(50),
 	  	 @Col24 nvarchar(50),
        @SQL nvarchar(3000),
        @vId nvarchar(10)
if @ET_Id = 2
  Begin
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6314
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6020
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6021
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6022
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6023
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    select * from #T
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6261 --User
    Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6314 --Modifed On
    Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6316 --Trans Type
    Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6020 --Start Date
    Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6021 --Start Time
    Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6022 --End Date
    Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6023 --End Time
    Select @Col8 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6124 --Uptime
    Select @Col9 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6024 --Downtime
    Select @Col10 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6025 --Product
    Select @Col11 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6026 --Location
    Select @Col12 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6027 --Status
    Select @Col13 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6182 --Fault
    Select @Col14 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6317 --Reason 1
    Select @Col15 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6318 --Reason 2
    Select @Col16 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6319 --Reason 3
    Select @Col17 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6320 --Reason 4
    Select @Col18 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6321 --Action 1
    Select @Col19 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6322 --Action 2
    Select @Col20 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6323 --Action 3
    Select @Col21 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6324 --Action 4
 	 Select @Col24 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6334
 	 Select @Col24 = @Col24 + ' Id' 	 
    Select @vId = Convert(nvarchar(10),@Id)
    Select @SQL = 'Select U.Username as [' + @Col1 + '], H.Modified_On as [' + @Col2 + '], T.DBTT_Desc as [' + @Col3 + '], H.Start_Time as [' + @Col4 + '], H.Start_Time as [' + @Col5 + '], H.End_Time as [' + @Col6 + '], H.End_Time as [' + @Col7 + '], 
           H.Uptime as [' + @Col8 + '], H.Duration as [' + @Col9 + '], P.Prod_Code as [' + @Col10 + '], PU.PU_Desc as [' + @Col11 + '], S.TEStatus_Name as [' + @Col12 + '], F.TEFault_Name as [' + @Col13 + '], 
           R1.Event_Reason_Name as [' + @Col14 + '], R2.Event_Reason_Name as [' + @Col15 + '], R3.Event_Reason_Name as [' + @Col16 + '], R4.Event_Reason_Name as [' + @Col17 + '], 
           A1.Event_Reason_Name as [' + @col18 + '], A2.Event_Reason_Name as [' + @Col19 + '], A3.Event_Reason_Name as [' + @Col20 + '], A4.Event_Reason_Name as [' + @Col21 + '],
           H.TEDet_Id as ['+ @Col24 +']
      From Timed_Event_Detail_History H
      Join Timed_Event_Details D on D.TEDet_Id = H.TEDet_Id
      Join DB_Trans_Types T on T.DBTT_Id = H.DBTT_Id
      Join Users U on U.User_Id = H.User_Id
      Left Join Prod_Units PU on PU.PU_Id = H.Source_PU_Id and PU.PU_Id > 0
      Join Production_Starts PS  on ((PS.pu_id = D.PU_Id) and (PS.start_time <= D.start_time) and ((PS.end_time > D.start_time) or (PS.end_time is null)))
      Join Products P on P.Prod_Id = PS.Prod_Id
      Left Outer Join Timed_Event_Status S on S.TEStatus_Id = H.TEStatus_Id
      Left Outer Join Timed_Event_Fault F on F.TEFault_Id = H.TEFault_Id
      Left Outer Join Event_Reasons R1 on R1.Event_Reason_Id = H.Reason_Level1
      Left Outer Join Event_Reasons R2 on R2.Event_Reason_Id = H.Reason_Level2
      Left Outer Join Event_Reasons R3 on R3.Event_Reason_Id = H.Reason_Level3
      Left Outer Join Event_Reasons R4 on R4.Event_Reason_Id = H.Reason_Level4
      Left Outer Join Event_Reasons A1 on A1.Event_Reason_Id = H.Action_Level1
      Left Outer Join Event_Reasons A2 on A2.Event_Reason_Id = H.Action_Level2
      Left Outer Join Event_Reasons A3 on A3.Event_Reason_Id = H.Action_Level3
      Left Outer Join Event_Reasons A4 on A4.Event_Reason_Id = H.Action_Level4'
      Select @SQL = @SQL + ' Where H.TEDet_Id = ' + @vId + ' Order By H.Modified_On DESC'
      exec (@SQL)
  End
else if @ET_Id = 3
  Begin
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6314
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6315
    Insert Into #T  (TIMECOLUMNS) Values (@Col1)
    select * from #T
    Select @Col1 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6261 --User
    Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6314 --Modifed On
    Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6316 --Trans Type
    Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6169 --Event
    Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6315 --Time
    Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6025 --Product
    Select @Col7 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6325 --Type
    Select @Col8 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6326 --Amount
    Select @Col9 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6327 --Units
    Select @Col10 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6026 --Location
    Select @Col11 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6317 --Reason 1
    Select @Col12 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6318 --Reason 2
    Select @Col13 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6319 --Reason 3
    Select @Col14 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6320 --Reason 4
    Select @Col15 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6321 --Action 1
    Select @Col16 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6322 --Action 2
    Select @Col17 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6323 --Action 3
    Select @Col18 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6324 --Action 4
 	 Select @Col24 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 6334
 	 Select @Col24 = @Col24 + ' Id'
Select @vId = Convert(nvarchar(10),@Id)
Select @SQL = 'Select U.Username as [' + @Col1 + '], H.Modified_On as [' + @Col2 + '], T.DBTT_Desc as [' + @Col3 + '], E.Event_Num as [' + @Col4 + '], 
           H.TimeStamp as [' + @Col5 + '], P.Prod_Code as [' + @Col6 + '], WET.WET_Name as [' + @Col7 + '], H.Amount as [' + @Col8 + '], WEM.WEMT_Name as [' + @Col9 + '], PU.PU_Desc as [' + @Col10 + '],
           R1.Event_Reason_Name as [' + @Col11 + '], R2.Event_Reason_Name as [' + @Col12 + '], R3.Event_Reason_Name as [' + @Col13 + '], R4.Event_Reason_Name as [' + @Col14 + '], 
           A1.Event_Reason_Name as [' + @Col15 + '], A2.Event_Reason_Name as [' + @Col16 + '], A3.Event_Reason_Name as [' + @Col17 + '], A4.Event_Reason_Name as [' + @Col18 + '],
           H.WED_Id as ['+ @Col24 +']
      From Waste_Event_Detail_History H
      Join Waste_Event_Details D on D.WED_Id = H.WED_Id
      Join DB_Trans_Types T on T.DBTT_Id = H.DBTT_Id
      Join Users U on U.User_Id = H.User_Id
      Left Join Prod_Units PU on PU.PU_Id = H.Source_PU_Id and PU.PU_Id > 0
      Join Production_Starts PS  on ((PS.pu_id = D.PU_Id) and (PS.start_time <= D.TimeStamp) and ((PS.end_time > D.TimeStamp) or (PS.end_time is null)))
      Join Products P on P.Prod_Id = PS.Prod_Id
      Left Outer Join Waste_Event_Type WET on WET.WET_Id = H.WET_Id
      Left Outer Join Waste_Event_Meas WEM on WEM.WEMT_Id = H.WEMT_Id
      Left Outer Join Events E on E.Event_Id = H.Event_Id
      Left Outer Join Event_Reasons R1 on R1.Event_Reason_Id = H.Reason_Level1
      Left Outer Join Event_Reasons R2 on R2.Event_Reason_Id = H.Reason_Level2
      Left Outer Join Event_Reasons R3 on R3.Event_Reason_Id = H.Reason_Level3
      Left Outer Join Event_Reasons R4 on R4.Event_Reason_Id = H.Reason_Level4
      Left Outer Join Event_Reasons A1 on A1.Event_Reason_Id = H.Action_Level1
      Left Outer Join Event_Reasons A2 on A2.Event_Reason_Id = H.Action_Level2
      Left Outer Join Event_Reasons A3 on A3.Event_Reason_Id = H.Action_Level3
      Left Outer Join Event_Reasons A4 on A4.Event_Reason_Id = H.Action_Level4'
Select @SQL = @SQL + ' Where H.WED_Id = ' + @vId + ' Order By H.Modified_On DESC'
      exec (@SQL)
  End
Drop Table #T
