Create Procedure dbo.spSS_SearchProcessOrder
 @ProcessOrderNumber nVarChar(50) = NULL,
 @Date1 DateTime = NULL,
 @Date2 DateTime = NULL,
 @Product Int = NULL,
 @PUId Int = NULL,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
/*
exec dbo.spSS_SearchProcessOrder 'TP_040406_001', NULL, NULL, NULL, 10
*/
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @ProcessOrderId int, 
         @FlgAnd int,
         @FlgFirst int
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @FlgAnd = 0
 Select @SQLCOnd0 = NULL
-- Any modification to this select statement should also be done on the #alarm table
  Select @SQLCommand = 'Select P.PP_Id, P.Forecast_Start_Date, P.Forecast_End_Date, ' +
                       'P.Forecast_Quantity, P.Comment_Id, PPU.PU_Id, P.Prod_Id, ' +
                       'P.Block_Number, P.Process_Order, PS.PP_Status_Desc, PR.Prod_Code, P.Implied_Sequence ' + 
 	  	        'From Production_Plan P ' +
           'join [dbo].[PrdExec_Path_Units] ppu on p.path_id = ppu.path_id ' + 
                       'Join Production_Plan_Statuses PS on PS.PP_Status_Id = P.PP_Status_Id ' +
                       'Join Products PR on PR.Prod_Id = P.Prod_Id '
--------------------------------------------------------
-- Process Order Number
------------------------------------------------------
 If (@ProcessOrderNumber Is Not Null  And Len(@ProcessOrderNumber)>0) 
  Begin
   Select @SQLCond0 = "P.Process_Order Like '%" + @ProcessOrderNumber + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------------------
-- Date condition 1
--------------------------------------------------------------------
--insert into local_test (TimeStampTst, MessageTst)
-- values (getDate(), 'starting date condition1')
 If (@Date1 Is Not Null And @Date1>'01-Jan-1970')
   Begin
    Select @SQLCond0 = "P.Forecast_Start_Date Between '" + Convert(nVarChar(30), @Date1) + "' And '" +
                                                   Convert(nVarChar(30), @Date2) + "'"   
    If (@FlgAnd=1)
     Begin
      Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
     End
    Else
     Begin
      Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
      Select @FlgAnd = 1  
     End
   End
--------------------------------------------------------
-- Product
------------------------------------------------------
 If (@Product > 0) 
  Begin
   Select @SQLCond0 = "P.Prod_Id = " + Convert(nVarChar(5), @Product)
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------
-- PU Id
------------------------------------------------------
 If (@PUId > 0) 
  Begin
   Select @SQLCond0 = "Ppu.PU_Id = " + Convert(nVarChar(5), @PUId)
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
----------------------------------------------------------------
--  Output result to a temp table
-----------------------------------------------------------------
 Create Table #OrderTemp (
  PP_Id Int NULL,
  ForeCast_Start_Date DateTime NULL,
  ForeCast_End_Date DateTime NULL,
  ForeCast_Quantity float NULL,
  Comment_Id Int NULL,
  PU_Id Int NULL,
  Prod_Id Int NULL,
  Block_Number nVarChar(50) NULL,
  Process_Order_Number nVarChar(50) NULL,
  PP_Status_Desc nVarChar(50) NULL,
  Prod_Code nVarChar(25),
  Implied_Sequence Int NULL
 )
 Select @SQLCommand = 'Insert Into #OrderTemp ' + @SQLCommand 
 Exec (@SQLCommand)
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Forecast Start')
 	 Insert into @T(TimeColumns) Values ('Forecast End')
 	 Insert into @CHT(HeaderTag,Idx) Values (16363,1) -- Process Order Number
 	 Insert into @CHT(HeaderTag,Idx) Values (16313,2) -- Status
 	 Insert into @CHT(HeaderTag,Idx) Values (16164,3) -- Product
 	 Insert into @CHT(HeaderTag,Idx) Values (16354,4) -- Forecast Start
 	 Insert into @CHT(HeaderTag,Idx) Values (16355,5) -- Forecast End
 	 Insert into @CHT(HeaderTag,Idx) Values (16356,6) -- Forecast Qty
 	 Insert into @CHT(HeaderTag,Idx) Values (16364,7) -- Block Number
 	 Insert into @CHT(HeaderTag,Idx) Values (16100,8) -- Production Unit
 	 Insert into @CHT(HeaderTag,Idx) Values (16319,9) -- Comment
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Tag] = PP_Id,
 	  	  	 [Process Order Number] = Process_Order_Number, 
 	  	  	 [Status] = PP_Status_Desc, 
 	  	  	 [Product] = Prod_Code,
 	  	  	 [Forecast Start] = Forecast_Start_Date, 
 	  	  	 [Forecast End] = Forecast_End_Date, 
 	  	  	 [Forecast Qty] = Forecast_Quantity, 
 	  	  	 [Block Number] = Block_Number, 
 	  	  	 [Production Unit] = PU_Id, 
 	  	  	 [Comment] = a.comment_Id,
 	  	  	 [Prod_Id] = Prod_Id
 	 From #OrderTemp  a
 	 Order By PU_Id, Implied_Sequence
END
ELSE
BEGIN
 Select PP_Id, Forecast_Start_Date, Forecast_End_Date, Forecast_Quantity, Comment_Id,
        PU_Id, Prod_Id, Block_Number, Process_Order_Number, PP_Status_Desc, Prod_Code
   From #OrderTemp  
    Order By PU_Id, Implied_Sequence
END
 Drop Table #OrderTemp
