CREATE Procedure dbo.spSV_SearchProcessOrders
@SearchString nvarchar(50),
@Sheet_Id int,
@Path_Id int,
@DisplayUnboundOrders bit = NULL,
@RegionalServer 	  	  	 Int = 0
AS
If @RegionalServer is null
 	 Set @RegionalServer = 0
If @Sheet_Id = 0
  Select @Sheet_Id = NULL
If @Path_Id = 0
  Select @Path_Id = NULL
If @DisplayUnboundOrders = 0
  Select @DisplayUnboundOrders = NULL
Declare @DescSearch nvarchar(50)
Select @DescSearch = @SearchString
If @DescSearch = ''
  Select @DescSearch = '%%'
Else
  Select @DescSearch = '%' + @DescSearch + '%'
Create Table #ProdPlan (Process_Order nvarchar(50), Prod_Code nvarchar(25), Forecast_Start_Date datetime, PP_Id int)
If @Sheet_Id is NOT NULL
  Begin
    Insert Into #ProdPlan 	 (Process_Order, Prod_Code, Forecast_Start_Date, PP_Id)
     	 Select pp.Process_Order, p.Prod_Code, pp.Forecast_Start_Date, pp.PP_Id
       	 From Production_Plan pp 
        Join Products p on p.Prod_Id = pp.Prod_Id
        Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id And pep.Path_Id In (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id)
        Left Outer Join PrdExec_Path_Units pepu on pepu.Path_Id = pep.Path_Id and Is_Schedule_Point = 1 
        Where pp.Process_Order like @DescSearch
    If @DisplayUnboundOrders = 1
      Insert Into #ProdPlan 	 (Process_Order, Prod_Code, Forecast_Start_Date, PP_Id)
       	 Select pp.Process_Order, p.Prod_Code, pp.Forecast_Start_Date, pp.PP_Id
         	 From Production_Plan pp 
          Join Products p on p.Prod_Id = pp.Prod_Id
         	 Where pp.Process_Order like @DescSearch
          And pp.Path_Id is NULL
          And pp.Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Prod_Id = pp.Prod_Id and Path_Id In (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id))
  End
Else If @Path_Id is NOT NULL
  Insert Into #ProdPlan 	 (Process_Order, Prod_Code, Forecast_Start_Date, PP_Id)
   	 Select pp.Process_Order, p.Prod_Code, pp.Forecast_Start_Date, pp.PP_Id
     	 From Production_Plan pp 
      Join Products p on p.Prod_Id = pp.Prod_Id
      Join PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
      Left Outer Join PrdExec_Path_Units pepu on pepu.Path_Id = pep.Path_Id and Is_Schedule_Point = 1 
      Where pp.Process_Order like @DescSearch
     	 And pp.Path_Id = @Path_Id
-- { start addition
Else
  -- Add this code block to benefit Real Time Information Portal (RTIP) Connector by giving users to retrieve "Unbound Process Order"
  -- Portal will only use "bound process order" (@Path_Id specified) OR "Unbound process order" (@Sheet_Id not specified, @Path_Id not specified)
  -- mt/2-18-2005
  INSERT INTO #ProdPlan 	 (Process_Order, Prod_Code, Forecast_Start_Date, PP_Id)
    SELECT pp.Process_Order, p.Prod_Code, pp.Forecast_Start_Date, pp.PP_Id
      FROM Production_Plan pp 
      JOIN Products p on p.Prod_Id = pp.Prod_Id
     WHERE pp.Process_Order like @DescSearch AND pp.Path_Id is NULL
--EndIf
-- } end addition
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nvarchar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @CHT(HeaderTag,Idx) Values (20068,1) -- Process Order
 	 Insert into @CHT(HeaderTag,Idx) Values (20047,2) -- Product
 	 Insert into @CHT(HeaderTag,Idx) Values (20055,2) -- Start Time
 	 Insert into @CHT(HeaderTag,Idx) Values (20499,5) -- PP_Id
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select [Process Order] = Process_Order,
 	  	 [Product] = Prod_Code,
 	  	 [Start Time] = Forecast_Start_Date,
 	  	 [PP Id] = PP_Id
 	 FROM #ProdPlan 
 	 order by Process_Order
END
ELSE
BEGIN
 	 Select Process_Order, Prod_Code, Forecast_Start_Date, PP_Id
 	 From #ProdPlan
 	 Order by Process_Order ASC
END
Drop Table #ProdPlan
