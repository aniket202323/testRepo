CREATE Procedure dbo.spDBR_ProcessOrderSearch
@PathList text = NULL
AS
SET ANSI_WARNINGS off
/*****************************************************
-- For Testing
--*****************************************************
Declare @PathList varchar(1000)
Select @PathList = '<Root></Root>'
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
      update #Paths set PathName = path_code from prdexec_Paths where path_id = pathid
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
create table #Statuses
(
 	 StatusId int,
 	 StatusName varchar(50)
)
insert into #Statuses 
  select distinct pp_status_id, pp_status_desc
    from production_plan_statuses 
--*****************************************************/
--*****************************************************/
--Return Header and Translation Information
--*****************************************************/
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
insert into #Columns values('Title', dbo.fnDBTranslate(N'0', 38109, 'Search For Process Orders'))
insert into #Columns values('Resource', dbo.fnDBTranslate(N'0', 38295, 'Resource'))
insert into #Columns values('Status', dbo.fnDBTranslate(N'0', 38118, 'Status'))
insert into #Columns values('ProductCode', dbo.fnDBTranslate(N'0', 38391, 'Product Code'))
insert into #Columns values('Time', dbo.fnDBTranslate(N'0', 38289, 'Time'))
insert into #Columns values('Search', dbo.fnDBTranslate(N'0', 38108, 'Search'))
select * from #Columns
drop table #Columns
select * from #Paths
  order by pathname
drop table #Paths
select * from #Statuses
  order by statusname
drop table #Statuses
