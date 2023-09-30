CREATE PROCEDURE dbo.spXLAGetEventSubtypeID 
 	 @Event_Subtype_Desc  varchar(50) 
AS 
SELECT Event_Subtype_Id FROM Event_Subtypes WHERE Event_Subtype_Desc = @Event_Subtype_Desc  
