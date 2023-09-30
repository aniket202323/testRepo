--exec spASP_wrProductChangeDetail 1,null,''
CREATE PROCEDURE [dbo].[spASP_wrProductChangeDetail]
  @EventId int,
  @Command int = NULL,
  @InTimeZone nvarchar(200)=NULL
AS
Declare @UnitId Int
Declare @StartTime DateTime
Declare @Report Table ([Key] nvarchar(255), Value nvarchar(255))
--Get the production start info for scrolling
Select @UnitId = PU_Id, @StartTime = Start_Time
From Production_Starts ps
Where ps.Start_Id = @EventId
If @Command = 1
  Begin
 	 Print 'Scrolling forward'
    -- Scroll Next Event
    Select @EventId = Start_Id 
    From Production_Starts
    Where Start_Time = (Select Min(ps.Start_Time) --Get the start with the next lowest start time
 	  	  	  	  	  	 From Production_Starts ps
 	  	  	  	  	  	 Where ps.Start_Time > @StartTime
 	  	  	  	  	  	 And ps.PU_Id = @UnitId)
 	 And PU_Id = @UnitId
 	 --Check if there are no more production starts
 	 If @EventId Is Null
 	  	 Select @EventId = Start_Id
 	  	 From Production_Starts ps
 	  	 Where Start_Time = (Select Min(ps.Start_Time)
 	  	  	  	  	  	  	 From Production_Starts ps
 	  	  	  	  	  	  	 Where ps.PU_Id = @UnitId)
 	  	 And PU_Id = @UnitId
  End
Else If @Command = 2
  Begin
 	 Print 'Scrolling Backwards'
    -- Scroll Previous Event
    Select @EventId = Start_Id 
    From Production_Starts
    Where Start_Time = (Select Max(ps.Start_Time) --Get the start with the next lowest start time
 	  	  	  	  	  	 From Production_Starts ps
 	  	  	  	  	  	 Where ps.Start_Time < @StartTime
 	  	  	  	  	  	 And ps.PU_Id = @UnitId)
 	 And PU_Id = @UnitId
 	 --Check if there are no more production starts
 	 If @EventId Is Null
 	  	 Select @EventId = Start_Id
 	  	 From Production_Starts ps
 	  	 Where Start_Time = (Select Max(ps.Start_Time)
 	  	  	  	  	  	  	 From Production_Starts ps
 	  	  	  	  	  	  	 Where ps.PU_Id = @UnitId)
 	  	 And PU_Id = @UnitId
  End
Select ps.Start_Id, ps.Start_Time, ps.End_Time, p.Prod_Code, p.Prod_Desc, p.Alias_For_Product, c.Comment_Text,
 	  	 pf.Product_Family_Desc, Is_Sales_Product, Is_Manufacturing_Product
Into #TempData
From Production_Starts ps
Join Products p On ps.Prod_Id = p.Prod_Id
Left Outer Join Comments c On c.Comment_Id = ps.Comment_Id
Left Outer Join Product_Family pf On PF.Product_Family_Id = p.Product_Family_Id
Where c.TopOfChain_Id Is Null
And ps.Start_Id = @EventId
Insert Into @Report
Select 'Start Time', Start_Time
From #TempData
Insert Into @Report
Select 'End Time', End_Time
From #TempData
Insert Into @Report
Select 'Product Code', Prod_Code
From #TempData
Insert Into @Report
Select 'Product Description', Prod_Desc
From #TempData
Insert Into @Report
Select 'Product Alias', Alias_For_Product
From #TempData
Insert Into @Report
Select 'Comment', Comment_Text
From #TempData
Insert Into @Report
Select 'Product Family', Product_Family_Desc
From #TempData
Insert Into @Report
Select 'Sales Product', Is_Sales_Product
From #TempData
Insert Into @Report
Select 'Manufacturing Product', Is_Manufacturing_Product
From #TempData
Select Prod_Desc,dbo.fnServer_CmnGetDate(getutcdate()) As GenerateTime, Start_Id As EventId
From #TempData
Drop Table #TempData
Select [Key],'Value' = case when (ISDATE(Convert(varchar,[Value]))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(varchar,[dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,[Value]),@InTimeZone))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [Value]
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end  From @Report
