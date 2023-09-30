 -- EXECUTE dbo.spCMN_QualityData 7,1,null
Create Procedure dbo.spCMN_QualityData
 	 @PU_Id 	  	  	 Int,
    @Language_Id 	 Int,
 	 @StartTime 	  	 DateTime
  AS
set nocount on
Declare @MasterPU_Id int,
 	  	 @EventId     int,
 	  	 @TimeStamp  DateTime,
        @Col3       nvarchar(50),
        @Col4       nvarchar(50),
        @Col5       nvarchar(50),
        @Col6       nvarchar(50),
        @SQL        nvarchar(2000),
 	  	 @Now 	  	 DateTime
--If Required Prompt is not found, substitute the English prompt
Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
               Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
               where ld.Language_Id = 0 and ld.Prompt_Number = 24036
Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
               Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
               where ld.Language_Id = 0 and ld.Prompt_Number = 24061
Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
               Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
               where ld.Language_Id = 0 and ld.Prompt_Number = 24112
Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
               Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
               where ld.Language_Id = 0 and ld.Prompt_Number = 24038
Select @Now =  dbo.fnServer_CmnGetDate(GetutcDate())
If @StartTime is Null
   Begin
 	 DECLARE @timeTable table (RRDId Int,PDesc nvarchar(100),PromptId Int,StartTime Datetime,EndTime DateTime)
 	 DECLARE @TZ nvarchar(200)
 	 SELECT @TZ = dbo.fnServer_GetTimeZone(@PU_Id)
 	 Insert Into @timeTable(RRDId ,PDesc ,PromptId ,StartTime ,EndTime)
 	  	 EXECUTE dbo.spGE_GetRelativeDates @TZ
    	 Select @StartTime = StartTime FROM @timeTable Where RRDId = 30
   End
Create Table #Events(  	 Event_Id int,
 	  	  	 Icon_Id 	 Int,
 	  	  	 Event_num nvarchar(25),
 	  	  	 ProdStatus_Desc nvarchar(25) Null,
 	  	  	 Timestamp  Datetime,
 	  	  	 prod_code nvarchar(25) Null)
  SELECT @MasterPU_Id  = coalesce((select master_unit from prod_units where pu_id = @PU_Id),@PU_Id)
  --
Insert into #Events(Event_Id,Icon_Id,Event_num,Timestamp,ProdStatus_Desc,prod_code)
  SELECT  e.Event_Id,ps.Icon_Id,e.Event_num,e.Timestamp,ps.ProdStatus_Desc,p.Prod_Code
    FROM Events e
    Join  Production_Status ps on ps.ProdStatus_Id = e.event_status
 	 left Join Products p on p.Prod_id = e.Applied_Product
   where  e.pu_id  = @MasterPU_Id  and e.timestamp between  @StartTime and  @Now
    order by Timestamp desc
Execute ( 'Declare QualityDataEventCursor Cursor Global ' +
  'For Select Event_Id,TimeStamp from #Events ' +
  'Where Prod_Code Is Null ' +
  'For Update')
  Open  QualityDataEventCursor   
 QualityDataEventCursorLoop1:
  Fetch Next From  QualityDataEventCursor  Into @EventId,@TimeStamp
  If (@@Fetch_Status = 0)
    Begin
         update #Events set prod_code = (
              Select Prod_Code From     Production_Starts s
 	    Join  Products pp on pp.prod_id = s.prod_id
 	    Where s.Start_Time <= @TimeStamp and  (s.End_time > @TimeStamp or  s.End_time is null) and s.pu_id = @MasterPU_Id)
 	 where current of QualityDataEventCursor
        Goto QualityDataEventCursorLoop1
    End
Close  QualityDataEventCursor 
Deallocate  QualityDataEventCursor 
select [TIMECOLUMNS] = @Col5
Select @SQL = 'Select [Key] = Event_Id, Icon = Icon_Id, Event_num as [' + @Col3 + '], ProdStatus_Desc as [' + @Col4 + '], 
               Timestamp as [' + @Col5 + '], Prod_Code as [' + @Col6 + '] from #Events'
exec (@SQL)
Drop table #Events
set nocount off
