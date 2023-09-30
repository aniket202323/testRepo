Create Procedure dbo.spCHT_GetRealTimeUpdateData
@VarId int,
@TimeStamp datetime,
@DecimalSep char(1) = '.'
AS
  -- Declare local variables.
  DECLARE @MasterUnitId int,
 	   @ProdId int,
      @DataType Int,
 	   @EventType int,
      @EventNum nvarchar(25),
      @ProdCode nvarchar(20),
      @OLCL nvarchar(25),
      @OTCL nvarchar(25),
      @OUCL nvarchar(25),
      @prec 	 Int,
      @HasOverRide Int
  Select @EventNum = NULL
Select @DecimalSep = Coalesce(@DecimalSep, '.')
 Select @MasterUnitId = Coalesce(PU.Master_Unit, PU.PU_Id), 
        @EventType =  Case V.Event_type When 1 then 1 else 0 end,
        @prec = Var_Precision,@DataType = v.Data_Type_Id 
  From Variables V Inner Join Prod_Units PU On PU.PU_Id = V.PU_id
   Where V.Var_Id = @VarId          
    And v.data_type_id in (1,2,6,7)
SELECT @HasOverRide = 0
SELECT  	 @OLCL = 	 ltrim(str(tsd.Mean - 3 * tsd.sigma,25,@prec)),
 	  	 @OTCL = 	 ltrim(str(tsd.Mean,25,@prec)),
 	  	 @OUCL = 	 ltrim(str(tsd.Mean + 3 * tsd.sigma,25,@prec)),
 	  	 @HasOverRide = 1
 	 FROM Tests t
 	 Join Test_Sigma_Data tsd on tsd.Test_Id = t.Test_Id 
 	 WHERE Var_Id =  @VarId and Result_On = @TimeStamp
 	 
 If (@EventType=1) -- Event-based variable
  Select @EventNum = EV.Event_Num
   From Events EV 
    Where EV.PU_Id = @MasterUnitId 
      And EV.TimeStamp = @TimeStamp 
--  Select @VarId as VarId, @ProdId as ProdId,  @ProdCode as ProdCode, @EventNum as EventNum
 Select @EventNum as EventNum,
 	  	 OLCL = Case When @DecimalSep <> '.' and @DataType = 2 Then Replace (@OLCL,'.', @DecimalSep) ELSE @OLCL END,
 	  	 OTCL = Case When @DecimalSep <> '.' and @DataType = 2 Then Replace (@OTCL,'.', @DecimalSep) ELSE @OTCL END,
 	  	 OUCL = Case When @DecimalSep <> '.' and @DataType = 2 Then Replace (@OUCL,'.', @DecimalSep) ELSE @OUCL END,
 	  	 HasOverRide = @HasOverRide
