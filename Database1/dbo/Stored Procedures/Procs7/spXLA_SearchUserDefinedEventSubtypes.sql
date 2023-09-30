-- ECR #27894: mt/5-5-2004: Service stored procedure to Search Reason: Get PU_Id for User-Defined Events
-- Get a list of Event subtypes associated with User-Defined Events for a given PU_Id
CREATE PROCEDURE dbo.spXLA_SearchUserDefinedEventSubtypes
 	 @PU_Id  Integer
AS
  SELECT DISTINCT ec.Event_Subtype_Id, es.Event_Subtype_Desc
    FROM Event_Configuration ec 
    JOIN Event_Subtypes es ON es.Event_Subtype_Id = ec.Event_Subtype_Id
   WHERE ec.Event_Subtype_Id Is NOT NULL AND ec.ET_Id = 14 AND ec.PU_Id = @PU_Id
ORDER BY ec.Event_Subtype_Id
