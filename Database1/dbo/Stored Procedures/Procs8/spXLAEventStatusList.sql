-- DESCRIPTION: spXLAEventStatusList returns "Event Status" ID and description. PrfXla.XLA call this to generate a 
-- drop down event status list which will server as filter in Event Search. MT/3-26-2002
CREATE PROCEDURE dbo.spXLAEventStatusList
AS
SELECT ps.ProdStatus_Id, ps.ProdStatus_Desc FROM Production_Status ps ORDER BY ps.ProdStatus_Desc
