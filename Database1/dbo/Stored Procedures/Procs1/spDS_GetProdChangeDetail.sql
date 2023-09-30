Create Procedure dbo.spDS_GetProdChangeDetail
@StartId int,
@RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @PUId int,
         @ProductionEventSubTypeId int,
         @ProductionEventSubTypeDesc nVarChar(50),
         @StartTime DateTime,
         @NextStartTime DateTime,
         @NextProdId Int,
         @NextMinStartTime DateTime,
         @PreviousStartTime DateTime,
         @PreviousProdId Int,
         @PreviousMaxStartTime DateTime
 Select @PUId = NULL
-------------------------------------------------------
-- Get basic info
-------------------------------------------------------
 Select @PUID = PU_Id,
        @StartTime = Start_Time
  From Production_Starts
   Where Start_Id = @StartID
--------------------------------------------------------
-- Get Products produced on the PUId
--------------------------------------------------------
 Select PP.Prod_Id as ProdId, PR.Prod_Code as ProdCode 
  From PU_Products PP Inner Join Products PR
   On PP.Prod_Id = PR.Prod_Id
   Where PP.PU_Id = @PUId
    Order by PR.Prod_Code
------------------------------------------------------------------------------
-- Detail info
-----------------------------------------------------------------------------
 Select @ProductionEventSubTypeId =  Min(EC.Event_SubType_Id)
--From Event_Config EC Inner Join Event_SubTypes ES  On EC.Event_SubType_Id = ES.Event_SubType_Id
  From Event_Configuration EC Inner Join Event_SubTypes ES  On EC.Event_SubType_Id = ES.Event_SubType_Id
   Where EC.PU_Id = @PUId
     And ES.ET_Id = 1
 If (@ProductionEventSubTypeId IS Not Null)
  Select @ProductionEventSubTypeDesc = Event_SubType_Desc
   From Event_SubTypes
    Where Event_SubType_Id = @ProductionEventSubTypeId  
 Select PS.PU_Id as PUId, PU.PU_Desc as PUDesc, PS.Prod_Id as ProdId, PR.Prod_Code as ProdCode, PS.Start_Time as StartTime, 
   PS.End_Time as EndTime,
-- datediff(minute, PS.Start_Time , PS.End_Time) as Duration, PS.Event_SubType_Id as EventSubTypeId, ES.Event_SubType_Desc as EventSubTypeDesc,
   datediff(minute, PS.Start_Time , PS.End_Time) as Duration, @ProductionEventSubTypeId as EventSubTypeId, 
   @ProductionEventSubTypeDesc as EventSubTypeDesc,
   PS.Comment_Id as CommentId, PR.Product_Change_ESignature_Level -- , CO.Comment as Comment
  From Production_Starts PS
   Inner Join Prod_Units PU On PS.PU_Id = PU.PU_Id
   Inner Join Products PR on PS.Prod_Id = PR.Prod_Id 
--   Left Outer Join Comments CO on PS.Comment_Id = CO.Comment_Id  
--   Left Outer Join Event_SubTypes ES on ES.Event_SubType_Id = PS.Event_SubType_Id
    Where PS.Start_Id = @StartId
-------------------------------------------------------------------
-- Get previous record data for the PU
--------------------------------------------------------------------
 Select @PreviousStartTime = Null
 Select @PreviousProdId = Null
 Select @PreviousMaxStartTime = Null
 Select @PreviousMaxStartTime = Max(Start_Time)
  From Production_Starts 
   Where PU_Id = @PUId
    And Start_Time < @StartTime
 If (@PreviousMaxStartTime Is Not Null)
  Select @PreviousStartTime = Start_Time,
         @PreviousProdId = Prod_Id
   From Production_Starts
    Where PU_Id = @PUId
     And Start_Time = @PreviousMaxStartTime
-------------------------------------------------------------------
-- Get next record data for the PU
--------------------------------------------------------------------
 Select @NextStartTime = Null
 Select @NextProdId = Null
 Select @NextMinStartTime = Null
 Select @NextMinStartTime = Min(Start_Time)
  From Production_Starts 
   Where PU_Id = @PUId
    And Start_Time > @StartTime
 If (@NextMinStartTime Is Not Null)
  Select @NextStartTime = Start_Time,
         @NextProdId = Prod_Id
   From Production_Starts
    Where PU_Id = @PUId
     And Start_Time = @NextMinStartTime
 Select @PreviousStartTime As PreviousStartTime, 
        @PreviousProdId As PreviousProdId, 
        @NextStartTime As NextStartTime,
        @NextProdId As NextProdId
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Start Time')
 	 Insert into @T(TimeColumns) Values ('End Time')
 	 Insert into @CHT(HeaderTag,Idx) Values (16164,1) -- Product
 	 Insert into @CHT(HeaderTag,Idx) Values (16342,2) -- Start Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16333,3) -- End Time
 	 Insert into @CHT(HeaderTag,Idx) Values (16345,4) -- User
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 -------------------------------------------------------------------
 	 -- History
 	 --------------------------------------------------------------------
 	  Select [Product] = p.Prod_Desc, 
 	  	  	 [Start Time] = ph.Start_Time,
 	  	  	 [End Time] = ph.End_Time,
 	  	  	 [User] = u.Username
 	    From Production_Starts_History ph
 	  	  Join Products p on p.Prod_Id = ph.Prod_Id
 	  	  Join Users u on u.User_Id = ph.User_Id
 	  	  Where Start_Id = @StartId
 	  	    Order by Modified_On desc
END
ELSE
BEGIN
 Select p.Prod_Desc, ph.Start_Time, ph.End_Time, u.Username
   From Production_Starts_History ph
     Join Products p on p.Prod_Id = ph.Prod_Id
     Join Users u on u.User_Id = ph.User_Id
     Where Start_Id = @StartId
       Order by Modified_On desc
END
