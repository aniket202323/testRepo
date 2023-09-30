create procedure [dbo].[spRS_ListEventTypes]
@Units varchar(255)
AS
DECLARE @UnitTable TABLE(PU_ID INT)
DECLARE @EventTypes TABLE(PU_ID INT, EventTypeId INT, EventSubTypeId INT, EventDescription varchar(50))
DECLARE @Count int
-------------------------------------------------------
-- Get Temp Table containing all of the selected units
-------------------------------------------------------
INSERT into @UnitTable
 	 SELECT Id_Value FROM fnRS_MakeOrderedResultSet(@Units)
SELECT @Count=Count(*) FROM @unitTable
-------------------------------------------------------
-- Get all configured events for all units
-------------------------------------------------------
INSERT INTO @EventTypes
SELECT DISTINCT
 	 ec.pu_id,
 	 EventTypeId = ec.et_id, 
 	 EventSubTypeId = es.event_subtype_id, 
 	 EventDescription = COALESCE(es.event_subtype_desc, et.et_desc)  
  FROM Event_Configuration ec
  JOIN Event_Types et ON et.et_id = ec.et_id
  LEFT OUTER JOIN Event_Subtypes es ON es.event_subtype_id = ec.event_subtype_id 
  WHERE ec.PU_Id IN (SELECT pu_id FROM @UnitTable) and 
        ec.et_id NOT IN (0,4,5,6,7,8,9,10,11,16,17,18,19,20,21,22) 
-------------------------------------------------------
-- Select only the events that are common to all units
-------------------------------------------------------
SELECT EventTypeId, EventSubTypeId, EventDescription, Sum(1) [good]
FROM @EventTypes
GROUP BY EventTypeId, EventSubTypeId, EventDescription
HAVING SUM(1) = @Count
/*
If Additional Events Are Required
Use Stored Proc spASP_AppEventAnalysisEvents and pass in variables as 2nd parameter
*/
