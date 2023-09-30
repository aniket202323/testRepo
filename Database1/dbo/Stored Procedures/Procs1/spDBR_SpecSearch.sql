CREATE Procedure dbo.spDBR_SpecSearch
@UnitList text = NULL
AS
SET ANSI_WARNINGS off
/*********************************
-- For Testing
--**********************************
Declare @UnitList varchar(1000)
--**********************************/
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
create table #Units
(
  LineName varchar(100) NULL, 
  LineId int NULL,
 	 UnitName varchar(100) NULL,
 	 UnitID int
)
insert into #Columns values('Title', dbo.fnDBTranslate(N'0', 38110, 'Search For Specifications'))
insert into #Columns values('Unit', dbo.fnDBTranslate(N'0', 38129, 'Unit'))
insert into #Columns values('RelativeTime', dbo.fnDBTranslate(N'0', 38289, 'Time'))
insert into #Columns values('Search', dbo.fnDBTranslate(N'0', 38108, 'Search'))
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'UnitId;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (UnitID) EXECUTE spDBR_Prepare_Table @Text
      update #Units set UnitName = pu_desc from prod_units where pu_id = UnitId
    end
    else
    begin
      insert into #Units (LineName, LineId, UnitName, UnitId) EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
else
begin
 	 insert into #Units (LineName, LineId, UnitName, UnitId) select l.pl_desc, l.pl_id, u.pu_desc, u.pu_id from prod_units u, prod_lines l where u.pl_id = l.pl_id and not u.pu_id = 0 and not l.pl_id = 0 order by u.pu_desc
end
select * from #Columns
drop table #Columns
select * from #Units
drop table #Units
