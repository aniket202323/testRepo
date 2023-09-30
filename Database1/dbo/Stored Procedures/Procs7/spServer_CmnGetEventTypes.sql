-- =============================================
-- Author: 	  	 <Tom Nettell>
-- Create date: <5/2/2011>
-- Description: 	 <retuns event types>
-- =============================================
CREATE PROCEDURE [dbo].[spServer_CmnGetEventTypes]
AS
BEGIN
 	 Select ET_Id,ET_Desc,Parent_ET_Id,IsTimeBased,ValidateTestData From Event_Types
END
