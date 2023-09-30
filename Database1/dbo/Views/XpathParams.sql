CREATE VIEW dbo.XpathParams
AS
SELECT     ElementId, ParamName, xPathExpr
FROM         dbo.PdbProcsDS_R_PdbParmXpathDS
