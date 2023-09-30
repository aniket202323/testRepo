Create Procedure dbo.spDS_GetProcessOrders
 @ProdId int,
 @PUId int,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
/* Changed to path id */
--Select * from prdExec_path_units 
Declare @Paths Table (PathId Int)
Insert Into @Paths (PathId) 
 	 Select Distinct Path_Id from prdExec_path_units Where PU_Id = @PUId and Is_Production_Point = 1 
Declare @Orders Table  (PP_Id int,Process_Order nVarChar(100),Prod_Id Int,Forecast_Start_Date DateTime,Forecast_End_Date DateTime,Forecast_Quantity Float,Path_Id Int,Status Int,Implied_Sequence Int)
Insert INTO @Orders (PP_Id ,Process_Order ,Prod_Id ,Forecast_Start_Date ,Forecast_End_Date ,Forecast_Quantity ,Path_Id ,Status,Implied_Sequence)
  Select PP.PP_Id, PP.Process_Order , PP.Prod_Id, PP.Forecast_Start_Date,   PP.Forecast_End_Date , PP.Forecast_Quantity ,a.PathId,PP.PP_Status_Id,Implied_Sequence
    From Production_Plan PP
 	  Join @Paths a On a.PathId = pp.Path_Id
       Where  PP.Prod_Id = @ProdId and PP.PP_Status_Id < 4
Insert INTO @Orders (PP_Id ,Process_Order ,Prod_Id ,Forecast_Start_Date ,Forecast_End_Date ,Forecast_Quantity ,Path_Id ,Status,Implied_Sequence )
  Select Top 10 PP.PP_Id, PP.Process_Order , PP.Prod_Id, PP.Forecast_Start_Date,   PP.Forecast_End_Date , PP.Forecast_Quantity ,a.PathId,PP.PP_Status_Id,pp.Implied_Sequence
    From Production_Plan PP
 	  Join @Paths a On a.PathId = pp.Path_Id
       Where  PP.Prod_Id = @ProdId and PP.PP_Status_Id > 3
       Order by Actual_End_Time desc
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Forecast Start Date')
 	 Insert into @T(TimeColumns) Values ('Forecast End')
 	 Insert into @CHT(HeaderTag,Idx) Values (16325,1) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16313,2) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16340,3) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16164,4) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16365,5) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16355,6) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16356,7) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16547,8) -- 
 	 SELECT TimeColumns From @T 
 	 Select HeaderTag From @CHT Order by Idx
 	 Select  [Tag] = PP.PP_Id, 
 	  	  	 [Id] = PP.PP_Id,
 	  	  	 [Status] = PP_Status_Desc,
 	  	  	 [Process Order] = PP.Process_Order, 
 	  	  	 [Product] = P.Prod_Code,
 	  	  	 [Forecast Start Date] =  PP.Forecast_Start_Date, 
 	  	  	 [Forecast End] = Forecast_End_Date, 
 	  	  	 [Forecast Qty] = PP.Forecast_Quantity,
 	  	  	 [Path Code] = Path_Code
 	 From @Orders PP
 	 Join Products P on P.Prod_Id = PP.Prod_Id
 	 Join PrdExec_Paths ppp on ppp.Path_Id = pp.Path_Id
 	 JOIN Production_Plan_Statuses pps on pps.PP_Status_Id = pp.Status
 	 Order by PP_Status_Id,Implied_Sequence desc
END
ELSE
BEGIN
  Select  PP.PP_Id,
 	  	 Status = PP_Status_Desc,
 	  	 [Process Order] = PP.Process_Order, 
 	  	 Product = P.Prod_Code,
 	  	 [Forecast Start Date] =  PP.Forecast_Start_Date, 
          	 [Forecast End Date] = Forecast_End_Date , 
 	  	 [Forecast Quantity] = PP.Forecast_Quantity,
 	  	 [Path Code] = Path_Code
    From @Orders PP
      Join Products P on P.Prod_Id = PP.Prod_Id
 	  Join PrdExec_Paths ppp on ppp.Path_Id = pp.Path_Id
 	  JOIN Production_Plan_Statuses pps on pps.PP_Status_Id = pp.Status
 	 Order by PP_Status_Id,Implied_Sequence desc
END
