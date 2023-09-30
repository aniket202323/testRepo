Create Procedure dbo.spGE_GetInputHistory
 	 @PU_Id  	 int,
 	 @PEIID 	 Int,
   @Language_Id int
  AS
  --
 Declare @Col1 nvarchar(50),
         @Col2 nvarchar(50),
         @Col3 nvarchar(50),         
         @Col4 nvarchar(50),
         @Col5 nvarchar(50),
         @Col6 nvarchar(50), 
         @SQL  nvarchar(2000),
 	  	  @Now  DateTime
SELECT @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
--If Required Prompt is not found, substitute the English prompt
 Select @Col2 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24104
 Select @Col3 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24036
 Select @Col4 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24061
 Select @Col5 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24105
 Select @Col6 = coalesce(ld2.Prompt_String, ld.Prompt_String) from Language_Data ld 
                Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @Language_Id
                where ld.Language_Id = 0 and ld.Prompt_Number = 24106
Create Table #Output ( [Key]            Int,
                       [Input]          nvarchar(50),
                       [Event Number]   nvarchar(25),
                       Status           nvarchar(25),
 	  	        Time             DateTime,
 	  	        Action           nVarChar(15))
IF @PEIID = 0 
 Insert Into #Output ([Key],[Input],[Event Number],Status ,Time,Action) 
  SELECT  Input_Event_History_Id,Input_Name,Event_num,ProdStatus_Desc ,pie.Timestamp,case when Unloaded = 1 then 'Unloaded'
 	  	  	  	  	  	  	  	  	  	  	  when Unloaded = 3 Then 'Substitute'
 	  	  	  	  	  	  	  	  	  	  	  Else 'Loaded' 
 	  	  	  	  	  	  	  	  	  	     End
  From PrdExec_Input_Event_History pie
    Join PrdExec_Inputs pei on pei.pei_Id = pie.PEI_Id
    Join Events e on e.Event_Id = pie.Event_Id
    Join  Production_Status p on p.ProdStatus_Id = e.event_status
    where  pie.timestamp between  dateadd(day,-1,@Now)  and @Now
 	 and  pie.PEI_Id  in (select PEI_Id from PrdExec_Inputs where pu_id  = @PU_Id)
 	 and Peip_Id = 1
Else
 Insert Into #Output([Key],[Input],[Event Number],Status ,Time,Action) 
  SELECT  Input_Event_History_Id,Input_Name,Event_num,ProdStatus_Desc ,pie.Timestamp,case when Unloaded = 1 then 'Unloaded'
 	  	  	  	  	  	  	  	  	  	  	  when Unloaded = 3 Then 'Substitute'
 	  	  	  	  	  	  	  	  	  	  	  Else 'Loaded' 
 	  	  	  	  	  	  	  	  	  	     End
  From PrdExec_Input_Event_History pie
    Join PrdExec_Inputs pei on pei.pei_Id = pie.PEI_Id
    Join Events e on e.Event_Id = pie.Event_Id
    Join  Production_Status p on p.ProdStatus_Id = e.event_status
    where  pie.timestamp between  dateadd(day,-1,@Now)  and @Now
 	 and  pie.PEI_Id  = @PEIID and Peip_Id = 1 
Select @SQL = 'Select [Key], [Input] as [' + @Col2 + '], [Event Number] as [' + @Col3 + '], Status as [' + @Col4 + '], Time as [' + @Col5 + '], Action as [' + @Col6 + '] from #Output Order by time desc'
select [TIMECOLUMNS] = @Col5
exec (@SQL)
drop table #Output
