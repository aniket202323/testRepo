
 
CREATE PROCEDURE [dbo].[spActivities_GetProcessOrderForActivities]
@ActivityIds nvarchar(max) = NULL,
@ProcessOrderName nvarchar(50) = NULL
As 
Begin

CREATE TABLE #ProcessOrdersForActivities(ActivityId Int,ProcessOrderId int,ProcessOrderName nvarchar(50))


DECLARE @Sql Nvarchar(max)
IF @ActivityIds iS NOT NULL
BEgin
SET
@Sql =
'
Select 
	A.Activity_Id as ActivityId ,PP_PP.PP_Id as ProcessOrderId ,PP_PP.Process_Order as ProcessOrderName
From 
	Activities  A 
	 
	JOIN Event_Components EC on EC.Source_Event_Id =  A.keyid1
	JOIN Event_Details ED ON ED.Event_Id = EC.Source_Event_Id
	JOIN Production_Plan PP_PP ON PP_PP.PP_Id = ED.PP_Id
	Where A.Activity_Type_Id = 2 and Activity_Id in ('+@activityIds+')'
	INSERT INTO #ProcessOrdersForActivities
	EXEC(@sql)
SELECT @sql='
Select 
	A.Activity_Id as ActivityId ,PP_PP.PP_Id as ProcessOrderId ,PP_PP.Process_Order as ProcessOrderName
From 
	Activities  A 
	JOIN User_defined_Events UDE on UDE.UDE_Id = a.keyid1 
	  JOIN Event_Components EC on UDE.Event_Id = EC.Event_Id
	  JOIN Event_Details ED ON EC.Source_Event_Id = ED.Event_Id
	JOIN Production_Plan PP_PP ON PP_PP.PP_Id = ED.PP_Id
Where A.Activity_Type_Id = 3 and Activity_Id in ('+@activityIds+')'
INSERT INTO #ProcessOrdersForActivities
	EXEC(@sql)
Select @sql='
Select 
	A.Activity_Id as ActivityId ,PP_PP.PP_Id as ProcessOrderId ,PP_PP.Process_Order as ProcessOrderName
From 
	Activities  A 
	  JOIN Production_Plan_Starts PPS ON PPS.PU_Id = A.PU_Id AND PPS.Start_Time < A.KeyId AND (PPS.End_Time >= A.KeyId OR PPS.End_Time IS NULL)
	  JOIN Production_Plan PP_PP ON PP_PP.PP_Id = PPS.PP_Id
WHERE A.Activity_Type_Id not in (2, 3) and Activity_Id in ('+@activityIds+')'
INSERT INTO #ProcessOrdersForActivities
	EXEC(@sql)
Select @sql='
Select 
	A.Activity_Id as ActivityId ,PP_PP.PP_Id as ProcessOrderId ,PP_PP.Process_Order as ProcessOrderName
From 
	Activities  A 
	  JOIN Production_Plan_Starts PPS ON PPS.PU_Id = A.PU_Id AND PPS.Start_Time < A.KeyId AND (PPS.End_Time >= A.KeyId OR PPS.End_Time IS NULL)
	  JOIN Production_Plan PP_PP ON PP_PP.PP_Id = PPS.PP_Id
WHERE Activity_Id in ('+@activityIds+') and NOT EXISTS(SELECT 1 from #ProcessOrdersForActivities Where ActivityId = A.Activity_Id)
AND NOT EXISTS (SELECT 1 FROM WorkOrder.WorkOrders Where PP_Id = PP_PP.PP_id)'
INSERT INTO #ProcessOrdersForActivities
	EXEC(@sql)

	Select DISTINCT * from #ProcessOrdersForActivities

END
IF @ProcessOrderName IS NOT NULL
BEGIN


 
SET @ProcessOrderName = REPLACE(REPLACE(REPLACE(REPLACE(@ProcessOrderName, '\', '\\'), '[', '\['), '%', '[%]'), '_', '[_]')
SET @ProcessOrderName = '%'+@ProcessOrderName+'%';
                 

SET @Sql =
'
Select 
	A.Activity_Id as ActivityId ,PP_PP.PP_Id as ProcessOrderId ,PP_PP.Process_Order as ProcessOrderName
From 
	Activities  A 
	 
	JOIN Event_Components EC on EC.Source_Event_Id = A.keyid1
	JOIN Event_Details ED ON ED.Event_Id = EC.Source_Event_Id
	JOIN Production_Plan PP_PP ON PP_PP.PP_Id = ED.PP_Id
	Where A.Activity_Type_Id = 2 and PP_PP.Process_Order  LIKE ''%'+@ProcessOrderName+'%''
UNION
Select 
	A.Activity_Id as ActivityId ,PP_PP.PP_Id as ProcessOrderId ,PP_PP.Process_Order as ProcessOrderName
From 
	Activities  A 
	JOIN User_defined_Events UDE on UDE.UDE_Id = a.keyid1 
	  JOIN Event_Components EC on UDE.Event_Id = EC.Event_Id
	  JOIN Event_Details ED ON EC.Source_Event_Id = ED.Event_Id
	JOIN Production_Plan PP_PP ON PP_PP.PP_Id = ED.PP_Id
Where A.Activity_Type_Id = 3 and PP_PP.Process_Order  LIKE ''%'+@ProcessOrderName+'%''
UNION
Select 
	A.Activity_Id as ActivityId ,PP_PP.PP_Id as ProcessOrderId ,PP_PP.Process_Order as ProcessOrderName
From 
	Activities  A 
	  JOIN Production_Plan_Starts PPS ON PPS.PU_Id = A.PU_Id AND PPS.Start_Time < A.KeyId AND (PPS.End_Time >= A.KeyId OR PPS.End_Time IS NULL)
	LEFT JOIN Production_Plan PP_PP ON PP_PP.PP_Id = PPS.PP_Id
WHERE A.Activity_Type_Id not in (2, 3) and PP_PP.Process_Order  LIKE ''%'+@ProcessOrderName+'%''
UNION
Select 
	A.Activity_Id as ActivityId ,PP_PP.PP_Id as ProcessOrderId ,PP_PP.Process_Order as ProcessOrderName
From 
	Activities  A 
	  JOIN Production_Plan_Starts PPS ON PPS.PU_Id = A.PU_Id AND PPS.Start_Time < A.KeyId AND (PPS.End_Time >= A.KeyId OR PPS.End_Time IS NULL)
	  JOIN Production_Plan PP_PP ON PP_PP.PP_Id = PPS.PP_Id
WHERE A.Activity_Type_Id in (2, 3) and PP_PP.Process_Order  LIKE ''%'+@ProcessOrderName+'%''
AND NOT EXISTS (SELECT 1 FROM WorkOrder.WorkOrders Where PP_Id = PP_PP.PP_id)
'
EXEC (@Sql)
END



End


GRANT EXECUTE ON dbo.spActivities_GetProcessOrderForActivities TO [ComXClient]
