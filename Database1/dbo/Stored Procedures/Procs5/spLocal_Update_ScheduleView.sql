-------------------------------------------------------------------------------
-- This SP is used to be triggered by a Historian Tag
-- When the Historian Tag is changed, this stored proc will be triggered
-- and then look at the triggered PPId
-- it will Broadcast the PPId so that the schedule
-- will be shown at the Schedule View
-- 
-- The historian Tag is written by the Proficy Workflow thru the Service provider
--
-- 2009-07-24 	 S.Poon 	  	 Original
--
/*
DECLARE @Success 	  	 Int,
 	  	 @ErrorMsg 	  	 VarChar(500)
exec [dbo].[spLocal_Update_ScheduleView]      
 	 @Success  	  	  	  	 output,
 	 @ErrorMsg 	  	  	  	 output,
 	 @EC_Id 	  	  	  	  	  = 100,
 	 @TriggerTime 	  	  	  = '2009-07-21'
.*/
-------------------------------------------------------------------------------
CREATE  PROCEDURE [dbo].[spLocal_Update_ScheduleView]      
 	 @Success  	  	  	  	 Int  	  	  	 output,
 	 @ErrorMsg 	  	  	  	 Varchar(500)  	 output,
 	 @EC_Id 	  	  	  	  	 Int,
 	 @TriggerTime 	  	  	 Datetime,
 	 @PPId 	  	  	  	  	 Int
AS
DECLARE 	 @tppId 	  	 Int,
-- 	  	 @PPId 	  	 Int,
 	  	 @LoopCount 	 Int,
 	  	 @LoopIndex 	 Int
SELECT 	 @Success = 1
---------------------------------------------------------------
-- Declare the Variable Tables
---------------------------------------------------------------
--DECLARE @tUpdateScheduleView TABLE
-- 	 ( 	 Id 	  	  	  	  	 Int 	  	 IDENTITY,
-- 	  	 tppId 	  	  	  	 Int,
-- 	  	 PPID 	  	  	  	 Int,
-- 	  	 ProcessOrder 	  	 VarChar(50),
-- 	  	 EntryOn 	  	  	  	 DateTime
-- 	  	 )
IF @PPId = 0
 	 GoTo Finished
DECLARE @tProductionPlan TABLE
 	 ( 	 PathId 	  	  	  	 Int,
 	  	 PPId 	  	  	  	 Int,
 	  	 CommentId 	  	  	 Int,
 	  	 ProdId 	  	  	  	 Int,
 	  	 ImpliedSequence 	  	 Int,
 	  	 PPStatusId 	  	  	 Int,
 	  	 PPTypeId 	  	  	 Int,
 	  	 SourcePPId 	  	  	 Int,
 	  	 UserId 	  	  	  	 Int,
 	  	 ParentPPId 	  	  	 Int,
 	  	 ControlType 	  	  	 Int,
 	  	 ForecastStartTime 	 DateTime,
 	  	 ForecastEndTime 	  	 DateTime,
 	  	 EntryOn 	  	  	  	 DateTime,
 	  	 ForecastQuantity 	 Float,
 	  	 ProductionRate 	  	 Float,
 	  	 AdjustedQuantity 	 Float,
 	  	 BlockNumber 	  	  	 VarChar(50),
 	  	 ProcessOrder 	  	 VarChar(50),
 	  	 TransactionTime 	  	 DateTime,
 	  	 Misc1 	  	  	  	 VarChar(255),
 	  	 Misc2 	  	  	  	 VarChar(255),
 	  	 Misc3 	  	  	  	 VarChar(255),
 	  	 Misc4 	  	  	  	 VarChar(255),
 	  	 BOMFormulationId 	 Int)
---------------------------------------------------------------
-- Get the Production Plan needed to be Publish
---------------------------------------------------------------
--INSERT @tUpdateScheduleView(tppId, PPID, ProcessOrder, EntryOn)
-- 	 SELECT 	 tppId,
-- 	  	  	 PPId,
-- 	  	  	 ProcessOrder,
-- 	  	  	 EntryOn
-- 	  	 FROM Local_Update_ScheduleView
-- 	  	 WHERE Processed = 0
--
--SELECT @LoopCount = MAX(Id) FROM @tUpdateScheduleView
--SELECT @LoopIndex = MIN(Id) FROM @tUpdateScheduleView
--
--WHILE @LoopIndex <= @LoopCount
--BEGIN
-- 	  	 
-- 	 SELECT 	 @tppId = tppid,
-- 	  	  	 @PPId = PPId
-- 	  	 FROM @tUpdateScheduleView
-- 	  	 WHERE Id = @LoopIndex
 	 INSERT INTO @tProductionPlan(
 	  	 PathId 	  	  	  	 ,
 	  	 PPId 	  	  	  	 ,
 	  	 CommentId 	  	  	 ,
 	  	 ProdId 	  	  	  	 ,
 	  	 ImpliedSequence 	  	 ,
 	  	 PPStatusId 	  	  	 ,
 	  	 PPTypeId 	  	  	 ,
 	  	 SourcePPId 	  	  	 ,
 	  	 UserId 	  	  	  	 ,
 	  	 ParentPPId 	  	  	 ,
 	  	 ControlType 	  	  	 ,
 	  	 ForecastStartTime 	 ,
 	  	 ForecastEndTime 	  	 ,
 	  	 EntryOn 	  	  	  	 ,
 	  	 ForecastQuantity 	 ,
 	  	 ProductionRate 	  	 ,
 	  	 AdjustedQuantity 	 ,
 	  	 BlockNumber 	  	  	 ,
 	  	 ProcessOrder 	  	 ,
 	  	 TransactionTime 	  	 ,
 	  	 Misc1 	  	  	  	 ,
 	  	 Misc2 	  	  	  	 ,
 	  	 Misc3 	  	  	  	 ,
 	  	 Misc4 	  	  	  	 ,
 	  	 BOMFormulationId 	 )
 	 SELECT
 	  	  	 PathId 	  	  	  	 = Path_id,
 	  	  	 PPId 	  	  	  	 = PP_Id,
 	  	  	 CommentId 	  	  	 = Comment_Id,
 	  	  	 ProdId 	  	  	  	 = Prod_Id,
 	  	  	 ImpliedSequence 	  	 = Implied_Sequence,
 	  	  	 PPStatusId 	  	  	 = PP_Status_Id,
 	  	  	 PPTypeId 	  	  	 = PP_Type_Id,
 	  	  	 SourcePPId 	  	  	 = Source_PP_Id,
 	  	  	 UserId 	  	  	  	 = User_Id,
 	  	  	 ParentPPId 	  	  	 = Parent_PP_Id,
 	  	  	 ControlType 	  	  	 = Control_Type,
 	  	  	 ForecastStartTime 	 = Forecast_Start_Date,
 	  	  	 ForecastEndTime 	  	 = Forecast_End_Date,
 	  	  	 EntryOn 	  	  	  	 = Entry_On,
 	  	  	 ForecastQuantity 	 = Forecast_Quantity,
 	  	  	 ProductionRate 	  	 = Production_Rate,
 	  	  	 AdjustedQuantity 	 = Adjusted_Quantity,
 	  	  	 BlockNumber 	  	  	 = Block_Number,
 	  	  	 ProcessOrder 	  	 = Process_Order,
 	  	  	 TransactionTime 	  	 = NULL,
 	  	  	 Misc1 	  	  	  	 = NULL,
 	  	  	 Misc2 	  	  	  	 = NULL,
 	  	  	 Misc3 	  	  	  	 = NULL,
 	  	  	 Misc4 	  	  	  	 = NULL,
 	  	  	 BOMFormulationId 	 = BOM_Formulation_Id
 	  	 FROM Production_Plan
 	  	 Where PP_Id = @PPId
-- 	  	 UPDATE Local_Update_ScheduleView
-- 	  	  	 SET Processed = 1,
-- 	  	  	  	 ProcessedDateTime = GetDate()
-- 	  	  	 WHERE tppId = @tppId
--
-- 	  	 SELECT @LoopIndex = @LoopIndex + 1
-- 	 END 
---------------------------------------------------------------
-- Publish Production Plan 
---------------------------------------------------------------
SELECT  15, 	  	  	  	  	 -- ResultSetTyoe
 	  	 0, 	  	  	  	  	 -- PreDB
 	  	 1, 	  	  	  	  	 -- Transtype
 	  	 0,  	  	  	  	  	 -- TransNum
 	  	 PathId 	  	  	  	 ,
 	  	 PPId 	  	  	  	 ,
 	  	 CommentId 	  	  	 ,
 	  	 ProdId 	  	  	  	 ,
 	  	 ImpliedSequence 	  	 ,
 	  	 PPStatusId 	  	  	 ,
 	  	 PPTypeId 	  	  	 ,
 	  	 SourcePPId 	  	  	 ,
 	  	 UserId 	  	  	  	 ,
 	  	 ParentPPId 	  	  	 ,
 	  	 ControlType 	  	  	 ,
 	  	 ForecastStartTime 	 ,
 	  	 ForecastEndTime 	  	 ,
 	  	 EntryOn 	  	  	  	 ,
 	  	 ForecastQuantity 	 ,
 	  	 ProductionRate 	  	 ,
 	  	 AdjustedQuantity 	 ,
 	  	 BlockNumber 	  	  	 ,
 	  	 ProcessOrder 	  	 ,
 	  	 TransactionTime 	  	 ,
 	  	 Misc1 	  	  	  	 ,
 	  	 Misc2 	  	  	  	 ,
 	  	 Misc3 	  	  	  	 ,
 	  	 Misc4 	  	  	  	 ,
 	  	 BOMFormulationId 	 
 	 FROM @tProductionPlan
GOTO 	 Finished
ErrCode:
 	 SELECT 	 @Success = 0
Finished:
 	 RETURN
