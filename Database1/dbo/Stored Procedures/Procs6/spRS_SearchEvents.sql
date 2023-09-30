CREATE PROCEDURE dbo.spRS_SearchEvents 
@PU_Id int,
@StartTime datetime,
@EndTime datetime,
@EventMask varchar(50),
@MaskFlag tinyint,
@ProductGroupId int,
@ProductId int,
@ExcludeStr varchar(8000) = Null,
@InTimeZone Varchar(200) = NULL
AS
--*****************************************************/
SELECT @PU_Id = coalesce(master_Unit,@PU_Id) From Prod_Units where PU_Id = @PU_Id
Declare @INstr VarChar(7999)
Declare @Id int
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
IF @ProductGroupId = 0 SELECT @ProductGroupId = Null
IF @ProductId = 0 SELECT @ProductId = Null
Create Table #T (VarId Int)
If @ExcludeStr Is Not Null
  Begin
 	 Select @INstr = @ExcludeStr + ','
 	 While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
 	   Begin
 	     Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
 	     insert into #T (VarId) Values (@Id)
 	     Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	     Select @INstr = Right(@INstr,Datalength(@INstr)-1)
 	   End
  End  
Declare @FullEventMask varchar(50)
If @EventMask Is Not Null
  Begin
    If @MaskFlag = 1 Select @FullEventMask = @EventMask + '%'
    Else If @MaskFlag = 2 Select @FullEventMask = '%' + @EventMask
    Else Select @FullEventMask = '%' + @EventMask + '%'
  End
Declare @DSQL1 varchar(4000)
Select @DSQL1 = ''
if (@ProductGroupId < 0)
begin
 	 select @ProductGroupId = null
end
Select @DSQL1 = @DSQL1 + 'SELECT EventId = e.Event_Id, '
Select @DSQL1 = @DSQL1 + 'Convert(VarChar(20), e.Event_Num) + '' - '' + COALESCE(Convert(VarChar(20), [apProd].Prod_Code), '
Select @DSQL1 = @DSQL1 + 'Convert(VarChar(20), p.Prod_Code)) + '' - '' + Convert(varchar(20),dbo.fnServer_CmnConvertFromDBTime(e.TimeStamp,'''+ @InTimeZone + ''')) [EventDesc], '
Select @DSQL1 = @DSQL1 + 'EventNumber = e.Event_Num,TimeStamp= dbo.fnServer_CmnConvertFromDBTime(e.TimeStamp,'''+ @InTimeZone + '''), '
Select @DSQL1 = @DSQL1 + 'ProductCode = COALESCE([apProd].Prod_Code, p.Prod_Code) '
Select @DSQL1 = @DSQL1 + 'FROM Events e  '
Select @DSQL1 = @DSQL1 + 'JOIN Production_Starts ps on ps.PU_Id = [e].[pu_id] and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))  '
If @ProductGroupId Is Not Null
 	 Select @DSQL1 = @DSQL1 + 'LEFT JOIN [Product_Group_Data] pg on pg.Product_Grp_Id = ' + convert(varchar(5), @ProductGroupId) + ' and pg.Prod_Id = [ps].[Prod_Id] '
Select @DSQL1 = @DSQL1 + 'JOIN Products p on p.Prod_Id = ps.Prod_Id '
Select @DSQL1 = @DSQL1 + 'LEFT JOIN [Products] AS [apProd] ON [apProd].[Prod_Id] = [e].[Applied_Product] '
If @ProductGroupId Is Not Null
 	 Select @DSQL1 = @DSQL1 + 'LEFT JOIN [Product_Group_Data] [appg] on [appg].[Product_Grp_Id] = ' + convert(varchar(5), @ProductGroupId) + ' and [appg].Prod_Id = apProd.Prod_Id  '
-------------------------
-- Begin Where Clause
-------------------------
Select @DSQL1 = @DSQL1 + 'WHERE e.PU_Id = ' + convert(varchar(5), @PU_Id) + ' and e.TimeStamp >= ' + '''' + convert(varchar(20), @StartTime, 120) + '''' + 'and e.TimeStamp < ' + '''' + convert(varchar(20), @EndTime, 120)  + ''''
If @FullEventMask Is Not Null
 	 Select @DSQL1 = @DSQL1 + ' AND e.Event_Num Like ' + '''' + @FullEventMask + ''''
If @ExcludeStr Is Not Null
 	 Select @DSQL1 = @DSQL1 + ' AND e.Event_Id not in (Select varId from #t)  '
If @ProductId Is Not Null
 	 Select @DSQL1 = @DSQL1 + ' AND ' + Convert(varchar(5), @ProductId) + ' = COALESCE(apProd.Prod_Id, p.Prod_Id)'
If @ProductGroupId Is Not Null
 	 Select @DSQL1 = @DSQL1 + ' AND case when e.applied_Product IS NOT NULL THEN [appg].[Product_Grp_Id] else [pg].[Product_Grp_Id] end = ' + convert(varchar(5), @ProductGroupId)
Select @DSQL1 = @DSQL1 + ' Order By e.Event_Num  '
PRINT @DSQL1
exec (@DSQL1)
Drop Table #t
