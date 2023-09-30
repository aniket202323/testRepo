
CREATE PROCEDURE dbo.[spServer_SchMgrGetGoodAndBad_Bak_177]
	@PPId								int,
	@SetupId						int,
	@Unit								int,
	@StartTime					datetime,
	@EndTime						datetime,
	@ProductionVariable int,
	@TotalProduction		real OUTPUT,
	@TotalWaste					real OUTPUT,
	@ActualGoodItems		int OUTPUT,
	@ActualBadItems			int OUTPUT,
	@AddNonNullPPIds		Int = 0,
	@Repetitions				Int  = 0 OUTPUT 


 AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
/*
Fix for DE151839 
DE154783
*/

declare @PathProdId int
DECLARE
	@CurProdId		int,
	@CurStartId		int,
	@Tmp					nVarChar(100)

DECLARE	@UnitStart TABLE(PuId Int)
DECLARE	@PathId Int
 	 

/************************************************************
-- For Testing
--************************************************************
DECLARE
@PPId int,
@SetupId int,
@Unit int,
@StartTime datetime,
@EndTime datetime,
@ProductionVariable int,
@TotalProduction real,
@TotalWaste real,
@ActualGoodItems int,
@ActualBadItems int
SELECT @PPId = 9364
SELECT @SetupId = NULL
SELECT @StartTime = '1-jan-2003'
SELECT @EndTime = '1-jan-2004'
SELECT @Unit = 2
SELECT @ProductionVariable = NULL
--************************************************************/

--*****************************************************
-- Get Currently Running Grade
--*****************************************************
Create table #tmpEvents(Event_Id int, Event_Status int)
/*IF @PPId Is Null 
BEGIN
	IF (@StartTime is not null)
		SELECT @Tmp = convert(nVarChar(100) , @StartTime)
	ELSE
		SELECT @Tmp = convert(nVarChar(100) , dbo.fnServer_CmnGetDate(GetUTCDate()))
	EXEC spServer_CmnGetRunningGrade @Unit, @Tmp, 0, @CurProdId output, @CurStartId output
END
ELSE
BEGIN
	SELECT @PathId = Path_Id,@CurProdId = Prod_Id FROM Production_Plan WHERE PP_Id = @PPId
	INSERT INTO @UnitStart(PuId)
		--SELECT DISTINCT PU_Id 
		--	FROM Production_Plan_Starts 
		--	WHERE Is_Production = 1 and PP_Id = @PPId
		--UNION
		SELECT DISTINCT PU_Id
			FROM PrdExec_Path_units 
			WHERE Is_Production_Point = 1 AND Path_Id = @PathId 
END
*/
--Ivo Mares: PA 8.0 allows more than one PO active on production point. Reworked logic to count production correctly againts PO with correct product 
IF (@StartTime is not null)
   SELECT @Tmp = convert(varchar(100) , @StartTime)
ELSE
   SELECT @Tmp = convert(varchar(100) , dbo.fnServer_CmnGetDate(GetUTCDate()))
   EXEC spServer_CmnGetRunningGrade @Unit, @Tmp, 0, @CurProdId output, @CurStartId output
--Select  'Running product:', @CurProdId, @CurStartId


SELECT @PathId = Path_Id, @PathProdId = Prod_Id FROM Production_Plan WHERE PP_Id = @PPId
INSERT INTO @UnitStart(PuId)
 	  	 --SELECT DISTINCT PU_Id 
 	  	 -- 	 FROM Production_Plan_Starts 
 	  	 -- 	 WHERE Is_Production = 1 and PP_Id = @PPId
 	  	 --UNION
SELECT DISTINCT PU_Id
FROM PrdExec_Path_units 
WHERE Is_Production_Point = 1 AND Path_Id = @PathId
--*****************************************************
-- Get Production Amounts
--*****************************************************
SELECT @TotalProduction = 0
SELECT @ActualGoodItems = 0
SELECT @ActualBadItems = 0
SELECT @AddNonNullPPIds = Isnull(@AddNonNullPPIds,0)
SELECT @Repetitions = 0

IF @ProductionVariable Is Null
BEGIN
  -- Sum By Event Dimensions

  -- Sum Events That Are Produced During Time Period And Inherit A Process Order, Setup / Sequence
	IF @AddNonNullPPIds = 0
	BEGIN
		
		IF (@PathProdId = @CurProdId)
 	  	   INSERT INTO   #tmpEvents(Event_Id  , Event_Status  )
 	  	   SELECT e.Event_Id,e.Event_Status   
		   FROM Events e 
		   WHERE pu_id = @Unit AND e.Timestamp > @StartTime AND e.Timestamp <= @EndTime AND (e.Applied_Product is null or e.Applied_Product = @CurProdId)
		ELSE
		   INSERT INTO   #tmpEvents(Event_Id  , Event_Status  )
 	  	   SELECT e.Event_Id,e.Event_Status   
		   FROM Events e 
		   WHERE pu_id = @Unit AND e.Timestamp > @StartTime AND e.Timestamp <= @EndTime AND (e.Applied_Product is null or e.Applied_Product = @PathProdId)

 	  	 Select 
 	  	  	  	 @TotalProduction = coalesce(sum(case when s.count_for_production = 1 then coalesce(ed.initial_dimension_x,0.0) ELSE 0.0 End),0.0),
 	  	  	  	 @ActualGoodItems = coalesce(sum(case when s.count_for_production = 1 and s.status_valid_for_input = 1 then 1 ELSE 0 end),0),
 	  	  	  	 @ActualBadItems = coalesce(sum(case when s.count_for_production = 1 and s.status_valid_for_input = 0 then 1 ELSE 0 end),0)
 	  	 From
 	  	  	 Event_Details ed 
 	  	  	 Join #tmpEvents e on ed.event_id = e.event_id 
 	  	  	 Join Production_Status s on e.Event_Status = s.ProdStatus_Id 
 	  	 Where
 	  	  	 ed.pp_id Is Null and
 	  	  	  	  	  	 ed.initial_dimension_x is not null
		
	END
	ELSE
	BEGIN
		IF @SetupId Is NULL
		BEGIN
			-- Sum Events That Have A Process Order, Setup / Sequence Set



			Select event_id,event_status Into #tmpEvents_1 from Events e Join @UnitStart us on us.PuId = e.PU_Id Where (e.Applied_Product is null or ( e.Applied_Product = @CurProdId  and @CurProdId is not null and @PathProdId = @CurProdId) OR (e.Applied_Product = @PathProdId and @PathProdId is not null))
			Select initial_dimension_x,event_Id into #tmpEventDetails from Event_Details ed where ed.pp_Id = @PPId ANd ed.initial_dimension_x IS not null

			SELECT	@TotalProduction = @TotalProduction + coalesce(sum(case when s.count_for_production = 1 then coalesce(ed.initial_dimension_x,0.0) ELSE 0.0 End),0.0),
							@ActualGoodItems = @ActualGoodItems + coalesce(sum(case when s.count_for_production = 1 and s.status_valid_for_input = 1 then 1 ELSE 0 end),0),
							@ActualBadItems = @ActualBadItems + coalesce(sum(case when s.count_for_production = 1 and s.status_valid_for_input = 0 then 1 ELSE 0 end),0)
				FROM	#tmpEventDetails ed ---WITH (Index (Event_Details_IDX_PPSetupDetail))
				JOIN	#tmpEvents_1 e  on ed.event_id = e.event_id -- And (e.Applied_Product is null or e.Applied_Product = @CurProdId)
				JOIN	production_status s on s.prodstatus_id = e.event_status
				--JOIN	@UnitStart us ON us.PuId = e.PU_Id 
				--WHERE  ed.pp_id = @PPId And ed.initial_dimension_x is not null

			Drop Table #tmpEvents_1
			Drop Table #tmpEventDetails

		END	
		ELSE
		BEGIN /* add setups to the counts*/ 
			
			
			Select event_id,event_status Into #tmpEvents_2 from Events e join @UnitStart us ON us.PuId = e.PU_Id Where (e.Applied_Product is null or ( e.Applied_Product = @CurProdId  and @CurProdId is not null and @PathProdId = @CurProdId) OR (e.Applied_Product = @PathProdId and @PathProdId is not null))
			Select initial_dimension_x,event_id Into #tmpEventDetails_2 from Event_Details Where initial_dimension_x Is not null and pp_setup_id = @SetupId And (pp_id Is Null or pp_id = @PPId)
			
			
			SELECT	@TotalProduction = @TotalProduction + coalesce(sum(case when s.count_for_production = 1 then coalesce(ed.initial_dimension_x,0.0) ELSE 0.0 End),0.0),
							@ActualGoodItems = @ActualGoodItems + coalesce(sum(case when s.count_for_production = 1 and s.status_valid_for_input = 1 then 1 ELSE 0 end),0),
							@ActualBadItems = @ActualBadItems + coalesce(sum(case when s.count_for_production = 1 and s.status_valid_for_input = 0 then 1 ELSE 0 end),0)
				FROM	#tmpEventDetails_2 ed
				JOIN	#tmpEvents_2 e on ed.event_id = e.event_id 
				JOIN	production_status s on s.prodstatus_id = e.event_status

			/*Figure Out Repetitions*/
			SELECT	@Repetitions = count(Distinct ec.Source_Event_Id)
				FROM	Event_Details ed
				JOIN	Event_Components ec on ec.event_Id = ed.event_Id
				JOIN	Events e on e.event_Id = ec.event_Id
				WHERE ed.PP_Setup_Id = @SetupId and		(e.Applied_Product is null or e.Applied_Product = @CurProdId)


			Drop Table #tmpEvents_2
			Drop Table #tmpEventDetails_2
		END
	END
END
ELSE
BEGIN
    -- Sum By Variable
    -- No Items Counted For Variable Based Production
	IF ((@StartTime IS NOT NULL) AND (@EndTime IS NOT NULL))
	BEGIN
		SELECT @TotalProduction = isnull(sum(convert(real,isnull(result,0))),0)
			FROM Tests t
			LEFT Join Events E on E.Event_Id = t.Event_Id and (e.Applied_Product is null or ((case when @CurProdId = @PathProdId Then @CurProdId ELSE @PathProdId end = E.Applied_Product) AND E.Applied_Product IS NOT NULL) )
			WHERE t.var_id = @ProductionVariable and
						t.result_on > @StartTime and
						t.result_on <= @EndTime and
						t.result is not null
	END
END


--**************************************************************
-- Get Time Based Waste Amounts Produced During Time Period
--**************************************************************
IF ((@StartTime IS NOT NULL) AND (@EndTime IS NOT NULL) AND (@Unit IS NOT NULL))
BEGIN
	SELECT @TotalWaste = 0
	SELECT @TotalWaste = isnull(sum(isnull(w.amount,0)),0) 
	  FROM Waste_Event_Details w
	  WHERE PU_id = @Unit and	Timestamp >= @StartTime and	Timestamp < @EndTime and	Event_Id Is Null and
					amount is not null  
END



--****************************************************************************************
-- Get Event Based Waste Amounts Of Events That Have A Process Order, Setup / Sequence Set
--**************************************************************************************

	IF @PPId IS NOT NULL
	BEGIN
		IF @SetupId IS NULL
		BEGIN
			SELECT @TotalWaste = @TotalWaste + isnull(sum(isnull(w.amount,0)),0) 
				FROM Event_Details ed 
				JOIN Waste_Event_Details w on ed.Event_id = w.Event_id 
				JOIN	@UnitStart us ON us.PuId = w.PU_Id 
				WHERE ed.pp_id = @PPId


				
		END
		ELSE
		BEGIN
			SELECT @TotalWaste = @TotalWaste + isnull(sum(isnull(w.amount,0)),0) 
				FROM Event_Details ed
				JOIN Waste_Event_Details w on ed.Event_id = w.Event_id 
				JOIN	@UnitStart us ON us.PuId = w.PU_Id 
				WHERE ed.pp_id = @PPId AND ed.pp_setup_id = @SetupId
		END
	END  	  

	--*********************************************************************
	-- Get Event Based Waste Amounts Of Events Produced During Time Period
	-- 12222008 Added Index Hint ecr#36386 for performance issues
	--*********************************************************************
	IF ((@StartTime IS NOT NULL) AND (@EndTime IS NOT NULL) AND (@Unit IS NOT NULL))
	BEGIN





		SELECT @TotalWaste = @TotalWaste + isnull(sum(isnull(w.amount,0)),0) 
			FROM Events e 
			JOIN waste_event_details w WITH(INDEX(WEvent_Details_IDX_EventId)) on w.event_id = e.event_id
			LEFT JOIN event_details ed on ed.event_id = e.event_id 
			WHERE e.pu_id = @Unit and
						e.Timestamp > @StartTime and
						e.Timestamp <= @EndTime and
						ed.pp_id is NULL and
						w.amount is not null 

			

	END


-- Adjust to NET Good Production
SELECT @TotalProduction = @TotalProduction - @TotalWaste
Drop Table #tmpEvents
/************************************************************
-- For Testing
--************************************************************
SELECT 'TotalProduction=' + convert(nVarChar(25),convert(decimal(15,1), @TotalProduction))
SELECT 'TotalWaste=' + convert(nVarChar(25),convert(decimal(15,1), @TotalWaste))
SELECT 'GoodItems=' + convert(nVarChar(25),@ActualGoodItems)
SELECT 'BadItems=' + convert(nVarChar(25),@ActualBadItems)
--************************************************************/


