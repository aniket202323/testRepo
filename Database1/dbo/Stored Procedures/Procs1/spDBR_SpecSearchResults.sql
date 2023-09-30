CREATE Procedure dbo.spDBR_SpecSearchResults
@UnitList text = NULL,
@ProductCode varchar(50) = null,
@Timestamp datetime = NULL,
@InTimeZone varchar(200) = NULL
AS
SET ANSI_WARNINGS off
/***************************i
--  For Testing
--****************************
Declare @UnitList varchar(1000)
Declare @ProductCode varchar(50)
Declare @Timestamp datetime
Select @UnitList  = '<Root></Root>'
Select @ProductCode = 'Gloss'
--****************************/
Declare @Description varchar(1000)
SELECT @Timestamp = dbo.fnServer_CmnConvertToDBTime(@Timestamp,@InTimeZone)
If @ProductCode Is Null
  Begin
    Select @Description = dbo.fnDBTranslate(N'0', 38157, 'Product') + ' = ' + dbo.fnDBTranslate(N'0', 38444, 'Any')
    Select @ProductCode = '%%'
  End
Else
  Begin
    Select @Description = dbo.fnDBTranslate(N'0', 38157, 'Product') + ' = ' + @ProductCode
    Select @ProductCode = '%' + @ProductCode + '%'
  End
create table #Columns
(
 	 ColumnName varchar(50),
 	 Prompt varchar(50)
)
create table #SpecResults
(
 	 ProductCode varchar(50),
 	 Description varchar(100),
 	 UnitName varchar(100),
 	 ProductID int,
 	 UnitID int
)
create table #Units
(
  LineName varchar(100) NULL, 
  LineId int NULL,
 	 UnitName varchar(100) NULL,
 	 UnitID int
)
--***************************
--  Get Unit List
--****************************
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'UnitId;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (UnitId) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Units (LineName, LineId, UnitName, UnitId) EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
--****************************
--***************************
--  Return Prompts
--****************************
insert into #Columns (ColumnName, Prompt) values('Description',@Description)
insert into #Columns (ColumnName, Prompt) values('ProductCode',dbo.fnDBTranslate(N'0', 38391, 'Product Code'))
insert into #Columns (ColumnName, Prompt) values('Description',dbo.fnDBTranslate(N'0', 38174, 'Description'))
insert into #Columns (ColumnName, Prompt) values('UnitName',dbo.fnDBTranslate(N'0', 38129, 'Unit'))
select * from #Columns
--****************************
--***************************
--  Product List
--****************************
if (not @UnitList like '%<Root></Root>%')
  begin
    Select ProductCode = p.prod_code,
   	        Description = p.prod_desc,
     	  	  	  UnitName = u.UnitName,  
 	      	  	  ProductID = p.prod_id,
     	  	  	  UnitID = u.UnitId
      From pu_products pup
      Join #units u on u.UnitId = pup.pu_id
      Join Products p on p.prod_id = pup.prod_id and p.prod_code like @ProductCode
      Order By ProductCode, UnitName
  End
Else
  begin
    Select ProductCode = p.prod_code,
     	      Description = p.prod_desc,
     	  	  	  UnitName = u.pu_desc,  
 	      	  	  ProductID = p.prod_id,
     	  	  	  UnitID = u.pu_id
      From pu_products pup
      Join prod_units u on u.pu_id = pup.pu_id
      Join Products p on p.prod_id = pup.prod_id and p.prod_code like @ProductCode
      Order By ProductCode, UnitName
End
drop table #SpecResults
drop table #Units
drop table #Columns
