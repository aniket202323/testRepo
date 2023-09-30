CREATE FUNCTION [dbo].[fnCMN_GetSpecLimits](@VarId int, @StartTime datetime, @EndTime datetime) 
  	  returns  @TestSpecs Table(VarId Int,
  	  	  	  	  	  	  	  	 ProdId Int,
  	  	  	  	  	  	  	  	 LReject nVarchar(25),
  	  	  	  	  	  	  	  	 LWarning nVarchar(25),
  	  	  	  	  	  	  	  	 UWarning nVarchar(25),
  	  	  	  	  	  	  	  	 UReject nVarchar(25),
  	  	  	  	  	  	  	  	 LCL nVarchar(25),
  	  	  	  	  	  	  	  	 TCL nVarchar(25),
  	  	  	  	  	  	  	  	 UCL nVarchar(25),
  	  	  	  	  	  	  	  	 StartTime datetime, 
  	  	  	  	  	  	  	  	 EndTime datetime)
AS 
BEGIN
  	  DECLARE @RunTimes Table(Id int Identity(1,1),ProdId Int, StartTime datetime, EndTime datetime,
  	  	  	  	  	  	  	  	 LReject nVarchar(25),
  	  	  	  	  	  	  	  	 LWarning nVarchar(25),
  	  	  	  	  	  	  	  	 UWarning nVarchar(25),
  	  	  	  	  	  	  	  	 UReject nVarchar(25),
  	  	  	  	  	  	  	  	 LCL nVarChar(25),
  	  	  	  	  	  	  	  	 TCL nVarChar(25),
  	  	  	  	  	  	  	  	 UCL nVarChar(25))
  	  	  	  	  	  	  	  	  
  	  DECLARE @AllTests  TABLE(Id int Identity(1,1),ProdId Int, Result_On DateTime,
   	  	  	  	  	  	  	  	 LReject nVarchar(25),
  	  	  	  	  	  	  	  	 LWarning nVarchar(25),
  	  	  	  	  	  	  	  	 UWarning nVarchar(25),
  	  	  	  	  	  	  	  	 UReject nVarchar(25),
  	  	  	  	  	  	  	  	 LCL nVarChar(25),
  	  	  	  	  	  	  	  	 TCL nVarChar(25),
  	  	  	  	  	  	  	  	 UCL nVarChar(25))
  	  DECLARE @UnitId Int,@EventType  Int
  	  Declare @Precision Int,@ProdId Int
 	  DECLARE @Start Int,@End Int, @PrevStartTime DateTime, @CurrentEndTime DateTime
  	   Declare @EffDate DateTime
 	  
 	  select @Precision = a.Var_Precision,@EventType = a.Event_Type  
 	  From Variables a
 	  Where Var_Id = @VarId
  	  SELECT @UnitId = coalesce(pu.Master_Unit,pu.PU_Id)
  	  	 FROM Variables v
  	  	 Join Prod_Units pu on pu.PU_Id = v.pu_id
  	  	 WHERE v.Var_Id = @VarId
  	 INSERT INTO @RunTimes (ProdId , StartTime , EndTime )
 	  	 SELECT ProdId , StartTime , EndTime 
 	  	 FROM [dbo].[fnRS_GetReportProductMap](@UnitId , @StartTime , @EndTime,@EventType )
  	  UPDATE @RunTimes SET EndTime = @EndTime Where EndTime Is Null or EndTime > @EndTime
  	  UPDATE @RunTimes SET StartTime = @StartTime Where StartTime < @StartTime
 	 -- Loop thru all starts and look for spec changes during the grade run
 	  	 SELECT  @End = MAX(Id) FROM  @RunTimes
 	  	 Set @Start = 1
  	  	 While @Start <= @End
 	  	 BEGIN
 	  	  	 SELECT  @PrevStartTime = StartTime, @CurrentEndTime = EndTime,@ProdId = ProdId 
 	  	  	  	 FROM  @RunTimes 
 	  	  	  	 WHERE Id = @Start 
  	    	    	  SET @EffDate = Null
  	    	    	  SELECT @EffDate = Effective_date  
  	    	    	    	  FROM  Var_Specs v
  	    	    	    	  WHERE v.Var_Id = @VarId and Prod_Id = @ProdId
  	    	    	    	    	  and v.Effective_Date Between  @PrevStartTime and  @CurrentEndTime
  	    	    	   IF @EffDate IS Not Null
  	    	    	   BEGIN
 	  	  	 INSERT INTO @RunTimes (ProdId , StartTime , EndTime )
  	    	    	    	  	  SELECT Prod_Id , @EffDate , @CurrentEndTime 
 	  	  	  	 FROM  Var_Specs v
 	  	  	  	 WHERE v.Var_Id = @VarId and Prod_Id = @ProdId
  	    	    	    	    	  	  and v.Effective_Date Between  @PrevStartTime and  @CurrentEndTime
  	    	    	  	   Update @RunTimes SET EndTime = @EffDate WHERE Id = @Start
  	    	    	     END
 	  	  	  	  	 SET @Start = @Start + 1
 	  	 END
 	 
 	 UPDATE @RunTimes SET EndTime = @EndTime Where EndTime Is Null or EndTime > @EndTime
 	 UPDATE @RunTimes SET StartTime = @StartTime Where StartTime < @StartTime
 	 UPDATE @RunTimes SET TCL = b.T_Control,
 	  	  	  	  	  	  LCL = L_Control,
 	  	  	  	  	  	  UCL = U_Control,
 	  	  	  	  	  	  LReject = L_Reject,
 	  	  	  	  	  	  LWarning = L_Warning,
 	  	  	  	  	  	  UReject = U_Reject,
 	  	  	  	  	  	  UWarning = U_Warning  
 	  	 FROM @RunTimes a
 	  	 JOIN Var_Specs b on b.Prod_Id = a.ProdId and b.Var_Id = @VarId 
 	  	 WHERE b.Effective_Date <= a.StartTime and ( b.Expiration_Date >  a.StartTime  or b.Expiration_Date is null) 	 
 	 IF EXISTS(SELECT 1 
 	  	 FROM Tests a
 	  	 JOIN Test_Sigma_Data b on b.Test_Id = a.Test_Id 
  	    	  WHERE a.Var_Id = @VarId and a.Result_On Between @StartTime and @EndTime and a.Result is not null) 
 	 BEGIN
 	  	 INSERT INTO @AllTests(ProdId,Result_On,LCL,TCL,UCL,LReject,LWarning,UWarning,UReject)
 	  	  	 SELECT c.Prodid,a.Result_On,
 	  	  	 coalesce(ltrim(str(b.Mean - 3 * b.sigma,25,@Precision)),c.Lcl),
 	  	  	 coalesce(ltrim(str(b.Mean,25,@Precision)),c.Tcl),
 	  	  	 coalesce(ltrim(str(b.Mean + 3 * b.sigma,25,@Precision)),c.Ucl),
 	  	  	 c.LReject,c.LWarning,c.UReject,c.UWarning 
 	  	  	 FROM Tests a
 	  	  	 LEFT JOIN Test_Sigma_Data b on b.Test_Id = a.Test_Id 
 	  	   	 Join @RunTimes c On a.Result_On between c.StartTime and c.EndTime
  	    	    	  WHERE a.Var_Id = @VarId and a.Result_On Between @StartTime and @EndTime and a.Result is not null
 	  	 SET @End = @@ROWCOUNT 
 	  	 Set @Start = 1
 	  	 SELECT @CurrentEndTime = Result_On FROM @AllTests WHERE id = @Start
 	  	 SELECT @PrevStartTime = Max(Result_On) FROM Tests WHERE Var_Id = @VarId And Result_On < @CurrentEndTime
 	  	 IF @PrevStartTime IS NULL SELECT @PrevStartTime = DATEADD(second,-10,@CurrentEndTime)
 	  	 INSERT INTO @TestSpecs(VarId,Prodid, StartTime,endTime,LCL,TCL,UCL,LReject,LWarning,UWarning,UReject)
 	  	  	 SELECT @VarId,Prodid,@PrevStartTime,Result_On,LCL,TCL,UCL,LReject,LWarning,UWarning,UReject
 	  	  	 FROM @AllTests
 	  	  	 WHERE id = @Start
 	  	 Set @Start = 2
 	  	 While @Start <= @End
 	  	 BEGIN
 	  	  	 SELECT @PrevStartTime = Result_On From @AllTests Where ID = @Start - 1
 	  	  	 INSERT INTO @TestSpecs(VarId,Prodid, StartTime,endTime,LCL,TCL,UCL,LReject,LWarning,UWarning,UReject)
 	  	  	  	 SELECT @VarId,Prodid,@PrevStartTime,Result_On,LCL,TCL,UCL,LReject,LWarning,UWarning,UReject
 	  	  	  	 FROM @AllTests
 	  	  	  	 WHERE id = @Start
 	  	  	 SET @Start = @Start + 1
 	  	 END
 	 END
 	 ELSE
 	 BEGIN
 	  	 INSERT INTO @TestSpecs(VarId,Prodid, StartTime,endTime,LCL,TCL,UCL,LReject,LWarning,UWarning,UReject)
 	  	  	 SELECT @VarId,Prodid,StartTime,EndTime,LCL,TCL,UCL,LReject,LWarning,UWarning,UReject 
 	  	  	 FROM @RunTimes
 	 END
 	 RETURN
END
