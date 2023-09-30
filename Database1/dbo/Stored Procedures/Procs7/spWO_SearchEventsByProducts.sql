CREATE PROCEDURE [dbo].[spWO_SearchEventsByProducts]
@PU_Id int,
@StartTime datetime,
@EndTime datetime,
@EventMask nvarchar(50),
@MaskFlag tinyint,
@ProductGroupId int,
@ProductIds varchar(8000),
@ExcludeStr varchar(8000) = Null,
@InTimeZone nvarchar(200)=NULL
AS 

SELECT @PU_Id = coalesce(master_Unit,@PU_Id) From Prod_Units where PU_Id = @PU_Id
 
 	 select @StartTime =[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)
 	 select @EndTime =[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
 
Declare @INstr VarChar(7999)
Declare @Id int
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
Declare @FullEventMask nVarChar(50)
If @EventMask Is Not Null
  Begin
    If @MaskFlag = 1 Select @FullEventMask = @EventMask + '%'
    Else If @MaskFlag = 2 Select @FullEventMask = '%' + @EventMask
    Else Select @FullEventMask = '%' + @EventMask + '%'
  End
If @ProductGroupId Is Null and @ProductIds Is Null 
  Begin
    -- Niether Product Group Or Product Has Been Specified
    If @EventMask Is Not Null
  	   If @ExcludeStr Is Null
  	     Begin
  	    	  Select EventId = e.Event_Id, 
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	  
  	    	    	  ,EventNumber = e.Event_Num, 'TimeStamp'=  [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone)  , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
 	  	    Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id
  	    	          and e.TimeStamp >= @StartTime
  	    	          and e.TimeStamp < @EndTime
  	    	          and e.Event_Num Like @FullEventMask 
  	    	    Order By e.Event_Num
  	      End
  	    Else
  	      Begin
  	      -- With Exclude String
  	    	  Select EventId = e.Event_Id, 
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	  
  	    	    	  ,EventNumber = e.Event_Num, 'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone) , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)--Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id 
  	    	          and e.TimeStamp >= @StartTime 
  	    	          and e.TimeStamp < @EndTime 
  	    	          and e.Event_Num Like @FullEventMask 
  	    	          and e.Event_Id not in (Select varId from #t)
  	    	    Order By e.Event_Num
  	      
  	      End
  	      
    Else
      If @ExcludeStr Is Null
        Begin
  	    	  Select EventId = e.Event_Id, 
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	  
  	    	    	  ,EventNumber = e.Event_Num, 'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone) , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)--Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id 
  	    	          and e.TimeStamp >= @StartTime 
  	    	          and e.TimeStamp < @EndTime
  	    	    Order By e.Event_Num
        End
      Else
  	     Begin
  	    	  Select EventId = e.Event_Id, 
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	  
  	    	    	  ,EventNumber = e.Event_Num,'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone) , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)--Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id 
  	    	          and e.TimeStamp >= @StartTime
  	    	          and e.TimeStamp < @EndTime
  	    	          and e.Event_Id not in (Select varId from #t)
  	    	    Order By e.Event_Num
  	     
  	     End
  End
Else If @ProductIds Is Null
  Begin
    -- Product Group Only Has Been Specified
    If @EventMask Is Not Null
  	   If @ExcludeStr Is Null
  	     Begin
  	    	  Select EventId = e.Event_Id, 
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	        
  	    	    	  ,EventNumber = e.Event_Num, 'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone) , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)--Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Product_Groups pg on pg.Product_Grp_Id = @ProductGroupId and ps.Prod_Id = ps.Prod_Id
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id
  	    	          and e.TimeStamp >= @StartTime
  	    	          and e.TimeStamp < @EndTime
  	    	          and e.Event_Num Like @FullEventMask 
  	    	    Order By e.Event_Num
  	     
  	     End
  	   Else
  	     Begin
  	    	  Select EventId = e.Event_Id, 
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	        
  	    	    	  ,EventNumber = e.Event_Num, 'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone) , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code) 
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Product_Groups pg on pg.Product_Grp_Id = @ProductGroupId and ps.Prod_Id = ps.Prod_Id
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id 
  	    	          and e.TimeStamp >= @StartTime
  	    	          and e.TimeStamp < @EndTime 
  	    	          and e.Event_Num Like @FullEventMask 
  	    	          and e.Event_Id not in (Select varId from #t)
  	    	    Order By e.Event_Num
  	     
  	     End 
  	     
    Else
      If @ExcludeStr Is Null
        Begin
  	    	  Select EventId = e.Event_Id,
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	        
  	    	  , EventNumber = e.Event_Num, 'TimeStamp'=  [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone) , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code) 
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Product_Groups pg on pg.Product_Grp_Id = @ProductGroupId and ps.Prod_Id = ps.Prod_Id
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id
  	    	          and e.TimeStamp >= @StartTime 
  	    	          and e.TimeStamp < @EndTime
  	    	    Order By e.Event_Num
        End
      Else
        Begin
  	    	  Select EventId = e.Event_Id,
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	        
  	    	  , EventNumber = e.Event_Num, 'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone)  , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)--Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Product_Groups pg on pg.Product_Grp_Id = @ProductGroupId and ps.Prod_Id = ps.Prod_Id
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id
  	    	          and e.TimeStamp >= @StartTime
  	    	          and e.TimeStamp < @EndTime
  	    	          and e.Event_Id not in (Select varId from #t)
  	    	    Order By e.Event_Num
        End
  End
Else
  Begin
    -- Products Has Been Specified
 	 Create Table #SelectedProducts(
 	  	 ProductId Int
 	 )
 	 INSERT 	 INTO #SelectedProducts 
 	  	 Select [Id] From dbo.[fnCMN_IdListToTable]('Products', @ProductIds, ',')
 	 --SELECT 	 * FROM dbo.fnWA_CSVToTable(@ProductIds)
    If @EventMask Is Not Null
      If @ExcludeStr Is Null
        Begin
  	    	  Select EventId = e.Event_Id,
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	        
  	    	  , EventNumber = e.Event_Num, 'TimeStamp'=  [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone) , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)--Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null)) 
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id 
  	    	    Where e.PU_Id = @PU_Id 
  	    	          and e.TimeStamp >= @StartTime 
  	    	          and e.TimeStamp < @EndTime 
  	    	          and e.Event_Num Like @FullEventMask 
 	  	  	  	  and IsNull(pa.Prod_id, p.Prod_id) in (SELECT * FROM #SelectedProducts)
  	    	    Order By e.Event_Num
        End
      Else
        Begin
  	    	  Select EventId = e.Event_Id,
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	        
  	    	  , EventNumber = e.Event_Num, 'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone)  , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)--Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null)) 
           Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id 
  	    	    Where e.PU_Id = @PU_Id
  	    	          and e.TimeStamp >= @StartTime 
  	    	          and e.TimeStamp < @EndTime 
  	    	          and e.Event_Num Like @FullEventMask 
  	    	          and e.Event_Id not in (Select varId from #t)
 	  	  	  	  and IsNull(pa.Prod_id, p.Prod_id) in (SELECT * FROM #SelectedProducts)
  	    	    Order By e.Event_Num
        End
    Else
      If @ExcludeStr Is Null
        Begin
  	    	  Select EventId = e.Event_Id, 
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	  
  	    	    	  ,EventNumber = e.Event_Num, 'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone)  , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code)--Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id
  	    	          and e.TimeStamp >= @StartTime
  	    	          and e.TimeStamp < @EndTime
 	  	  	  	  and IsNull(pa.Prod_id, p.Prod_id) in (SELECT * FROM #SelectedProducts)
  	    	    Order By e.Event_Num
        End
      Else
        Begin
  	    	  Select EventId = e.Event_Id, 
  	    	    	  Convert(nvarchar(20), e.Event_Num) + ' - ' + Convert(nvarchar(20), IsNull(pa.Prod_Code, p.Prod_Code)) + ' - ' + Convert(nvarchar(20), e.TimeStamp)  	    	  
  	    	    	  ,EventNumber = e.Event_Num, 'TimeStamp'=   [dbo].[fnServer_CmnConvertFromDbTime] (e.[TimeStamp],@InTimeZone)  , ProductCode = IsNull(pa.Prod_Code, p.Prod_Code) --Sarla
  	    	    From Events e
  	    	    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Start_Time <= e.TimeStamp and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
  	    	    Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Products pa on e.Applied_Product = pa.Prod_Id
  	    	    Where e.PU_Id = @PU_Id
  	    	          and e.TimeStamp >= @StartTime
  	    	          and e.TimeStamp < @EndTime
  	    	          and e.Event_Id not in (Select varId from #t)
 	  	  	  	  and IsNull(pa.Prod_id, p.Prod_id) in (SELECT * FROM #SelectedProducts)
  	    	    Order By e.Event_Num
        End
  End
drop table #t
