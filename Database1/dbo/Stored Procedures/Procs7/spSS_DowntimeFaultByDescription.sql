Create Procedure dbo.spSS_DowntimeFaultByDescription
 @Desc nVarChar(50),
 @ProductionUnits nVarChar(2000) = NULL
AS
DECLARE @PUs table (PUId Int)
DECLARE @EndPosition 	 Int,
 	  	 @PUId 	  	  	 Int
IF (@ProductionUnits Is Not Null And Len(@ProductionUnits) > 0) 
BEGIN
 	 SELECT @EndPosition=0
 	 SELECT @EndPosition=CharIndex("\",@ProductionUnits)
 	 WHILE (@EndPosition<>0)
 	 BEGIN
 	  	 SELECT @PUId = Convert(Int,Substring(@ProductionUnits,1,(@EndPosition-1)))
 	  	 INSERT INTO @PUs (PUId) Values (@PUId)
 	  	 SELECT @ProductionUnits =  Right(@ProductionUnits, Len(@ProductionUnits)- @EndPosition)
 	  	 SELECT @EndPosition=CharIndex("\",@ProductionUnits)
    END
END
ELSE
BEGIN
 	 INSERT INTO @PUs (PUId)
 	  	 SELECT PU_Id From Prod_Units WHERE Master_Unit Is null
END
---------------------------------------------------------
--
---------------------------------------------------------
Select F.TEFault_Id, F.PU_Id, P.PU_Desc, F.TEFault_Name, F.Tefault_Value
 	 From Timed_Event_Fault F 
 	 Join @PUs P1 On F.PU_Id = P1.PUId
 	 Join Prod_Units P ON P.PU_Id = P1.PUId
   Where F.TEFault_Name Like '%' + @Desc + '%'
    Order by P.PU_Desc, F.TEFault_Name
