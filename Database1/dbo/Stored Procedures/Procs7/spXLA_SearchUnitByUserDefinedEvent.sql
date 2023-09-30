-- ECR #27894: mt/5-4-2004: Service stored procedure to Search Reason: Get PU_Id for User-Defined Events
-- Get a list of Production Units which are associated with User-Defined Events
CREATE PROCEDURE dbo.spXLA_SearchUnitByUserDefinedEvent
AS
  SELECT DISTINCT ec.PU_Id, pu.PU_Desc
    FROM Event_Configuration ec 
    JOIN Prod_Units pu ON pu.PU_ID = ec.PU_Id 
   WHERE Event_Subtype_Id Is NOT NULL AND ET_Id = 14 --14 is User-Defined Event
ORDER BY pu.PU_Desc
