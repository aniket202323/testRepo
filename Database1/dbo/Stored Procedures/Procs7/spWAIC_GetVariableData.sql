Create Procedure [dbo].[spWAIC_GetVariableData]
@VariableId Int Output,
@StartTime datetime = Null,
@EndTime datetime = Null,
@NumberOfPoints int = Null,
@IncludeSpecifications bit = 0,
@ProductId Int = null, 
@ContextType int = null,
@ContextData nvarchar(255) = null,
@ContextCommand int = null,
@Events 	 VARCHAR(8000) = null,
@InTimeZone nvarchar(200)=NULL
AS
Set ArithAbort On
 	 Select @StartTime =[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)
 	 Select @EndTime =[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
Declare @IsEventBased int
Declare @MasterUnit int
Declare @SheetId int
Declare @NewVariable int
Declare @CurrentOrder int
Select @NewVariable = NULL
-- See If There Is A Command To Process To Find The Next Variable
If DATALENGTH(@Events) > 7500
Begin
 	 Raiserror('Maximum Number Of Events In Filter Exceeded',16,1)
    return
End
If @ContextType = 1
  Begin
    -- 'Sheet' Context Type
    Select @SheetId = Sheet_id From Sheets where Sheet_Desc = @ContextData
    Select @CurrentOrder = var_order from Sheet_Variables where sheet_id = @SheetId and Var_id = @VariableId
    If @ContextCommand = 1 
      Begin
        -- Scroll Down
        Select @NewVariable = sv1.Var_Id
          From Sheet_Variables sv1
          Where sv1.Sheet_Id = @SheetId and
                sv1.var_Order = (Select min(sv2.var_order) 
                                   From sheet_variables sv2
                                   Join variables v on v.var_id = sv2.var_id and v.data_type_id in (1,2,6,7) 
                                   where sv2.sheet_id = @SheetId and sv2.Var_Order > @CurrentOrder and 
                                         sv2.var_id is not null
                                 )
      End
    Else If @ContextCommand = 2
      Begin
        -- Scroll Up
        Select @NewVariable = sv1.Var_Id
          From Sheet_Variables sv1
          Where sv1.Sheet_Id = @SheetId and
                sv1.var_Order = (Select max(sv2.var_order) 
                                   From sheet_variables sv2
                                   Join variables v on v.var_id = sv2.var_id and v.data_type_id in (1,2,6,7) 
                                   where sv2.sheet_id = @SheetId and sv2.Var_Order < @CurrentOrder and 
                                         sv2.var_id is not null
                                 )
      End
  End
Else If @ContextType = 2
  Begin
    -- 'Unit' Context Type
    Select @MasterUnit = pu_id from Variables Where Var_Id = @VariableId
    Select @CurrentOrder = 1000 * g.pug_order + v.pug_order from variables v join pu_groups g on g.pug_id = v.pug_id where v.var_id = @VariableId
    If @ContextCommand = 1 
      Begin
        -- Scroll Down
        Select @NewVariable = v1.Var_Id
          From Variables v1
          join pu_groups g1 on g1.pug_id = v1.pug_id 
          Where v1.PU_Id = @MasterUnit and
                1000 * g1.pug_order + v1.pug_order = (Select min(1000 * g2.pug_order + v2.pug_order) 
                                   From variables v2
           	  	  	  	  	  	  	  	  	  	  	  	  join pu_groups g2 on g2.pug_id = v2.pug_id 
                                   where v2.pu_id = @MasterUnit and 
                                   (1000 * g2.pug_order + v2.pug_order) > (@CurrentOrder)
                                 )
      End
    Else If @ContextCommand = 2
      Begin
        -- Scroll Up
        Select @NewVariable = v1.Var_Id
          From Variables v1
          join pu_groups g1 on g1.pug_id = v1.pug_id 
          Where v1.PU_Id = @MasterUnit and
                1000 * g1.pug_order + v1.pug_order = (Select max(1000 * g2.pug_order + v2.pug_order) 
                                   From variables v2
           	  	  	  	  	  	  	  	  	  	  	  	  join pu_groups g2 on g2.pug_id = v2.pug_id 
                                   where v2.pu_id = @MasterUnit and 
                                   (1000 * g2.pug_order + v2.pug_order) < (@CurrentOrder)
                                 )
      End
  End
If @NewVariable Is Not Null
  Set @VariableId = @NewVariable
Select @MasterUnit = PU_Id, 
       @IsEventBased = Case When Event_Type = 1 Then 1 Else 0 End
  From Variables 
  Where Var_Id = @VariableId
Select @MasterUnit = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End
  From Prod_Units Where PU_Id = @MasterUnit
--***********************************************************
-- Get the data for the variable
--***********************************************************
Select Var_Desc LongName, Coalesce(Test_name, Var_Desc) ShortName, Eng_Units
From Variables
Where Var_Id = @VariableId
--***********************************************************
-- Get The Timestamps / Data points
--***********************************************************
Declare @CurrStartTime DateTime
Declare @CurrEndTime DateTime
Declare @WindowMove Int -- The number of days to to move the time window
Declare @FirstResultTime DateTime -- The timestamp of the first data point in the tests table
Declare @LastResultTime DateTime
Declare @CurrRowCount Int
Declare @Direction Bit --1 = backwards, 0 = forwards, used for number of points mode
Declare @ReachedBounds Bit -- If 1, we can't go any farther to find data
Set @ReachedBounds = 0
If @NumberOfPoints Is Not Null
 	 Begin
 	  	 If @StartTime Is Null
 	  	  	 Begin
 	  	  	  	 If @EndTime Is Null
 	  	  	  	  	 raiserror('StartTime and EndTime Cannot Both Be Null', 16, 1)
 	  	  	  	 Set @Direction = 1
 	  	  	 End
 	  	 Else If @EndTime Is Null
 	  	  	 Set @Direction = 0
 	 End
Create Table #CurrVarData
(
 	 [Timestamp] DateTime,
 	 Value nvarchar(100),
 	 EventId nVarChar(100) --,
 	 --Target nvarchar(100),
 	 --LowerWarning nvarchar(100),
 	 --UpperWarning nvarchar(100),
 	 --LowerReject nvarchar(100),
 	 --UpperReject nvarchar(100),
)
--Run the query
Declare @SQL varchar(8000)
Create Table #SelectedEvents(
 	  EventId Int
)
If @Events Is Not Null
Begin
 	 Select @SQL = 'Insert Into #SelectedEvents(EventId) Select Event_Id From Events Where Event_Id In (' + @Events + ')'
 	 Exec(@SQL)
End 	  	 
--Create the #FinalData table idential to #CurrVarData
Select * Into #FinalData From #CurrVarData
--Figure out our bounds for number of points mode
If @Direction = 1
 	 Select @FirstResultTime = Min(Result_On) From Tests Where Var_Id = @VariableId
If @Direction = 0
 	 Select @LastResultTime = Max(Result_On) From Tests Where Var_Id = @VariableId
While (@CurrRowCount Is Null Or @CurrRowCount < @NumberOfPoints) And (@ReachedBounds Is Null Or @ReachedBounds = 0)
 	 Begin
 	  	 If @CurrRowCount Is Null Print 'No Rows Found So Far'
 	  	 Print Cast(@CurrRowCount As nvarchar(10)) + ' Rows Found So Far'
--todo: because of the way the time window moves, points could get counted
--twice if they fall right on the bounds of a time window
--todo: avoid overflow errors with the datetimes, the dateadd can cause an overflow easily
 	  	 If @Direction = 1 --Backwards 
 	  	  	 Begin
 	  	  	  	 If @WindowMove Is Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Set @WindowMove = -1
 	  	  	  	  	  	 Set @CurrEndTime = @EndTime
 	  	  	  	  	  	 Set @CurrStartTime = Dateadd(day, @WindowMove, @EndTime) --Look at 1 day
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Set @CurrEndTime = @CurrStartTime --Move the end of the new time window to the start of the last one
 	  	  	  	  	  	 If @WindowMove > -1000
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Set @WindowMove = @WindowMove * 2
 	  	  	  	  	  	  	  	 Set @CurrStartTime = Dateadd(day, @WindowMove, @CurrStartTime)
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else  --The window has gotten huge, just look at everything
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Set @CurrStartTime = @FirstResultTime
 	  	  	  	  	  	  	  	 Set @ReachedBounds = 1
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	 Else If @Direction = 0 --forwards
 	  	  	 Begin
 	  	  	  	 If @WindowMove Is Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Set @WindowMove = 1
 	  	  	  	  	  	 Set @CurrStartTime = @StartTime
 	  	  	  	  	  	 Set @CurrEndTime = Dateadd(day, @WindowMove, @StartTime) --Look at 1 day
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Set @CurrStartTime = @CurrEndTime --Move the start of the new time window to the end of the last one
 	  	  	  	  	  	 If @WindowMove < 1000
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Set @WindowMove = @WindowMove * 2
 	  	  	  	  	  	  	  	 Set @CurrEndTime = Dateadd(day, @WindowMove, @CurrStartTime)
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else  --The window has gotten huge, just look at everything
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Set @CurrEndTime = @LastResultTime
 	  	  	  	  	  	  	  	 Set @ReachedBounds = 1
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 Set @CurrStartTime = @StartTime
 	  	  	  	 Set @CurrEndTime = @EndTime
 	  	  	 End
        If (@ProductId is NULL and @Events is NULL) Begin
 	  	   Insert Into #CurrVarData
 	  	   Select t.Result_on [Timestamp], t.Result [Value],t.Event_Id [EventId]
 	  	   From Tests t
 	  	   Where t.Result_On >= @CurrStartTime And t.Result_On <= @CurrEndTime
 	  	  	 And t.Var_Id = @VariableId
        End
        Else Begin
 	  	   Insert Into #CurrVarData
 	  	   Select t.Result_on [Timestamp], t.Result [Value],t.event_Id
 	  	   From Tests t
 	  	   Left outer join events e on t.event_id = e.event_id and (@Events IS NULL OR e.Event_Id IN (Select 	 * From #SelectedEvents))  	 
 	  	  	 Left outer Join Production_Starts ps on (@ProductId Is Null Or @ProductId = ps.prod_id)
 	  	  	  	  	  	  	  	  	  	  	  	    --ps1.prod_id = 4 
 	  	  	  	  	  	  	  	  	  	  	  	    and ps.PU_id = @MasterUnit 
 	  	  	  	  	  	  	  	  	  	  	  	    and ps.Start_Time < t.Result_on 
 	  	  	  	  	  	  	  	  	  	  	  	    and (ps.End_Time >= t.result_On or ps.End_Time Is Null) 	  	  	 
 	  	   Where t.Result_On >= @CurrStartTime And t.Result_On <= @CurrEndTime
 	  	  	 And t.Var_Id = @VariableId
 	  	  	 --And (@ProductId is NULL  OR ps.Prod_Id = @ProductId)
 	  	  	 and (@ProductId Is Null 
 	  	  	  	  	 Or @ProductId = case when e.applied_product is not null then e.applied_product else ps.prod_id end)
 	  	  	 --Filter By Events
 	  	  	  --And (t.Event_Id IN (Select * From #SelectedEvents))
        End
 	  	 --Don't keep looping if it is a time query
 	  	 If @NumberOfPoints Is Null
 	  	 Break
 	  	 Select @CurrRowCount = Count(*)
 	  	 From #CurrVarData
 	 End
--Return the data and reset our variables
If @NumberOfPoints Is Not Null
 	 Set RowCount @NumberOfPoints
If @Direction = 1 --backwards
 	 Insert Into #FinalData
 	 Select *
 	 From #CurrVarData
 	 Order by [Timestamp] Desc
Else
 	 Insert Into #FinalData
 	 Select *
 	 From #CurrVarData
 	 Order By [Timestamp] Asc
Set RowCount 0
--Sarla
--Select * From #FinalData Order By [Timestamp] Asc
Select 'Timestamp' =  [dbo].[fnServer_CmnConvertFromDbTime] ([Timestamp],@InTimeZone)  ,[value],EventId From #FinalData Order By [Timestamp] Asc
--Sarla
Drop Table #FinalData
Drop Table #CurrVarData
Drop Table #SelectedEvents
