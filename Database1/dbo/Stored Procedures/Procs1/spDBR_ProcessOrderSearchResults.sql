CREATE Procedure dbo.spDBR_ProcessOrderSearchResults
@PathList text = NULL,
@StatusList text = NULL,
@ProductCode varchar(50) = NULL,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@ProcessOrderNumber varchar(50) = NULL,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
SET ANSI_WARNINGS off
Declare @ResourceDescription varchar(255)
Select @ResourceDescription = ''
/*****************************************************
-- For Testing
--*****************************************************
Declare @PathList varchar(1000)
Declare @StatusList varchar(1000)
Declare @ProductCode varchar(50)
Declare @StartTime datetime
Declare @EndTime datetime
Declare @ProcessOrderNumber varchar(50)
Select @PathList = '<Root></Root>'
Select @StatusList = '<Root></Root>'
Select @ProductCode = null
Select @StartTime = '1/1/2000'
Select @EndTime = '1/1/2004'
Select @ProcessOrderNumber = null
--*****************************************************/
--*****************************************************/
--Build List Of Execution Paths
--*****************************************************/
Create Table #Paths (
  PathName varchar(100) NULL,
  PathId int
)
if (not @PathList like '%<Root></Root>%' and not @PathList is NULL)
  begin
    if (not @PathList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'PathId;' + Convert(nvarchar(4000), @PathList)
      Insert Into #Paths (PathId) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Paths EXECUTE spDBR_Prepare_Table @PathList
    end
  end
Else
  Begin
    Insert Into #Paths (PathId, PathName) 
      Select distinct path_id, path_code From prdexec_paths     
  End
/*****************************************************
-- For Testing
--*****************************************************
truncate table #Paths
insert into #Paths (pathid, pathname) values (1, 'Test')
--*****************************************************/
--*****************************************************/
--*****************************************************/
--Build List Of Statuses
--*****************************************************/
Create Table #Status (
  StatusName varchar(100) NULL,
  StatusId int
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
if (not @StatusList like '%<Root></Root>%' and not @StatusList is NULL)
  begin
    if (not @StatusList like '%<Root>%')
    begin
      select @Text = N'StatusId;' + Convert(nvarchar(4000), @StatusList)
      Insert Into #Status (StatusId) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Status EXECUTE spDBR_Prepare_Table @StatusList
    end
  end
Else
  Begin
 	  	 insert into #Status (StatusId, StatusName)
 	  	   select distinct pp_status_id, pp_status_desc
 	  	     from production_plan_statuses 
  End
--*****************************************************/
--*****************************************************/
--Prepare Parameters
--*****************************************************/
If @ProductCode Is Null
  Select @ProductCode = ''
Select @ProductCode = '%' + @ProductCode + '%'
If @ProcessOrderNumber Is Null
  Select @ProcessOrderNumber = ''
Select @ProcessOrderNumber = '%' + @ProcessOrderNumber + '%'
--*****************************************************/
--Load Results Into Temporary Table
--*****************************************************/
create table #ProcessOrders
(
 	 IsBeingMadeNowFlag bit default 0,
 	 ProcessOrderNumber varchar(100) NULL,
 	 ResourceCode varchar(50) NULL,
 	 Status varchar(255) NULL,
 	 ProductCode varchar(50) NULL,
 	 PreQuantity varchar(255) NULL,
 	 Quantity decimal(10,2) NULL,
 	 PostQuantity varchar(255) NULL,
 	 Quantity2 decimal(10,2) NULL,
 	 PreStartTime varchar(255) NULL,
 	 StartTime datetime NULL,
 	 PostStartTime varchar(255) NULL,
 	 PreEndTime varchar(255) NULL,
 	 EndTime datetime NULL,
 	 PostEndTime varchar(255) NULL,
 	 ProcessOrderID int NULL,
  ImpliedSequence int NULL
)
Declare @@PathId int
Declare @PathCode varchar(100)
Declare @LineName varchar(100)
Declare Path_Cursor Insensitive Cursor 
  For Select PathId From #Paths 
  For Read Only
Open Path_Cursor
Fetch Next From Path_Cursor Into @@PathId
While @@Fetch_Status = 0
  Begin
    -- Look Up Resource Name
    Select @PathCode = path_code From prdexec_paths where path_id = @@PathId    
    if (not @PathList like '%<Root></Root>%' and not @PathList is NULL)
      If @ResourceDescription = '' 
        Select @ResourceDescription = @PathCode
      Else
        Select @ResourceDescription = @ResourceDescription + ', ' + @PathCode
    else
      Select @ResourceDescription = 'All'
    Select @LineName = pl_desc from prod_lines where pl_id = (Select pl_id from prdexec_paths where path_id = @@PathId)
    Insert Into #ProcessOrders (IsBeingMadeNowFlag, 	 ProcessOrderNumber, ResourceCode, Status,ProductCode, PreQuantity, Quantity, PostQuantity, Quantity2, PreStartTime, StartTime, PostStartTime, PreEndTime, EndTime, PostEndTime, ProcessOrderID, ImpliedSequence)
      Select IsBeingMadeNowFlag = Case
                                    When pp.pp_status_id = 3 Then 1
                                    Else 0
                                  End, 	 
             ProcessOrderNumber = '<b>' + pp.Process_Order + '</b>', 
             ResourceCode = @LineName + ' (' + @PathCode + ')', 
             Status = Case pp.pp_status_id
                        When 1 Then  '<font color=black><b>' + s.pp_status_desc + '</b></font>'
                        When 2 Then  '<font color=blue><b>' + s.pp_status_desc + '</b></font>'
                        When 3 Then  '<font color=green><b>' + s.pp_status_desc + '</b></font>'
                        When 4 Then  '<font color=gray>' + s.pp_status_desc + '</font>'
                        When 5 Then  '<font color=black>' + s.pp_status_desc + '</font>'
                        When 6 Then  '<font color=black>' + s.pp_status_desc + '</font>'
                        When 7 Then  '<font color=black><b>' + s.pp_status_desc + '</b></font>' 
                        Else s.pp_status_desc  
                      End,
             ProductCode = p.prod_code, 
 	      PreQuantityFormat = case
                          When pp.pp_status_id = 3 Then '<b>' + convert(varchar(25),convert(decimal(10,2),pp.forecast_quantity)) + '<font color=blue>' + '(' +  case when coalesce(pp.predicted_remaining_quantity,0) <= 0 Then '+' Else '' End
                          When pp.actual_good_quantity is null or pp.actual_good_quantity = 0 Then '<b>'
 	  	  	   else ''
                        end,
             Quantity = case
                          When pp.pp_status_id = 3 Then convert(decimal(10,2),-1 * coalesce(pp.predicted_remaining_quantity,0))
                          When pp.actual_good_quantity is null or pp.actual_good_quantity = 0 Then convert(decimal(10,2),pp.forecast_quantity)
                          Else convert(decimal(10,2),pp.actual_good_quantity)
                        end, 
             PostQuantity = case
                          When pp.pp_status_id = 3 Then ')' + '</font>' + '</b>'
                          When pp.actual_good_quantity is null or pp.actual_good_quantity = 0 Then '</b>'
                          Else '<font color=red><small>' + '(' +  case when coalesce(pp.predicted_remaining_quantity,0) <= 0 Then '+' Else '' End + '@remainingquantity@' + ')' + '</small></font>'
                        end, 
 	      Quantity2 = convert(decimal(10,2),-1 * coalesce(pp.predicted_remaining_quantity,0)),
 	      PreStartTime = '<b>',
             StartTime = Case
                            When pp.actual_start_time is null Then pp.forecast_start_date
                            Else pp.actual_start_time
/*                            When pp.actual_start_time is null Then convert(varchar(20),pp.forecast_start_date,109)
                            Else convert(varchar(20),pp.actual_start_time,109)*/
                         End,
 	      PostStartTime = '</b>',  
 	      PreEndTime = '<b>',
             EndTime = Case
                         When pp.predicted_remaining_duration is null Then pp.forecast_end_date
                         When pp.actual_start_time is null Then pp.forecast_end_date
                         When pp.pp_status_id = 3 Then dateadd(minute,coalesce(pp.predicted_remaining_duration,0),pp.actual_start_time)
                         When pp.actual_end_time is not null Then + pp.actual_end_time
                         Else pp.forecast_end_date
                       End,
 	      PostEndTime = Case
                         When pp.predicted_remaining_duration is null Then '</b>'
                         When pp.actual_start_time is null Then '</b>'
                         When pp.pp_status_id = 3 Then '<font color=blue>' + '(' +  case 
                                                               when coalesce(pp.predicted_remaining_duration,0) <= 0 Then '+' 
                                                               Else '' 
                                                             End + 
                                 convert(varchar(25),
                                            floor(-1 * 
                                                    coalesce(pp.predicted_remaining_duration / 60.0 ,0)
                                                  )
                                         ) + ':' +
                                 right ('0' + convert(varchar(25),
                                                    coalesce(convert(int, pp.predicted_remaining_duration) % 60 ,0)
                                                     )
                                       ,2) 
                                + ')' + '</font>' + '</b>'
                         When pp.actual_end_time is not null Then '<font color=red><small>' + '(' +  case 
                                                               when coalesce(pp.predicted_remaining_duration,0) <= 0 Then '+' 
                                                               Else '' 
                                                             End + 
                                 convert(varchar(25),
                                            floor(-1 * 
                                                    coalesce(pp.predicted_remaining_duration / 60.0 ,0)
                                                  )
                                         ) + ':' +
                                 right ('0' + convert(varchar(25),
                                                    coalesce(convert(int, pp.predicted_remaining_duration) % 60 ,0)
                                                     )
                                       ,2) 
                                + ')' + '</small></font>'
                         Else '</b>'
                       End,  
             ProcessOrderID = pp.pp_id, 
             ImpliedSequence = pp.implied_sequence
      from Production_Plan pp
      Join #Status l on l.StatusId = pp.pp_Status_id
      Join products p on p.prod_id = pp.prod_id
      Join production_plan_statuses s on s.pp_status_id = pp.pp_status_id
      Where pp.path_id = @@PathId and
            ( 
 	  	  	  	  	  	  	 coalesce(pp.actual_start_time, pp.forecast_start_date) between @StartTime and @EndTime or
 	  	  	  	  	  	  	 coalesce(pp.actual_end_time, pp.forecast_end_date) between @StartTime and @EndTime or
 	  	  	  	  	  	  	 (@StartTime < coalesce(pp.actual_start_time, pp.forecast_start_date) and @EndTime > coalesce(pp.actual_end_time, pp.forecast_end_date)) or
 	  	  	  	  	  	  	 @EndTime > coalesce(pp.actual_start_time, pp.forecast_start_date) and pp.actual_end_time is null
 	  	  	  	  	  	 ) and
            pp.process_order Like @ProcessOrderNumber and
            p.Prod_Code like @ProductCode
    Fetch Next From Path_Cursor Into @@PathId
  End
Close Path_Cursor
Deallocate Path_Cursor  
--*****************************************************/
--Return Header and Translation Information
--*****************************************************/
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(255)
)
Declare @Description varchar(255)
If len(@ResourceDescription) > 200 
  Select @Description = dbo.fnDBTranslate(N'0', 38392, 'Multiple Units') + case When @ProductCode = '%%' then '; ' + dbo.fnDBTranslate(N'0', 38393, 'Product=All') Else '; ' + dbo.fnDBTranslate(N'0', 38394, 'Product Like') + ' ' + @ProductCode End
Else 
  Select @Description = dbo.fnDBTranslate(N'0', 38395, 'Resources') + '=' + @ResourceDescription + case When @ProductCode = '%%' then '; ' + dbo.fnDBTranslate(N'0', 38393, 'Product=All') Else '; ' + dbo.fnDBTranslate(N'0', 38394, 'Product Like') + ' ' + @ProductCode End
insert into #Columns (ColumnName, Prompt) values('Description',@Description)
insert into #Columns (ColumnName, Prompt) values('ProcessOrderNumber',dbo.fnDBTranslate(N'0', 38396,'Process Order'))
insert into #Columns (ColumnName, Prompt) values('ResourceCode',dbo.fnDBTranslate(N'0', 38295,'Resource'))
insert into #Columns (ColumnName, Prompt) values('Status',dbo.fnDBTranslate(N'0', 38305,'Status'))
insert into #Columns (ColumnName, Prompt) values('ProductCode',dbo.fnDBTranslate(N'0', 38157,'Product'))
insert into #Columns (ColumnName, Prompt) values('Quantity',dbo.fnDBTranslate(N'0', 38397,'Quantity'))
insert into #Columns (ColumnName, Prompt) values('StartTime',dbo.fnDBTranslate(N'0', 38302,'Start'))
insert into #Columns (ColumnName, Prompt) values('EndTime',dbo.fnDBTranslate(N'0', 38303,'End'))
select * from #Columns
Drop Table #Columns
---23/08/2010 - Update datetime formate in UTC into #ProcessOrders table
Update #ProcessOrders Set StartTime = dbo.fnServer_CmnConvertFromDBTime(StartTime,@InTimeZone),
 	  	  	  	  	  	  	 EndTime = dbo.fnServer_CmnConvertFromDBTime(EndTime,@InTimeZone)
--*****************************************************/
--Return Search Results
--*****************************************************/
If @ProcessOrderNumber = '%%' 
 	 select top 100 * from #ProcessOrders
 	   order by ResourceCode, ImpliedSequence ASC
Else
 	 select top 100 * from #ProcessOrders
 	   order by ProcessOrderNumber, ResourceCode
drop table #ProcessOrders
drop table #Paths
drop table #Status
